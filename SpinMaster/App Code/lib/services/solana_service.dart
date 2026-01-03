import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solana/solana.dart';
import 'package:solana/encoder.dart';
import 'package:solana/base58.dart';
import 'package:solana_mobile_client/solana_mobile_client.dart';
import 'package:wheeler/services/config.dart';
import 'package:wheeler/services/auth_api.dart';
import 'package:wheeler/services/daily_spin_service.dart';
import 'package:wheeler/services/wheel_manage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SolanaState {
  final AuthorizationResult? authorizationResult;
  final bool isMainnet;
  final bool isRequestingAirdrop;

  const SolanaState({
    this.authorizationResult,
    this.isMainnet = false,
    this.isRequestingAirdrop = false,
  });

  bool get isAuthorized => authorizationResult != null;

  String? get address {
    final publicKey = authorizationResult?.publicKey;
    if (publicKey == null) return null;
    return Ed25519HDPublicKey(publicKey).toBase58();
  }

  SolanaState copyWith({
    AuthorizationResult? authorizationResult,
    bool? isMainnet,
    bool? isRequestingAirdrop,
    bool clearAuth = false,
  }) {
    return SolanaState(
      authorizationResult: clearAuth
          ? null
          : (authorizationResult ?? this.authorizationResult),
      isMainnet: isMainnet ?? this.isMainnet,
      isRequestingAirdrop: isRequestingAirdrop ?? this.isRequestingAirdrop,
    );
  }
}

class SolanaService extends ChangeNotifier {
  static final SolanaService _instance = SolanaService._internal();

  factory SolanaService() {
    return _instance;
  }

  SolanaService._internal() {
    _initializeClient();
    _loadAuthData();
  }

  static const String _storagePrefix = 'solana_auth_';

  SolanaState _state = const SolanaState();
  SolanaState get state => _state;

  late SolanaClient _solanaClient;

  void _initializeClient() {
    final envCluster = dotenv.get('SOLANA_CLUSTER', fallback: 'devnet');
    final bool useMainnet = envCluster == 'mainnet-beta' || _state.isMainnet;

    final rpcUrl = useMainnet ? mainnetRpcUrl : devnetRpcUrl;
    final websocketUrl = useMainnet ? mainnetWsUrl : devnetWsUrl;

    debugPrint('MWA: Cluster from Env: $envCluster');
    debugPrint('MWA: RPC URL: $rpcUrl');
    debugPrint('MWA: Websocket URL: $websocketUrl');

    _solanaClient = SolanaClient(
      rpcUrl: Uri.parse(rpcUrl),
      websocketUrl: Uri.parse(websocketUrl),
    );
  }

  void updateNetwork(bool isMainnet) {
    if (_state.isMainnet == isMainnet) return;
    _state = _state.copyWith(isMainnet: isMainnet);
    _initializeClient();
    notifyListeners();
  }

  Future<void> _loadAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('${_storagePrefix}token');
      final publicKeyBase64 = prefs.getString('${_storagePrefix}pubkey');
      final label = prefs.getString('${_storagePrefix}label');
      final walletUri = prefs.getString('${_storagePrefix}uri');

      if (authToken != null && publicKeyBase64 != null) {
        final publicKey = base64Decode(publicKeyBase64);
        final result = AuthorizationResult(
          authToken: authToken,
          publicKey: Uint8List.fromList(publicKey),
          accountLabel: label,
          walletUriBase: walletUri != null ? Uri.parse(walletUri) : null,
        );
        _state = _state.copyWith(authorizationResult: result);
        notifyListeners();
        debugPrint('MWA: Loaded persisted auth data for ${state.address}');
      }
    } catch (e) {
      debugPrint('MWA: Error loading persisted auth: $e');
    }
  }

  Future<void> _saveAuthData(AuthorizationResult? result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (result != null) {
        await prefs.setString('${_storagePrefix}token', result.authToken);
        await prefs.setString(
          '${_storagePrefix}pubkey',
          base64Encode(result.publicKey),
        );
        if (result.accountLabel != null) {
          await prefs.setString('${_storagePrefix}label', result.accountLabel!);
        }
        if (result.walletUriBase != null) {
          await prefs.setString(
            '${_storagePrefix}uri',
            result.walletUriBase.toString(),
          );
        }
      } else {
        await _clearAuthData();
      }
    } catch (e) {
      debugPrint('MWA: Error saving auth data: $e');
    }
  }

  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_storagePrefix}token');
      await prefs.remove('${_storagePrefix}pubkey');
      await prefs.remove('${_storagePrefix}label');
      await prefs.remove('${_storagePrefix}uri');
    } catch (e) {
      debugPrint('MWA: Error clearing auth data: $e');
    }
  }

  // --- MWA Core Flow (Matching Example Pattern) ---

  Future<bool> authorize() async {
    try {
      debugPrint('MWA: Creating LocalAssociationScenario for authorize...');
      final session = await LocalAssociationScenario.create();

      debugPrint('MWA: Starting Activity for result...');
      session.startActivityForResult(null).ignore();

      debugPrint('MWA: Waiting for session start...');
      final client = await session.start();

      final success = await _doAuthorize(client);

      // Authenticate with backend after successful wallet connection
      // We do this BEFORE closing the session to avoid a second popup
      bool backendSuccess = false;
      if (success) {
        debugPrint(
          'MWA: Wallet authorized, authenticating with backend (in-session)...',
        );
        backendSuccess = await authenticateWithBackend(existingClient: client);
      }

      await session.close();

      if (success && !backendSuccess) {
        debugPrint(
          'MWA: Backend authentication failed! Clearing local auth...',
        );
        // Clear local auth state since backend login failed
        _state = _state.copyWith(clearAuth: true);
        await _clearAuthData();
        notifyListeners();
        return false;
      }

      return success && backendSuccess;
    } catch (e, stack) {
      debugPrint('MWA: ERROR in authorize: $e');
      debugPrint('MWA: STACKTRACE: $stack');
      return false;
    }
  }

  Future<bool> reauthorize() async {
    final authToken = _state.authorizationResult?.authToken;
    if (authToken == null) return false;

    try {
      debugPrint('MWA: Creating LocalAssociationScenario for reauthorize...');
      final session = await LocalAssociationScenario.create();

      debugPrint('MWA: Starting Activity for result...');
      session.startActivityForResult(null).ignore();

      debugPrint('MWA: Waiting for session start...');
      final client = await session.start();

      final success = await _doReauthorize(client);
      await session.close();
      return success;
    } catch (e, stack) {
      debugPrint('MWA: ERROR in reauthorize: $e');
      debugPrint('MWA: STACKTRACE: $stack');
      return false;
    }
  }

  Future<void> deauthorize() async {
    final authToken = _state.authorizationResult?.authToken;
    if (authToken == null) {
      _state = _state.copyWith(clearAuth: true);
      await _clearAuthData();
      notifyListeners();
      return;
    }

    try {
      debugPrint('MWA: Creating LocalAssociationScenario for deauthorize...');
      final session = await LocalAssociationScenario.create();

      debugPrint('MWA: Starting Activity for result...');
      session.startActivityForResult(null).ignore();

      debugPrint('MWA: Waiting for session start...');
      final client = await session.start();

      await client.deauthorize(authToken: authToken);
      await session.close();

      _state = _state.copyWith(clearAuth: true);
      await _clearAuthData();
      debugPrint('MWA: Deauthorized successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('MWA: Error during deauthorize: $e');
      _state = _state.copyWith(clearAuth: true);
      await _clearAuthData();
      notifyListeners();
    }
  }

  /// Clear authentication state locally (without calling wallet app)
  Future<void> clearLocalSession() async {
    _state = _state.copyWith(clearAuth: true);
    await _clearAuthData();
    notifyListeners();
  }

  // --- Transaction Helpers ---

  Future<String?> transferSol(String recipientAddress, double amountSol) async {
    final session = await LocalAssociationScenario.create();
    session.startActivityForResult(null).ignore();

    try {
      final client = await session.start();

      bool authorized = await _doReauthorize(client);
      if (!authorized) {
        debugPrint('MWA: Reauthorize failed, trying fresh authorization...');
        authorized = await _doAuthorize(client);
      }

      if (authorized) {
        final publicKey = _state.authorizationResult?.publicKey;
        if (publicKey == null) return null;

        final sender = Ed25519HDPublicKey(publicKey);
        final lamports = (amountSol * 1000000000).toInt();

        // fetch blockhash
        final blockhashVal = await _solanaClient.rpcClient
            .getLatestBlockhash()
            .then((it) => it.value.blockhash);

        // Create instruction
        final instruction = SystemInstruction.transfer(
          fundingAccount: sender,
          recipientAccount: Ed25519HDPublicKey.fromBase58(recipientAddress),
          lamports: lamports,
        );

        // Create message
        final message = Message(instructions: [instruction]);

        // Create transaction
        // With 'solana' package 0.30+, building transactions is slightly different.
        // We construct a CompiledMessage.
        final compiledMessage = message.compile(
          recentBlockhash: blockhashVal,
          feePayer: sender,
        );

        // Create a transaction with empty signature for the sender
        final tx = SignedTx(
          compiledMessage: compiledMessage,
          signatures: [Signature(List.filled(64, 0), publicKey: sender)],
        );

        final txBytes = Uint8List.fromList(tx.toByteArray().toList());

        // Send to MWA
        final result = await client.signAndSendTransactions(
          transactions: [txBytes],
        );

        if (result.signatures.isNotEmpty) {
          // signatures are in bytes, need to base58 encode
          final sigBytes = result.signatures.first;
          return base58encode(sigBytes);
        }
      }
    } catch (e) {
      debugPrint('MWA: Error in transferSol: $e');
    } finally {
      await session.close();
    }
    return null;
  }

  // --- Private Helper Methods (Matching _do... patterns) ---

  Future<bool> _doAuthorize(MobileWalletAdapterClient client) async {
    try {
      final envCluster = dotenv.get('SOLANA_CLUSTER', fallback: 'devnet');
      final cluster = _state.isMainnet ? mainnetCluster : envCluster;

      // Kiểm tra khả năng của ví
      final capabilities = await client.getCapabilities();
      debugPrint(
        'MWA: Wallet capabilities: ${capabilities?.supportsCloneAuthorization}',
      );

      debugPrint('MWA: Sending authorize request Cluster: $cluster');

      final result = await client.authorize(
        identityUri: Uri.parse('https://seekspin.app'),
        iconUri: Uri.parse('favicon.png'),
        identityName: 'SeekSpin',
        cluster: cluster,
      );

      _state = _state.copyWith(authorizationResult: result);
      await _saveAuthData(result);
      debugPrint('MWA: Authorize result received: ${result != null}');
      notifyListeners();
      return result != null;
    } catch (e) {
      debugPrint('MWA: Error during _doAuthorize: $e');
      return false;
    }
  }

  Future<bool> _doReauthorize(MobileWalletAdapterClient client) async {
    final authToken = _state.authorizationResult?.authToken;
    if (authToken == null) return false;

    debugPrint('MWA: Sending reauthorize request...');
    final result = await client.reauthorize(
      identityUri: Uri.parse('https://seekspin.app'),
      iconUri: Uri.parse('https://seekspin.app/favicon.png'),
      identityName: 'SeekSpin',
      authToken: authToken,
    );

    _state = _state.copyWith(authorizationResult: result);
    await _saveAuthData(result);
    debugPrint('MWA: Reauthorize result: ${result != null}');
    notifyListeners();
    return result != null;
  }

  // Legacy compatibility for simple logic
  String? get walletAddress => _state.address;

  // --- Transaction Generation Helpers (Matching Example) ---

  /// Sign a message with the wallet (for backend authentication)
  Future<String?> signMessage(
    String message, {
    MobileWalletAdapterClient? existingClient,
  }) async {
    try {
      debugPrint('MWA: Signing message: $message');

      LocalAssociationScenario? session;
      MobileWalletAdapterClient client;

      if (existingClient != null) {
        client = existingClient;
      } else {
        session = await LocalAssociationScenario.create();
        session.startActivityForResult(null).ignore();
        client = await session.start();
      }

      // Try to reauthorize first, if that fails, try fresh authorization
      // Only trigger re-auth if we created a new session OR if we need to ensure auth
      bool authorized = true;
      if (existingClient == null) {
        authorized = await _doReauthorize(client);
        if (!authorized) {
          debugPrint('MWA: Reauthorize failed, trying fresh authorization...');
          authorized = await _doAuthorize(client);
        }
      }

      if (authorized) {
        final publicKey = _state.authorizationResult?.publicKey;
        if (publicKey == null) {
          debugPrint('MWA: No public key available after authorization');
          await session?.close();
          return null;
        }

        final signer = Ed25519HDPublicKey(publicKey);

        // Convert message to bytes
        final messageBytes = Uint8List.fromList(message.codeUnits);

        debugPrint('MWA: Requesting signature from wallet...');
        // Sign the message
        final result = await client.signMessages(
          messages: [messageBytes],
          addresses: [Uint8List.fromList(signer.bytes)],
        );

        await session?.close();

        // Return base58 encoded signature
        if (result.signedMessages.isNotEmpty) {
          final signedMessage = result.signedMessages.first;
          debugPrint('MWA: Message signed successfully');
          // SignedMessage contains the signatures array
          return base58encode(signedMessage.signatures[0]);
        } else {
          debugPrint('MWA: No signed messages returned');
        }
      } else {
        debugPrint('MWA: Authorization failed, cannot sign message');
      }

      await session?.close();
      return null;
    } catch (e, stack) {
      debugPrint('MWA: Error signing message: $e');
      debugPrint('MWA: Stack trace: $stack');
      return null;
    }
  }

  /// Authenticate with backend after wallet connection
  Future<bool> authenticateWithBackend({
    MobileWalletAdapterClient? existingClient,
  }) async {
    final walletAddr = walletAddress;
    if (walletAddr == null) {
      debugPrint('Backend Auth: No wallet address available');
      return false;
    }

    try {
      debugPrint('Backend Auth: Getting nonce for $walletAddr');
      final nonce = await AuthApi.getNonce(walletAddr);

      debugPrint('Backend Auth: Got nonce, signing message...');
      // Pass existing client to reuse session if available
      final signature = await signMessage(
        nonce,
        existingClient: existingClient,
      );

      if (signature == null) {
        debugPrint('Backend Auth: Failed to sign message');
        return false;
      }

      debugPrint('Backend Auth: Logging in with signature...');
      final response = await AuthApi.login(walletAddr, signature);

      debugPrint('Backend Auth: Login successful!');
      debugPrint('Backend Auth: User ID: ${response['user']['id']}');

      // Sync daily claim status and spins balance from backend
      try {
        final dailySpinService = DailySpinService();
        final wheelProvider = WheelProvider();
        await Future.wait([
          dailySpinService.syncWithBackend(),
          wheelProvider.syncSpinsWithBackend(),
          wheelProvider.syncOfficialWheelConfig(),
        ]);

        debugPrint(
          'Backend Auth: User data synced (Daily claim, Spins, Wheel Config)',
        );
      } catch (e) {
        debugPrint('Backend Auth: Failed to sync user data: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Backend Auth: Error - $e');
      return false;
    }
  }
}

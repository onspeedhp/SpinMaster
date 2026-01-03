import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wheeler/widget/custom_drawer.dart';
import 'package:wheeler/widget/wheel_card.dart';
import 'package:wheeler/services/wheel_manage.dart';
import 'package:wheeler/utils/ui_utils.dart'; // Consolidated to a single import
import '../services/solana_service.dart';
import '../services/mission_service.dart';
import '../services/leaderboard_service.dart';
import '../widget/daily_free_spin_card.dart';
import '../services/spin_api.dart';
import '../services/purchase_api.dart';
import '../services/daily_spin_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class SpinnerHomePage extends StatefulWidget {
  const SpinnerHomePage({super.key});

  @override
  _SpinnerHomePageState createState() => _SpinnerHomePageState();
}

class _SpinnerHomePageState extends State<SpinnerHomePage> {
  List<Map<String, dynamic>> spinHistory = [];
  bool _isLoadingHistory = true;
  int _historyPage = 0;
  final int _itemsPerPage = 7;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _syncServices();
  }

  void _syncServices() {
    // Sync daily spin status with backend
    Provider.of<DailySpinService>(context, listen: false).syncWithBackend();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await SpinApi.getSpinHistory();
      if (mounted) {
        setState(() {
          spinHistory = history.map((item) {
            final DateTime timestamp =
                DateTime.tryParse(item['created_at']) ?? DateTime.now();
            final String rewardType = item['reward_type'] ?? 'none';
            // Simple color mapping
            Color color;
            switch (rewardType) {
              case 'token':
                color = Colors.yellow;
                break;
              case 'extra_spin':
                color = Colors.green;
                break;
              case 'jackpot':
                color = Colors.purpleAccent;
                break;
              default:
                color = Colors.grey;
            }

            return {
              'result': item['result'] ?? 'Spin result',
              'color': color,
              'timestamp': timestamp,
            };
          }).toList();
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  void _showShopDialog({
    required BuildContext dialogContext,
    required WheelProvider provider,
  }) {
    showModalBottomSheet(
      context: dialogContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16213e),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: const Color(0xFFF48FB1).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF48FB1).withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: Color(0xFFF48FB1),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'GET MORE SPINS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildShopItem(ctx, provider, 10, 0.1, isBestValue: false),
            const SizedBox(height: 12),
            _buildShopItem(ctx, provider, 25, 0.2, isPopular: true),
            const SizedBox(height: 12),
            _buildShopItem(ctx, provider, 50, 0.35, isBestValue: true),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildShopItem(
    BuildContext ctx,
    WheelProvider provider,
    int spins,
    double price, {
    bool isPopular = false,
    bool isBestValue = false,
  }) {
    final borderColor = isPopular || isBestValue
        ? const Color(0xFFF48FB1)
        : Colors.white10;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10), // Space for badge
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1a1a2e),
                const Color(0xFF16213e).withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor.withValues(
                alpha: isPopular || isBestValue ? 0.6 : 0.2,
              ),
              width: isPopular || isBestValue ? 1.5 : 1,
            ),
            boxShadow: [
              if (isPopular || isBestValue)
                BoxShadow(
                  color: const Color(0xFFF48FB1).withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                // Trigger Purchase Logic
                _handlePurchase(ctx, provider, spins, price);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF48FB1).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.flash_on,
                          color: Color(0xFFF48FB1),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$spins Spins',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$price SOL',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF48FB1),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFF48FB1,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'BUY',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isPopular)
          Positioned(
            top: 0,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'POPULAR',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (isBestValue)
          Positioned(
            top: 0,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'BEST VALUE',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _handlePurchase(
    BuildContext ctx,
    WheelProvider provider,
    int spins,
    double price,
  ) async {
    Navigator.pop(ctx);
    final statusNotifier = ValueNotifier<String>('Confirm in your wallet...');
    _showLoadingPurchase(ctx, statusNotifier);

    try {
      // 1. Get Treasury Wallet
      statusNotifier.value = 'Preparing transaction...';
      final config = await PurchaseApi.getPackages();
      final String? treasuryWallet = config['treasuryWallet'];

      if (treasuryWallet == null || treasuryWallet.isEmpty) {
        throw Exception('Treasury wallet not configured');
      }

      // 2. Perform SOL Transfer
      if (!mounted) return;
      final solanaService = Provider.of<SolanaService>(context, listen: false);
      final signature = await solanaService.transferSol(treasuryWallet, price);

      if (signature == null) {
        // User cancelled or failed to sign
        if (context.mounted) {
          Navigator.pop(context); // Hide loading
          UIUtils.showMessageDialog(
            context,
            title: 'Payment Cancelled',
            message: 'You cancelled the transaction.',
            isError: true,
          );
        }
        return;
      }

      // Update status after signature
      statusNotifier.value = 'Verifying on-chain...';
      debugPrint('Transaction sent: $signature. Verifying...');

      // 3. Verify with Backend
      final result = await PurchaseApi.purchaseSpins(
        txSignature: signature,
        packageId: spins,
      );

      if (context.mounted) {
        Navigator.pop(context); // Hide loading

        if (result.containsKey('error')) {
          UIUtils.showMessageDialog(
            context,
            title: 'Payment Error',
            message: 'Verification failed: ${result['error']}',
            isError: true,
          );
        } else {
          // Success!
          provider.addSpins(
            spins,
          ); // Optimistic update, but backend should return balance too
          if (result.containsKey('spinsBalance')) {
            provider.setBalanceAfterSpin(result['spinsBalance']);
          }

          UIUtils.showMessageDialog(
            context,
            title: 'Success',
            message: 'Successfully purchased $spins spins!',
          );
        }
      }
    } catch (e) {
      debugPrint('Purchase error: $e');
      if (context.mounted) {
        Navigator.pop(context); // Hide loading
        UIUtils.showMessageDialog(
          context,
          title: 'Error',
          message: 'An error occurred: $e',
          isError: true,
        );
      }
    }
  }

  void _showLoadingPurchase(
    BuildContext ctx,
    ValueNotifier<String> statusNotifier,
  ) {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: 280,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFFF48FB1).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF48FB1).withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFF48FB1,
                            ).withValues(alpha: 0.25),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFF48FB1),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.security_rounded,
                      color: Color(0xFFF48FB1),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'PROCESSING',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: statusNotifier,
                  builder: (context, status, _) {
                    return Text(
                      status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.none,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addToHistory(String result, Color color) {
    // Check if it's the official wheel (ID: seek_spin_official)
    final wheelProvider = Provider.of<WheelProvider>(context, listen: false);
    final isOfficial = wheelProvider.currentWheel?.id == 'seek_spin_official';

    setState(() {
      spinHistory.insert(0, {
        'result': result,
        'color': color,
        'timestamp': DateTime.now(),
      });
      if (spinHistory.length > 50) {
        spinHistory = spinHistory.sublist(0, 50);
      }
      _historyPage = 0; // Reset to first page on new spin
    });

    if (isOfficial) {
      // Sync balance after spin complete to be absolute sure it matches backend
      wheelProvider.syncSpinsWithBackend();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WheelProvider>(
      builder: (context, wheelProvider, child) {
        final currentWheel = wheelProvider.currentWheel;
        if (currentWheel == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Spin Master'),
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('No wheels available')),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'SEEKSPIN',
              style: TextStyle(
                color: Color(0xFFF48FB1),
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    color: Color(0x80F48FB1),
                    blurRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            foregroundColor: const Color(0xFFF48FB1),
            actions: [
              Consumer<SolanaService>(
                builder: (context, solanaService, _) {
                  final address = solanaService.state.address;
                  final displayAddress = address != null
                      ? '${address.substring(0, 4)}...${address.substring(address.length - 4)}'
                      : 'Not Connected';

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213e).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFF48FB1).withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF48FB1).withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 14,
                          color: address != null
                              ? const Color(0xFFF48FB1)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          drawer: CustomDrawer(),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF000000),
                  Color(0xFF16213e),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 100,
                  left: -50,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF48FB1).withValues(alpha: 0.03),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 200,
                  right: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF48FB1).withValues(alpha: 0.04),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 20,
                                ),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(
                                        0xFF16213e,
                                      ).withValues(alpha: 0.9),
                                      const Color(
                                        0xFF1a1a2e,
                                      ).withValues(alpha: 0.9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFF48FB1,
                                    ).withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFF48FB1,
                                      ).withValues(alpha: 0.2),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.bolt,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'AVAILABLE SPINS',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${wheelProvider.spinsBalance}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900,
                                            shadows: [
                                              BoxShadow(
                                                color: Colors.white.withValues(
                                                  alpha: 0.5,
                                                ),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFF48FB1,
                                            ).withValues(alpha: 0.4),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _showShopDialog(
                                            dialogContext: context,
                                            provider: wheelProvider,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFF48FB1,
                                          ),
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.add_circle_outline,
                                              size: 18,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'GET SPINS',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                child: const DailyFreeSpinCard(),
                              ),
                              const SizedBox(height: 20),
                              WheelCard(
                                segments: currentWheel.segments,
                                wheelName: currentWheel.name,
                                onSpinComplete: (result, color) {
                                  _addToHistory(result, color);
                                  Provider.of<MissionService>(
                                    context,
                                    listen: false,
                                  ).recordSpin();
                                  Provider.of<LeaderboardService>(
                                    context,
                                    listen: false,
                                  ).recordSpin(rewardValue: 10);
                                },
                                onSpinRequest: () async {
                                  final isOfficial =
                                      wheelProvider.currentWheel?.id ==
                                      'seek_spin_official';
                                  if (isOfficial) {
                                    try {
                                      final result =
                                          await SpinApi.executeSpin();
                                      if (result.containsKey('error')) {
                                        if (context.mounted) {
                                          UIUtils.showMessageDialog(
                                            context,
                                            title: 'Spin Error',
                                            message: result['error'],
                                            isError: true,
                                          );
                                        }
                                        return -1;
                                      }
                                      final int targetIndex =
                                          result['result']['index'];
                                      final int newBalance =
                                          result['spinsBalance'];
                                      wheelProvider.setBalanceAfterSpin(
                                        newBalance,
                                      );
                                      return targetIndex;
                                    } catch (e) {
                                      if (context.mounted) {
                                        UIUtils.showMessageDialog(
                                          context,
                                          title: 'Connection Error',
                                          message:
                                              'Failed to connect to server.',
                                          isError: true,
                                        );
                                      }
                                      return -1;
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              Container(
                                margin: const EdgeInsets.only(
                                  bottom: 30,
                                  left: 16,
                                  right: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF16213e,
                                  ).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.only(
                                  left: 24.0,
                                  right: 24.0,
                                  top: 24.0,
                                  bottom: 4.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.history,
                                              color: Color(0xFFF48FB1),
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'RECENT HISTORY',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (spinHistory.isNotEmpty)
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                spinHistory.clear();
                                              });
                                              UIUtils.showMessageDialog(
                                                context,
                                                title: 'Success',
                                                message: 'History cleared',
                                              );
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'CLEAR',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (_isLoadingHistory)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(32.0),
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFFF48FB1),
                                                ),
                                          ),
                                        ),
                                      )
                                    else if (spinHistory.isEmpty)
                                      Container(
                                        height: 100,
                                        alignment: Alignment.center,
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.casino_outlined,
                                              size: 32,
                                              color: Colors.white24,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Spin to make history!',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white38,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else ...[
                                      ListView.separated(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount:
                                            (spinHistory.length -
                                                    (_historyPage *
                                                        _itemsPerPage))
                                                .clamp(0, _itemsPerPage),
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final int itemIndex =
                                              (_historyPage * _itemsPerPage) +
                                              index;
                                          if (itemIndex >= spinHistory.length) {
                                            return const SizedBox.shrink();
                                          }
                                          final item = spinHistory[itemIndex];
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.05,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.05,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: item['color']
                                                        .withValues(alpha: 0.2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.star,
                                                      size: 16,
                                                      color: item['color'],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    item['result'],
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black26,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    timeago.format(
                                                      item['timestamp'],
                                                      locale: 'en_short',
                                                    ),
                                                    style: const TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.chevron_left,
                                              color: Colors.white,
                                            ),
                                            onPressed: _historyPage > 0
                                                ? () {
                                                    setState(() {
                                                      _historyPage--;
                                                    });
                                                  }
                                                : null,
                                          ),
                                          Text(
                                            '${_historyPage + 1} / ${((spinHistory.length - 1) / _itemsPerPage).floor() + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.chevron_right,
                                              color: Colors.white,
                                            ),
                                            onPressed:
                                                (_historyPage + 1) *
                                                        _itemsPerPage <
                                                    spinHistory.length
                                                ? () {
                                                    setState(() {
                                                      _historyPage++;
                                                    });
                                                  }
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

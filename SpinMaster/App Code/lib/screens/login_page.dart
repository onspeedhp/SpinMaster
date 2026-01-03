import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/solana_service.dart';
import 'spinner_home_page.dart';
import '../utils/ui_utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _handleConnectWallet() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<SolanaService>().authorize();
      if (success && mounted) {
        // Navigate to Home Page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SpinnerHomePage()),
        );
      } else {
        if (mounted) {
          UIUtils.showMessageDialog(
            context,
            title: 'Connect Wallet Error',
            message: 'Failed to connect wallet. Please try again.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showMessageDialog(
          context,
          title: 'Error',
          message: 'An error occurred: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e), // Deep Navy
              Color(0xFF000000), // Pure Black
              Color(0xFF16213e), // Darker Navy
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background Decorative Elements (Subtle glows)
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF48FB1).withValues(alpha: 0.05),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo / Visual Element
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(
                                  0xFFF48FB1,
                                ).withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                          ),
                          // Inner glow
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF48FB1,
                                  ).withValues(alpha: 0.15),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 60,
                              color: Color(0xFFF48FB1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // App Title
                      const Text(
                        'SeekSpin',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(color: Color(0xFFF48FB1), blurRadius: 10),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'EXPERIENCE THE FUTURE OF SPIN',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 80),

                      // Connection Status / Action
                      if (_isLoading)
                        const Column(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFF48FB1),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'CONNECTING...',
                              style: TextStyle(
                                color: Color(0xFFF48FB1),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: _handleConnectWallet,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF48FB1),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 10,
                                  shadowColor: const Color(
                                    0xFFF48FB1,
                                  ).withValues(alpha: 0.4),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.account_balance_wallet_rounded),
                                    SizedBox(width: 16),
                                    Text(
                                      'CONNECT WALLET',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Secondary Info
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Solana Network Active',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                      const SizedBox(height: 60),

                      // Developed by / Powered by
                      Opacity(
                        opacity: 0.8,
                        child: Column(
                          children: [
                            const Text(
                              'POWERED BY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Image.network(
                              'https://cryptologos.cc/logos/solana-sol-logo.png?v=024',
                              height: 24,
                              errorBuilder: (ctx, _, __) => const Text(
                                'SOLANA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Dev Only Section
                      if (!kReleaseMode) ...[
                        TextButton.icon(
                          onPressed: () async {
                            await context
                                .read<SolanaService>()
                                .clearLocalSession();
                            if (context.mounted) {
                              UIUtils.showMessageDialog(
                                context,
                                title: 'Dev Info',
                                message: 'Dev: Wallet Disconnected',
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.link_off,
                            color: Colors.redAccent,
                            size: 16,
                          ),
                          label: const Text(
                            'FORCE DISCONNECT (DEV)',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

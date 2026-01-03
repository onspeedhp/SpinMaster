import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/solana_service.dart';
import 'spinner_home_page.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to connect wallet. Please try again.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      backgroundColor: Colors.black, // Dark rich background
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo or Title
                Icon(
                  Icons.change_circle_outlined, // Placeholder logo
                  size: 100,
                  color: const Color(0xFFF48FB1),
                ),
                SizedBox(height: 20),
                Text(
                  'SeekSpin',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Spin to Win - Play to Earn',
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
                SizedBox(height: 60),

                // Connect Button
                _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFF48FB1),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _handleConnectWallet,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFF48FB1),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                color: const Color(0xFFF48FB1),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'CONNECT WALLET',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF48FB1),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                SizedBox(height: 20),
                Text(
                  'Powered by Solana',
                  style: TextStyle(fontSize: 12, color: Colors.white24),
                ),
                // Dev Only: Disconnect Button
                if (!kReleaseMode) ...[
                  SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () async {
                      await context.read<SolanaService>().deauthorize();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Dev: Wallet Disconnected')),
                        );
                      }
                    },
                    icon: Icon(Icons.link_off, color: Colors.redAccent),
                    label: Text(
                      'DEV: Force Disconnect',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

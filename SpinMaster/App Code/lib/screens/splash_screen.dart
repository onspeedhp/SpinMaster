import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/solana_service.dart';
import '../services/daily_spin_service.dart';
import '../services/wheel_manage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash animation/delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      final accessToken = await ApiService.getAccessToken();
      final solanaService = Provider.of<SolanaService>(context, listen: false);

      // Check if we have both backend token and authorized wallet
      if (accessToken != null && solanaService.state.isAuthorized) {
        debugPrint('Splash: Auto-login detected! Syncing data...');

        // Sync vital data before entering
        await Future.wait([
          DailySpinService().syncWithBackend(),
          WheelProvider().syncSpinsWithBackend(),
          WheelProvider().syncOfficialWheelConfig(),
        ]);

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        debugPrint('Splash: No valid auth found, going to login');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      debugPrint('Splash: Error during auth check: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black, // Match app theme
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/preloader.png',
                width: 300,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF48FB1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

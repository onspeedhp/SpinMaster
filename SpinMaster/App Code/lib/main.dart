import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/wheel_manage.dart';
import 'services/solana_service.dart';
import 'services/daily_spin_service.dart';
import 'services/mission_service.dart';
import 'services/leaderboard_service.dart';
import 'screens/login_page.dart';
import 'screens/spinner_home_page.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WheelProvider()),
        ChangeNotifierProvider(create: (_) => SolanaService()),
        ChangeNotifierProvider(create: (_) => DailySpinService()),
        ChangeNotifierProvider(create: (_) => MissionService()),
        ChangeNotifierProvider(create: (_) => LeaderboardService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SeekSpin',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFFF48FB1),
          scaffoldBackgroundColor: Colors.black,
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFFF48FB1),
            secondary: const Color(0xFFF48FB1),
            surface: Colors.grey[900]!,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginPage(),
          '/home': (context) => const SpinnerHomePage(),
        },
      ),
    );
  }
}

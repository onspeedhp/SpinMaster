// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wheeler/screens/leaderboard_page.dart';
import 'package:wheeler/services/solana_service.dart';
import 'package:wheeler/screens/custom_wheels_list_page.dart';
import 'package:wheeler/services/auth_api.dart';
import 'package:wheeler/utils/ui_utils.dart';

class CustomDrawer extends StatelessWidget {
  final String currentRoute;

  const CustomDrawer({super.key, this.currentRoute = '/home'});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e), // Deep Navy
              Color(0xFF000000), // Pure Black
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFF48FB1,
                            ).withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      // Using a simpler placeholder-like logo container if asset logic needs adjustment,
                      // but keeping original asset for now.
                      child: Image.asset(
                        'assets/images/extend_logo.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 2,
                      width: 50,
                      color: const Color(0xFFF48FB1).withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 30),
                    // Wallet Info Card
                    Consumer<SolanaService>(
                      builder: (context, solanaService, _) {
                        final address = solanaService.state.address;
                        final displayAddress = address != null
                            ? '${address.substring(0, 8)}...${address.substring(address.length - 8)}'
                            : 'Not Connected';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: address != null
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (address != null
                                                      ? Colors.greenAccent
                                                      : Colors.redAccent)
                                                  .withValues(alpha: 0.5),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    address != null
                                        ? 'CONNECTED'
                                        : 'DISCONNECTED',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: Color(0xFFF48FB1),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      displayAddress,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.dashboard_rounded,
                      title: 'Home',
                      onTap: () {
                        if (currentRoute == '/home') {
                          Navigator.pop(context);
                        } else {
                          // Navigate to home and clear stack until home
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/home', (route) => false);
                        }
                      },
                      isActive: currentRoute == '/home',
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.pie_chart_rounded,
                      title: 'My Wheels',
                      onTap: () {
                        if (currentRoute == '/custom_wheels') {
                          Navigator.pop(context);
                        } else {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CustomWheelsListPage(),
                            ),
                          );
                        }
                      },
                      isActive: currentRoute == '/custom_wheels',
                    ),
                    const SizedBox(height: 12),
                    _buildMenuItem(
                      context,
                      icon: Icons.leaderboard_rounded,
                      title: 'Leaderboards',
                      onTap: () {
                        if (currentRoute == '/leaderboard') {
                          Navigator.pop(context);
                        } else {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LeaderboardPage(),
                            ),
                          );
                        }
                      },
                      isActive: currentRoute == '/leaderboard',
                    ),
                  ],
                ),
              ),

              // Footer / Logout
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Divider(color: Colors.white12),
                    const SizedBox(height: 16),
                    _buildLogoutButton(context),
                    const SizedBox(height: 16),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        overlayColor: WidgetStateProperty.all(
          const Color(0xFFF48FB1).withValues(alpha: 0.1),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFF48FB1).withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? const Color(0xFFF48FB1).withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFFF48FB1) : Colors.white70,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? const Color(0xFFF48FB1) : Colors.white,
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF48FB1),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2d1f2a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Show confirmation dialog
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF1a1a2e),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Are you sure you want to logout?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );

            if (confirmed == true) {
              if (Navigator.canPop(context)) Navigator.pop(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF48FB1)),
                ),
              );

              try {
                await AuthApi.logout();
                final solanaService = Provider.of<SolanaService>(
                  context,
                  listen: false,
                );
                await solanaService.clearLocalSession();

                // Dismiss loading dialog
                if (Navigator.canPop(context)) {
                  Navigator.of(context, rootNavigator: true).pop();
                }

                // Navigate to Login Page
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);

                // Show success message after navigation
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (context.mounted) {
                    UIUtils.showMessageDialog(
                      context,
                      title: 'Logout',
                      message: 'Logged out successfully',
                    );
                  }
                });
              } catch (e) {
                // Dismiss loading dialog on error
                if (Navigator.canPop(context)) {
                  Navigator.of(context, rootNavigator: true).pop();
                }

                if (context.mounted) {
                  UIUtils.showMessageDialog(
                    context,
                    title: 'Status',
                    message: 'Logout failed: $e',
                    isError: true,
                  );
                }
              }
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                SizedBox(width: 10),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/daily_spin_service.dart';
import '../services/wheel_manage.dart';
import '../services/mission_service.dart';

/// Widget displaying daily free spin button with countdown
class DailyFreeSpinCard extends StatelessWidget {
  const DailyFreeSpinCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<DailySpinService, WheelProvider, MissionService>(
      builder: (context, dailySpinService, wheelProvider, missionService, _) {
        final status = dailySpinService.status;
        final isAvailable = status.isAvailable;

        return Container(
          // Removed horizontal margin to match parent alignment (handled by parent padding)
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isAvailable
                ? const LinearGradient(
                    colors: [
                      Color(0xFF2E0C1A), // Darker Pink/Purple
                      Color(0xFF1a1a2e),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF121212), Color(0xFF0d0d16)],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isAvailable
                  ? const Color(0xFFF48FB1).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              if (isAvailable)
                BoxShadow(
                  color: const Color(0xFFF48FB1).withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? const Color(0xFFF48FB1).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isAvailable
                            ? Icons.card_giftcard
                            : Icons.timer_outlined,
                        color: isAvailable
                            ? const Color(0xFFF48FB1)
                            : Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAvailable ? 'DAILY GIFT' : 'COOLDOWN ACTIVE',
                            style: TextStyle(
                              color: isAvailable
                                  ? const Color(0xFFF48FB1)
                                  : Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAvailable
                                ? 'Claim your free spin!'
                                : 'Next reward unlocks in...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action / Timer Section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: isAvailable
                    ? _buildClaimButton(
                        context,
                        dailySpinService,
                        wheelProvider,
                        missionService,
                      )
                    : _buildCountdownDisplay(
                        dailySpinService.getCountdownString(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClaimButton(
    BuildContext context,
    DailySpinService dailySpinService,
    WheelProvider wheelProvider,
    MissionService missionService,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final claimed = await dailySpinService.claimDailySpin();
          if (claimed) {
            wheelProvider.addSpins(1);
            await missionService.recordDailyFreeClaim();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Daily free spin claimed! +1 spin added'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF48FB1),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: const Color(0xFFF48FB1).withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.touch_app, size: 20),
            SizedBox(width: 8),
            Text(
              'CLAIM REWARD',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownDisplay(String countdown) {
    // Assuming countdown comes in format HH:MM:SS
    final parts = countdown.split(':');
    if (parts.length != 3) {
      // Fallback if format is different
      return Center(
        child: Text(countdown, style: const TextStyle(color: Colors.white)),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeBox(parts[0], 'HRS'),
        _buildSeparator(),
        _buildTimeBox(parts[1], 'MIN'),
        _buildSeparator(),
        _buildTimeBox(parts[2], 'SEC'),
      ],
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

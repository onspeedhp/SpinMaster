import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/daily_spin_service.dart';
import 'package:wheeler/utils/ui_utils.dart';
import '../services/wheel_manage.dart';
import '../services/mission_service.dart';

/// Widget displaying daily free spin button with countdown in premium style
/// Optimized for minimum height as requested.
class DailyFreeSpinCard extends StatelessWidget {
  const DailyFreeSpinCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<DailySpinService, WheelProvider, MissionService>(
      builder: (context, dailySpinService, wheelProvider, missionService, _) {
        final status = dailySpinService.status;
        final isAvailable = status.isAvailable;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
          decoration: BoxDecoration(
            gradient: isAvailable
                ? const LinearGradient(
                    colors: [Color(0xFF2E0C1A), Color(0xFF1a1a2e)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF111111), Color(0xFF0d0d16)],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAvailable
                  ? const Color(0xFFF48FB1).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    // Small Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: isAvailable
                            ? const LinearGradient(
                                colors: [Color(0xFFF48FB1), Color(0xFFAD1457)],
                              )
                            : null,
                        color: isAvailable
                            ? null
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isAvailable
                            ? Icons.card_giftcard_rounded
                            : Icons.timer_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Expanded Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isAvailable ? 'DAILY GIFT' : 'COOLDOWN',
                            style: TextStyle(
                              color: isAvailable
                                  ? const Color(0xFFF48FB1)
                                  : Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            isAvailable ? 'Claim Free Spin!' : 'Next Reward In',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Countdown directly in the row if not available
                    if (!isAvailable)
                      _buildCompactCountdown(
                        dailySpinService.getCountdownString(),
                      ),
                  ],
                ),
              ),
              // Only show the separate action section in a very compact way if available
              if (isAvailable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _buildClaimButton(
                    context,
                    dailySpinService,
                    wheelProvider,
                    missionService,
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
      height: 44, // Reduced height
      child: ElevatedButton(
        onPressed: () async {
          final claimed = await dailySpinService.claimDailySpin();
          if (claimed) {
            wheelProvider.addSpins(1);
            await missionService.recordDailyFreeClaim();
            if (context.mounted) {
              UIUtils.showMessageDialog(
                context,
                title: 'Success!',
                message: '🎉 Daily free spin claimed! +1 spin added',
                isError: false,
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF48FB1),
          foregroundColor: Colors.black,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'CLAIM REWARD',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCountdown(String countdown) {
    final parts = countdown.split(':');
    if (parts.length != 3) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactUnit(parts[0], 'h'),
        const SizedBox(width: 4),
        _buildCompactUnit(parts[1], 'm'),
        const SizedBox(width: 4),
        _buildCompactUnit(parts[2], 's'),
      ],
    );
  }

  Widget _buildCompactUnit(String value, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 1),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

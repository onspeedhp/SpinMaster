import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/daily_spin_service.dart';
import 'package:wheeler/utils/ui_utils.dart';
import '../services/wheel_manage.dart';
import '../services/mission_service.dart';

/// Widget displaying daily free spin button with countdown in premium style
class DailyFreeSpinCard extends StatelessWidget {
  const DailyFreeSpinCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<DailySpinService, WheelProvider, MissionService>(
      builder: (context, dailySpinService, wheelProvider, missionService, _) {
        final status = dailySpinService.status;
        final isAvailable = status.isAvailable;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
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
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isAvailable
                  ? const Color(0xFFF48FB1).withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
            boxShadow: [
              if (isAvailable)
                BoxShadow(
                  color: const Color(0xFFF48FB1).withValues(alpha: 0.1),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: isAvailable
                            ? const LinearGradient(
                                colors: [Color(0xFFF48FB1), Color(0xFFAD1457)],
                              )
                            : null,
                        color: isAvailable
                            ? null
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isAvailable
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF48FB1,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isAvailable
                            ? Icons.card_giftcard_rounded
                            : Icons.timer_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(height: 4),
                          Text(
                            isAvailable
                                ? 'Claim Daily Free Spin!'
                                : 'Next Gift Unlocking',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 20),
            SizedBox(width: 10),
            Text(
              'CLAIM FREE SPIN',
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
    final parts = countdown.split(':');
    if (parts.length != 3) {
      return Center(
        child: Text(
          countdown,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
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
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
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
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.2),
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

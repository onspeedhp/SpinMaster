import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mission.dart';
import '../services/mission_service.dart';
import '../services/wheel_manage.dart';

/// Widget to display missions list
class MissionsCard extends StatelessWidget {
  const MissionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MissionService, WheelProvider>(
      builder: (context, missionService, wheelProvider, _) {
        final missions = missionService.missions;
        final streak = missionService.loginStreak;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1e2a3a),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade700, Colors.orange.shade900],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DAILY MISSIONS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            '${missionService.completedMissionsCount} completed',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Streak indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${streak.currentStreak}',
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

              // Missions list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: missions.length,
                itemBuilder: (context, index) {
                  final mission = missions[index];
                  return _MissionTile(
                    mission: mission,
                    onClaim: () async {
                      final reward = await missionService.claimMissionReward(
                        mission.id,
                      );
                      if (reward > 0) {
                        wheelProvider.addSpins(reward);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '🎉 Mission completed! +$reward spins',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MissionTile extends StatelessWidget {
  final Mission mission;
  final VoidCallback onClaim;

  const _MissionTile({required this.mission, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final isCompleted = mission.status == MissionStatus.completed;
    final isClaimed = mission.status == MissionStatus.claimed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isClaimed
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getMissionColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getMissionIcon(), color: _getMissionColor(), size: 24),
          ),
          const SizedBox(width: 12),

          // Mission info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    color: isClaimed ? Colors.grey : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mission.description,
                  style: TextStyle(
                    color: isClaimed
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: mission.progressPercentage,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getMissionColor(),
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${mission.currentProgress}/${mission.targetValue}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Reward/Claim button
          if (isClaimed)
            const Icon(Icons.check_circle, color: Colors.grey, size: 32)
          else if (isCompleted)
            GestureDetector(
              onTap: onClaim,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      '+${mission.rewardSpins}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.flash_on, color: Colors.white, size: 16),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    '+${mission.rewardSpins}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.flash_on, color: Colors.orange, size: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getMissionIcon() {
    switch (mission.type) {
      case MissionType.dailySpins:
        return Icons.refresh;
      case MissionType.loginStreak:
        return Icons.local_fire_department;
      case MissionType.claimDailyFree:
        return Icons.card_giftcard;
      case MissionType.totalSpins:
        return Icons.star;
    }
  }

  Color _getMissionColor() {
    switch (mission.type) {
      case MissionType.dailySpins:
        return Colors.blue;
      case MissionType.loginStreak:
        return Colors.orange;
      case MissionType.claimDailyFree:
        return Colors.green;
      case MissionType.totalSpins:
        return Colors.purple;
    }
  }
}

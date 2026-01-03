import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mission.dart';

/// Service to manage missions and streaks
class MissionService extends ChangeNotifier {
  static final MissionService _instance = MissionService._internal();
  factory MissionService() => _instance;
  MissionService._internal() {
    _loadData();
  }

  static const String _missionsKey = 'missions_data';
  static const String _streakKey = 'login_streak_data';
  static const String _statsKey = 'user_stats';

  List<Mission> _missions = [];
  LoginStreak _loginStreak = const LoginStreak();
  Map<String, int> _userStats = {
    'totalSpins': 0,
    'todaySpins': 0,
    'dailyFreesClaimed': 0,
  };

  List<Mission> get missions => _missions;
  LoginStreak get loginStreak => _loginStreak;
  Map<String, int> get userStats => _userStats;

  /// Load all data from storage
  Future<void> _loadData() async {
    await _loadMissions();
    await _loadStreak();
    await _loadStats();
    _checkAndResetDaily();
    _updateLoginStreak();
  }

  /// Load missions from storage
  Future<void> _loadMissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_missionsKey);

      if (jsonStr != null) {
        final List<dynamic> jsonList = json.decode(jsonStr);
        _missions = jsonList.map((e) => Mission.fromJson(e)).toList();
      } else {
        _missions = _generateDefaultMissions();
      }
    } catch (e) {
      debugPrint('Error loading missions: $e');
      _missions = _generateDefaultMissions();
    }
  }

  /// Save missions to storage
  Future<void> _saveMissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _missions.map((e) => e.toJson()).toList();
      await prefs.setString(_missionsKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving missions: $e');
    }
  }

  /// Load login streak
  Future<void> _loadStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_streakKey);

      if (jsonStr != null) {
        _loginStreak = LoginStreak.fromJson(json.decode(jsonStr));
      }
    } catch (e) {
      debugPrint('Error loading streak: $e');
    }
  }

  /// Save login streak
  Future<void> _saveStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_streakKey, json.encode(_loginStreak.toJson()));
    } catch (e) {
      debugPrint('Error saving streak: $e');
    }
  }

  /// Load user stats
  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_statsKey);

      if (jsonStr != null) {
        _userStats = Map<String, int>.from(json.decode(jsonStr));
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  /// Save user stats
  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statsKey, json.encode(_userStats));
    } catch (e) {
      debugPrint('Error saving stats: $e');
    }
  }

  /// Generate default daily missions
  List<Mission> _generateDefaultMissions() {
    return [
      Mission(
        id: 'daily_spin_3',
        title: 'Spin Master',
        description: 'Spin the wheel 3 times today',
        type: MissionType.dailySpins,
        targetValue: 3,
        rewardSpins: 2,
      ),
      Mission(
        id: 'daily_spin_5',
        title: 'Spin Champion',
        description: 'Spin the wheel 5 times today',
        type: MissionType.dailySpins,
        targetValue: 5,
        rewardSpins: 5,
      ),
      Mission(
        id: 'claim_daily_free',
        title: 'Daily Collector',
        description: 'Claim your daily free spin',
        type: MissionType.claimDailyFree,
        targetValue: 1,
        rewardSpins: 1,
      ),
      Mission(
        id: 'streak_3',
        title: '3-Day Warrior',
        description: 'Login 3 days in a row',
        type: MissionType.loginStreak,
        targetValue: 3,
        rewardSpins: 3,
      ),
      Mission(
        id: 'streak_7',
        title: 'Week Champion',
        description: 'Login 7 days in a row',
        type: MissionType.loginStreak,
        targetValue: 7,
        rewardSpins: 10,
      ),
    ];
  }

  /// Check and reset daily missions if new day
  Future<void> _checkAndResetDaily() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetStr = prefs.getString('last_daily_reset');
    final now = DateTime.now();

    if (lastResetStr != null) {
      final lastReset = DateTime.parse(lastResetStr);
      if (!_isSameDay(now, lastReset)) {
        // Reset daily missions
        _userStats['todaySpins'] = 0;
        await _saveStats();

        // Reset daily missions progress
        _missions = _missions.map((mission) {
          if (mission.type == MissionType.dailySpins ||
              mission.type == MissionType.claimDailyFree) {
            return mission.copyWith(
              currentProgress: 0,
              status: MissionStatus.active,
              completedAt: null,
              claimedAt: null,
            );
          }
          return mission;
        }).toList();

        await _saveMissions();
        await prefs.setString('last_daily_reset', now.toIso8601String());
      }
    } else {
      await prefs.setString('last_daily_reset', now.toIso8601String());
    }
  }

  /// Update login streak
  Future<void> _updateLoginStreak() async {
    final now = DateTime.now();
    final lastLogin = _loginStreak.lastLoginDate;

    if (lastLogin == null) {
      // First login
      _loginStreak = _loginStreak.copyWith(
        currentStreak: 1,
        longestStreak: 1,
        lastLoginDate: now,
      );
    } else if (!_isSameDay(now, lastLogin)) {
      final daysDiff = now.difference(lastLogin).inDays;

      if (daysDiff == 1) {
        // Consecutive day
        final newStreak = _loginStreak.currentStreak + 1;
        _loginStreak = _loginStreak.copyWith(
          currentStreak: newStreak,
          longestStreak: newStreak > _loginStreak.longestStreak
              ? newStreak
              : _loginStreak.longestStreak,
          lastLoginDate: now,
        );
      } else if (daysDiff > 1) {
        // Streak broken
        _loginStreak = _loginStreak.copyWith(
          currentStreak: 1,
          lastLoginDate: now,
        );
      }

      await _saveStreak();
      _updateStreakMissions();
    }
  }

  /// Update streak-based missions
  void _updateStreakMissions() {
    _missions = _missions.map((mission) {
      if (mission.type == MissionType.loginStreak) {
        return mission.copyWith(currentProgress: _loginStreak.currentStreak);
      }
      return mission;
    }).toList();
    _checkMissionCompletion();
  }

  /// Record a spin
  Future<void> recordSpin() async {
    _userStats['totalSpins'] = (_userStats['totalSpins'] ?? 0) + 1;
    _userStats['todaySpins'] = (_userStats['todaySpins'] ?? 0) + 1;

    await _saveStats();

    // Update daily spin missions
    _missions = _missions.map((mission) {
      if (mission.type == MissionType.dailySpins) {
        return mission.copyWith(currentProgress: _userStats['todaySpins']!);
      }
      return mission;
    }).toList();

    _checkMissionCompletion();
  }

  /// Record daily free spin claim
  Future<void> recordDailyFreeClaim() async {
    _userStats['dailyFreesClaimed'] =
        (_userStats['dailyFreesClaimed'] ?? 0) + 1;
    await _saveStats();

    // Update claim mission
    _missions = _missions.map((mission) {
      if (mission.type == MissionType.claimDailyFree) {
        return mission.copyWith(currentProgress: 1);
      }
      return mission;
    }).toList();

    _checkMissionCompletion();
  }

  /// Check and update mission completion status
  void _checkMissionCompletion() {
    bool updated = false;

    _missions = _missions.map((mission) {
      if (mission.status == MissionStatus.active && mission.isCompleted) {
        updated = true;
        return mission.copyWith(
          status: MissionStatus.completed,
          completedAt: DateTime.now(),
        );
      }
      return mission;
    }).toList();

    if (updated) {
      _saveMissions();
      notifyListeners();
    }
  }

  /// Claim mission reward
  Future<int> claimMissionReward(String missionId) async {
    final missionIndex = _missions.indexWhere((m) => m.id == missionId);

    if (missionIndex == -1) return 0;

    final mission = _missions[missionIndex];

    if (mission.status != MissionStatus.completed) return 0;

    _missions[missionIndex] = mission.copyWith(
      status: MissionStatus.claimed,
      claimedAt: DateTime.now(),
    );

    await _saveMissions();
    notifyListeners();

    return mission.rewardSpins;
  }

  /// Helper to check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get active missions count
  int get activeMissionsCount =>
      _missions.where((m) => m.status == MissionStatus.active).length;

  /// Get completed missions count
  int get completedMissionsCount =>
      _missions.where((m) => m.status == MissionStatus.completed).length;
}

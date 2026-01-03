import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leaderboard.dart';

/// Service to manage leaderboards
class LeaderboardService extends ChangeNotifier {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal() {
    _loadData();
  }

  static const String _leaderboardKey = 'leaderboard_data';
  static const String _userStatsKey = 'user_leaderboard_stats';

  List<LeaderboardEntry> _dailyLeaderboard = [];
  List<LeaderboardEntry> _weeklyLeaderboard = [];
  List<LeaderboardEntry> _allTimeLeaderboard = [];
  UserStats _userStats = const UserStats();

  List<LeaderboardEntry> get dailyLeaderboard => _dailyLeaderboard;
  List<LeaderboardEntry> get weeklyLeaderboard => _weeklyLeaderboard;
  List<LeaderboardEntry> get allTimeLeaderboard => _allTimeLeaderboard;
  UserStats get userStats => _userStats;

  /// Load all leaderboard data
  Future<void> _loadData() async {
    await _loadLeaderboards();
    await _loadUserStats();
    _generateMockData(); // For demo purposes
  }

  /// Load leaderboards from storage
  Future<void> _loadLeaderboards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_leaderboardKey);

      if (jsonStr != null) {
        final Map<String, dynamic> data = json.decode(jsonStr);
        _dailyLeaderboard =
            (data['daily'] as List?)
                ?.map((e) => LeaderboardEntry.fromJson(e))
                .toList() ??
            [];
        _weeklyLeaderboard =
            (data['weekly'] as List?)
                ?.map((e) => LeaderboardEntry.fromJson(e))
                .toList() ??
            [];
        _allTimeLeaderboard =
            (data['allTime'] as List?)
                ?.map((e) => LeaderboardEntry.fromJson(e))
                .toList() ??
            [];
      }
    } catch (e) {
      debugPrint('Error loading leaderboards: $e');
    }
  }

  /// Save leaderboards to storage
  Future<void> _saveLeaderboards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'daily': _dailyLeaderboard.map((e) => e.toJson()).toList(),
        'weekly': _weeklyLeaderboard.map((e) => e.toJson()).toList(),
        'allTime': _allTimeLeaderboard.map((e) => e.toJson()).toList(),
      };
      await prefs.setString(_leaderboardKey, json.encode(data));
    } catch (e) {
      debugPrint('Error saving leaderboards: $e');
    }
  }

  /// Load user stats
  Future<void> _loadUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_userStatsKey);

      if (jsonStr != null) {
        _userStats = UserStats.fromJson(json.decode(jsonStr));
      }
    } catch (e) {
      debugPrint('Error loading user stats: $e');
    }
  }

  /// Save user stats
  Future<void> _saveUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userStatsKey, json.encode(_userStats.toJson()));
    } catch (e) {
      debugPrint('Error saving user stats: $e');
    }
  }

  /// Record a spin for the current user
  Future<void> recordSpin({int rewardValue = 0}) async {
    _userStats = _userStats.copyWith(
      totalSpins: _userStats.totalSpins + 1,
      totalRewards: _userStats.totalRewards + rewardValue,
    );

    await _saveUserStats();
    await _updateUserRanking();
    notifyListeners();
  }

  /// Update user's ranking across all leaderboards
  Future<void> _updateUserRanking() async {
    // In a real app, this would call backend API
    // For now, we'll calculate based on mock data

    final userScore = _userStats.totalRewards;

    // Calculate daily rank
    _userStats = _userStats.copyWith(
      dailyRank: _calculateRank(_dailyLeaderboard, userScore),
      weeklyRank: _calculateRank(_weeklyLeaderboard, userScore),
      allTimeRank: _calculateRank(_allTimeLeaderboard, userScore),
    );

    await _saveUserStats();
  }

  /// Calculate user rank based on score
  int _calculateRank(List<LeaderboardEntry> leaderboard, int userScore) {
    int rank = 1;
    for (final entry in leaderboard) {
      if (entry.totalRewards > userScore) {
        rank++;
      }
    }
    return rank;
  }

  /// Get leaderboard by period
  List<LeaderboardEntry> getLeaderboard(LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.daily:
        return _dailyLeaderboard;
      case LeaderboardPeriod.weekly:
        return _weeklyLeaderboard;
      case LeaderboardPeriod.allTime:
        return _allTimeLeaderboard;
    }
  }

  /// Generate mock leaderboard data for demo
  void _generateMockData() {
    if (_allTimeLeaderboard.isEmpty) {
      final random = Random();
      final names = [
        'SpinMaster',
        'LuckyPlayer',
        'WheelKing',
        'FortuneSeeker',
        'SpinChampion',
        'MegaWinner',
        'LuckyStrike',
        'GoldenSpinner',
        'DiamondPlayer',
        'EliteGamer',
      ];

      _allTimeLeaderboard = List.generate(10, (index) {
        final spins = 1000 - (index * 50) + random.nextInt(50);
        final rewards = spins * (10 + random.nextInt(20));

        return LeaderboardEntry(
          userId: 'user_$index',
          username: names[index],
          walletAddress: _generateMockAddress(),
          totalSpins: spins,
          totalRewards: rewards,
          rank: index + 1,
          lastUpdated: DateTime.now(),
        );
      });

      _weeklyLeaderboard = _allTimeLeaderboard
          .map(
            (e) => e.copyWith(
              totalSpins: (e.totalSpins * 0.3).toInt(),
              totalRewards: (e.totalRewards * 0.3).toInt(),
            ),
          )
          .toList();

      _dailyLeaderboard = _allTimeLeaderboard
          .map(
            (e) => e.copyWith(
              totalSpins: (e.totalSpins * 0.1).toInt(),
              totalRewards: (e.totalRewards * 0.1).toInt(),
            ),
          )
          .toList();

      _saveLeaderboards();
    }
  }

  /// Generate mock Solana address
  String _generateMockAddress() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        44,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Refresh leaderboards (would call API in production)
  Future<void> refreshLeaderboards() async {
    // In production, this would fetch from backend
    await Future.delayed(const Duration(seconds: 1));
    notifyListeners();
  }
}

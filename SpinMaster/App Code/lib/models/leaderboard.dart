/// Leaderboard time period
enum LeaderboardPeriod { daily, weekly, allTime }

/// Model for a leaderboard entry
class LeaderboardEntry {
  final String userId;
  final String username;
  final String? walletAddress;
  final int totalSpins;
  final int totalRewards;
  final int rank;
  final DateTime lastUpdated;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.walletAddress,
    required this.totalSpins,
    required this.totalRewards,
    required this.rank,
    required this.lastUpdated,
  });

  LeaderboardEntry copyWith({
    String? userId,
    String? username,
    String? walletAddress,
    int? totalSpins,
    int? totalRewards,
    int? rank,
    DateTime? lastUpdated,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      walletAddress: walletAddress ?? this.walletAddress,
      totalSpins: totalSpins ?? this.totalSpins,
      totalRewards: totalRewards ?? this.totalRewards,
      rank: rank ?? this.rank,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'walletAddress': walletAddress,
      'totalSpins': totalSpins,
      'totalRewards': totalRewards,
      'rank': rank,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      username: json['username'] as String,
      walletAddress: json['walletAddress'] as String?,
      totalSpins: json['totalSpins'] as int? ?? 0,
      totalRewards: json['totalRewards'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  /// Get shortened wallet address for display
  String get shortAddress {
    if (walletAddress == null || walletAddress!.length < 8) {
      return walletAddress ?? 'Anonymous';
    }
    return '${walletAddress!.substring(0, 4)}...${walletAddress!.substring(walletAddress!.length - 4)}';
  }
}

/// Model for user's own stats
class UserStats {
  final int totalSpins;
  final int totalRewards;
  final int dailyRank;
  final int weeklyRank;
  final int allTimeRank;

  const UserStats({
    this.totalSpins = 0,
    this.totalRewards = 0,
    this.dailyRank = 0,
    this.weeklyRank = 0,
    this.allTimeRank = 0,
  });

  UserStats copyWith({
    int? totalSpins,
    int? totalRewards,
    int? dailyRank,
    int? weeklyRank,
    int? allTimeRank,
  }) {
    return UserStats(
      totalSpins: totalSpins ?? this.totalSpins,
      totalRewards: totalRewards ?? this.totalRewards,
      dailyRank: dailyRank ?? this.dailyRank,
      weeklyRank: weeklyRank ?? this.weeklyRank,
      allTimeRank: allTimeRank ?? this.allTimeRank,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSpins': totalSpins,
      'totalRewards': totalRewards,
      'dailyRank': dailyRank,
      'weeklyRank': weeklyRank,
      'allTimeRank': allTimeRank,
    };
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalSpins: json['totalSpins'] as int? ?? 0,
      totalRewards: json['totalRewards'] as int? ?? 0,
      dailyRank: json['dailyRank'] as int? ?? 0,
      weeklyRank: json['weeklyRank'] as int? ?? 0,
      allTimeRank: json['allTimeRank'] as int? ?? 0,
    );
  }
}

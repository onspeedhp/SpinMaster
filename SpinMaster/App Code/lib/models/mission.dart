/// Types of missions available
enum MissionType {
  dailySpins, // Spin X times today
  loginStreak, // Login X days in a row
  totalSpins, // Total spins across all time
  claimDailyFree, // Claim daily free spin
}

/// Mission status
enum MissionStatus { active, completed, claimed }

/// Model for a mission/quest
class Mission {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final int targetValue;
  final int currentProgress;
  final MissionStatus status;
  final int rewardSpins;
  final DateTime? completedAt;
  final DateTime? claimedAt;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    this.currentProgress = 0,
    this.status = MissionStatus.active,
    this.rewardSpins = 1,
    this.completedAt,
    this.claimedAt,
  });

  bool get isCompleted => currentProgress >= targetValue;
  double get progressPercentage =>
      (currentProgress / targetValue).clamp(0.0, 1.0);

  Mission copyWith({
    String? id,
    String? title,
    String? description,
    MissionType? type,
    int? targetValue,
    int? currentProgress,
    MissionStatus? status,
    int? rewardSpins,
    DateTime? completedAt,
    DateTime? claimedAt,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      status: status ?? this.status,
      rewardSpins: rewardSpins ?? this.rewardSpins,
      completedAt: completedAt ?? this.completedAt,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'targetValue': targetValue,
      'currentProgress': currentProgress,
      'status': status.name,
      'rewardSpins': rewardSpins,
      'completedAt': completedAt?.toIso8601String(),
      'claimedAt': claimedAt?.toIso8601String(),
    };
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: MissionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MissionType.dailySpins,
      ),
      targetValue: json['targetValue'] as int,
      currentProgress: json['currentProgress'] as int? ?? 0,
      status: MissionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MissionStatus.active,
      ),
      rewardSpins: json['rewardSpins'] as int? ?? 1,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      claimedAt: json['claimedAt'] != null
          ? DateTime.parse(json['claimedAt'] as String)
          : null,
    );
  }
}

/// Model for login streak tracking
class LoginStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLoginDate;

  const LoginStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastLoginDate,
  });

  LoginStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoginDate,
  }) {
    return LoginStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastLoginDate': lastLoginDate?.toIso8601String(),
    };
  }

  factory LoginStreak.fromJson(Map<String, dynamic> json) {
    return LoginStreak(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.parse(json['lastLoginDate'] as String)
          : null,
    );
  }
}

/// Model for tracking daily free spin availability
class DailySpinStatus {
  final DateTime? lastClaimedAt;
  final bool isAvailable;
  final Duration? timeUntilNext;

  const DailySpinStatus({
    this.lastClaimedAt,
    required this.isAvailable,
    this.timeUntilNext,
  });

  factory DailySpinStatus.initial() {
    return const DailySpinStatus(
      isAvailable: true,
      lastClaimedAt: null,
      timeUntilNext: null,
    );
  }

  DailySpinStatus copyWith({
    DateTime? lastClaimedAt,
    bool? isAvailable,
    Duration? timeUntilNext,
  }) {
    return DailySpinStatus(
      lastClaimedAt: lastClaimedAt ?? this.lastClaimedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      timeUntilNext: timeUntilNext ?? this.timeUntilNext,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastClaimedAt': lastClaimedAt?.toIso8601String(),
      'isAvailable': isAvailable,
    };
  }

  factory DailySpinStatus.fromJson(Map<String, dynamic> json) {
    final lastClaimedStr = json['lastClaimedAt'] as String?;
    final lastClaimed = lastClaimedStr != null
        ? DateTime.parse(lastClaimedStr)
        : null;

    return DailySpinStatus(
      lastClaimedAt: lastClaimed,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_spin.dart';
import 'user_api.dart';
import 'spin_api.dart';

/// Service to manage daily free spin logic
class DailySpinService extends ChangeNotifier {
  static final DailySpinService _instance = DailySpinService._internal();
  factory DailySpinService() => _instance;
  DailySpinService._internal() {
    _loadStatus();
    _startTimer();
  }

  static const String _storageKey = 'daily_spin_status';
  static const Duration _cooldownDuration = Duration(hours: 24);

  DailySpinStatus _status = DailySpinStatus.initial();
  DailySpinStatus get status => _status;

  Timer? _timer;

  /// Load status from local storage
  Future<void> _loadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);

      if (jsonStr != null) {
        final json = Map<String, dynamic>.from(Uri.splitQueryString(jsonStr));
        _status = DailySpinStatus.fromJson(json);
        _updateAvailability();
      }
    } catch (e) {
      debugPrint('Error loading daily spin status: $e');
    }
  }

  /// Save status to local storage
  Future<void> _saveStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = _status.toJson();
      await prefs.setString(_storageKey, json.toString());
    } catch (e) {
      debugPrint('Error saving daily spin status: $e');
    }
  }

  /// Sync with backend to get the real last claim time
  Future<void> syncWithBackend() async {
    try {
      final userProfile = await UserApi.getProfile();
      final lastClaimStr = userProfile['lastDailyClaimAt'] as String?;

      if (lastClaimStr != null && lastClaimStr.isNotEmpty) {
        final lastClaimed = DateTime.parse(lastClaimStr);
        _status = _status.copyWith(lastClaimedAt: lastClaimed);
        await _saveStatus();
        _updateAvailability();
        debugPrint('Daily spin status synced with backend: $lastClaimStr');
      } else {
        // Never claimed on backend, reset local state
        _status = _status.copyWith(lastClaimedAt: null, isAvailable: true);
        await _saveStatus();
        _updateAvailability();
        debugPrint('Daily spin: Never claimed before');
      }
    } catch (e) {
      debugPrint('Error syncing daily spin with backend: $e');
    }
  }

  /// Start periodic timer to update availability
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateAvailability();
    });
  }

  /// Update availability based on last claimed time
  void _updateAvailability() {
    final lastClaimed = _status.lastClaimedAt;

    if (lastClaimed == null) {
      // Never claimed before
      _status = _status.copyWith(isAvailable: true, timeUntilNext: null);
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final timeSinceClaim = now.difference(lastClaimed);

    if (timeSinceClaim >= _cooldownDuration) {
      // Cooldown expired
      _status = _status.copyWith(isAvailable: true, timeUntilNext: null);
    } else {
      // Still in cooldown
      final remaining = _cooldownDuration - timeSinceClaim;
      _status = _status.copyWith(isAvailable: false, timeUntilNext: remaining);
    }

    notifyListeners();
  }

  /// Claim the daily free spin
  Future<bool> claimDailySpin() async {
    if (!_status.isAvailable) {
      debugPrint('Daily spin not available yet');
      return false;
    }

    try {
      debugPrint('Daily spin: Calling backend API to claim...');
      final result = await SpinApi.claimDailySpin();

      if (result.containsKey('error')) {
        debugPrint('Daily spin: Backend returned error - ${result['error']}');
        // If already claimed on backend, sync to update local state
        await syncWithBackend();
        return false;
      }

      _status = _status.copyWith(
        lastClaimedAt: DateTime.now(),
        isAvailable: false,
      );

      await _saveStatus();
      _updateAvailability();

      debugPrint('Daily spin claimed successfully on backend');
      return true;
    } catch (e) {
      debugPrint('Daily spin: Error claiming - $e');
      return false;
    }
  }

  /// Get formatted countdown string
  String getCountdownString() {
    final timeUntilNext = _status.timeUntilNext;
    if (timeUntilNext == null) return 'Available now!';

    final hours = timeUntilNext.inHours;
    final minutes = timeUntilNext.inMinutes.remainder(60);
    final seconds = timeUntilNext.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

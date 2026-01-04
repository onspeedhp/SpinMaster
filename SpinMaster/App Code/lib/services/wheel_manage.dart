import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../model/spinner_segment_model.dart';
import '../widget/wheel_painter.dart';
import 'user_api.dart';
import 'spin_api.dart';

class WheelProvider with ChangeNotifier {
  List<Wheel> _wheels = [];
  Wheel? _currentWheel;

  List<Wheel> get wheels => _wheels;
  Wheel? get currentWheel => _currentWheel;

  // Separate official wheel from user wheels
  Wheel? _officialWheel;
  Wheel? get officialWheel => _officialWheel;

  // New features for SeekSpin
  int _spinsBalance = 0;

  int get spinsBalance => _spinsBalance;

  WheelProvider() {
    _loadWheels();
  }

  // Load wheels from SharedPreferences
  Future<void> _loadWheels() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Custom Wheels
      final wheelsJson = prefs.getString('wheels');
      if (wheelsJson != null) {
        final List<dynamic> wheelsList = json.decode(wheelsJson);
        _wheels = wheelsList.map((wheel) => Wheel.fromJson(wheel)).toList();

        // Migration: Remove official wheel from legacy storage if present
        final hasLegacyOfficial = _wheels.any(
          (w) => w.id == 'seek_spin_official',
        );
        if (hasLegacyOfficial) {
          _wheels.removeWhere((w) => w.id == 'seek_spin_official');
          _saveWheels(); // Clean up storage
        }

        // Check availability of current wheel in loaded list
        if (_wheels.isNotEmpty && _currentWheel == null) {
          // Don't auto-set current wheel to official here implicitly,
          // just default to first custom if available
          _currentWheel = _wheels.first;
        }
        notifyListeners();
      } else {
        _createDefaultWheel();
      }

      // Always initialize official wheel separately
      _createSeekSpinWheel();

      // Initial sync with backend
      await Future.wait([syncSpinsWithBackend(), syncOfficialWheelConfig()]);
    } catch (e) {
      debugPrint('Error loading wheels: $e');
      _createDefaultWheel();
    }
  }

  /// Synchronize spin balance with backend
  Future<void> syncSpinsWithBackend() async {
    try {
      final balance = await UserApi.getSpinsBalance();
      _setSpinsBalance(balance);
      debugPrint('Spins synced with backend: $balance');
    } catch (e) {
      debugPrint('Failed to sync spins with backend: $e');
    }
  }

  /// Synchronize official wheel configuration with backend
  Future<void> syncOfficialWheelConfig() async {
    try {
      final response = await SpinApi.getWheelConfig();
      final List<dynamic> config = response['config'];

      debugPrint(
        '🎡 Received Wheel Config from Backend: ${config.length} items',
      );
      for (var item in config) {
        debugPrint(
          '   [${item['segment_index']}] ${item['label']} (Val: ${item['reward_value']})',
        );
      }

      if (config.isNotEmpty) {
        final segments = config.map((item) {
          return SpinnerSegment(
            text: item['label'],
            color: _parseColor(item['color_hex']),
            iconUrl: item['icon_url'],
          );
        }).toList();

        // 🚀 Preload images BEFORE updating the UI to prevent popping
        debugPrint('⏳ Preloading wheel images...');
        await WheelPainter.loadImagesForSegments(segments);
        debugPrint('✅ Wheel images preloaded.');

        // Update official wheel directly
        if (_officialWheel != null) {
          _officialWheel = _officialWheel!.copyWith(segments: segments);
          debugPrint('🎡 Updated Official Wheel with Sent Config');
          notifyListeners();
          // We don't save official wheel to local storage "wheels" key anymore
          debugPrint('Official wheel config synced with backend');
        }
      }
    } catch (e) {
      debugPrint('Failed to sync wheel config with backend: $e');
    }
  }

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.purple;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.purple;
    }
  }

  void _setSpinsBalance(int amount) {
    if (_spinsBalance != amount) {
      _spinsBalance = amount;
      notifyListeners();
    }
  }

  // Method to manually update balance (e.g., after a purchase or mission)
  void addSpins(int amount) {
    _spinsBalance += amount;
    notifyListeners();
    // Ideally, we should sync with backend after this
    syncSpinsWithBackend();
  }

  // Method to locally use a spin for UI responsiveness
  bool useSpin() {
    if (_spinsBalance > 0) {
      _spinsBalance--;
      notifyListeners();
      return true;
    }
    return false;
  }

  // useSpin should be called after a successful /api/spin/execute call
  void setBalanceAfterSpin(int newBalance) {
    _spinsBalance = newBalance;
    notifyListeners();
  }

  // Create Official Play-to-Earn Wheel
  void _createSeekSpinWheel() {
    _officialWheel = Wheel(
      id: 'seek_spin_official',
      name: 'SeekSpin Official',
      segments: [
        SpinnerSegment(text: '0.01 SOL', color: Colors.purpleAccent),
        SpinnerSegment(text: 'Good Luck', color: Colors.grey),
        SpinnerSegment(text: '100 SEEK', color: Colors.blueAccent),
        SpinnerSegment(text: 'Try Again', color: Colors.redAccent),
        SpinnerSegment(text: '1 SOL', color: Colors.amber),
        SpinnerSegment(text: 'Bonus Spin', color: Colors.green),
      ],
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  // Create default wheel
  void _createDefaultWheel() {
    final defaultWheel = Wheel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Wheel 1',
      segments: [
        SpinnerSegment(
          text: 'Win big prize today!',
          color: Colors.purple[300]!,
        ),
        SpinnerSegment(text: 'You win', color: Colors.yellow),
        SpinnerSegment(text: 'Spin again for more', color: Colors.orange),
        SpinnerSegment(text: 'Win 10', color: Colors.green),
        SpinnerSegment(text: 'Better luck next time', color: Colors.lightBlue),
        SpinnerSegment(text: 'No prize today', color: Colors.green[700]!),
        SpinnerSegment(text: 'Try again later', color: Colors.red),
        SpinnerSegment(text: 'Win 5', color: Colors.purple[600]!),
      ],
      createdAt: DateTime.now(),
    );

    _wheels.add(defaultWheel);
    _currentWheel = defaultWheel;
    _saveWheels();
    notifyListeners();
  }

  // Save wheels to SharedPreferences
  Future<void> _saveWheels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wheelsJson = json.encode(
        _wheels.map((wheel) => wheel.toJson()).toList(),
      );
      await prefs.setString('wheels', wheelsJson);
    } catch (e) {
      debugPrint('Error saving wheels: $e');
    }
  }

  // Add a new wheel
  void addWheel(Wheel wheel) {
    _wheels.add(wheel);
    _currentWheel = wheel;
    _saveWheels();
    notifyListeners();
  }

  // Update an existing wheel
  void updateWheel(String wheelId, Wheel updatedWheel) {
    final index = _wheels.indexWhere((wheel) => wheel.id == wheelId);
    if (index != -1) {
      _wheels[index] = updatedWheel;
      if (_currentWheel?.id == wheelId) {
        _currentWheel = updatedWheel;
      }
      _saveWheels();
      notifyListeners();
    }
  }

  // Delete a wheel
  void deleteWheel(String wheelId) {
    _wheels.removeWhere((wheel) => wheel.id == wheelId);

    // If the deleted wheel was the current wheel, set another wheel as current
    if (_currentWheel?.id == wheelId) {
      _currentWheel = _wheels.isNotEmpty ? _wheels.first : null;
    }

    _saveWheels();
    notifyListeners();
  }

  // Set current wheel
  void setCurrentWheel(String wheelId) {
    final wheel = _wheels.firstWhere(
      (wheel) => wheel.id == wheelId,
      orElse: () => _wheels.first,
    );
    _currentWheel = wheel;
    notifyListeners();
  }

  // Update wheel segments by wheel ID (works for any wheel, not just current)
  void updateWheelSegments(String wheelId, List<SpinnerSegment> segments) {
    final index = _wheels.indexWhere((wheel) => wheel.id == wheelId);
    if (index != -1) {
      final updatedWheel = _wheels[index].copyWith(segments: segments);
      updateWheel(wheelId, updatedWheel);
    }
  }

  // Update current wheel segments (kept for backward compatibility)
  void updateCurrentWheelSegments(List<SpinnerSegment> segments) {
    if (_currentWheel != null) {
      updateWheelSegments(_currentWheel!.id, segments);
    }
  }

  // Update current wheel name
  void updateCurrentWheelName(String name) {
    if (_currentWheel != null) {
      final updatedWheel = _currentWheel!.copyWith(name: name);
      updateWheel(_currentWheel!.id, updatedWheel);
    }
  }

  // Get wheel by ID
  Wheel? getWheelById(String wheelId) {
    try {
      return _wheels.firstWhere((wheel) => wheel.id == wheelId);
    } catch (e) {
      return null;
    }
  }
}

  import 'dart:async';
  import 'package:audioplayers/audioplayers.dart';

  class SoundManager {
    static final AudioPlayer _dicePlayer = AudioPlayer();

    // Optimized pool for wheel ticks
    static final List<AudioPlayer> _wheelPlayerPool = [];
    static const int _poolSize = 2; // Reduced from 3
    static int _currentPlayerIndex = 0;

    static const String _wheelSoundPath = 'sounds/tick.wheel';
    static const String _diceSoundPath = 'sounds/dice.wheel';
    static const String _victorySoundPath = 'sounds/victory.wheel';

    static bool _isDicePlaying = false;
    static bool _isPoolInitialized = false;
    static final AudioPlayer _victoryPlayer = AudioPlayer();
    static bool _isVictoryPlaying = false;

    // ✅ Rate limiting to prevent excessive sound playback
    static DateTime? _lastSoundTime;
    static const int _minSoundIntervalMs = 50; // Minimum 50ms between sounds

    /// Initialize the player pool with optimized settings
    static Future<void> initializePlayerPool() async {
      if (_isPoolInitialized) return;

      try {
        for (int i = 0; i < _poolSize; i++) {
          final player = AudioPlayer();

          // ✅ Optimized audio context - use transient duck for less intrusive focus
          await player.setAudioContext(
            AudioContext(
              android: AudioContextAndroid(
                isSpeakerphoneOn: false,
                stayAwake: false,
                contentType: AndroidContentType.sonification,
                usageType: AndroidUsageType.game,
                audioFocus: AndroidAudioFocus.gainTransientMayDuck, // Less aggressive
              ),
            ),
          );

          await player.setSource(AssetSource(_wheelSoundPath));
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setVolume(0.6); // Slightly lower volume
          _wheelPlayerPool.add(player);
        }
        _isPoolInitialized = true;
      } catch (e) {
        print('Error initializing player pool: $e');
      }
    }

    /// Preload dice sound
    static Future<void> preloadDiceSound() async {
      try {
        await _dicePlayer.setAudioContext(
          AudioContext(
            android: AudioContextAndroid(
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.game,
              audioFocus: AndroidAudioFocus.gain,
            ),
          ),
        );
        await _dicePlayer.setSource(AssetSource(_diceSoundPath));
        await _dicePlayer.setReleaseMode(ReleaseMode.stop);
        await _dicePlayer.setVolume(1.0);
      } catch (e) {
        print('Error preloading dice sound: $e');
      }
    }

    /// ✅ Rate-limited spin sound to prevent jerking
    static Future<void> playSpinSound() async {
      // Rate limiting check
      final now = DateTime.now();
      if (_lastSoundTime != null) {
        final timeSinceLastSound = now.difference(_lastSoundTime!).inMilliseconds;
        if (timeSinceLastSound < _minSoundIntervalMs) {
          return; // Skip this sound to prevent overload
        }
      }
      _lastSoundTime = now;

      if (!_isPoolInitialized || _wheelPlayerPool.isEmpty) {
        await initializePlayerPool();
      }

      try {
        final player = _wheelPlayerPool[_currentPlayerIndex];
        _currentPlayerIndex = (_currentPlayerIndex + 1) % _poolSize;

        // Non-blocking playback
        player.stop();
        player.seek(Duration.zero);
        player.resume();
      } catch (e) {
        print('Error playing wheel sound: $e');
      }
    }

    /// Dice rolling sound with adjustable speed
    /// [speed] should be between 0.5 (half speed) and 2.0 (double speed)
    static Future<void> playDiceSound({double speed = 1.0}) async {
      if (_isDicePlaying) return;
      try {
        _isDicePlaying = true;
        await _dicePlayer.stop();
        await _dicePlayer.seek(Duration.zero);
        // Clamp speed between 0.5 and 4.0 for reasonable playback
        final clampedSpeed = speed.clamp(0.38, 2.15);
        await _dicePlayer.setPlaybackRate(clampedSpeed);
        await _dicePlayer.resume();
        _dicePlayer.onPlayerComplete.listen((_) => _isDicePlaying = false);
      } catch (e) {
        print('Error playing dice sound: $e');
        _isDicePlaying = false;
      }
    }

    static Future<void> stopSpinSound() async {
      try {
        _lastSoundTime = null; // Reset rate limiter
        for (final player in _wheelPlayerPool) {
          await player.stop();
        }
      } catch (e) {
        print('Error stopping wheel sound: $e');
      }
    }

    /// Play victory sound
    static Future<void> playVictorySound() async {
      if (_isVictoryPlaying) return;
      try {
        _isVictoryPlaying = true;
        await _victoryPlayer.stop();
        await _victoryPlayer.setSource(AssetSource(_victorySoundPath));
        await _victoryPlayer.setReleaseMode(ReleaseMode.stop);
        await _victoryPlayer.setVolume(1.0);
        await _victoryPlayer.resume();
        _victoryPlayer.onPlayerComplete.listen((_) {
          _isVictoryPlaying = false;
        });
      } catch (e) {
        print('Error playing victory sound: $e');
        _isVictoryPlaying = false;
      }
    }

    /// Stop victory sound
    static Future<void> stopVictorySound() async {
      try {
        await _victoryPlayer.stop();
        _isVictoryPlaying = false;
      } catch (e) {
        print('Error stopping victory sound: $e');
      }
    }

    static Future<void> dispose() async {
      try {
        for (final player in _wheelPlayerPool) {
          await player.dispose();
        }
        _wheelPlayerPool.clear();
        await _dicePlayer.dispose();
        await _victoryPlayer.dispose();
        _isPoolInitialized = false;
        _lastSoundTime = null;
        _isVictoryPlaying = false;
      } catch (e) {
        print('Error disposing audio players: $e');
      }
    }
  }
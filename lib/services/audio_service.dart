import 'package:audioplayers/audioplayers.dart';
import 'debug_service.dart';
import '../models/meditation_settings.dart';

/// Service for playing meditation sounds (chimes, bells).
///
/// Uses local audio assets for reliable offline playback.
/// Gracefully handles missing audio files.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final DebugService _debug = DebugService();
  AudioPlayer? _player;
  bool _isInitialized = false;
  bool _audioAvailable = true;

  /// Delay between bells in a triple bell sequence (milliseconds)
  static const int _tripleBellDelay = 800;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _player = AudioPlayer();

      // Set release mode to stop after playing
      await _player!.setReleaseMode(ReleaseMode.stop);

      _isInitialized = true;
      await _debug.info('AudioService', 'Audio service initialized');
    } catch (e) {
      _audioAvailable = false;
      await _debug.warning(
        'AudioService',
        'Failed to initialize audio: $e. Meditation will work without sound.',
      );
    }
  }

  /// Play the meditation bell/chime sound
  Future<void> playChime() async {
    if (!_audioAvailable || _player == null) {
      await _debug.info('AudioService', 'Audio not available, skipping chime');
      return;
    }

    try {
      // Try to play from local asset first
      await _player!.play(AssetSource('audio/meditation_bell.mp3'));
      await _debug.info('AudioService', 'Played meditation chime');
    } catch (e) {
      // If local asset fails, try alternative approaches
      try {
        // Try .wav format
        await _player!.play(AssetSource('audio/meditation_bell.wav'));
        await _debug.info('AudioService', 'Played meditation chime (wav)');
      } catch (e2) {
        // Audio file not found - this is OK, meditation still works
        await _debug.warning(
          'AudioService',
          'Meditation bell audio not found. Add meditation_bell.mp3 or .wav to assets/audio/',
        );
        _audioAvailable = false;
      }
    }
  }

  /// Play a gentle start chime (same as regular chime for now)
  Future<void> playStartChime() async {
    await playChime();
  }

  /// Play an end chime (could be different sound in future)
  Future<void> playEndChime() async {
    // Play twice for end (common meditation convention)
    await playChime();
    await Future.delayed(const Duration(milliseconds: _tripleBellDelay));
    await playChime();
  }

  /// Play a single bell
  Future<void> playSingleBell() async {
    await playChime();
  }

  /// Play three bells with pauses between
  Future<void> playTripleBell() async {
    await playChime();
    await Future.delayed(const Duration(milliseconds: _tripleBellDelay));
    await playChime();
    await Future.delayed(const Duration(milliseconds: _tripleBellDelay));
    await playChime();
  }

  /// Play bell based on BellType setting
  Future<void> playBell(BellType bellType) async {
    switch (bellType) {
      case BellType.single:
        await playSingleBell();
        break;
      case BellType.triple:
        await playTripleBell();
        break;
    }
  }

  /// Play an interval bell (single chime during meditation)
  Future<void> playIntervalBell() async {
    await playChime();
  }

  /// Check if audio is available
  bool get isAudioAvailable => _audioAvailable && _player != null;

  /// Dispose of audio resources
  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    _isInitialized = false;
  }
}

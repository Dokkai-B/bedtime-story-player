import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  AudioPlayer? _player;
  String? _currentStoryId;
  
  AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  // Current playback state
  bool get isPlaying => player.playing;
  bool get isPaused => !player.playing && player.processingState != ProcessingState.idle;
  Duration get currentPosition => player.position;
  Duration? get totalDuration => player.duration;
  
  // Play audio from URL
  Future<void> playFromUrl(String url, String storyId) async {
    try {
      // If playing a different story, stop current and load new
      if (_currentStoryId != storyId) {
        await stop();
        await player.setUrl(url);
        _currentStoryId = storyId;
      }
      
      // If paused, resume. Otherwise start from beginning
      if (isPaused) {
        await player.play();
      } else {
        await player.seek(Duration.zero);
        await player.play();
      }
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }

  // Pause playback
  Future<void> pause() async {
    await player.pause();
  }

  // Resume playback
  Future<void> resume() async {
    await player.play();
  }

  // Stop playback
  Future<void> stop() async {
    await player.stop();
    _currentStoryId = null;
  }

  // Seek to position
  Future<void> seekTo(Duration position) async {
    await player.seek(position);
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await player.setVolume(volume.clamp(0.0, 1.0));
  }

  // Check if this story is currently loaded
  bool isCurrentStory(String storyId) {
    return _currentStoryId == storyId;
  }

  // Get playback streams for UI updates
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<bool> get playingStream => player.playingStream;
  Stream<ProcessingState> get processingStateStream => player.processingStateStream;

  // Dispose resources
  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    _currentStoryId = null;
  }
}

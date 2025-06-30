import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  AudioPlayer? _player;
  String? _currentStoryId;
  
  AudioPlayer get player {
    if (_player == null) {
      _player = AudioPlayer();
      // Configure player for better seeking and buffering
      _player!.setLoopMode(LoopMode.off);
      _player!.setShuffleModeEnabled(false);
    }
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

  // Seek to position with buffering wait
  Future<void> seekTo(Duration position) async {
    try {
      // Store current playing state
      final wasPlaying = player.playing;
      
      // Pause playback before seeking to avoid audio artifacts
      if (wasPlaying) {
        await player.pause();
      }
      
      // Perform the seek
      await player.seek(position);
      
      // Wait for buffering to complete before resuming
      if (wasPlaying) {
        // Wait a brief moment for buffer to stabilize
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Wait for player to be ready
        await _waitForPlayerReady();
        
        // Resume playback
        await player.play();
      }
    } catch (e) {
      // If seek fails, try to recover by stopping and restarting
      print('Seek error: $e, attempting recovery...');
      await player.stop();
      await Future.delayed(const Duration(milliseconds: 200));
      await player.play();
    }
  }
  
  // Helper method to wait for player to be ready after seek
  Future<void> _waitForPlayerReady() async {
    try {
      // Wait for the player to reach a ready state
      await player.processingStateStream
          .where((state) => 
              state == ProcessingState.ready || 
              state == ProcessingState.completed)
          .timeout(
            const Duration(seconds: 2),
          )
          .first;
    } catch (e) {
      // If timeout occurs, continue anyway to avoid hanging
      print('Player ready timeout: $e');
    }
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

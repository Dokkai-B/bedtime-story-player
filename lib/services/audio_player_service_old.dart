import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/story.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  AudioPlayer? _player;
  String? _currentStoryId;
  
  // Playlist management
  List<Story> _playlist = [];
  int _currentTrackIndex = -1;
  
  // Stream controllers for reactive UI updates
  final StreamController<Story?> _currentTrackController = StreamController<Story?>.broadcast();
  
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
  
  // Playlist getters
  List<Story> get playlist => _playlist;
  int get currentTrackIndex => _currentTrackIndex;
  Story? get currentTrack => _currentTrackIndex >= 0 && _currentTrackIndex < _playlist.length 
      ? _playlist[_currentTrackIndex] 
      : null;
  bool get hasNext => _currentTrackIndex < _playlist.length - 1;
  bool get hasPrevious => _currentTrackIndex > 0;
  
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

  // Set the current playlist
  void setPlaylist(List<Story> audioStories, {int initialIndex = 0}) {
    _playlist = audioStories.where((story) => story.isAudio).toList();
    _currentTrackIndex = initialIndex.clamp(0, _playlist.length - 1);
    // Emit current track change
    _currentTrackController.add(currentTrack);
  }
  
  // Play specific track by index
  Future<void> playTrackAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    
    _currentTrackIndex = index;
    final story = _playlist[index];
    // Emit current track change
    _currentTrackController.add(story);
    await playFromUrl(story.s3Location, story.s3Key);
  }
  
  // Debouncing for rapid track changes
  Timer? _trackChangeDebouncer;
  
  // Play next track with debouncing
  Future<void> nextTrack() async {
    if (!hasNext) return;
    
    // Cancel any pending track change
    _trackChangeDebouncer?.cancel();
    
    _trackChangeDebouncer = Timer(const Duration(milliseconds: 300), () async {
      _currentTrackIndex++;
      final story = _playlist[_currentTrackIndex];
      await _playTrackSafely(story);
    });
  }
  
  // Play previous track with debouncing
  Future<void> previousTrack() async {
    if (!hasPrevious) return;
    
    // Cancel any pending track change
    _trackChangeDebouncer?.cancel();
    
    _trackChangeDebouncer = Timer(const Duration(milliseconds: 300), () async {
      _currentTrackIndex--;
      final story = _playlist[_currentTrackIndex];
      await _playTrackSafely(story);
    });
  }
  
  // Safe track playing with proper disposal
  Future<void> _playTrackSafely(Story story) async {
    try {
      // Emit current track change immediately for UI update
      _currentTrackController.add(story);
      
      // Stop current playback and dispose resources
      await player.stop();
      
      // Small delay to ensure proper disposal
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Load and play new track
      await player.setUrl(story.s3Location);
      _currentStoryId = story.s3Key;
      await player.play();
    } catch (e) {
      print('Error playing track safely: $e');
      // Attempt recovery
      await _recoverFromError(story);
    }
  }
  
  // Error recovery mechanism
  Future<void> _recoverFromError(Story story) async {
    try {
      // Force dispose and recreate player
      await _player?.dispose();
      _player = null;
      
      // Recreate player with new instance
      final newPlayer = player; // This will create a new instance
      await newPlayer.setUrl(story.s3Location);
      _currentStoryId = story.s3Key;
      await newPlayer.play();
    } catch (e) {
      print('Recovery failed: $e');
      throw Exception('Failed to recover from playback error: $e');
    }
  }
  
  // Find and set current track index based on story ID
  void setCurrentTrackByStoryId(String storyId) {
    final index = _playlist.indexWhere((story) => story.s3Key == storyId);
    if (index >= 0) {
      _currentTrackIndex = index;
      // Emit current track change
      _currentTrackController.add(currentTrack);
    }
  }

  // Get playback streams for UI updates
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<bool> get playingStream => player.playingStream;
  Stream<ProcessingState> get processingStateStream => player.processingStateStream;
  
  // Stream for current track changes
  Stream<Story?> get currentTrackStream => _currentTrackController.stream;

  // Dispose resources
  Future<void> dispose() async {
    _trackChangeDebouncer?.cancel();
    await _currentTrackController.close();
    await _player?.dispose();
    _player = null;
    _currentStoryId = null;
  }
}

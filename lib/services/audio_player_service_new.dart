import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/story.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _initializePlayer();
  }

  late AudioPlayer _player;
  String? _currentStoryId;
  
  // Playlist management
  List<Story> _playlist = [];
  int _currentTrackIndex = -1;
  
  // Stream controllers for reactive UI updates
  final StreamController<Story?> _currentTrackController = StreamController<Story?>.broadcast();
  
  void _initializePlayer() {
    _player = AudioPlayer();
    _player.setLoopMode(LoopMode.off);
    _player.setShuffleModeEnabled(false);
  }
  
  AudioPlayer get player => _player;

  // Current playback state
  bool get isPlaying => _player.playing;
  bool get isPaused => !_player.playing && _player.processingState != ProcessingState.idle;
  Duration get currentPosition => _player.position;
  Duration? get totalDuration => _player.duration;
  
  // Playlist getters
  List<Story> get playlist => _playlist;
  int get currentTrackIndex => _currentTrackIndex;
  Story? get currentTrack => _currentTrackIndex >= 0 && _currentTrackIndex < _playlist.length 
      ? _playlist[_currentTrackIndex] 
      : null;
  bool get hasNext => _currentTrackIndex < _playlist.length - 1;
  bool get hasPrevious => _currentTrackIndex > 0;
  
  // Play audio from URL - SIMPLIFIED
  Future<void> playFromUrl(String url, String storyId) async {
    try {
      // Update metadata IMMEDIATELY
      _currentStoryId = storyId;
      _updateCurrentTrackFromStoryId(storyId);
      
      // If same story, just play/resume
      if (_currentStoryId == storyId && _player.processingState != ProcessingState.idle) {
        await _player.play();
        return;
      }
      
      // Load new audio
      await _player.setUrl(url);
      await _player.play();
      
    } catch (e) {
      print('Audio playback error: $e');
      throw Exception('Failed to play audio: $e');
    }
  }
  
  // Update current track from story ID
  void _updateCurrentTrackFromStoryId(String storyId) {
    final index = _playlist.indexWhere((story) => story.s3Key == storyId);
    if (index >= 0) {
      _currentTrackIndex = index;
      _currentTrackController.add(_playlist[index]);
    }
  }

  // Pause playback
  Future<void> pause() async {
    await _player.pause();
  }

  // Resume playback
  Future<void> resume() async {
    await _player.play();
  }

  // Stop playback
  Future<void> stop() async {
    await _player.stop();
    _currentStoryId = null;
  }

  // Seek to position
  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
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
    if (_currentTrackIndex >= 0 && _currentTrackIndex < _playlist.length) {
      _currentTrackController.add(_playlist[_currentTrackIndex]);
    }
  }
  
  // Play specific track by index
  Future<void> playTrackAtIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    
    _currentTrackIndex = index;
    final story = _playlist[index];
    
    // Update metadata IMMEDIATELY
    _currentTrackController.add(story);
    
    await playFromUrl(story.s3Location, story.s3Key);
  }
  
  // Play next track - SIMPLIFIED
  Future<void> nextTrack() async {
    if (!hasNext) return;
    
    _currentTrackIndex++;
    final story = _playlist[_currentTrackIndex];
    
    // Update metadata IMMEDIATELY
    _currentTrackController.add(story);
    
    await playFromUrl(story.s3Location, story.s3Key);
  }
  
  // Play previous track - SIMPLIFIED  
  Future<void> previousTrack() async {
    if (!hasPrevious) return;
    
    _currentTrackIndex--;
    final story = _playlist[_currentTrackIndex];
    
    // Update metadata IMMEDIATELY
    _currentTrackController.add(story);
    
    await playFromUrl(story.s3Location, story.s3Key);
  }
  
  // Find and set current track index based on story ID
  void setCurrentTrackByStoryId(String storyId) {
    final index = _playlist.indexWhere((story) => story.s3Key == storyId);
    if (index >= 0) {
      _currentTrackIndex = index;
      _currentTrackController.add(_playlist[index]);
    }
  }

  // Get playback streams for UI updates
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<ProcessingState> get processingStateStream => _player.processingStateStream;
  
  // Stream for current track changes
  Stream<Story?> get currentTrackStream => _currentTrackController.stream;

  // Dispose resources
  Future<void> dispose() async {
    await _currentTrackController.close();
    await _player.dispose();
    _currentStoryId = null;
  }
}

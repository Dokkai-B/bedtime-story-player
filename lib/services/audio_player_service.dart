import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
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
  
  Future<void> _initializePlayer() async {
    _player = AudioPlayer();
    _player.setLoopMode(LoopMode.off);
    _player.setShuffleModeEnabled(false);
    
    // Configure audio session for better performance
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      print('Failed to configure audio session: $e');
    }
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
  
  // Play audio from URL - FIXED
  Future<void> playFromUrl(String url, String storyId) async {
    try {
      // Check if same story is already loaded AND playing
      final isSameStory = _currentStoryId == storyId && _player.processingState != ProcessingState.idle;
      
      // If same story and currently paused, just resume
      if (isSameStory && !_player.playing) {
        await _player.play();
        return;
      }
      
      // If different story or not loaded, load new audio
      if (!isSameStory) {
        // Update metadata IMMEDIATELY
        _currentStoryId = storyId;
        _updateCurrentTrackFromStoryId(storyId);
        
        // Load new audio
        await _loadAndPlayAudio(url);
      } else {
        // Same story, already playing, just ensure it's playing
        await _player.play();
      }
      
    } catch (e) {
      print('Audio playbook error: $e');
      throw Exception('Failed to play audio: $e');
    }
  }
  
  // Force play audio from URL (useful for manual selections)
  Future<void> forcePlayFromUrl(String url, String storyId) async {
    try {
      // Always update metadata and load new audio
      _currentStoryId = storyId;
      _updateCurrentTrackFromStoryId(storyId);
      
      // Load new audio
      await _loadAndPlayAudio(url);
      
    } catch (e) {
      print('Audio playbook error: $e');
      throw Exception('Failed to play audio: $e');
    }
  }
  
  // Load and play audio without metadata updates
  Future<void> _loadAndPlayAudio(String url) async {
    await _player.setUrl(url);
    await _player.play();
  }
  
  // Update current track from story ID
  void _updateCurrentTrackFromStoryId(String storyId) {
    final index = _playlist.indexWhere((story) => story.s3Key == storyId);
    if (index >= 0) {
      _currentTrackIndex = index;
      _currentTrackController.add(_playlist[index]);
    } else {
      // If story is not in playlist, keep current index but clear the track
      // This handles direct playback of stories not in the current playlist
      print('Story $storyId not found in current playlist');
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
    // Reset track index to avoid confusion
    _currentTrackIndex = -1;
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
    _currentStoryId = story.s3Key;
    _currentTrackController.add(story);
    
    // Load and play audio
    await _loadAndPlayAudio(story.s3Location);
  }
  
  // Play next track - FIXED
  Future<void> nextTrack() async {
    if (!hasNext) return;
    
    _currentTrackIndex++;
    final story = _playlist[_currentTrackIndex];
    
    // Update metadata IMMEDIATELY
    _currentStoryId = story.s3Key;
    _currentTrackController.add(story);
    
    // Load and play audio
    await _loadAndPlayAudio(story.s3Location);
  }
  
  // Play previous track - FIXED
  Future<void> previousTrack() async {
    if (!hasPrevious) return;
    
    _currentTrackIndex--;
    final story = _playlist[_currentTrackIndex];
    
    // Update metadata IMMEDIATELY
    _currentStoryId = story.s3Key;
    _currentTrackController.add(story);
    
    // Load and play audio
    await _loadAndPlayAudio(story.s3Location);
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

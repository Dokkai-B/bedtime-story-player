import 'package:flutter/material.dart';
import 'dart:async';
import '../models/story.dart';
import '../services/audio_player_service.dart';

class ExpandableAudioPlayer extends StatefulWidget {
  final Story story;
  final VoidCallback? onClose;

  const ExpandableAudioPlayer({
    super.key,
    required this.story,
    this.onClose,
  });

  @override
  State<ExpandableAudioPlayer> createState() => _ExpandableAudioPlayerState();
}

class _ExpandableAudioPlayerState extends State<ExpandableAudioPlayer>
    with TickerProviderStateMixin {
  final AudioPlayerService _audioService = AudioPlayerService();
  bool _isLoading = false;
  String? _error;
  Timer? _seekDebounceTimer;
  bool _isSeeking = false;
  double? _seekingValue;
  bool _isExpanded = false;
  Story? _currentTrack; // Track the current playing track
  
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _currentTrack = widget.story; // Initialize with the passed story
    
    // Listen to current track changes
    _audioService.currentTrackStream.listen((track) {
      if (mounted && track != null) {
        setState(() {
          _currentTrack = track;
        });
      }
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));
  }

  @override
  void dispose() {
    _seekDebounceTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Expanded player overlay
            if (_isExpanded)
              _buildExpandedPlayer(),
              
            // Mini player bar
            if (!_isExpanded || _animationController.value < 1.0)
              _buildMiniPlayer(),
          ],
        );
      },
    );
  }

  Widget _buildMiniPlayer() {
    return StreamBuilder<bool>(
      stream: _audioService.playingStream,
      builder: (context, playingSnapshot) {
        final isPlaying = playingSnapshot.data ?? false;
        
        return StreamBuilder<Duration?>(
          stream: _audioService.durationStream,
          builder: (context, durationSnapshot) {
            final duration = durationSnapshot.data;
            
            return StreamBuilder<Duration>(
              stream: _audioService.positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                
                return GestureDetector(
                  onTap: _toggleExpanded,
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, -2),
                        ),
                      ],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        // Thumbnail
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.audiotrack,
                            color: Colors.deepPurple.shade600,
                            size: 20,
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Title and progress
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentTrack?.title ?? widget.story.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Progress bar
                              SizedBox(
                                height: 2,
                                child: LinearProgressIndicator(
                                  value: duration != null && duration.inMilliseconds > 0
                                      ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                                      : 0.0,
                                  backgroundColor: Colors.deepPurple.shade100,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple.shade400),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Play/Pause button
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _togglePlayPause,
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildExpandedPlayer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight * 0.8; // Use 80% of available height
        
        return Positioned.fill(
          child: AnimatedBuilder(
            animation: _heightAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, MediaQuery.of(context).size.height * (1 - _heightAnimation.value)),
                child: Container(
                  height: maxHeight, // Constrained height
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16 * _heightAnimation.value),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2 * _heightAnimation.value),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: StreamBuilder<bool>(
                    stream: _audioService.playingStream,
                    builder: (context, playingSnapshot) {
                      final isPlaying = playingSnapshot.data ?? false;
                      
                      return StreamBuilder<Duration?>(
                        stream: _audioService.durationStream,
                        builder: (context, durationSnapshot) {
                          final duration = durationSnapshot.data;
                          
                          return StreamBuilder<Duration>(
                            stream: _audioService.positionStream,
                            builder: (context, positionSnapshot) {
                              final position = positionSnapshot.data ?? Duration.zero;
                              
                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    // Handle bar
                                    Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Header with close button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const SizedBox(width: 40), // Balance the close button
                                        Text(
                                          'Now Playing',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: _toggleExpanded,
                                          icon: const Icon(Icons.keyboard_arrow_down),
                                          color: Colors.grey.shade600,
                                          iconSize: 24,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 40,
                                            minHeight: 40,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Large thumbnail
                                    Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.deepPurple.withOpacity(0.2),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.audiotrack,
                                        color: Colors.deepPurple.shade600,
                                        size: 80,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Title
                                    Text(
                                      _currentTrack?.title ?? widget.story.title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    
                                    const SizedBox(height: 6),
                                    
                                    // Time display
                                    Text(
                                      '${_formatDuration(position)} / ${duration != null ? _formatDuration(duration) : '--:--'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Expanded controls
                                    _buildExpandedControls(isPlaying, duration, position),
                                    
                                    if (_error != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: Colors.red.shade600,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _error!,
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExpandedControls(bool isPlaying, Duration? duration, Duration position) {
    return Column(
      children: [
        // Progress bar
        Row(
          children: [
            Text(
              _formatDuration(position),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Slider(
                value: _isSeeking && _seekingValue != null
                    ? _seekingValue!
                    : (duration != null && duration.inMilliseconds > 0
                        ? (position.inMilliseconds / duration.inMilliseconds)
                            .clamp(0.0, 1.0)
                        : 0.0),
                onChangeStart: (value) {
                  setState(() {
                    _isSeeking = true;
                    _seekingValue = value;
                  });
                },
                onChanged: duration != null
                    ? (value) {
                        setState(() {
                          _seekingValue = value;
                        });
                        
                        // Cancel previous timer
                        _seekDebounceTimer?.cancel();
                        
                        // Set new timer for debounced seeking
                        _seekDebounceTimer = Timer(const Duration(milliseconds: 150), () {
                          if (mounted && duration != null) {
                            final seekPosition = Duration(
                              milliseconds: (duration.inMilliseconds * value).round(),
                            );
                            _performSeek(seekPosition);
                          }
                        });
                      }
                    : null,
                onChangeEnd: (value) {
                  // Immediately seek on release for better UX
                  if (duration != null && mounted) {
                    _seekDebounceTimer?.cancel();
                    final seekPosition = Duration(
                      milliseconds: (duration.inMilliseconds * value).round(),
                    );
                    _performSeek(seekPosition);
                  }
                  setState(() {
                    _isSeeking = false;
                    _seekingValue = null;
                  });
                },
                activeColor: Colors.deepPurple,
                inactiveColor: Colors.deepPurple.shade100,
              ),
            ),
            Text(
              duration != null ? _formatDuration(duration) : '--:--',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous track (using fast_rewind icon)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _audioService.hasPrevious ? Colors.deepPurple.shade50 : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _audioService.hasPrevious ? _previousTrack : null,
                icon: const Icon(Icons.fast_rewind),
                color: _audioService.hasPrevious ? Colors.deepPurple.shade600 : Colors.grey.shade400,
                iconSize: 20,
                padding: EdgeInsets.zero,
              ),
            ),
            
            // Play/Pause button
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _togglePlayPause,
                padding: EdgeInsets.zero,
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            
            // Next track (using fast_forward icon)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _audioService.hasNext ? Colors.deepPurple.shade50 : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _audioService.hasNext ? _nextTrack : null,
                icon: const Icon(Icons.fast_forward),
                color: _audioService.hasNext ? Colors.deepPurple.shade600 : Colors.grey.shade400,
                iconSize: 20,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
                onPressed: _audioService.hasNext ? _nextTrack : null,
                icon: const Icon(Icons.skip_next),
                color: _audioService.hasNext ? Colors.deepPurple.shade600 : Colors.grey.shade400,
                iconSize: 20,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _togglePlayPause() async {
    if (!mounted) return;
    
    try {
      if (_audioService.isCurrentStory(widget.story.s3Key)) {
        // Current story is loaded
        if (_audioService.isPlaying) {
          await _audioService.pause();
        } else {
          await _audioService.resume();
        }
      } else {
        // Load and play new story (force play for manual selection)
        await _audioService.forcePlayFromUrl(widget.story.s3Location, widget.story.s3Key);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _performSeek(Duration position) async {
    try {
      await _audioService.seekTo(position);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Seek failed: ${e.toString()}';
        });
      }
    }
  }

  // Track navigation methods - SIMPLIFIED
  Future<void> _nextTrack() async {
    if (!mounted || !_audioService.hasNext) return;
    
    try {
      await _audioService.nextTrack();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to play next track: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _previousTrack() async {
    if (!mounted || !_audioService.hasPrevious) return;
    
    try {
      await _audioService.previousTrack();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to play previous track: ${e.toString()}';
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

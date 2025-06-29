import 'package:flutter/material.dart';
import '../models/story.dart';
import '../services/audio_player_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Story story;
  final VoidCallback? onClose;

  const AudioPlayerWidget({
    super.key,
    required this.story,
    this.onClose,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayerService _audioService = AudioPlayerService();
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.audiotrack,
                color: Colors.deepPurple.shade400,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.story.fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.story.displaySize,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _audioService.stop();
                    widget.onClose!();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Error Display
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Controls and Progress
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
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
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: duration != null && duration.inMilliseconds > 0
                                ? (position.inMilliseconds / duration.inMilliseconds)
                                    .clamp(0.0, 1.0)
                                : 0.0,
                            onChanged: duration != null
                                ? (value) {
                                    final seekPosition = Duration(
                                      milliseconds: (duration.inMilliseconds * value).round(),
                                    );
                                    _audioService.seekTo(seekPosition);
                                  }
                                : null,
                            activeColor: Colors.deepPurple,
                            inactiveColor: Colors.deepPurple.shade100,
                          ),
                        ),
                        Text(
                          duration != null ? _formatDuration(duration) : '--:--',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Skip back 15s
                        IconButton(
                          onPressed: () {
                            final newPosition = position - const Duration(seconds: 15);
                            _audioService.seekTo(
                              newPosition < Duration.zero ? Duration.zero : newPosition,
                            );
                          },
                          icon: const Icon(Icons.fast_rewind),
                          color: Colors.deepPurple.shade600,
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Play/Pause button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: _isLoading ? null : _togglePlayPause,
                            icon: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Skip forward 15s
                        IconButton(
                          onPressed: () {
                            final newPosition = position + const Duration(seconds: 15);
                            if (duration != null && newPosition < duration) {
                              _audioService.seekTo(newPosition);
                            }
                          },
                          icon: const Icon(Icons.fast_forward),
                          color: Colors.deepPurple.shade600,
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _togglePlayPause() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_audioService.isCurrentStory(widget.story.s3Key)) {
        // Current story is loaded
        if (_audioService.isPlaying) {
          await _audioService.pause();
        } else {
          await _audioService.resume();
        }
      } else {
        // Load and play new story
        await _audioService.playFromUrl(widget.story.s3Location, widget.story.s3Key);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

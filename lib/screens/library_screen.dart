import 'package:flutter/material.dart';
import '../models/story.dart';
import '../services/story_library_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/expandable_audio_player.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Story> _stories = [];
  List<Story> _filteredStories = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'all';
  String _sortBy = 'date';
  String _searchQuery = '';
  
  // Audio player state
  Story? _currentlyPlayingStory;
  final AudioPlayerService _audioService = AudioPlayerService();

  final List<String> _categories = ['all', 'text', 'audio'];
  final List<String> _sortOptions = ['date', 'name', 'size'];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }
  
  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    if (!mounted) return;
    
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final stories = await StoryLibraryService.fetchStories();
      if (mounted) {
        setState(() {
          _stories = stories;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    if (!mounted) return;
    
    var filtered = StoryLibraryService.filterByCategory(_stories, _selectedCategory);
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((story) =>
          story.fileName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    
    filtered = StoryLibraryService.sortStories(filtered, _sortBy);
    
    if (mounted) {
      setState(() {
        _filteredStories = filtered;
      });
    }
  }

  void _onCategoryChanged(String? category) {
    if (!mounted) return;
    
    setState(() {
      _selectedCategory = category ?? 'all';
      _applyFilters();
    });
  }

  void _onSortChanged(String? sortBy) {
    if (!mounted) return;
    
    setState(() {
      _sortBy = sortBy ?? 'date';
      _applyFilters();
    });
  }

  void _onSearchChanged(String query) {
    if (!mounted) return;
    
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stories'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStories,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.grey[100],
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search stories...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: 12),
                    // Filter Row
                    Row(
                      children: [
                        // Category Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(
                                  category == 'all' ? Icons.all_inclusive :
                                  category == 'text' ? Icons.text_snippet :
                                  Icons.audiotrack,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(category.toUpperCase()),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _onCategoryChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: InputDecoration(
                          labelText: 'Sort by',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _sortOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Row(
                              children: [
                                Icon(
                                  option == 'date' ? Icons.date_range :
                                  option == 'name' ? Icons.sort_by_alpha :
                                  Icons.data_usage,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(option.toUpperCase()),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _onSortChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content Area
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: _currentlyPlayingStory != null ? 72.0 : 0.0,
              ),
              child: _buildContent(),
            ),
          ),
        ],
      ),
      
      // Expandable Audio Player (shown when playing)
      if (_currentlyPlayingStory != null)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ExpandableAudioPlayer(
            story: _currentlyPlayingStory!,
            onClose: () {
              if (mounted) {
                setState(() {
                  _currentlyPlayingStory = null;
                });
              }
            },
          ),
        ),
    ],
  ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your stories...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load stories',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStories,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredStories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _stories.isEmpty ? Icons.library_books_outlined : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _stories.isEmpty ? 'No Stories Yet' : 'No Stories Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _stories.isEmpty 
                  ? 'Upload your first bedtime story to get started!'
                  : 'Try adjusting your search or filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStories,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredStories.length,
        itemBuilder: (context, index) {
          final story = _filteredStories[index];
          return _buildStoryCard(story);
        },
      ),
    );
  }

  Widget _buildStoryCard(Story story) {
    final isCurrentlyPlaying = _currentlyPlayingStory?.s3Key == story.s3Key;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _onStoryTap(story),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Story Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: story.isAudio ? Colors.orange[100] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      story.isAudio ? Icons.audiotrack : Icons.text_snippet,
                      color: story.isAudio ? Colors.orange[800] : Colors.blue[800],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Story Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.fileName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              story.displaySize,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              story.formattedDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Play button for audio stories
                  if (story.isAudio)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isCurrentlyPlaying ? Colors.deepPurple : Colors.deepPurple.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => _onPlayButtonTap(story),
                        icon: StreamBuilder<bool>(
                          stream: _audioService.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            return Icon(
                              isCurrentlyPlaying && isPlaying ? Icons.pause : Icons.play_arrow,
                              color: isCurrentlyPlaying ? Colors.white : Colors.deepPurple,
                            );
                          },
                        ),
                      ),
                    ),
                    
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: story.isAudio ? Colors.orange[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      story.category.toUpperCase(),
                      style: TextStyle(
                        color: story.isAudio ? Colors.orange[800] : Colors.blue[800],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onStoryTap(Story story) {
    // Show a simple dialog for now - you can enhance this later
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(story.fileName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${story.fileType}'),
            Text('Size: ${story.displaySize}'),
            Text('Uploaded: ${story.formattedDate}'),
            Text('Category: ${story.category}'),
            const SizedBox(height: 16),
            Text('S3 Location:', style: TextStyle(color: Colors.grey[600])),
            Text(
              story.s3Location,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (story.isAudio)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _onPlayButtonTap(story);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          if (story.isText)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement text reader
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Text reader coming soon!')),
                );
              },
              icon: const Icon(Icons.text_snippet),
              label: const Text('Read'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onPlayButtonTap(Story story) async {
    if (!story.isAudio) return;

    try {
      final isCurrentStory = _currentlyPlayingStory?.s3Key == story.s3Key;
      
      if (isCurrentStory) {
        // Toggle play/pause for current story
        if (_audioService.isPlaying) {
          await _audioService.pause();
        } else {
          await _audioService.resume();
        }
      } else {
        // Play new story - initialize playlist
        if (mounted) {
          setState(() {
            _currentlyPlayingStory = story;
          });
        }
        
        // Set up playlist with all audio stories
        final audioStories = _filteredStories.where((s) => s.isAudio).toList();
        final currentIndex = audioStories.indexWhere((s) => s.s3Key == story.s3Key);
        
        _audioService.setPlaylist(audioStories, initialIndex: currentIndex >= 0 ? currentIndex : 0);
        await _audioService.forcePlayFromUrl(story.s3Location, story.s3Key);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to play audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // If there was an error, clear the currently playing story
      if (mounted) {
        setState(() {
          _currentlyPlayingStory = null;
        });
      }
    }
  }
}

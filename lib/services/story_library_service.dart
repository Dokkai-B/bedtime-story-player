import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/story.dart';
import '../config/app_config.dart';

class StoryLibraryService {
  // Backend URL - Uses centralized configuration
  static String get baseUrl => AppConfig.baseUrl;
  
  /// Fetch all stories from the backend
  static Future<List<Story>> fetchStories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stories'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['success'] == true) {
          final List<dynamic> storiesJson = data['stories'] ?? [];
          return storiesJson.map((json) => Story.fromJson(json)).toList();
        } else {
          throw Exception('Failed to fetch stories: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  /// Filter stories by category
  static List<Story> filterByCategory(List<Story> stories, String? category) {
    if (category == null || category.isEmpty || category == 'all') {
      return stories;
    }
    return stories.where((story) => story.category == category).toList();
  }

  /// Sort stories by different criteria
  static List<Story> sortStories(List<Story> stories, String sortBy) {
    switch (sortBy) {
      case 'name':
        stories.sort((a, b) => a.fileName.compareTo(b.fileName));
        break;
      case 'size':
        stories.sort((a, b) => b.fileSize.compareTo(a.fileSize));
        break;
      case 'date':
      default:
        stories.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
        break;
    }
    return stories;
  }
}

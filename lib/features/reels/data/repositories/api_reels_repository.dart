import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gomhor_alahly_clean_new/features/reels/domain/entities/reel.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/repositories/reels_repository.dart';

class ApiReelsRepository implements ReelsRepository {
  final String _baseUrl = 'https://api.example.com'; // Replace with your API base URL

  @override
  Future<List<Reel>> getReels({int page = 1}) async {
    final response = await http.get(Uri.parse('$_baseUrl/reels?page=$page'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Reel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reels');
    }
  }
}

// Add fromJson to Reel entity
class Reel {
  // ... existing code

  factory Reel.fromJson(Map<String, dynamic> json) {
    return Reel(
      videoUrl: json['videoUrl'],
      userName: json['userName'],
      caption: json['caption'],
      isLiked: json['isLiked'] ?? false,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      isFollowed: json['isFollowed'] ?? false,
    );
  }
}

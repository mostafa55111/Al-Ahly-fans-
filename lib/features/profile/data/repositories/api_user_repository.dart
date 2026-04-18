import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gomhor_alahly_clean_new/features/profile/domain/entities/user.dart';
import 'package:gomhor_alahly_clean_new/features/profile/domain/repositories/user_repository.dart';

class ApiUserRepository implements UserRepository {
  final String _baseUrl = 'https://api.example.com'; // Replace with your API base URL

  @override
  Future<User> getUserProfile(String userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/users/$userId'));

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  @override
  Future<void> followUser(String userId) async {
    final response = await http.post(Uri.parse('$_baseUrl/users/$userId/follow'));

    if (response.statusCode != 200) {
      throw Exception('Failed to follow user');
    }
  }

  @override
  Future<void> unfollowUser(String userId) async {
    final response = await http.post(Uri.parse('$_baseUrl/users/$userId/unfollow'));

    if (response.statusCode != 200) {
      throw Exception('Failed to unfollow user');
    }
  }
}

// Add fromJson to User entity
class User {
  // ... existing code

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      userName: json['userName'],
      profilePicUrl: json['profilePicUrl'],
      isFollowed: json['isFollowed'] ?? false,
    );
  }
}

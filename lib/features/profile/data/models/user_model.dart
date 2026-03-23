import 'package:firebase_database/firebase_database.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String profileImageUrl;
  final String bio;
  final int followersCount;
  final int followingCount;
  final int reelsCount;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.profileImageUrl,
    this.bio = '',
    this.followersCount = 0,
    this.followingCount = 0,
    this.reelsCount = 0,
    required this.createdAt,
  });

  factory UserModel.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return UserModel(
      id: snapshot.key!,
      username: data['username'] as String,
      email: data['email'] as String,
      profileImageUrl: data['profileImageUrl'] as String,
      bio: data['bio'] as String? ?? '',
      followersCount: data['followersCount'] as int? ?? 0,
      followingCount: data['followingCount'] as int? ?? 0,
      reelsCount: data['reelsCount'] as int? ?? 0,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'reelsCount': reelsCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

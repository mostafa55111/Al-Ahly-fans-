import 'package:equatable/equatable.dart';

/// Core User Entity
/// Represents the user in the domain layer
class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isVerified;
  final Map<String, dynamic>? preferences;
  final List<String>? favoriteTeams;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    required this.createdAt,
    required this.lastActiveAt,
    this.isVerified = false,
    this.preferences,
    this.favoriteTeams,
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePicture,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isVerified,
    Map<String, dynamic>? preferences,
    List<String>? favoriteTeams,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isVerified: isVerified ?? this.isVerified,
      preferences: preferences ?? this.preferences,
      favoriteTeams: favoriteTeams ?? this.favoriteTeams,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        profilePicture,
        createdAt,
        lastActiveAt,
        isVerified,
        preferences,
        favoriteTeams,
      ];
}

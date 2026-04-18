import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String userName;
  final String profilePicUrl;
  final bool isFollowed;

  const User({
    required this.id,
    required this.userName,
    required this.profilePicUrl,
    this.isFollowed = false,
  });

  User copyWith({
    String? id,
    String? userName,
    String? profilePicUrl,
    bool? isFollowed,
  }) {
    return User(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }

  @override
  List<Object?> get props => [id, userName, profilePicUrl, isFollowed];
}

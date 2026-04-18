import 'package:gomhor_alahly_clean_new/features/profile/domain/entities/user.dart';
import 'package:gomhor_alahly_clean_new/features/profile/domain/repositories/user_repository.dart';

class MockUserRepository implements UserRepository {
  final Map<String, User> _users = {
    'flutterdev': const User(
      id: 'flutterdev',
      userName: 'flutterdev',
      profilePicUrl: 'https://yt3.ggpht.com/a/AATXAJz9y-k-iI-p-VnL-a-c-J-e-8-I-Z-u-q-Y-g=s900-c-k-c0xffffffff-no-rj-mo',
    ),
    'naturelover': const User(
      id: 'naturelover',
      userName: 'naturelover',
      profilePicUrl: 'https://images.unsplash.com/photo-1502082553048-f009c37129b9?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&w=1000&q=80',
    ),
  };

  @override
  Future<User> getUserProfile(String userId) async {
    // Simulate a network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _users[userId]!;
  }

  @override
  Future<void> followUser(String userId) async {
    // Simulate a network delay
    await Future.delayed(const Duration(milliseconds: 500));
    final user = _users[userId]!;
    _users[userId] = user.copyWith(isFollowed: true);
  }

  @override
  Future<void> unfollowUser(String userId) async {
    // Simulate a network delay
    await Future.delayed(const Duration(milliseconds: 500));
    final user = _users[userId]!;
    _users[userId] = user.copyWith(isFollowed: false);
  }
}

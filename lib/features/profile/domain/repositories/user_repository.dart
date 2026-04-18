import 'package:gomhor_alahly_clean_new/features/profile/domain/entities/user.dart';

abstract class UserRepository {
  Future<User> getUserProfile(String userId);
  Future<void> followUser(String userId);
  Future<void> unfollowUser(String userId);
}

import 'package:equatable/equatable.dart';

/// كيان المتابعة (Follow)
/// يمثل علاقة المتابعة بين مستخدمين
class FollowEntity extends Equatable {
  /// معرف المتابِع (الشخص الذي يتابع)
  final String followerId;
  
  /// اسم المتابِع
  final String followerName;
  
  /// صورة المتابِع
  final String followerProfileImage;
  
  /// معرف المتابَع (الشخص الذي يتم متابعته)
  final String followingId;
  
  /// اسم المتابَع
  final String followingName;
  
  /// صورة المتابَع
  final String followingProfileImage;
  
  /// وقت المتابعة
  final DateTime followedAt;
  
  /// هل هذه متابعة متبادلة
  final bool isMutual;
  
  /// هل تم حظر المتابِع
  final bool isBlocked;
  
  /// هل تم كتم صوت المتابِع
  final bool isMuted;
  
  /// هل تم إضافة المتابِع للمفضلة
  final bool isFavorite;

  const FollowEntity({
    required this.followerId,
    required this.followerName,
    required this.followerProfileImage,
    required this.followingId,
    required this.followingName,
    required this.followingProfileImage,
    required this.followedAt,
    required this.isMutual,
    required this.isBlocked,
    required this.isMuted,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [
    followerId,
    followerName,
    followerProfileImage,
    followingId,
    followingName,
    followingProfileImage,
    followedAt,
    isMutual,
    isBlocked,
    isMuted,
    isFavorite,
  ];
}

/// بيانات المستخدم المختصرة
class UserProfile extends Equatable {
  /// معرف المستخدم
  final String id;
  
  /// اسم المستخدم
  final String name;
  
  /// صورة الملف الشخصي
  final String profileImage;
  
  /// البيو (الوصف)
  final String bio;
  
  /// عدد المتابعين
  final int followersCount;
  
  /// عدد المتابَعين
  final int followingCount;
  
  /// عدد المنشورات
  final int postsCount;
  
  /// هل المستخدم معروف (Verified)
  final bool isVerified;
  
  /// هل المستخدم متابع من قبل المستخدم الحالي
  final bool isFollowing;

  const UserProfile({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.isVerified,
    required this.isFollowing,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    profileImage,
    bio,
    followersCount,
    followingCount,
    postsCount,
    isVerified,
    isFollowing,
  ];
}

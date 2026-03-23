import 'package:equatable/equatable.dart';

/// كيان المنشور في الفيد الاجتماعي
/// يمثل منشور واحد من المشجعين مع جميع البيانات المرتبطة به
class PostEntity extends Equatable {
  /// معرف فريد للمنشور
  final String id;
  
  /// معرف المستخدم الذي أنشأ المنشور
  final String userId;
  
  /// اسم المستخدم
  final String userName;
  
  /// صورة ملف المستخدم
  final String userProfileImage;
  
  /// النص الأساسي للمنشور
  final String content;
  
  /// قائمة الصور المرفقة
  final List<String> imageUrls;
  
  /// رابط الفيديو إن وجد
  final String? videoUrl;
  
  /// الموقع الجغرافي (اختياري)
  final String? location;
  
  /// عدد الإعجابات
  final int likesCount;
  
  /// عدد التعليقات
  final int commentsCount;
  
  /// عدد المشاركات
  final int sharesCount;
  
  /// هل أعجب المستخدم الحالي بهذا المنشور
  final bool isLikedByCurrentUser;
  
  /// الهاشتاجات المستخدمة
  final List<String> hashtags;
  
  /// الأشخاص المذكورين
  final List<String> mentions;
  
  /// وقت إنشاء المنشور
  final DateTime createdAt;
  
  /// وقت آخر تحديث
  final DateTime? updatedAt;
  
  /// هل المنشور مثبت
  final bool isPinned;
  
  /// هل المنشور محذوف
  final bool isDeleted;
  
  /// نوع المنشور (نص، صورة، فيديو، مختلط)
  final PostType postType;
  
  /// الإحداثيات الجغرافية (latitude, longitude)
  final GeoLocation? geoLocation;
  
  /// المشاعر المرتبطة بالمنشور
  final List<String> reactions;

  const PostEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfileImage,
    required this.content,
    required this.imageUrls,
    this.videoUrl,
    this.location,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.isLikedByCurrentUser,
    required this.hashtags,
    required this.mentions,
    required this.createdAt,
    this.updatedAt,
    required this.isPinned,
    required this.isDeleted,
    required this.postType,
    this.geoLocation,
    required this.reactions,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    userProfileImage,
    content,
    imageUrls,
    videoUrl,
    location,
    likesCount,
    commentsCount,
    sharesCount,
    isLikedByCurrentUser,
    hashtags,
    mentions,
    createdAt,
    updatedAt,
    isPinned,
    isDeleted,
    postType,
    geoLocation,
    reactions,
  ];
}

/// أنواع المنشورات المختلفة
enum PostType {
  text,      // نص فقط
  image,     // صور فقط
  video,     // فيديو فقط
  mixed,     // مختلط (نص + صور/فيديو)
  story,     // قصة
  reel,      // ريل
}

/// بيانات الموقع الجغرافي
class GeoLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;

  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];
}

import 'package:equatable/equatable.dart';

/// كيان القصة (Story)
/// تمثل قصة من قصص المشجعين التي تختفي بعد 24 ساعة
class StoryEntity extends Equatable {
  /// معرف فريد للقصة
  final String id;
  
  /// معرف المستخدم الذي أنشأ القصة
  final String userId;
  
  /// اسم المستخدم
  final String userName;
  
  /// صورة ملف المستخدم
  final String userProfileImage;
  
  /// نوع المحتوى (صورة أو فيديو)
  final StoryType type;
  
  /// رابط الصورة أو الفيديو
  final String mediaUrl;
  
  /// النص المرفق بالقصة (اختياري)
  final String? caption;
  
  /// وقت إنشاء القصة
  final DateTime createdAt;
  
  /// وقت انتهاء القصة (بعد 24 ساعة)
  final DateTime expiresAt;
  
  /// عدد المشاهدات
  final int viewsCount;
  
  /// هل شاهد المستخدم الحالي هذه القصة
  final bool isViewed;
  
  /// قائمة معرفات المستخدمين الذين شاهدوا القصة
  final List<String> viewedBy;
  
  /// هل القصة مثبتة
  final bool isPinned;
  
  /// الموقع الجغرافي (اختياري)
  final String? location;
  
  /// الموسيقى المستخدمة (اختياري)
  final String? music;
  
  /// المرشحات المستخدمة
  final List<String> filters;
  
  /// هل القصة محذوفة
  final bool isDeleted;

  const StoryEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfileImage,
    required this.type,
    required this.mediaUrl,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    required this.viewsCount,
    required this.isViewed,
    required this.viewedBy,
    required this.isPinned,
    this.location,
    this.music,
    required this.filters,
    required this.isDeleted,
  });

  /// التحقق من انتهاء صلاحية القصة
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    userProfileImage,
    type,
    mediaUrl,
    caption,
    createdAt,
    expiresAt,
    viewsCount,
    isViewed,
    viewedBy,
    isPinned,
    location,
    music,
    filters,
    isDeleted,
  ];
}

/// أنواع محتوى القصة
enum StoryType {
  image,  // صورة
  video,  // فيديو
  text,   // نص فقط
}

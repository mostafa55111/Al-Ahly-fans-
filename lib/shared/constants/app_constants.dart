/// ثوابت التطبيق الرئيسية
class AppConstants {
  // معلومات التطبيق
  static const String appName = 'جمهور الأهلي';
  static const String appVersion = '2.0.0';
  static const String appBuildNumber = '1';

  // مفتاح التخصيص في قاعدة البيانات
  static const String userCustomAppNameKey = 'customAppName';

  // ألوان الأهلي
  static const String primaryColor = '#CC0000'; // أحمر الأهلي
  static const String secondaryColor = '#FFD700'; // ذهبي
  static const String darkColor = '#0A0A0A'; // أسود عميق

  // Firebase
  static const String firebaseProjectId = 'ahly-fans-app';
  static const String firebaseApiKey = 'YOUR_API_KEY';
  static const String firebaseAppId = 'YOUR_APP_ID';

  // API Endpoints
  static const String baseApiUrl = 'https://api.ahly-fans-app.com';
  static const String apiVersion = 'v1';

  // Pagination
  static const int defaultPageSize = 10;
  static const int maxPageSize = 100;

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Cache
  static const int maxCacheSize = 256 * 1024 * 1024; // 256 MB
  static const Duration cacheExpiration = Duration(hours: 24);

  // Image
  static const int maxImageWidth = 1080;
  static const int maxImageHeight = 1920;
  static const int thumbnailSize = 200;

  // Video
  static const int maxVideoWidth = 1080;
  static const int maxVideoHeight = 1920;
  static const int maxVideoSize = 100 * 1024 * 1024; // 100 MB

  // Notifications
  static const String notificationChannelId = 'ahly_fans_notifications';
  static const String notificationChannelName = 'إشعارات جمهور الأهلي';

  // Story
  static const Duration storyExpiration = Duration(hours: 24);
  static const int maxStoriesPerUser = 100;

  // Post
  static const int maxPostLength = 5000;
  static const int maxHashtags = 30;
  static const int maxMentions = 50;

  // Leaderboard
  static const int leaderboardPageSize = 20;
  static const int topUsersLimit = 10;

  // Achievements
  static const int maxAchievements = 100;
  static const int maxBadges = 50;

  // Validation
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minBioLength = 0;
  static const int maxBioLength = 500;

  // Regex Patterns
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String usernamePattern = r'^[a-zA-Z0-9_]{3,30}$';
  static const String phonePattern = r'^[0-9]{10,15}$';
  static const String urlPattern =
      r'^https?://[^\s/$.?#].[^\s]*$';
  static const String hashtagPattern = r'#[a-zA-Z0-9_]+';
  static const String mentionPattern = r'@[a-zA-Z0-9_]+';

  // Database
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String storiesCollection = 'stories';
  static const String commentsCollection = 'comments';
  static const String likesCollection = 'likes';
  static const String followsCollection = 'follows';
  static const String achievementsCollection = 'achievements';
  static const String leaderboardCollection = 'leaderboard';
  static const String matchesCollection = 'matches';
  static const String notificationsCollection = 'notifications';

  // Shared Preferences Keys
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String userTokenKey = 'user_token';
  static const String userProfileImageKey = 'user_profile_image';
  static const String isDarkModeKey = 'is_dark_mode';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String lastSyncTimeKey = 'last_sync_time';
  static const String languageKey = 'language';

  // Error Messages
  static const String networkErrorMessage = 'خطأ في الاتصال بالإنترنت';
  static const String serverErrorMessage = 'خطأ في الخادم';
  static const String unknownErrorMessage = 'حدث خطأ غير معروف';
  static const String timeoutErrorMessage = 'انتهت مهلة الانتظار';
  static const String unauthorizedErrorMessage = 'غير مصرح';
  static const String forbiddenErrorMessage = 'ممنوع الوصول';
  static const String notFoundErrorMessage = 'لم يتم العثور على البيانات';
  static const String validationErrorMessage = 'بيانات غير صحيحة';

  // Success Messages
  static const String successMessage = 'تم بنجاح';
  static const String postCreatedMessage = 'تم إنشاء المنشور بنجاح';
  static const String postDeletedMessage = 'تم حذف المنشور بنجاح';
  static const String postUpdatedMessage = 'تم تحديث المنشور بنجاح';
  static const String userFollowedMessage = 'تم متابعة المستخدم بنجاح';
  static const String userUnfollowedMessage = 'تم إلغاء متابعة المستخدم بنجاح';

  // Social Media Links
  static const String facebookUrl = 'https://facebook.com/AlAhlyOfficial';
  static const String twitterUrl = 'https://twitter.com/AlAhlyOfficial';
  static const String instagramUrl = 'https://instagram.com/AlAhlyOfficial';
  static const String youtubeUrl = 'https://youtube.com/AlAhlyOfficial';

  // Deeplinks
  static const String deepLinkScheme = 'ahly://';
  static const String deepLinkProfile = 'profile';
  static const String deepLinkPost = 'post';
  static const String deepLinkMatch = 'match';
  static const String deepLinkLeaderboard = 'leaderboard';
}

/// ثوابت الأدوار والصلاحيات
class UserRoles {
  static const String admin = 'admin';
  static const String moderator = 'moderator';
  static const String user = 'user';
  static const String guest = 'guest';
}

/// ثوابت الحالات
class AppStatus {
  static const String loading = 'loading';
  static const String success = 'success';
  static const String error = 'error';
  static const String empty = 'empty';
}

/// ثوابت الأنواع
class ContentTypes {
  static const String text = 'text';
  static const String image = 'image';
  static const String video = 'video';
  static const String audio = 'audio';
  static const String link = 'link';
}

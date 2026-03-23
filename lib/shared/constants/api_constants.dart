/// API Constants
class ApiConstants {
  // Firebase
  static const String firebaseProjectId = 'ahly-fans-app';
  static const String firebaseDatabaseUrl = 'https://ahly-fans-app.firebaseio.com';
  static const String firebaseStorageBucket = 'ahly-fans-app.appspot.com';

  // Endpoints
  static const String baseUrl = 'https://api.example.com';
  static const String postsEndpoint = '/posts';
  static const String usersEndpoint = '/users';
  static const String followsEndpoint = '/follows';
  static const String achievementsEndpoint = '/achievements';
  static const String leaderboardEndpoint = '/leaderboard';
  static const String matchesEndpoint = '/matches';
  static const String storiesEndpoint = '/stories';
  static const String commentsEndpoint = '/comments';
  static const String notificationsEndpoint = '/notifications';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const Duration defaultCacheDuration = Duration(hours: 1);
  static const Duration longCacheDuration = Duration(days: 7);
  static const Duration shortCacheDuration = Duration(minutes: 5);

  // API Keys
  static const String geminiapiKey = 'AIzaSyCNlqhPN6dkOTjF8DfV9IE4wyEzWjrCgjQ';
  static const String footballApiKey = '8c16585903c335eb82435488feac3937';
  static const String cloudinaryApiKey = '497232166977864';
  static const String cloudinaryCloudName = 'dubc6k1iy';

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Error Messages
  static const String networkError = 'خطأ في الاتصال بالإنترنت';
  static const String serverError = 'خطأ في الخادم';
  static const String unauthorizedError = 'غير مصرح';
  static const String forbiddenError = 'ممنوع';
  static const String notFoundError = 'غير موجود';
  static const String validationError = 'خطأ في التحقق';
  static const String unknownError = 'خطأ غير معروف';

  // Success Messages
  static const String successMessage = 'تم بنجاح';
  static const String createdMessage = 'تم الإنشاء بنجاح';
  static const String updatedMessage = 'تم التحديث بنجاح';
  static const String deletedMessage = 'تم الحذف بنجاح';
}

/// Response Status Codes
class ResponseStatusCodes {
  static const int success = 200;
  static const int created = 201;
  static const int accepted = 202;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int conflict = 409;
  static const int unprocessableEntity = 422;
  static const int internalServerError = 500;
  static const int badGateway = 502;
  static const int serviceUnavailable = 503;
}

/// Firebase Paths
class FirebasePaths {
  static const String posts = 'posts';
  static const String users = 'users';
  static const String follows = 'follows';
  static const String achievements = 'achievements';
  static const String leaderboard = 'leaderboard';
  static const String matches = 'matches';
  static const String stories = 'stories';
  static const String comments = 'comments';
  static const String notifications = 'notifications';
  static const String images = 'images';
  static const String videos = 'videos';
  static const String documents = 'documents';
}

/// Database Field Names
class DatabaseFieldNames {
  // Post Fields
  static const String postId = 'id';
  static const String userId = 'userId';
  static const String content = 'content';
  static const String mediaUrls = 'mediaUrls';
  static const String likesCount = 'likesCount';
  static const String commentsCount = 'commentsCount';
  static const String sharesCount = 'sharesCount';
  static const String hashtags = 'hashtags';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';

  // User Fields
  static const String userName = 'userName';
  static const String email = 'email';
  static const String profileImage = 'profileImage';
  static const String bio = 'bio';
  static const String followersCount = 'followersCount';
  static const String followingCount = 'followingCount';
  static const String postsCount = 'postsCount';
  static const String isVerified = 'isVerified';

  // Match Fields
  static const String homeTeam = 'homeTeam';
  static const String awayTeam = 'awayTeam';
  static const String homeScore = 'homeScore';
  static const String awayScore = 'awayScore';
  static const String status = 'status';
  static const String matchDate = 'matchDate';
  static const String tournament = 'tournament';
  static const String season = 'season';

  // Story Fields
  static const String storyId = 'id';
  static const String mediaUrl = 'mediaUrl';
  static const String mediaType = 'mediaType';
  static const String caption = 'caption';
  static const String viewsCount = 'viewsCount';
  static const String reactionsCount = 'reactionsCount';
  static const String expiresAt = 'expiresAt';

  // Achievement Fields
  static const String achievementId = 'id';
  static const String achievementName = 'name';
  static const String achievementDescription = 'description';
  static const String achievementIcon = 'icon';
  static const String unlockedAt = 'unlockedAt';

  // Leaderboard Fields
  static const String rank = 'rank';
  static const String points = 'points';
  static const String level = 'level';
}

/// Query Limits
class QueryLimits {
  static const int maxPostsPerPage = 20;
  static const int maxUsersPerPage = 50;
  static const int maxLeaderboardEntries = 100;
  static const int maxStoriesPerUser = 100;
  static const int maxCommentsPerPost = 500;
  static const int maxNotificationsPerUser = 1000;
}

/// Validation Rules
class ValidationRules {
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int minBioLength = 0;
  static const int maxBioLength = 500;
  static const int minPostContentLength = 1;
  static const int maxPostContentLength = 5000;
  static const int maxMediaPerPost = 10;
  static const int maxHashtagsPerPost = 30;
  static const int maxFileSize = 52428800; // 50 MB
}

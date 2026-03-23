import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Local Storage Utilities
class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  static late SharedPreferences _prefs;

  factory LocalStorage() {
    return _instance;
  }

  LocalStorage._internal();

  /// Initialize Local Storage
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save String
  static Future<bool> saveString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  /// Get String
  static String? getString(String key, {String? defaultValue}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  /// Save Int
  static Future<bool> saveInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  /// Get Int
  static int? getInt(String key, {int? defaultValue}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  /// Save Double
  static Future<bool> saveDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  /// Get Double
  static double? getDouble(String key, {double? defaultValue}) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  /// Save Bool
  static Future<bool> saveBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  /// Get Bool
  static bool? getBool(String key, {bool? defaultValue}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  /// Save List
  static Future<bool> saveList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  /// Get List
  static List<String>? getList(String key, {List<String>? defaultValue}) {
    return _prefs.getStringList(key) ?? defaultValue;
  }

  /// Save JSON
  static Future<bool> saveJson(String key, Map<String, dynamic> value) async {
    return await _prefs.setString(key, jsonEncode(value));
  }

  /// Get JSON
  static Map<String, dynamic>? getJson(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Save Object
  static Future<bool> saveObject(String key, dynamic object) async {
    return await _prefs.setString(key, jsonEncode(object));
  }

  /// Get Object
  static dynamic getObject(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString);
  }

  /// Remove
  static Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  /// Clear All
  static Future<bool> clearAll() async {
    return await _prefs.clear();
  }

  /// Check Key Exists
  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  /// Get All Keys
  static Set<String> getAllKeys() {
    return _prefs.getKeys();
  }
}

/// User Preferences
class UserPreferences {
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userProfileImageKey = 'user_profile_image';
  static const String _userTokenKey = 'user_token';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _isDarkModeKey = 'is_dark_mode';
  static const String _appLanguageKey = 'app_language';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  /// Save User ID
  static Future<bool> saveUserId(String userId) async {
    return await LocalStorage.saveString(_userIdKey, userId);
  }

  /// Get User ID
  static String? getUserId() {
    return LocalStorage.getString(_userIdKey);
  }

  /// Save User Name
  static Future<bool> saveUserName(String userName) async {
    return await LocalStorage.saveString(_userNameKey, userName);
  }

  /// Get User Name
  static String? getUserName() {
    return LocalStorage.getString(_userNameKey);
  }

  /// Save User Email
  static Future<bool> saveUserEmail(String email) async {
    return await LocalStorage.saveString(_userEmailKey, email);
  }

  /// Get User Email
  static String? getUserEmail() {
    return LocalStorage.getString(_userEmailKey);
  }

  /// Save User Profile Image
  static Future<bool> saveUserProfileImage(String imageUrl) async {
    return await LocalStorage.saveString(_userProfileImageKey, imageUrl);
  }

  /// Get User Profile Image
  static String? getUserProfileImage() {
    return LocalStorage.getString(_userProfileImageKey);
  }

  /// Save User Token
  static Future<bool> saveUserToken(String token) async {
    return await LocalStorage.saveString(_userTokenKey, token);
  }

  /// Get User Token
  static String? getUserToken() {
    return LocalStorage.getString(_userTokenKey);
  }

  /// Save Login Status
  static Future<bool> saveLoginStatus(bool isLoggedIn) async {
    return await LocalStorage.saveBool(_isLoggedInKey, isLoggedIn);
  }

  /// Is Logged In
  static bool isLoggedIn() {
    return LocalStorage.getBool(_isLoggedInKey, defaultValue: false) ?? false;
  }

  /// Save Dark Mode
  static Future<bool> saveDarkMode(bool isDarkMode) async {
    return await LocalStorage.saveBool(_isDarkModeKey, isDarkMode);
  }

  /// Is Dark Mode
  static bool isDarkMode() {
    return LocalStorage.getBool(_isDarkModeKey, defaultValue: false) ?? false;
  }

  /// Save App Language
  static Future<bool> saveAppLanguage(String language) async {
    return await LocalStorage.saveString(_appLanguageKey, language);
  }

  /// Get App Language
  static String getAppLanguage() {
    return LocalStorage.getString(_appLanguageKey, defaultValue: 'ar') ?? 'ar';
  }

  /// Save Notifications Status
  static Future<bool> saveNotificationsStatus(bool enabled) async {
    return await LocalStorage.saveBool(_notificationsEnabledKey, enabled);
  }

  /// Are Notifications Enabled
  static bool areNotificationsEnabled() {
    return LocalStorage.getBool(_notificationsEnabledKey, defaultValue: true) ??
        true;
  }

  /// Clear User Data
  static Future<bool> clearUserData() async {
    await LocalStorage.remove(_userIdKey);
    await LocalStorage.remove(_userNameKey);
    await LocalStorage.remove(_userEmailKey);
    await LocalStorage.remove(_userProfileImageKey);
    await LocalStorage.remove(_userTokenKey);
    return await LocalStorage.remove(_isLoggedInKey);
  }
}

/// App Cache Manager
class AppCacheManager {
  static const String _lastSyncKey = 'last_sync';
  static const String _cachedPostsKey = 'cached_posts';
  static const String _cachedUsersKey = 'cached_users';
  static const String _cachedMatchesKey = 'cached_matches';

  /// Save Last Sync Time
  static Future<bool> saveLastSyncTime(DateTime dateTime) async {
    return await LocalStorage.saveString(
      _lastSyncKey,
      dateTime.toIso8601String(),
    );
  }

  /// Get Last Sync Time
  static DateTime? getLastSyncTime() {
    final dateString = LocalStorage.getString(_lastSyncKey);
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }

  /// Cache Posts
  static Future<bool> cachePosts(List<dynamic> posts) async {
    return await LocalStorage.saveString(
      _cachedPostsKey,
      jsonEncode(posts),
    );
  }

  /// Get Cached Posts
  static List<dynamic>? getCachedPosts() {
    final jsonString = LocalStorage.getString(_cachedPostsKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as List<dynamic>;
  }

  /// Cache Users
  static Future<bool> cacheUsers(List<dynamic> users) async {
    return await LocalStorage.saveString(
      _cachedUsersKey,
      jsonEncode(users),
    );
  }

  /// Get Cached Users
  static List<dynamic>? getCachedUsers() {
    final jsonString = LocalStorage.getString(_cachedUsersKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as List<dynamic>;
  }

  /// Cache Matches
  static Future<bool> cacheMatches(List<dynamic> matches) async {
    return await LocalStorage.saveString(
      _cachedMatchesKey,
      jsonEncode(matches),
    );
  }

  /// Get Cached Matches
  static List<dynamic>? getCachedMatches() {
    final jsonString = LocalStorage.getString(_cachedMatchesKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as List<dynamic>;
  }

  /// Clear Cache
  static Future<bool> clearCache() async {
    await LocalStorage.remove(_cachedPostsKey);
    await LocalStorage.remove(_cachedUsersKey);
    return await LocalStorage.remove(_cachedMatchesKey);
  }
}

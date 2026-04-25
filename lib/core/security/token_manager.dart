import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/debug_logger.dart';

/// Token Manager - Handles authentication tokens securely
class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save authentication tokens securely
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    Map<String, dynamic>? userData,
  }) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: accessToken);
      
      if (refreshToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }
      
      if (userData != null) {
        await _secureStorage.write(key: _userKey, value: jsonEncode(userData));
      }
      
      DebugLogger.log('Tokens saved successfully');
    } catch (e) {
      DebugLogger.logError('Error saving tokens: $e');
      rethrow;
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      DebugLogger.logError('Error getting access token: $e');
      return null;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      DebugLogger.logError('Error getting refresh token: $e');
      return null;
    }
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userDataString = await _secureStorage.read(key: _userKey);
      if (userDataString != null) {
        return jsonDecode(userDataString);
      }
      return null;
    } catch (e) {
      DebugLogger.logError('Error getting user data: $e');
      return null;
    }
  }

  /// Check if token is valid
  bool isTokenValid(String? token) {
    if (token == null || token.isEmpty) return false;
    
    // Simple validation - in production, you might want to use JWT decoder
    // For now, just check if token exists and is not empty
    return token.isNotEmpty;
  }

  /// Check if user is authenticated
  Future<bool> isUserAuthenticated() async {
    try {
      // Check Firebase Auth state
      if (_auth.currentUser == null) {
        return false;
      }

      // Check stored token
      final token = await getAccessToken();
      if (token == null || !isTokenValid(token)) {
        return false;
      }

      return true;
    } catch (e) {
      DebugLogger.logError('Error checking authentication: $e');
      return false;
    }
  }

  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userKey);
      
      await _auth.signOut();
      
      DebugLogger.log('Tokens cleared successfully');
    } catch (e) {
      DebugLogger.logError('Error clearing tokens: $e');
      rethrow;
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Monitor token expiration and refresh if needed
  Stream<String?> tokenExpirationMonitor() async* {
    while (true) {
      await Future.delayed(const Duration(minutes: 1));
      
      final token = await getAccessToken();
      if (token != null && !isTokenValid(token)) {
        // Token expired or invalid, trigger refresh
        yield null; // Signal need to re-authenticate
      }
    }
  }
}

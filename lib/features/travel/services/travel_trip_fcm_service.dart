import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// اشتراك FCM topics للرحلة:
/// - [subscribeBusAlerts]: كل من حجز الرحلة (إعلان تحرك الحافلة).
/// - [subscribeChatAlerts]: من سُجّل له صعود فقط (إشعار فتح الشات).
///
/// الأسماء متوافقة مع قواعد مواضيع FCM (`[a-zA-Z0-9-_.~%]{1,900}`).
class TravelTripFcmService {
  TravelTripFcmService._();

  static final TravelTripFcmService instance = TravelTripFcmService._();

  static String _sanitizeTopicSegment(String id) =>
      id.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');

  String _busTopic(String tripId) => 'tr_${_sanitizeTopicSegment(tripId)}_bus';
  String _chatTopic(String tripId) => 'tr_${_sanitizeTopicSegment(tripId)}_chat';

  Future<void> subscribeBusAlerts(String tripId) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(_busTopic(tripId));
    } catch (e) {
      debugPrint('TravelTripFcm subscribeBusAlerts: $e');
    }
  }

  Future<void> subscribeChatAlerts(String tripId) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(_chatTopic(tripId));
    } catch (e) {
      debugPrint('TravelTripFcm subscribeChatAlerts: $e');
    }
  }

  Future<void> unsubscribeAllForTrip(String tripId) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(_busTopic(tripId));
      await FirebaseMessaging.instance.unsubscribeFromTopic(_chatTopic(tripId));
    } catch (e) {
      debugPrint('TravelTripFcm unsubscribeAllForTrip: $e');
    }
  }
}

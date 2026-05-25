import 'dart:async';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gomhor_alahly_clean_new/features/shared_marketplace/data/marketplace_unified_paths.dart';
import 'package:gomhor_alahly_clean_new/features/store/domain/marketplace_order.dart';

const String kMarketplaceOrdersChannelId = 'marketplace_orders_v1';

/// اشتراك FCM + إشعارات محلية عند تغيّر حالة الطلبات (مسار موحد `all/marketplace/orders`).
class MarketplaceBuyerNotifications {
  MarketplaceBuyerNotifications._();

  static FlutterLocalNotificationsPlugin? _local;
  static StreamSubscription<DatabaseEvent>? _ordersSub;
  static String? _boundUid;

  /// يُستدعى مرة بعد [initializePushNotifications].
  static void bindLocalPlugin(FlutterLocalNotificationsPlugin plugin) {
    _local = plugin;
  }

  /// إنشاء قناة أندرويد مخصصة للمتجر (يُستدعى من bootstrap بعد تهيئة الإضافة).
  static Future<void> ensureAndroidChannel() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final plugin = _local?.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kMarketplaceOrdersChannelId,
        'طلبات السوق',
        description: 'تحديثات حالة الطلب من متجر الجمهور',
        importance: Importance.high,
      ),
    );
  }

  /// عند تسجيل الدخول/الخروج — اشتراك موضوع FCM + مستمع RTDB.
  static Future<void> syncForUser(String? uid) async {
    await _ordersSub?.cancel();
    _ordersSub = null;
    if (_boundUid != null && _boundUid!.isNotEmpty) {
      try {
        await FirebaseMessaging.instance
            .unsubscribeFromTopic('mp_buyer_${_boundUid!}');
      } catch (e) {
        debugPrint('[MarketplaceFCM] unsubscribe: $e');
      }
    }
    _boundUid = uid;

    if (uid == null || uid.isEmpty) return;

    try {
      await FirebaseMessaging.instance.subscribeToTopic('mp_buyer_$uid');
    } catch (e) {
      debugPrint('[MarketplaceFCM] subscribe: $e');
    }

    final db = FirebaseDatabase.instance;
    final q = db
        .ref(MarketplaceRtdbPaths.orders)
        .orderByChild('buyerUid')
        .equalTo(uid);

    // عند تغيّر أي طلب — إشعار محلي (وَسيط Cloud Functions يرسل FCM لنفس الموضوع في الخلفية).
    _ordersSub = q.onValue.listen((event) {
      _onOrdersSnapshot(event);
    });
  }

  static final Map<String, String> _lastKnown = {};

  static void _onOrdersSnapshot(DatabaseEvent event) {
    final v = event.snapshot.value;
    if (v is! Map) return;
    v.forEach((key, val) {
      final id = key?.toString();
      if (id == null || val is! Map) return;
      final o = MarketplaceOrder.fromMap(id, Map<dynamic, dynamic>.from(val));
      final prev = _lastKnown[id];
      _lastKnown[id] = o.status;
      if (prev == null) {
        // أول مزامنة — لا إشعار لتفادي الضوضاء عند فتح التطبيق
        return;
      }
      if (prev == o.status) return;
      _showLocalOrderUpdate(o);
    });
  }

  static Future<void> _showLocalOrderUpdate(MarketplaceOrder o) async {
    final local = _local;
    if (local == null) return;
    final title = 'طلبك: ${o.productTitleSnapshot.isNotEmpty ? o.productTitleSnapshot : o.productId}';
    final body = 'الحالة الآن: ${_statusAr(o.status)}';
    try {
      await local.show(
        o.id.hashCode.abs(),
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            kMarketplaceOrdersChannelId,
            'طلبات السوق',
            channelDescription: 'تحديثات حالة الطلب',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_stat_notification',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'marketplace_order|${o.id}|${o.status}|${o.productTitleSnapshot}',
      );
    } catch (e) {
      debugPrint('[Marketplace] local order notification: $e');
    }
  }
}

String _statusAr(String s) {
  switch (s) {
    case 'pending':
      return 'قيد المراجعة';
    case 'confirmed':
      return 'مؤكد';
    case 'shipped':
      return 'تم الشحن';
    case 'cancelled':
      return 'ملغى';
    default:
      return s;
  }
}

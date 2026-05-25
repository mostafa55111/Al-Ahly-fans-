import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/navigation/app_navigator_key.dart';
import 'package:gomhor_alahly_clean_new/core/navigation/open_tiktok_reels_direct.dart';
import 'package:gomhor_alahly_clean_new/core/navigation/reels_deep_link_controller.dart';
import 'package:gomhor_alahly_clean_new/core/notifications/firebase_messaging_background.dart';
import 'package:gomhor_alahly_clean_new/features/social/presentation/pages/mutual_friend_chat_page.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/user_profile_view_page.dart';
import 'package:gomhor_alahly_clean_new/features/shared_marketplace/services/marketplace_buyer_notifications.dart';
import 'package:gomhor_alahly_clean_new/features/store/presentation/pages/store_page.dart';

/// قناة إشعارات أندرويد (ثابتة) لتفاعلات الريلز والمركز.
const String kReelsInteractionChannelId = 'reels_interactions_v1';

Color _foregroundBannerBg() => AppConfig.reelsFirestoreClubTag == 'ahly'
    ? const Color(0xFF8B1538)
    : const Color(0xFF00247D);

Color _androidNotificationColor() => AppConfig.reelsFirestoreClubTag == 'ahly'
    ? const Color(0xFFC7102E)
    : const Color(0xFF00247D);

const String kAndroidNotificationIcon = '@drawable/ic_stat_notification';

/// ترميز payload الإشعار المحلي وFCM — `type|videoId|actorUid` أو مع لاحقة `|authorScope` لفيديو جديد.
String encodeNotificationPayload(Map<String, dynamic> data) {
  final nType = data['type']?.toString().trim() ?? '';
  if (nType == 'mutual_chat') {
    final chatId = data['chatId']?.toString().trim() ?? '';
    final senderUid = data['senderUid']?.toString().trim() ?? '';
    return 'mutual_chat|$chatId|$senderUid';
  }
  if (nType == 'marketplace_order') {
    final orderId = data['orderId']?.toString().trim() ?? '';
    final status = data['status']?.toString().trim() ?? '';
    final productTitle = data['productTitle']?.toString().trim() ?? '';
    return 'marketplace_order|$orderId|$status|$productTitle';
  }
  final type = data['type']?.toString().trim() ?? '';
  final videoId = (data['videoId']?.toString().trim() ?? '').isNotEmpty
      ? data['videoId']!.toString().trim()
      : (data['reelId']?.toString().trim() ?? '');
  final actorUid = data['actorUid']?.toString().trim() ?? '';
  final authorUid = data['authorUid']?.toString().trim() ?? '';
  final ownerId = data['ownerId']?.toString().trim() ?? '';
  final authorScope =
      authorUid.isNotEmpty ? authorUid : (ownerId.isNotEmpty ? ownerId : '');

  if (type.isEmpty &&
      actorUid.isEmpty &&
      videoId.isNotEmpty &&
      authorScope.isEmpty) {
    return videoId;
  }
  var out = '$type|$videoId|$actorUid';
  if (isAuthorScopedReelNotificationType(type) && authorScope.isNotEmpty) {
    out = '$out|$authorScope';
  }
  return out;
}

/// فتح وجهة الإشعار بعد النقر (ريل / بروفايل).
void routeNotificationPayload(String raw) {
  final p = raw.trim();
  if (p.isEmpty) return;

  if (!p.contains('|')) {
    try {
      getIt<ReelsDeepLinkController>().openReel(p);
    } catch (e) {
      debugPrint('[FCM] route legacy reel: $e');
    }
    return;
  }

  final parts = p.split('|');
  final type = parts.isNotEmpty ? parts[0].trim() : '';
  final videoId = parts.length > 1 ? parts[1].trim() : '';
  final actorUid = parts.length > 2 ? parts[2].trim() : '';
  final authorScope = parts.length > 3 ? parts[3].trim() : '';

  try {
    switch (type) {
      case 'marketplace_order':
        final ctx = appNavigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          Navigator.of(ctx).push(
            MaterialPageRoute<void>(builder: (_) => const StorePage()),
          );
        }
        break;
      case 'mutual_chat':
        if (actorUid.isNotEmpty) {
          final ctx = appNavigatorKey.currentContext;
          if (ctx != null && ctx.mounted) {
            Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                builder: (_) => MutualFriendChatPage(peerUid: actorUid),
              ),
            );
          }
        }
        break;
      case 'follow':
        if (actorUid.isNotEmpty) {
          _openProfile(actorUid);
        }
        break;
      case 'like':
      case 'comment':
      case 'trending':
      default:
        if (videoId.isNotEmpty) {
          final scope = isAuthorScopedReelNotificationType(type) &&
                  authorScope.isNotEmpty
              ? authorScope
              : null;
          getIt<ReelsDeepLinkController>().openReel(
            videoId,
            profileOnlyUserId: scope,
          );
        } else if (actorUid.isNotEmpty) {
          _openProfile(actorUid);
        }
    }
  } catch (e) {
    debugPrint('[FCM] route payload: $e');
  }
}

void _openProfile(String uid) {
  final ctx = appNavigatorKey.currentContext;
  if (ctx == null || !ctx.mounted || uid.isEmpty) return;
  Navigator.of(ctx).push(
    MaterialPageRoute<void>(
      builder: (_) => UserProfileViewPage(
        userId: uid,
        fallbackName: '',
        fallbackAvatar: '',
      ),
    ),
  );
}

/// تهيئة [FirebaseMessaging] + الإشعارات المحلية + حفظ الـ FCM Token في Firestore.
Future<void> initializePushNotifications({
  required Color foregroundSnackColor,
}) async {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final local = FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  await local.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      final payload = response.payload?.trim() ?? '';
      routeNotificationPayload(payload);
    },
  );

  MarketplaceBuyerNotifications.bindLocalPlugin(local);

  if (!kIsWeb && Platform.isAndroid) {
    final androidPlugin = local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kReelsInteractionChannelId,
        'إشعارات الجمهور',
        description: 'تفاعلات الريلز، المتابعات، والترند',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.requestNotificationsPermission();
  }

  await MarketplaceBuyerNotifications.ensureAndroidChannel();

  final messaging = FirebaseMessaging.instance;
  if (!kIsWeb) {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  FirebaseMessaging.onMessage.listen((message) {
    _handleForegroundMessage(
      local,
      foregroundSnackColor,
      message,
    );
  });

  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user == null) {
      await MarketplaceBuyerNotifications.syncForUser(null);
      return;
    }
    await syncFcmTokenToFirestore(user.uid);
    await MarketplaceBuyerNotifications.syncForUser(user.uid);
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FcmTokenFirestoreSync.saveTokenForUser(user.uid, newToken);
    }
  });

  final cur = FirebaseAuth.instance.currentUser;
  if (cur != null) {
    await syncFcmTokenToFirestore(cur.uid);
    await MarketplaceBuyerNotifications.syncForUser(cur.uid);
  }

  _registerFcmOpenedHandlers();
}

Future<void> syncFcmTokenToFirestore(String uid) async {
  if (kIsWeb) return;
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await FcmTokenFirestoreSync.saveTokenForUser(uid, token);
    }
  } catch (e) {
    debugPrint('[FCM] sync token error: $e');
  }
}

Future<void> _handleForegroundMessage(
  FlutterLocalNotificationsPlugin local,
  Color snackColor,
  RemoteMessage message,
) async {
  final notification = message.notification;
  final title = notification?.title ?? message.data['title']?.toString() ?? '';
  final body =
      notification?.body ?? message.data['body']?.toString() ?? '';
  final payload = encodeNotificationPayload(message.data);
  final isMarketplace = message.data['type']?.toString() == 'marketplace_order';

  String? androidNotifTitle;
  if (title.isEmpty) {
    androidNotifTitle = null;
  } else if (isMarketplace) {
    androidNotifTitle = title;
  } else {
    androidNotifTitle = title;
  }

  // إشعار النظام (الدرج) مع ألوان هوية النادي على أندرويد.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await local.show(
        message.hashCode.abs(),
        androidNotifTitle,
        body.isEmpty ? 'إشعار جديد' : body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            isMarketplace ? kMarketplaceOrdersChannelId : kReelsInteractionChannelId,
            isMarketplace ? 'طلبات السوق' : 'إشعارات الجمهور',
            channelDescription: isMarketplace
                ? 'تحديثات الطلبات من المتجر الموحد'
                : 'تفاعلات الريلز، المتابعات، والترند',
            importance: Importance.high,
            priority: Priority.high,
            icon: kAndroidNotificationIcon,
            color: _androidNotificationColor(),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('[FCM] local notification error: $e');
    }
  }

  final ctx = appNavigatorKey.currentContext;
  if (ctx == null || !ctx.mounted) return;
  final text = body.isNotEmpty ? body : title;
  if (text.isEmpty) return;

  /// بانر علوي داخل التطبيق (أسلوب مركز الإشعارات أثناء الفتح).
  final bannerBg = _foregroundBannerBg();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final navCtx = appNavigatorKey.currentContext;
    if (navCtx == null || !navCtx.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(navCtx);
    if (messenger == null) return;
    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: bannerBg.withValues(alpha: 0.96),
        leading: const Icon(
          Icons.notifications_active_outlined,
          color: Colors.white,
          size: 28,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.25),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              routeNotificationPayload(payload);
            },
            child: const Text(
              'عرض',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: Text(
              'إغلاق',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    Future<void>.delayed(const Duration(seconds: 6), () {
      try {
        messenger.hideCurrentMaterialBanner();
      } catch (_) {}
    });
  });
}

/// فتح ريل من إشعار وصل والتطبيق في الخلفية / مغلق.
void _registerFcmOpenedHandlers() {
  if (kIsWeb) return;
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    routeNotificationPayload(encodeNotificationPayload(message.data));
  });
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      routeNotificationPayload(encodeNotificationPayload(message.data));
    }
  });
}

/// حفظ رمز FCM في مستند المستخدم في Firestore (للـ Cloud Functions).
class FcmTokenFirestoreSync {
  FcmTokenFirestoreSync._();

  static Future<void> saveTokenForUser(String uid, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'fcmAppSource': AppConfig.firestoreAppSource,
      },
      SetOptions(merge: true),
    );
  }

  /// عند تسجيل الخروج يمكن استدعاؤها لإزالة الرمز من السحابة (اختياري).
  static Future<void> clearTokenForUser(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      },
      SetOptions(merge: true),
    );
  }
}

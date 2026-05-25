import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gomhor_alahly_clean_new/firebase_options.dart';

/// معالج الإشعارات عندما يكون التطبيق في الخلفية أو مغلقاً.
/// يجب أن يبقى دالة top-level ويُسجَّل قبل [runApp].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

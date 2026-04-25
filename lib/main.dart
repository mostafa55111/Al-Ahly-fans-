import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/auth/domain/repositories/auth_repository.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/pages/splash_page.dart';
import 'package:gomhor_alahly_clean_new/firebase_options.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/widgets/nesr_celebration_overlay.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/celebration_seen_store.dart';

/// نقطة بدء التطبيق — تطبيق جمهور الأهلي
/// 1. تهيئة Firebase
/// 2. ضبط Service Locator
/// 3. توفير AuthCubit على مستوى التطبيق
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ضبط لون الـ status bar ليتماشى مع الثيم الداكن
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    debugPrint('✅ Firebase initialized');

    // تفعيل الكاش المحلي للـ Realtime Database
    // ═══════════════════════════════════════════════════════════
    // - الريلز تبقى متاحة حتى بدون إنترنت (آخر نسخة مُحمّلة)
    // - تقلّل latency عند فتح التطبيق
    // - الـ keepSynced يضمن أن /reels يتم مزامنتها تلقائياً
    try {
      if (!kIsWeb) {
        FirebaseDatabase.instance.setPersistenceEnabled(true);
        FirebaseDatabase.instance.setPersistenceCacheSizeBytes(20 * 1024 * 1024); // 20MB
      }
      FirebaseDatabase.instance.ref('reels').keepSynced(true);
      debugPrint('✅ Realtime DB persistence enabled + /reels kept in sync');
    } catch (e) {
      debugPrint('⚠️ Could not enable RTDB persistence: $e');
    }
  } catch (e) {
    debugPrint('❌ Firebase init failed: $e');
  }

  try {
    await setupServiceLocator().timeout(const Duration(seconds: 8));
    debugPrint('✅ Service Locator setup complete');
    // مزامنة أولية مع ساعة Firebase (نفس منطق ServerValue — انظر EgyptServerTimeService)
    try {
      await getIt<EgyptServerTimeService>()
          .refreshOffset()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('⚠️ Server time sync: $e');
    }
  } catch (e) {
    debugPrint('❌ Service Locator failed: $e');
  }

  runApp(const AhlyApp());
}

/// التطبيق الجذر — يوفّر AuthCubit + الثيم
class AhlyApp extends StatelessWidget {
  const AhlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(authRepository: getIt<AuthRepository>()),
      child: MaterialApp(
        title: 'جمهور الأهلي',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme(),
        // دعم اللغة العربية والكتابة من اليمين لليسار
        locale: const Locale('ar', 'EG'),
        builder: (context, child) {
          return NesrCelebrationOverlay(
            serverTime: getIt<EgyptServerTimeService>(),
            repository: getIt<CrowdRepository>(),
            seenStore: getIt<CelebrationSeenStore>(),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox(),
            ),
          );
        },
        home: const SplashPage(),
      ),
    );
  }
}

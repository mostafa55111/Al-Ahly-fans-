import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/ignored_reels_storage.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/cubit/reels_feed_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/tiktok_reels_page.dart';

/// أنواع إشعار تُعامل كـ «فيديو جديد» — عندها يُمرَّر [profileOnlyUserId] (مؤلف/مالك الريل)
/// لتقييد السحب على ريلزه فقط (مع الإبقاء على [initialReelId] في الفهرس 0).
bool isAuthorScopedReelNotificationType(String type) {
  const scoped = {
    'reel',
    'new_reel',
    'new_video',
    'upload',
    'video',
  };
  return scoped.contains(type.trim().toLowerCase());
}

/// يفتح [TikTokReelsPage] فوق الـ root navigator مع كيوبت مخصّص للجلسة:
/// — إشعار عادي: [initialReelId] (ريل مثبّت ثم تكميل الخوارزمية).
/// — إشعار «فيديو جديد» + [profileOnlyUserId]: فيد مرتبط بمؤلف الإشعار فقط.
/// — بروفايل: [profileOnlyUserId] + [seedProfileReels] اختياريًا.
void pushTikTokReelsDirect(
  BuildContext context, {
  required String initialReelId,
  String? profileOnlyUserId,
  List<VideoModel>? seedProfileReels,
}) {
  final id = initialReelId.trim();
  if (id.isEmpty) return;

  final scope = profileOnlyUserId?.trim();
  final profileUid =
      scope == null || scope.isEmpty ? null : scope;

  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        create: (_) => ReelsFeedCubit(
          ignoredReelsStorage: getIt<IgnoredReelsStorage>(),
          initialReelId: id,
          profileOnlyUserId: profileUid,
          seedProfileReels: seedProfileReels,
        ),
        child: const TikTokReelsPage(
          isTabActive: true,
        ),
      ),
    ),
  );
}

import 'package:flutter/scheduler.dart';

import 'package:gomhor_alahly_clean_new/core/navigation/app_navigator_key.dart';
import 'package:gomhor_alahly_clean_new/core/navigation/open_tiktok_reels_direct.dart';

/// يمرّر [videoId] من إشعار (FCM / محلي) إلى [pushTikTokReelsDirect].
class ReelsDeepLinkController {
  /// [profileOnlyUserId]: تقييد السحب على ريلز المؤلف عند إشعارات «فيديو جديد».
  void openReel(
    String videoId, {
    String? profileOnlyUserId,
  }) {
    final id = videoId.trim();
    if (id.isEmpty) return;
    final scope = profileOnlyUserId?.trim();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final ctx = appNavigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      pushTikTokReelsDirect(
        ctx,
        initialReelId: id,
        profileOnlyUserId:
            scope == null || scope.isEmpty ? null : scope,
      );
    });
  }
}

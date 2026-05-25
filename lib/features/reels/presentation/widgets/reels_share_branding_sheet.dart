import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/reels_video_watermark_service.dart';
import 'package:share_plus/share_plus.dart';

/// تراكب مشاركة ذكي: معاينة شعار التطبيق + @المستخدم، ومشاركة رابط أو فيديو بعلامة مائية (FFmpeg).
class ReelsShareBrandingSheet {
  static String _handleFor(VideoModel reel) {
    final raw = reel.userName.trim();
    return raw.isEmpty ? 'fan' : raw.replaceAll(RegExp(r'\s+'), '_');
  }

  /// معالجة FFmpeg + مؤشر نسبة مئوية، ثم حفظ للمعرض أو فتح Share Sheet.
  static Future<void> _exportWatermarkedAndAct(
    BuildContext context, {
    required VideoModel reel,
    required Color accentColor,
    required bool saveToGallery,
    required Future<void> Function(bool success) onShareComplete,
  }) async {
    final at = '@${_handleFor(reel)}';
    final progress = ValueNotifier<double>(0);

    void closeDialog() {
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) nav.pop();
    }

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (ctx, pct, _) {
            final indeterminate = pct <= 0;
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: Text(
                saveToGallery
                    ? 'جاري تحضير الفيديو للتحميل…'
                    : 'جاري تحضير الفيديو للمشاركة…',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: indeterminate
                          ? null
                          : (pct / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.white12,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    indeterminate
                        ? 'يرجى الانتظار…'
                        : '${pct.clamp(0, 100).toStringAsFixed(0)}٪',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      final file = await ReelsVideoWatermarkService.exportWatermarkedVideo(
        videoUrl: reel.videoUrl,
        atHandle: at,
        onProgress: (p) => progress.value = p,
      );
      progress.dispose();
      closeDialog();

      if (saveToGallery) {
        var okAccess = await Gal.hasAccess();
        if (!okAccess) {
          okAccess = await Gal.requestAccess();
        }
        if (!okAccess) {
          throw Exception('لم يُمنح إذن الحفظ في المعرض');
        }
        await Gal.putVideo(file.path);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ الفيديو في المعرض'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await onShareComplete(true);
      } else {
        final result = await Share.shareXFiles(
          [XFile(file.path)],
          text: '${AppConfig.appName} — $at',
          subject: '${AppConfig.appName} — ريل',
        );
        await onShareComplete(result.status == ShareResultStatus.success);
      }
    } catch (e) {
      progress.dispose();
      closeDialog();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذّر إعداد الفيديو: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
      await onShareComplete(false);
    }
  }

  static Future<void> show(
    BuildContext context, {
    required VideoModel reel,
    required Color accentColor,
    required Future<void> Function(bool success) onShareComplete,
  }) async {
    final handle = _handleFor(reel);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withValues(alpha: 0.45)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'مشاركة بعلامة ${AppConfig.appName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black,
                        accentColor.withValues(alpha: 0.22),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          ReelsVideoWatermarkService.logoAssetPath(),
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.shield_moon_rounded,
                            color: accentColor,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConfig.appName,
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '@$handle',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final brandedFooter =
                          '\n───────────\n${AppConfig.appName} • @$handle';
                      final shareText = reel.caption.isNotEmpty
                          ? '${reel.caption}$brandedFooter\n\n${reel.videoUrl}'
                          : '${AppConfig.appName}$brandedFooter\n\n${reel.videoUrl}';
                      try {
                        final result = await Share.shareWithResult(
                          shareText,
                          subject: '${AppConfig.appName} — ريل',
                        );
                        await onShareComplete(
                          result.status == ShareResultStatus.success,
                        );
                      } catch (_) {
                        await onShareComplete(false);
                      }
                    },
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('مشاركة الرابط'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: accentColor.withValues(alpha: 0.85)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _exportWatermarkedAndAct(
                        context,
                        reel: reel,
                        accentColor: accentColor,
                        saveToGallery: false,
                        onShareComplete: onShareComplete,
                      );
                    },
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('مشاركة كملف (علامة مائية)'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _exportWatermarkedAndAct(
                        context,
                        reel: reel,
                        accentColor: accentColor,
                        saveToGallery: true,
                        onShareComplete: onShareComplete,
                      );
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('تحميل الفيديو (علامة مائية)'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

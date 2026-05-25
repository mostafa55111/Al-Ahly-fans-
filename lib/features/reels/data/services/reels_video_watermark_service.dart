import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new_https/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_https/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_https/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_https/statistics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// معالجة FFmpeg: شعار النادي (أعلى يمين) + @المستخدم كصورة (أسفل يسار)، ثم تصدير MP4 سريع.
/// تطبيق جمهور الأهلي يستخدم دائماً [ahly_logo.png] فقط.
class ReelsVideoWatermarkService {
  ReelsVideoWatermarkService._();

  static const _exportSubdir = 'reels_watermark_exports';
  static const Duration defaultMaxCacheAge = Duration(days: 3);
  static const _logoTargetWidth = 120;

  /// مسار الشعار في الأصول — يطابق [ReelsShareBrandingSheet].
  static String logoAssetPath() => 'assets/images/ahly_logo.png';

  static Future<Directory> _ensureExportDir() async {
    final root = await getTemporaryDirectory();
    final dir = Directory(p.join(root.path, _exportSubdir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// حذف ملفات التصدير الأقدم من [olderThan] لتوفير مساحة التخزين.
  static Future<void> pruneWatermarkCache({
    Duration olderThan = defaultMaxCacheAge,
  }) async {
    try {
      final root = await getTemporaryDirectory();
      final dir = Directory(p.join(root.path, _exportSubdir));
      if (!await dir.exists()) return;
      final now = DateTime.now();
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        try {
          final stat = await entity.stat();
          if (now.difference(stat.modified) > olderThan) {
            await entity.delete();
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[Watermark] prune: $e');
    }
  }

  static Future<int> _probeDurationMs(String videoPath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(videoPath);
      final info = session.getMediaInformation();
      final durStr = info?.getDuration() ?? '0';
      final sec = double.tryParse(durStr) ?? 0;
      return (sec * 1000).round();
    } catch (_) {
      return 0;
    }
  }

  static Future<bool> _probeHasAudio(String videoPath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(videoPath);
      final streams = session.getMediaInformation()?.getStreams() ?? [];
      for (final s in streams) {
        if (s.getType() == 'audio') return true;
      }
    } catch (_) {}
    return false;
  }

  /// رسم نص @handle كـ PNG (يدعم العربية عبر محرك خط Flutter).
  static Future<File> _renderHandleBadgePng({
    required String atHandle,
    required Directory dir,
    required int stamp,
  }) async {
    final label = atHandle.startsWith('@') ? atHandle : '@$atHandle';
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const pad = 14.0;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          shadows: [
            Shadow(
              color: Colors.black87,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    tp.layout(maxWidth: 560);
    final w = (tp.width + pad * 2).ceil();
    final h = (tp.height + pad * 2).ceil();
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0x73000000),
    );
    tp.paint(canvas, const Offset(pad, pad));
    final pic = recorder.endRecording();
    final img = await pic.toImage(w, h);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File(p.join(dir.path, 'wm_handle_$stamp.png'));
    await f.writeAsBytes(bd!.buffer.asUint8List());
    return f;
  }

  /// تصدير فيديو بعلامة مائية؛ [onProgress] يمرّر 0…100 أثناء الترميز.
  static Future<File> exportWatermarkedVideo({
    required String videoUrl,
    required String atHandle,
    required void Function(double percent) onProgress,
  }) async {
    await pruneWatermarkCache();
    if (videoUrl.isEmpty) {
      throw Exception('رابط الفيديو غير صالح');
    }

    final videoFile = await DefaultCacheManager().getSingleFile(videoUrl);
    final dir = await _ensureExportDir();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final outPath = p.join(dir.path, 'wm_export_$stamp.mp4');

    late File logoFile;
    try {
      final bd = await rootBundle.load(logoAssetPath());
      logoFile = File(p.join(dir.path, 'wm_logo_$stamp.png'));
      await logoFile.writeAsBytes(bd.buffer.asUint8List());
    } catch (e) {
      throw Exception(
        'تعذّر تحميل شعار النادي من الأصول: ${logoAssetPath()} ($e)',
      );
    }

    final handleFile = await _renderHandleBadgePng(
      atHandle: atHandle,
      dir: dir,
      stamp: stamp,
    );

    final durationMs = await _probeDurationMs(videoFile.path);
    final hasAudio = await _probeHasAudio(videoFile.path);

    final filter =
        '[1:v]scale=$_logoTargetWidth:-1[lg];'
        '[0:v][lg]overlay=main_w-overlay_w-16:16[t1];'
        '[t1][2:v]overlay=16:main_h-overlay_h-16[v]';

    final args = <String>[
      '-y',
      '-i',
      videoFile.path,
      '-i',
      logoFile.path,
      '-i',
      handleFile.path,
      '-filter_complex',
      filter,
      '-map',
      '[v]',
      '-c:v',
      'libx264',
      '-preset',
      'veryfast',
      '-crf',
      '23',
      '-pix_fmt',
      'yuv420p',
    ];
    if (hasAudio) {
      args.addAll(['-map', '0:a', '-c:a', 'copy']);
    } else {
      args.add('-an');
    }
    args.add(outPath);

    final completer = Completer<File>();

    FFmpegKit.executeWithArgumentsAsync(
      args,
      (FFmpegSession session) {
        Future<void>(() async {
          try {
            await logoFile.delete();
            await handleFile.delete();
          } catch (_) {}

          final code = await session.getReturnCode();
          if (!ReturnCode.isSuccess(code)) {
            final logs = await session.getOutput();
            completer.completeError(
              Exception(logs ?? 'فشل ترميز الفيديو (FFmpeg)'),
            );
            return;
          }
          completer.complete(File(outPath));
        });
      },
      null,
      (Statistics statistics) {
        final t = statistics.getTime();
        if (durationMs <= 0) {
          onProgress(0);
          return;
        }
        final pct = (t / durationMs * 100).clamp(0.0, 100.0);
        onProgress(pct);
      },
    );

    final outFile = await completer.future;
    onProgress(100);
    return outFile;
  }
}

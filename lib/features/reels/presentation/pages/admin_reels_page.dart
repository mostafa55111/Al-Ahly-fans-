import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/cubit/reels_feed_cubit.dart';
import 'package:video_player/video_player.dart';

/// لوحة أدمن لرفع الريلز: Cloudinary + شريط تقدم + حفظ RTDB + Firestore عبر [ReelsFeedCubit.uploadReel].
class AdminReelsPage extends StatefulWidget {
  const AdminReelsPage({super.key});

  @override
  State<AdminReelsPage> createState() => _AdminReelsPageState();
}

class _AdminReelsPageState extends State<AdminReelsPage> {
  final _titleCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  final _picker = ImagePicker();

  File? _videoFile;
  VideoPlayerController? _preview;
  String? _error;

  bool _isPrivate = false;
  String _visibility = AppConfig.reelsFirestoreClubTag;
  bool _busy = false;
  double _progress = 0;
  UploadPhase _phase = UploadPhase.uploadingVideo;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _captionCtrl.dispose();
    _preview?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo({ImageSource source = ImageSource.gallery}) async {
    try {
      final picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
      if (picked == null) return;
      final file = File(picked.path);
      await _preview?.dispose();
      final c = VideoPlayerController.file(file);
      await c.initialize();
      c.setLooping(true);
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _videoFile = file;
        _preview = c..play();
        _error = null;
        _progress = 0;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _publish() async {
    final file = _videoFile;
    if (file == null) {
      setState(() => _error = 'اختر فيديواً أولاً');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _progress = 0.01;
    });
    try {
      await context.read<ReelsFeedCubit>().uploadReel(
            videoFile: file,
            caption: _captionCtrl.text.trim(),
            title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
            isPrivate: _isPrivate,
            visibility: _visibility,
            onPhaseChanged: (p) {
              if (mounted) setState(() => _phase = p);
            },
            onUploadProgress: (v) {
              if (mounted) setState(() => _progress = v.clamp(0.0, 1.0));
            },
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم النشر — الريل في Firestore والبث المباشر'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() {
        _busy = false;
        _progress = 1;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
    }
  }

  String _phaseLabel(UploadPhase p) {
    switch (p) {
      case UploadPhase.uploadingVideo:
        return 'جاري الرفع إلى Cloudinary…';
      case UploadPhase.savingToDatabase:
        return 'جاري الحفظ في قاعدة البيانات…';
      case UploadPhase.success:
        return 'تم';
      case UploadPhase.failed:
        return 'فشل';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('لوحة ريلز الأدمن'),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'الرفع يمر على Cloudinary مع شريط تقدم حقيقي، ثم يُدمَج المستند في مجموعة reels في Firestore تلقائياً.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'عنوان الريل',
                hintText: 'يظهر كحقل title في Firestore',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _captionCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'وصف / هاشتاجات',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _pickVideo(source: ImageSource.gallery),
                    icon: const Icon(Icons.video_library_outlined),
                    label: const Text('اختيار فيديو'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pickVideo(source: ImageSource.camera),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('تصوير'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 9 / 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.royalRed.withValues(alpha: 0.45)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _preview != null && _preview!.value.isInitialized
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _preview!.value.size.width,
                          height: _preview!.value.size.height,
                          child: VideoPlayer(_preview!),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.movie_outlined,
                          size: 56,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isPrivate,
              onChanged: _busy ? null : (v) => setState(() => _isPrivate = v),
              title: const Text('ريل خاص', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                'يظهر في بروفايلك فقط',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
              ),
            ),
            const ListTile(
              title: Text('الجمهور', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              subtitle: Text('يُخزَّن في visibility (zamalek / ahly / all)', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'zamalek', label: Text('زملكاوي')),
                ButtonSegment(value: 'ahly', label: Text('أهلي')),
                ButtonSegment(value: 'all', label: Text('الكل')),
              ],
              selected: {_visibility},
              onSelectionChanged: _busy
                  ? null
                  : (s) => setState(() => _visibility = s.first),
            ),
            if (_busy || _progress > 0) ...[
              const SizedBox(height: 20),
              Text(_phaseLabel(_phase), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _busy ? _progress : 1,
                minHeight: 8,
                backgroundColor: Colors.white12,
                color: AppColors.royalRed,
              ),
              const SizedBox(height: 4),
              Text(
                '${(_progress * 100).round()}%',
                textAlign: TextAlign.end,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _publish,
              icon: const Icon(Icons.cloud_upload_rounded),
              label: Text(_busy ? 'جاري النشر…' : 'رفع ونشر'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.royalRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

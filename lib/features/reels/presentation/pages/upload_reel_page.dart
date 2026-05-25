import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';

/// بيانات الريل اللي اختارها المستخدم، تُعاد للصفحة الأم عشان ترفع في الخلفية.
/// ═══════════════════════════════════════════════════════════════════
/// الهدف: المستخدم ما يشوفش شاشة "جاري النشر" — يضغط "نشر" وبس، والتطبيق
/// يكمّل الرفع في الـ background ويّنبّهه بالنتيجة (SnackBar).
class UploadReelRequest {
  final File videoFile;
  final String caption;
  final bool isPrivate;
  final String visibility;

  const UploadReelRequest({
    required this.videoFile,
    required this.caption,
    this.isPrivate = false,
    this.visibility = 'ahly',
  });
}

/// شاشة اختيار ريل جديد:
/// 1. اختيار فيديو من المعرض أو الكاميرا
/// 2. معاينة الفيديو
/// 3. وصف اختياري (غير مطلوب)
/// 4. Pop مع [UploadReelRequest] — الرفع الفعلي يتم بالصفحة الأم
class UploadReelPage extends StatefulWidget {
  const UploadReelPage({super.key});

  @override
  State<UploadReelPage> createState() => _UploadReelPageState();
}

class _UploadReelPageState extends State<UploadReelPage> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();

  File? _videoFile;
  VideoPlayerController? _previewController;
  String? _errorText;
  bool _isPrivate = false;
  String _visibilityChoice = 'ahly';

  @override
  void initState() {
    super.initState();
    // افتح معرض الفيديوهات فور دخول الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickVideo());
  }

  @override
  void dispose() {
    _captionController.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo({ImageSource source = ImageSource.gallery}) async {
    try {
      final picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 3),
      );
      if (picked == null) {
        // المستخدم ألغى الاختيار - نخرج من الشاشة إذا لم يكن هناك فيديو سابق
        if (_videoFile == null && mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      final file = File(picked.path);
      final newController = VideoPlayerController.file(file);
      await newController.initialize();
      newController
        ..setLooping(true)
        ..play();

      if (!mounted) {
        newController.dispose();
        return;
      }

      setState(() {
        _previewController?.dispose();
        _previewController = newController;
        _videoFile = file;
        _errorText = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'تعذّر قراءة الفيديو: $e');
    }
  }

  /// يُرجع الـ request للصفحة الأم ليكمل الرفع في الخلفية.
  /// ‣ الوصف اختياري بالكامل.
  /// ‣ المستخدم ما يشوفش أي شاشة تحميل.
  void _submit() {
    if (_videoFile == null) {
      setState(() => _errorText = 'اختر فيديو أولاً');
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      UploadReelRequest(
        videoFile: _videoFile!,
        caption: _captionController.text.trim(),
        isPrivate: _isPrivate,
        visibility: _visibilityChoice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('ريل جديد'),
        actions: [
          if (_videoFile != null)
            TextButton(
              onPressed: _submit,
              child: const Text(
                'نشر',
                style: TextStyle(
                  color: AppColors.luminousGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(child: _buildEditingView()),
    );
  }

  Widget _buildEditingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildVideoPreview(),
          const SizedBox(height: 20),

          if (_errorText != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.royalRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.royalRed.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.brightRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // حقل الوصف — اختياري بالكامل
          TextField(
            controller: _captionController,
            maxLines: 4,
            maxLength: 200,
            style: const TextStyle(color: Colors.white, height: 1.5),
            decoration: const InputDecoration(
              labelText: 'وصف الريل (اختياري)',
              hintText: 'اكتب وصفاً إذا أردت...',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 8),

          // مفتاح "خاص" — لو شغّال يظهر الريل في تبويب "الريلز الخاصة" بالبروفايل فقط
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.luminousGold.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                  color:
                      _isPrivate ? AppColors.brightRed : AppColors.luminousGold,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPrivate ? 'ريل خاص' : 'متاح للجميع',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _isPrivate
                            ? 'يظهر فقط في بروفايلك (أنت فقط تقدر تشوفه)'
                            : 'سيظهر في فيد الريلز لجميع المتابعين',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isPrivate,
                  activeColor: AppColors.brightRed,
                  onChanged: (v) => setState(() => _isPrivate = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // أزرار اختيار مصدر الفيديو
          Row(
            children: [
              Expanded(
                child: _SourceButton(
                  icon: Icons.photo_library_outlined,
                  label: 'من المعرض',
                  onTap: () => _pickVideo(source: ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SourceButton(
                  icon: Icons.videocam_outlined,
                  label: 'تصوير',
                  onTap: () => _pickVideo(source: ImageSource.camera),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _AudienceChoiceToggle(
            selected: _visibilityChoice,
            onSelect: (v) => setState(() => _visibilityChoice = v),
          ),
          const SizedBox(height: 12),

          // زر النشر البارز — يُغلق الشاشة فوراً
          _HalfRedHalfWhitePublishButton(
            enabled: _videoFile != null,
            onPressed: _submit,
          ),
          const SizedBox(height: 10),
          Text(
            'الفيديو يرفع في الخلفية — يمكنك تصفح التطبيق بينما يتم الرفع',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// معاينة الفيديو المختار (أو placeholder إذا لم يُختر بعد)
  Widget _buildVideoPreview() {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.luminousGold.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _previewController != null &&
                _previewController!.value.isInitialized
            ? Stack(
                fit: StackFit.expand,
                children: [
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _previewController!.value.size.width,
                      height: _previewController!.value.size.height,
                      child: VideoPlayer(_previewController!),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_previewController!.value.isPlaying) {
                            _previewController!.pause();
                          } else {
                            _previewController!.play();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _previewController!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.movie_creation_outlined,
                      color: Colors.white.withValues(alpha: 0.35),
                      size: 60,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'اختر فيديو للمعاينة',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AudienceChoiceToggle extends StatelessWidget {
  const _AudienceChoiceToggle({
    required this.selected,
    required this.onSelect,
  });

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'من يمكنه مشاهدة هذا الريل؟',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        _AudienceClubButton(
          selected: selected == 'ahly',
          onTap: () => onSelect('ahly'),
        ),
        const SizedBox(height: 8),
        _AudienceAllButton(
          selected: selected == 'all',
          onTap: () => onSelect('all'),
        ),
      ],
    );
  }
}

class _AudienceClubButton extends StatelessWidget {
  const _AudienceClubButton({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.royalRed,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.luminousGold : AppColors.royalRed,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'جمهورك فقط',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudienceAllButton extends StatelessWidget {
  const _AudienceAllButton({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: const [
                Expanded(child: ColoredBox(color: AppColors.royalRed)),
                Expanded(child: ColoredBox(color: Colors.white)),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      color: AppColors.darkBlack,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'الجمهورين',
                      style: TextStyle(
                        color: AppColors.darkBlack,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (selected)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.luminousGold, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HalfRedHalfWhitePublishButton extends StatelessWidget {
  const _HalfRedHalfWhitePublishButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: const [
                Expanded(child: ColoredBox(color: AppColors.royalRed)),
                Expanded(child: ColoredBox(color: Colors.white)),
              ],
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? onPressed : null,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: enabled ? AppColors.darkBlack : Colors.white38,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'نشر الآن',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: enabled ? AppColors.darkBlack : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر اختيار مصدر الفيديو (معرض / كاميرا)
class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.luminousGold.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.luminousGold, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

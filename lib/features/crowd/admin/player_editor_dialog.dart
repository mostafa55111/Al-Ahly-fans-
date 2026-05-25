import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_card_blend_mode.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_card_overlay_type.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_card_stadium_preview_dialog.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_vote_card_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

String _editorCoerceStyle(String w) {
  const ok = {'', 'ultra_red', 'royal_white'};
  final t = w.trim();
  return ok.contains(t) ? t : '';
}

String _editorCoerceRarity(String w) {
  const ok = {'', 'common', 'rare', 'epic', 'legendary', 'mythic'};
  final t = w.trim();
  return ok.contains(t) ? t : '';
}

String _editorCoerceTheme(String w) {
  const ok = {'', 'ahly_fire', 'zamalek_royal', 'royal_white'};
  final t = w.trim();
  return ok.contains(t) ? t : '';
}

String _editorCoerceOverlay(String w) {
  final t = w.trim();
  if (t.isEmpty) return '';
  if (t.toLowerCase() == 'none') return 'none';
  for (final e in MatchCardOverlayType.values) {
    if (e == MatchCardOverlayType.none) continue;
    if (e.name.toLowerCase() == t.toLowerCase()) return e.name;
  }
  return '';
}

String _editorCoerceBlend(String w) {
  const ok = {'normal', 'screen', 'additive', 'softLight', 'overlay'};
  final t = w.trim();
  return ok.contains(t) ? t : 'screen';
}

/// حوار إضافة/تعديل لاعب في جلسة تصويت المباراة (RTDB).
///
/// الكرت النهائي يُرفع يدوياً ([cardImageUrl])؛ الحقول الأخرى للمؤثرات فقط.
Future<void> showMatchVotePlayerEditor({
  required BuildContext context,
  required Future<void> Function(MatchPitchPlayer player) onSave,
  MatchPitchPlayer? existing,
  String defaultFormationSlotPosition = 'CM',
}) async {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final cardImageCtrl = TextEditingController(
    text: existing?.cardImageUrl.trim().isNotEmpty == true
        ? existing!.cardImageUrl
        : '',
  );
  final legacyImageCtrl = TextEditingController(text: existing?.imageUrl ?? '');
  final thumbCtrl = TextEditingController(text: existing?.cardThumbnailUrl ?? '');
  var styleWire = existing?.cardStyle ?? '';
  var rarityWire = existing?.cardRarity ?? '';
  var themeWire = existing?.cardTheme ?? '';
  var overlayWire = existing?.cardAnimatedOverlay ?? '';
  final overlayAssetCtrl = TextEditingController(text: existing?.cardOverlayAssetUrl ?? '');
  var overlayEnabled = existing?.cardOverlayEnabled ?? true;
  var overlayBlendWire = existing?.cardOverlayBlend ?? 'screen';
  var overlayOpacity = existing?.cardOverlayOpacity ?? 0.88;
  final posCtrl = TextEditingController(
    text: existing?.position ?? defaultFormationSlotPosition,
  );
  final ratingCtrl = TextEditingController(text: '${existing?.rating ?? 80}');
  final xCtrl = TextEditingController(text: '${existing?.x ?? 0.5}');
  final yCtrl = TextEditingController(text: '${existing?.y ?? 0.5}');
  final teamCtrl = TextEditingController(text: existing?.team ?? '');
  final glowCtrl = TextEditingController(text: existing?.glowColor ?? 'gold');
  final cloud = getIt<CloudinaryService>();

  final id = existing?.id ?? const Uuid().v4();
  var uploadingCard = false;
  var uploadingThumb = false;
  var uploadingOverlay = false;
  var previewFit = BoxFit.cover;

  var visible = existing?.visible ?? true;
  var highlighted = existing?.highlighted ?? false;

  MatchPitchPlayer draftForPreview() {
    final name = nameCtrl.text.trim().isEmpty ? 'معاينة' : nameCtrl.text.trim();
    final rating = int.tryParse(ratingCtrl.text.trim()) ?? 0;
    final x = double.tryParse(xCtrl.text.trim()) ?? 0.5;
    final y = double.tryParse(yCtrl.text.trim()) ?? 0.5;
    return MatchPitchPlayer(
      id: id,
      name: name,
      imageUrl: legacyImageCtrl.text.trim(),
      rating: rating,
      position: posCtrl.text.trim(),
      x: x.clamp(0.0, 1.0),
      y: y.clamp(0.0, 1.0),
      votes: existing?.votes ?? 0,
      team: teamCtrl.text.trim(),
      glowColor: glowCtrl.text.trim().isEmpty ? 'gold' : glowCtrl.text.trim(),
      visible: visible,
      highlighted: highlighted,
      cardImageUrl: cardImageCtrl.text.trim(),
      cardThumbnailUrl: thumbCtrl.text.trim(),
      cardStyle: styleWire.trim(),
      cardRarity: rarityWire.trim(),
      cardAnimatedOverlay: overlayWire.trim(),
      cardTheme: themeWire.trim(),
      cardOverlayAssetUrl: overlayAssetCtrl.text.trim(),
      cardOverlayEnabled: overlayEnabled,
      cardOverlayBlend: overlayBlendWire.trim().isEmpty ? 'screen' : overlayBlendWire.trim(),
      cardOverlayOpacity: overlayOpacity.clamp(0.05, 1.0),
    );
  }

  Future<void> pickAndUploadCard(StateSetter setLocal, bool thumb) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (x == null) return;
    if (!cloud.isReady) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cloudinary غير جاهز')),
        );
      }
      return;
    }
    setLocal(() {
      if (thumb) {
        uploadingThumb = true;
      } else {
        uploadingCard = true;
      }
    });
    try {
      final url = await cloud.uploadImage(File(x.path));
      if (url.isNotEmpty) {
        if (thumb) {
          thumbCtrl.text = url;
        } else {
          cardImageCtrl.text = url;
        }
      }
    } finally {
      setLocal(() {
        uploadingCard = false;
        uploadingThumb = false;
      });
    }
  }

  Future<void> pickAndUploadOverlay(StateSetter setLocal) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (x == null) return;
    if (!cloud.isReady) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cloudinary غير جاهز')),
        );
      }
      return;
    }
    setLocal(() => uploadingOverlay = true);
    try {
      final url = await cloud.uploadImage(File(x.path));
      if (url.isNotEmpty) overlayAssetCtrl.text = url;
    } finally {
      if (context.mounted) setLocal(() => uploadingOverlay = false);
    }
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setLocal) {
        final previewW = 88.0;
        final previewH = previewW * (86 / 62);
        final cardUrl = draftForPreview().displayCardImageUrl;

        return AlertDialog(
          backgroundColor: const Color(0xFF141414),
          title: Text(existing == null ? 'إضافة لاعب' : 'تعديل لاعب'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'صورة الكرت النهائية (PNG / WebP)',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: cardImageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رابط cardImageUrl',
                    hintText: 'https://…',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: uploadingCard ? null : () => pickAndUploadCard(setLocal, false),
                        icon: uploadingCard
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file_outlined),
                        label: Text(uploadingCard ? 'جاري الرفع…' : 'رفع كرت اللاعب'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => setLocal(() => cardImageCtrl.clear()),
                      child: const Text('مسح'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('معاينة سريعة (قص / احتواء)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                Align(
                  child: Container(
                    width: previewW + 16,
                    height: previewH + 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: previewW,
                          height: previewH,
                          child: cardUrl.isEmpty
                              ? Container(
                                  color: const Color(0xFF1E1E1E),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.image_outlined, color: Colors.white24),
                                )
                              : MatchVoteCardImage(
                                  imageUrl: cardUrl,
                                  width: previewW,
                                  height: previewH,
                                  fit: previewFit,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('ملء'),
                      selected: previewFit == BoxFit.cover,
                      onSelected: (_) => setLocal(() => previewFit = BoxFit.cover),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('احتواء'),
                      selected: previewFit == BoxFit.contain,
                      onSelected: (_) => setLocal(() => previewFit = BoxFit.contain),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: thumbCtrl,
                  decoration: const InputDecoration(
                    labelText: 'cardThumbnailUrl (اختياري)',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: uploadingThumb ? null : () => pickAndUploadCard(setLocal, true),
                        icon: uploadingThumb
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.broken_image_outlined),
                        label: const Text('رفع مصغّر'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: legacyImageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'imageUrl قديم (احتياطي إن لم يُضبط الكرت)',
                  ),
                ),
                const SizedBox(height: 8),
                const Text('مؤثرات الـ FX (حيّة على الملعب)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _editorCoerceStyle(styleWire),
                  decoration: const InputDecoration(labelText: 'cardStyle'),
                  dropdownColor: const Color(0xFF222222),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('تلقائي')),
                    DropdownMenuItem(value: 'ultra_red', child: Text('ultra_red')),
                    DropdownMenuItem(value: 'royal_white', child: Text('royal_white')),
                  ],
                  onChanged: (v) => setLocal(() => styleWire = v ?? ''),
                ),
                DropdownButtonFormField<String>(
                  value: _editorCoerceRarity(rarityWire),
                  decoration: const InputDecoration(labelText: 'cardRarity'),
                  dropdownColor: const Color(0xFF222222),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('تلقائي')),
                    DropdownMenuItem(value: 'common', child: Text('common')),
                    DropdownMenuItem(value: 'rare', child: Text('rare')),
                    DropdownMenuItem(value: 'epic', child: Text('epic')),
                    DropdownMenuItem(value: 'legendary', child: Text('legendary')),
                    DropdownMenuItem(value: 'mythic', child: Text('mythic')),
                  ],
                  onChanged: (v) => setLocal(() => rarityWire = v ?? ''),
                ),
                DropdownButtonFormField<String>(
                  value: _editorCoerceTheme(themeWire),
                  decoration: const InputDecoration(labelText: 'cardTheme'),
                  dropdownColor: const Color(0xFF222222),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('تلقائي')),
                    DropdownMenuItem(value: 'ahly_fire', child: Text('ahly_fire')),
                    DropdownMenuItem(value: 'zamalek_royal', child: Text('zamalek_royal')),
                    DropdownMenuItem(value: 'royal_white', child: Text('royal_white (ثيم)')),
                  ],
                  onChanged: (v) => setLocal(() => themeWire = v ?? ''),
                ),
                DropdownButtonFormField<String>(
                  value: _editorCoerceOverlay(overlayWire),
                  decoration: const InputDecoration(labelText: 'cardAnimatedOverlay (نوع المؤثر)'),
                  dropdownColor: const Color(0xFF222222),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('تلقائي (من الندرة والثيم)')),
                    const DropdownMenuItem(value: 'none', child: Text('بدون مؤثر')),
                    ...matchCardOverlayMenuItems
                        .where((e) => e.type != MatchCardOverlayType.none)
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: matchCardOverlayTypeWire(e.type),
                            child: Text(e.label),
                          ),
                        ),
                  ],
                  onChanged: (v) => setLocal(() => overlayWire = v ?? ''),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Overlay متحرك فوق الكرت (Lottie / GIF / WebP)',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                TextField(
                  controller: overlayAssetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'cardOverlayAssetUrl',
                    hintText: 'https://…json | .lottie | .gif | .webp',
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: uploadingOverlay ? null : () => pickAndUploadOverlay(setLocal),
                        icon: uploadingOverlay
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.layers_outlined),
                        label: Text(uploadingOverlay ? 'جاري الرفع…' : 'رفع overlay'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => setLocal(() => overlayAssetCtrl.clear()),
                      child: const Text('مسح'),
                    ),
                  ],
                ),
                CheckboxListTile(
                  value: overlayEnabled,
                  onChanged: (v) => setLocal(() => overlayEnabled = v ?? true),
                  title: const Text('تفعيل overlay الأصول', style: TextStyle(color: Colors.white70)),
                ),
                DropdownButtonFormField<String>(
                  value: _editorCoerceBlend(overlayBlendWire),
                  decoration: const InputDecoration(labelText: 'cardOverlayBlend'),
                  dropdownColor: const Color(0xFF222222),
                  items: [
                    for (final e in MatchCardBlendMode.values)
                      DropdownMenuItem(
                        value: matchCardBlendModeWire(e),
                        child: Text(matchCardBlendModeLabelAr(e)),
                      ),
                  ],
                  onChanged: (v) => setLocal(() => overlayBlendWire = v ?? 'screen'),
                ),
                Row(
                  children: [
                    const Text('شفافية', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: overlayOpacity.clamp(0.05, 1.0),
                        min: 0.05,
                        max: 1.0,
                        divisions: 19,
                        label: overlayOpacity.toStringAsFixed(2),
                        onChanged: (v) => setLocal(() => overlayOpacity = v),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: posCtrl,
                  decoration: const InputDecoration(labelText: 'المركز (GK, CB, …)'),
                ),
                TextField(
                  controller: ratingCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'التقييم'),
                ),
                TextField(
                  controller: xCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'X على الملعب (0–1)'),
                ),
                TextField(
                  controller: yCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Y على الملعب (0–1)'),
                ),
                TextField(
                  controller: teamCtrl,
                  decoration: const InputDecoration(labelText: 'الفريق (اختياري)'),
                ),
                TextField(
                  controller: glowCtrl,
                  decoration: const InputDecoration(
                    labelText: 'توهج: gold | red | blue | white',
                  ),
                ),
                CheckboxListTile(
                  value: visible,
                  onChanged: (v) => setLocal(() => visible = v ?? true),
                  title: const Text('ظهور على الملعب', style: TextStyle(color: Colors.white70)),
                ),
                CheckboxListTile(
                  value: highlighted,
                  onChanged: (v) => setLocal(() => highlighted = v ?? false),
                  title: const Text('تمييز للجمهور (Highlight)', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('إلغاء'),
            ),
            TextButton.icon(
              onPressed: () async {
                await showMatchCardStadiumPreview(
                  context: dialogCtx,
                  player: draftForPreview().toPastPlayerDto(),
                );
              },
              icon: const Icon(Icons.stadium_outlined, size: 18),
              label: const Text('معاينة داخل الملعب'),
            ),
            FilledButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('حفظ')),
          ],
        );
      },
    ),
  );

  if (ok != true || !context.mounted) return;
  final name = nameCtrl.text.trim();
  if (name.isEmpty) return;
  final rating = int.tryParse(ratingCtrl.text.trim()) ?? 0;
  final x = double.tryParse(xCtrl.text.trim()) ?? 0.5;
  final y = double.tryParse(yCtrl.text.trim()) ?? 0.5;

  final player = MatchPitchPlayer(
    id: id,
    name: name,
    imageUrl: legacyImageCtrl.text.trim(),
    rating: rating,
    position: posCtrl.text.trim(),
    x: x.clamp(0.0, 1.0),
    y: y.clamp(0.0, 1.0),
    votes: existing?.votes ?? 0,
    team: teamCtrl.text.trim(),
    glowColor: glowCtrl.text.trim().isEmpty ? 'gold' : glowCtrl.text.trim(),
    visible: visible,
    highlighted: highlighted,
    cardImageUrl: cardImageCtrl.text.trim(),
    cardThumbnailUrl: thumbCtrl.text.trim(),
    cardStyle: styleWire.trim(),
    cardRarity: rarityWire.trim(),
    cardAnimatedOverlay: overlayWire.trim(),
    cardTheme: themeWire.trim(),
    cardOverlayAssetUrl: overlayAssetCtrl.text.trim(),
    cardOverlayEnabled: overlayEnabled,
    cardOverlayBlend: overlayBlendWire.trim().isEmpty ? 'screen' : overlayBlendWire.trim(),
    cardOverlayOpacity: overlayOpacity.clamp(0.05, 1.0),
  );

  await onSave(player);
}

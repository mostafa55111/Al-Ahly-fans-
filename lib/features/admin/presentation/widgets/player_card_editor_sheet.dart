import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/custom_button.dart';

/// محرّر كارت اللاعب — رفع صورة، الطاقة، نوع الكارت، نشط/غير نشط.
Future<void> showPlayerCardEditor(
  BuildContext context, {
  PastPlayerDto? existing,
  required CrowdRepository repo,
  required VoidCallback onSaved,
}) async {
  final primary = Theme.of(context).colorScheme.primary;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final posCtrl = TextEditingController(text: existing?.position ?? '');
  final numCtrl = TextEditingController(text: existing?.number?.toString() ?? '');
  final powerCtrl = TextEditingController(text: existing?.power?.toString() ?? '');
  final cardUrlCtrl = TextEditingController(text: existing?.cardUrl ?? '');
  String cardType = existing?.cardType ?? 'gold';
  var active = existing?.active ?? true;
  File? pickedFile;
  var uploading = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121212),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModal) {
          Future<void> pickImage() async {
            final x = await ImagePicker().pickImage(
              source: ImageSource.gallery,
              imageQuality: 88,
            );
            if (x != null) setModal(() => pickedFile = File(x.path));
          }

          Future<void> uploadIfNeeded() async {
            final cloud = getIt<CloudinaryService>();
            if (pickedFile != null && cloud.isReady) {
              setModal(() => uploading = true);
              try {
                final url = await cloud.uploadImage(pickedFile!);
                cardUrlCtrl.text = url;
              } finally {
                if (ctx.mounted) setModal(() => uploading = false);
              }
            }
          }

          Future<void> save() async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            await uploadIfNeeded();
            final n = int.tryParse(numCtrl.text.trim());
            final pow = int.tryParse(powerCtrl.text.trim());
            if (existing == null) {
              await repo.adminAddPlayer(
                name: name,
                cardUrl: cardUrlCtrl.text.trim().isEmpty ? null : cardUrlCtrl.text.trim(),
                position: posCtrl.text.trim(),
                number: n,
                cardType: cardType,
                active: active,
                power: pow,
              );
            } else {
              await repo.adminUpdatePlayer(existing.id, {
                'name': name,
                'position': posCtrl.text.trim().toLowerCase(),
                if (n != null) 'number': n,
                if (cardUrlCtrl.text.trim().isNotEmpty) 'cardUrl': cardUrlCtrl.text.trim(),
                'cardType': cardType,
                'active': active,
                if (pow != null) 'power': pow,
              });
            }
            if (ctx.mounted) Navigator.pop(ctx);
            onSaved();
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        existing == null ? 'كارت جديد' : 'تعديل الكارت',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      CustomIconButton(
                        icon: Icons.close_rounded,
                        semanticsLabel: 'زر إغلاق محرّر الكارت',
                        color: Colors.white,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  if (cardUrlCtrl.text.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 120,
                        child: CachedNetworkImage(
                          imageUrl: cardUrlCtrl.text,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                    ),
                  if (pickedFile != null)
                    Image.file(pickedFile!, height: 100, fit: BoxFit.contain),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: uploading ? null : pickImage,
                    style: OutlinedButton.styleFrom(foregroundColor: primary),
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('اختيار صورة من الجهاز'),
                  ),
                  if (!getIt<CloudinaryService>().isReady)
                    const Text(
                      'Cloudinary غير مضبوط — الصق رابط الصورة يدوياً أو راجع إعدادات الرفع.',
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                    ),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'الاسم'),
                  ),
                  TextField(
                    controller: posCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'المركز'),
                  ),
                  TextField(
                    controller: numCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'الرقم'),
                  ),
                  TextField(
                    controller: powerCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'الطاقة / التقييم'),
                  ),
                  TextField(
                    controller: cardUrlCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'رابط صورة الكارت (اختياري)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: cardType,
                    dropdownColor: const Color(0xFF222222),
                    decoration: const InputDecoration(labelText: 'نوع الكارت'),
                    items: const [
                      DropdownMenuItem(value: 'gold', child: Text('ذهبي')),
                      DropdownMenuItem(value: 'silver', child: Text('فضي')),
                      DropdownMenuItem(value: 'special', child: Text('خاص')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModal(() => cardType = v);
                    },
                  ),
                  SwitchListTile(
                    value: active,
                    activeThumbColor: primary,
                    title: const Text('نشط في واجهة الجمهور', style: TextStyle(color: Colors.white)),
                    onChanged: (v) => setModal(() => active = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: uploading ? null : save,
                    style: FilledButton.styleFrom(backgroundColor: primary),
                    child: Text(uploading ? 'جاري الرفع…' : 'حفظ'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  nameCtrl.dispose();
  posCtrl.dispose();
  numCtrl.dispose();
  powerCtrl.dispose();
  cardUrlCtrl.dispose();
}

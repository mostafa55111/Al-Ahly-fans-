import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/card_repository/crowd_card_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/card_repository/owner_card_upload_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/models/owner_card_record.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/widgets/owner_card_tile.dart';

class OwnerCardRepositoryPage extends StatefulWidget {
  const OwnerCardRepositoryPage({
    super.key,
    required this.theme,
    this.onAddToPitch,
    this.onAddToBench,
  });

  final ControlRoomTheme theme;
  final void Function(OwnerCardRecord card)? onAddToPitch;
  final void Function(OwnerCardRecord card)? onAddToBench;

  @override
  State<OwnerCardRepositoryPage> createState() => _OwnerCardRepositoryPageState();
}

class _OwnerCardRepositoryPageState extends State<OwnerCardRepositoryPage> {
  final _name = TextEditingController();
  final _number = TextEditingController(text: '0');
  String _position = 'MID';
  bool _uploading = false;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      await getIt<OwnerCardUploadService>().uploadFromFile(
        imageFile: File(picked.path),
        playerName: _name.text,
        playerNumber: int.tryParse(_number.text) ?? 0,
        position: _position,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع الكرت')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appId = FanAppIdentity.registryAppId;
    final repo = getIt<CrowdCardRepository>();

    return StreamBuilder<List<OwnerCardRecord>>(
      stream: repo.watchCards(appId),
      builder: (context, snap) {
        final cards = (snap.data ?? [])
            .where((c) => !c.isArchived && c.matchesApp(appId))
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _uploadZone(),
            const SizedBox(height: 20),
            if (cards.isNotEmpty) ...[
              _section(
                'أُضيف مؤخراً',
                cards.take(8).toList(),
              ),
              const SizedBox(height: 16),
            ],
            for (final group in [
              OwnerCardPositionGroups.gk,
              OwnerCardPositionGroups.def,
              OwnerCardPositionGroups.mid,
              OwnerCardPositionGroups.att,
            ])
              _section(
                OwnerCardPositionGroups.labelAr(group),
                cards.where((c) => c.positionGroup == group).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _uploadZone() {
    final t = widget.theme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: t.panelDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'رفع كرت جديد',
            style: TextStyle(
              color: t.primaryText,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            style: TextStyle(color: t.primaryText),
            decoration: InputDecoration(
              labelText: 'اسم اللاعب',
              labelStyle: TextStyle(color: t.secondaryText),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: t.border)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _number,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: t.primaryText),
                  decoration: InputDecoration(
                    labelText: 'الرقم',
                    labelStyle: TextStyle(color: t.secondaryText),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: t.border)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _position,
                  dropdownColor: t.surface,
                  style: TextStyle(color: t.primaryText),
                  decoration: InputDecoration(
                    labelText: 'المركز',
                    labelStyle: TextStyle(color: t.secondaryText),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: t.border)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'GK', child: Text('حارس')),
                    DropdownMenuItem(value: 'DEF', child: Text('مدافع')),
                    DropdownMenuItem(value: 'MID', child: Text('وسط')),
                    DropdownMenuItem(value: 'ATT', child: Text('مهاجم')),
                  ],
                  onChanged: (v) => setState(() => _position = v ?? 'MID'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _uploading ? null : _pickAndUpload,
            icon: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_uploading ? 'جاري الرفع…' : 'اختيار صورة ورفع'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<OwnerCardRecord> cards) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final t = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: t.primaryText,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final c = cards[i];
              return OwnerCardTile(
                card: c,
                theme: t,
                onDelete: () async {
                  await getIt<CrowdCardRepository>().archiveCard(
                    FanAppIdentity.registryAppId,
                    c,
                  );
                },
                onUsePitch: widget.onAddToPitch == null
                    ? null
                    : () => widget.onAddToPitch!(c),
                onUseBench: widget.onAddToBench == null
                    ? null
                    : () => widget.onAddToBench!(c),
              );
            },
          ),
        ),
      ],
    );
  }
}

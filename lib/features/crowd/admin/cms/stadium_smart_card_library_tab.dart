import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_upload_coordinator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_design_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_library_logic.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_vote_card_image.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/card_soft_delete_service.dart';
import 'package:image_picker/image_picker.dart';
/// مكتبة كروت ذكية — بحث، فلاتر، مفضلة، حديثة، إضافة سريعة.
class StadiumSmartCardLibraryTab extends StatefulWidget {
  const StadiumSmartCardLibraryTab({
    super.key,
    required this.clubTag,
    required this.busy,
    required this.onPitch,
    required this.onBench,
    required this.onReplace,
    required this.onFavorite,
    this.onLibrarySearch,
    this.onCardUploadAttempt,
  });

  final String clubTag;
  final bool busy;
  final VoidCallback? onLibrarySearch;
  final VoidCallback? onCardUploadAttempt;
  final Future<void> Function(StadiumCardRegistryEntry entry) onPitch;
  final Future<void> Function(StadiumCardRegistryEntry entry) onBench;
  final Future<void> Function(StadiumCardRegistryEntry entry) onReplace;
  final Future<void> Function(StadiumCardRegistryEntry entry) onFavorite;

  @override
  State<StadiumSmartCardLibraryTab> createState() => _StadiumSmartCardLibraryTabState();
}

class _StadiumSmartCardLibraryTabState extends State<StadiumSmartCardLibraryTab> {
  final _queryCtrl = TextEditingController();
  StadiumCardLibraryFilter _filter = StadiumCardLibraryFilter.all;
  String? _rarityFilter;
  String? _clubFilter;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = getIt<StadiumCardRegistryRepository>();
    final defaultClub = widget.clubTag;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StadiumCmsDesign.spaceMd,
            StadiumCmsDesign.spaceSm,
            StadiumCmsDesign.spaceMd,
            0,
          ),
          child: TextField(
            controller: _queryCtrl,
            decoration: StadiumCmsDesign.fieldDecoration('بحث بالاسم، الوسم، الندرة…').copyWith(
              prefixIcon: const Icon(Icons.search, color: StadiumCmsDesign.textMuted),
            ),
            onChanged: (_) {
              widget.onLibrarySearch?.call();
              setState(() {});
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _FilterChip(
                label: 'الكل',
                selected: _filter == StadiumCardLibraryFilter.all,
                onTap: () => setState(() => _filter = StadiumCardLibraryFilter.all),
              ),
              _FilterChip(
                label: 'مفضلة',
                selected: _filter == StadiumCardLibraryFilter.favorites,
                onTap: () => setState(() => _filter = StadiumCardLibraryFilter.favorites),
              ),
              _FilterChip(
                label: 'حديثة',
                selected: _filter == StadiumCardLibraryFilter.recent,
                onTap: () => setState(() => _filter = StadiumCardLibraryFilter.recent),
              ),
              _FilterChip(
                label: 'آخر استخدام',
                selected: _filter == StadiumCardLibraryFilter.lastUsed,
                onTap: () => setState(() => _filter = StadiumCardLibraryFilter.lastUsed),
              ),
              _FilterChip(
                label: 'أرشيف',
                selected: _filter == StadiumCardLibraryFilter.archived,
                onTap: () => setState(() => _filter = StadiumCardLibraryFilter.archived),
              ),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: _rarityFilter,
                hint: const Text('الندرة', style: TextStyle(color: Colors.white70, fontSize: 12)),
                dropdownColor: const Color(0xFF222222),
                items: [
                  const DropdownMenuItem(value: null, child: Text('كل الندرات')),
                  for (final r in stadiumCardRarities)
                    DropdownMenuItem(value: r, child: Text(r)),
                ],
                onChanged: (v) => setState(() => _rarityFilter = v),
              ),
              const SizedBox(width: 4),
              DropdownButton<String?>(
                value: _clubFilter,
                hint: const Text('النادي', style: TextStyle(color: Colors.white70, fontSize: 12)),
                dropdownColor: const Color(0xFF222222),
                items: [
                  const DropdownMenuItem(value: null, child: Text('كل الأندية')),
                  DropdownMenuItem(value: defaultClub, child: Text(defaultClub)),
                  const DropdownMenuItem(value: 'ahly', child: Text('ahly')),
                  const DropdownMenuItem(value: 'zamalek', child: Text('zamalek')),
                ],
                onChanged: (v) => setState(() => _clubFilter = v),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: widget.busy
                    ? null
                    : () => _addCard(
                          context,
                          defaultClub,
                          onCardUploadAttempt: widget.onCardUploadAttempt,
                        ),
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('كرت جديد'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<StadiumCardRegistryEntry>>(
            stream: repo.watchCards(widget.clubTag),
            builder: (context, snap) {
              if (snap.hasError) {
                return StadiumCmsDesign.errorState(
                  message: 'تعذّر تحميل المكتبة',
                  onRetry: () => setState(() {}),
                );
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return StadiumCmsDesign.loadingState();
              }
              final all = snap.data ?? const [];
              final list = filterAndSortCardLibrary(
                cards: all,
                query: _queryCtrl.text,
                filter: _filter,
                rarityFilter: _rarityFilter,
                clubFilter: _clubFilter,
              );
              if (list.isEmpty) {
                return StadiumCmsDesign.emptyState(
                  icon: Icons.style_outlined,
                  title: _filter == StadiumCardLibraryFilter.archived
                      ? 'لا كروت في الأرشيف'
                      : 'لا نتائج في المكتبة',
                  hint: _filter == StadiumCardLibraryFilter.archived
                      ? 'الكروت المحذوفة تظهر هنا لمدة 7 أيام'
                      : 'جرّب فلتراً آخر أو أضف كرتاً جديداً',
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final e = list[i];
                  return _CardTile(
                    entry: e,
                    clubTag: widget.clubTag,
                    busy: widget.busy,
                    archivedView: _filter == StadiumCardLibraryFilter.archived,
                    onPitch: () => widget.onPitch(e),
                    onBench: () => widget.onBench(e),
                    onReplace: () => widget.onReplace(e),
                    onFavorite: () => widget.onFavorite(e),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  static Future<void> _addCard(
    BuildContext context,
    String clubTag, {
    VoidCallback? onCardUploadAttempt,
  }) async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final rarityCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    var uploading = false;
    File? pickedFile;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setL) => AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: const Text('كرت في المكتبة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم')),
                TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'رابط الصورة')),
                TextField(controller: rarityCtrl, decoration: const InputDecoration(labelText: 'الندرة')),
                TextField(controller: tagsCtrl, decoration: const InputDecoration(labelText: 'وسوم (فاصلة)')),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: uploading
                      ? null
                      : () async {
                          setL(() => uploading = true);
                          try {
                            final file = await ImagePicker().pickImage(source: ImageSource.gallery);
                            if (file == null) return;
                            pickedFile = File(file.path);
                            try {
                              urlCtrl.text =
                                  await getIt<CloudinaryService>().uploadImage(pickedFile!);
                            } catch (_) {
                              urlCtrl.text = '';
                            }
                          } finally {
                            setL(() => uploading = false);
                          }
                        },
                  icon: uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(uploading ? 'جاري الرفع…' : 'رفع Cloudinary'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final tags = tagsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final coordinator = getIt<StadiumCardUploadCoordinator>();
    onCardUploadAttempt?.call();
    try {
      await coordinator.saveCard(
        clubTag: clubTag,
        playerName: nameCtrl.text,
        rarity: rarityCtrl.text,
        tags: tags,
        imageUrl: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
        localImage: pickedFile,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الكرت')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('فشل الحفظ — أُضيف للطابور. اضغط «إعادة» أعلى الشاشة'),
            action: SnackBarAction(
              label: 'إعادة',
              onPressed: () async {
                final n = await coordinator.flushPending(clubTag);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(n > 0 ? 'تم إرسال $n عمل' : 'لا زال معلّقاً')),
                  );
                }
              },
            ),
          ),
        );
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.amber.withValues(alpha: 0.25),
        checkmarkColor: Colors.amberAccent,
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.entry,
    required this.clubTag,
    required this.busy,
    required this.archivedView,
    required this.onPitch,
    required this.onBench,
    required this.onReplace,
    required this.onFavorite,
  });

  final StadiumCardRegistryEntry entry;
  final String clubTag;
  final bool busy;
  final bool archivedView;
  final Future<void> Function() onPitch;
  final Future<void> Function() onBench;
  final Future<void> Function() onReplace;
  final Future<void> Function() onFavorite;

  Future<void> _archive(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181818),
        title: const Text('أرشفة الكرت؟'),
        content: const Text(
          'يُخفى من المكتبة ويمكن استرجاعه خلال 7 أيام.\nلن يُحذف من السيرفر فوراً.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('أرشفة')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (!getIt.isRegistered<CardSoftDeleteService>()) return;
    try {
      await getIt<CardSoftDeleteService>().archiveCard(clubTag: clubTag, entry: entry);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أُرشف الكرت — استرجاع من تبويب «أرشيف»')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الأرشفة: $e')),
        );
      }
    }
  }

  Future<void> _restore(BuildContext context) async {
    if (!getIt.isRegistered<CardSoftDeleteService>()) return;
    final soft = getIt<CardSoftDeleteService>();
    try {
      await soft.restoreCard(clubTag: clubTag, entry: entry);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم استرجاع الكرت')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _purge(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181818),
        title: const Text('حذف نهائي؟'),
        content: const Text('لا يمكن التراجع. يُستخدم بعد انتهاء مهلة الاسترجاع.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (!getIt.isRegistered<CardSoftDeleteService>()) return;
    try {
      await getIt<CardSoftDeleteService>().purgeCard(clubTag: clubTag, entry: entry);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حُذف الكرت نهائياً')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF151515),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (entry.imageUrl.isEmpty)
                  const Center(child: Icon(Icons.image_not_supported, color: Colors.white38))
                else
                  MatchVoteCardImage(
                    imageUrl: entry.imageUrl,
                    width: 140,
                    height: 180,
                    memCacheWidth: 420,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  entry.playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                if (entry.rarity.isNotEmpty)
                  Text(entry.rarity, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                if (entry.lastUsedAt > 0)
                  Text(
                    'آخر استخدام: ${_relTime(entry.lastUsedAt)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 9),
                  ),
                if (archivedView && entry.archivedAt > 0)
                  Text(
                    'أُرشف: ${_relTime(entry.archivedAt)}',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 9),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (archivedView) ...[
                      _QuickIcon(
                        tooltip: 'استرجاع',
                        icon: Icons.restore,
                        color: getIt.isRegistered<CardSoftDeleteService>() &&
                                getIt<CardSoftDeleteService>().isRecoverable(entry)
                            ? Colors.greenAccent
                            : Colors.white24,
                        busy: busy,
                        onTap: () => _restore(context),
                      ),
                      _QuickIcon(
                        tooltip: 'حذف نهائي',
                        icon: Icons.delete_forever,
                        color: Colors.redAccent,
                        busy: busy,
                        onTap: () => _purge(context),
                      ),
                    ] else ...[
                      _QuickIcon(
                        tooltip: 'ملعب',
                        icon: Icons.sports_soccer,
                        color: Colors.greenAccent,
                        busy: busy,
                        onTap: onPitch,
                      ),
                      _QuickIcon(
                        tooltip: 'بدلاء',
                        icon: Icons.event_seat_outlined,
                        color: Colors.lightBlueAccent,
                        busy: busy,
                        onTap: onBench,
                      ),
                      _QuickIcon(
                        tooltip: 'استبدال',
                        icon: Icons.swap_horiz,
                        color: Colors.orangeAccent,
                        busy: busy,
                        onTap: onReplace,
                      ),
                      _QuickIcon(
                        tooltip: 'مفضلة',
                        icon: entry.favorite ? Icons.star : Icons.star_border,
                        color: entry.favorite ? Colors.amberAccent : Colors.white54,
                        busy: busy,
                        onTap: onFavorite,
                      ),
                      _QuickIcon(
                        tooltip: 'أرشفة',
                        icon: Icons.archive_outlined,
                        color: Colors.white54,
                        busy: busy,
                        onTap: () => _archive(context),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _relTime(int ms) {
    final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (d.inMinutes < 60) return 'منذ ${d.inMinutes} د';
    if (d.inHours < 24) return 'منذ ${d.inHours} س';
    return 'منذ ${d.inDays} ي';
  }
}

class _QuickIcon extends StatelessWidget {
  const _QuickIcon({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final bool busy;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: tooltip,
      icon: Icon(icon, color: color, size: 22),
      onPressed: busy ? null : () => onTap(),
    );
  }
}

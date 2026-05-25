import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/admin/presentation/widgets/player_card_editor_sheet.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/crowd_rtdb_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/custom_button.dart';

/// إدارة كروت FIFA — مسار RTDB: `app_cards/{zamalek|ahly}/items` حسب التطبيق الحالي فقط.
class FifaCardManagerTab extends StatefulWidget {
  const FifaCardManagerTab({
    super.key,
    required this.repo,
    required this.primary,
  });

  final CrowdRepository repo;
  final Color primary;

  @override
  State<FifaCardManagerTab> createState() => _FifaCardManagerTabState();
}

class _FifaCardManagerTabState extends State<FifaCardManagerTab> {
  List<PastPlayerDto> _players = [];
  var _loading = true;

  String get _pathHint =>
      CrowdRtdbPaths.fifaCardsItems(FanAppIdentity.registryAppId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await widget.repo.loadPastPlayers();
    if (!mounted) return;
    setState(() {
      _players = list;
      _loading = false;
    });
  }

  Future<void> _confirmDelete(PastPlayerDto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('حذف الكارت؟', style: TextStyle(color: Colors.white)),
        content: Text(
          p.name,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await widget.repo.adminDeletePlayer(p.id);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: widget.primary));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: CustomFAB(
        isExtended: true,
        icon: Icons.add_rounded,
        label: 'كارت جديد',
        tooltip: 'فتح محرر كارت جديد',
        semanticsLabel: 'إضافة كارت فيفا جديد',
        backgroundColor: widget.primary,
        foregroundColor: Colors.white,
        onPressed: () => showPlayerCardEditor(
          context,
          existing: null,
          repo: widget.repo,
          onSaved: _load,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'مسار Firebase: $_pathHint\n'
              '(كروت هذا النادي فقط — لا تُعرض في تطبيق الجمهور الآخر)',
              style: TextStyle(
                color: widget.primary.withValues(alpha: 0.9),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
              // ارتفاع ثابت لصف الكارت يُحسّن تخطيط السحب (itemExtent / Robo).
              itemExtent: 100,
              itemCount: _players.length,
              itemBuilder: (context, i) {
                final p = _players[i];
                return RepaintBoundary(
                  child: Card(
                    color: const Color(0xFF151515),
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      dense: true,
                      leading: p.cardUrl != null && p.cardUrl!.isNotEmpty
                          ? Image.network(
                              p.cardUrl!,
                              width: 48,
                              height: 64,
                              cacheWidth: 250,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.person, color: widget.primary),
                      title: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${p.cardType} • ${p.active ? 'نشط' : 'مخفي'}'
                        '${p.power != null ? ' • طاقة ${p.power}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.primary.withValues(alpha: 0.85),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconButton(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'حذف',
                            semanticsLabel: 'حذف كارت اللاعب ${p.name}',
                            color: Colors.redAccent.shade200,
                            onPressed: () => _confirmDelete(p),
                          ),
                          CustomIconButton(
                            icon: Icons.edit_rounded,
                            tooltip: 'تعديل',
                            semanticsLabel: 'تعديل كارت ${p.name}',
                            color: widget.primary,
                            onPressed: () => showPlayerCardEditor(
                              context,
                              existing: p,
                              repo: widget.repo,
                              onSaved: _load,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => showPlayerCardEditor(
                        context,
                        existing: p,
                        repo: widget.repo,
                        onSaved: _load,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

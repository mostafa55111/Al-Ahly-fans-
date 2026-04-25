import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/design_system/theme/app_colors.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/eagle_session_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/crowd_admin_ai_service.dart';

class CrowdAdminPage extends StatefulWidget {
  const CrowdAdminPage({super.key});

  @override
  State<CrowdAdminPage> createState() => _CrowdAdminPageState();
}

class _CrowdAdminPageState extends State<CrowdAdminPage> {
  final CrowdRepository _repo = getIt<CrowdRepository>();
  final FirebaseDatabase _db = getIt<FirebaseDatabase>();
  final EgyptServerTimeService _serverTime = getIt<EgyptServerTimeService>();
  final FirebaseAuth _auth = getIt<FirebaseAuth>();
  late final CrowdAdminAiService _ai;
  final TextEditingController _aiController = TextEditingController();

  bool _checkingAdmin = true;
  bool _isAdmin = false;
  bool _busy = false;
  bool _aiBusy = false;

  List<PastPlayerDto> _players = [];
  EagleSessionDto? _session;
  final Set<String> _eligible = {};

  final Map<String, bool> _flags = {
    'profileEnabled': true,
    'travelEnabled': true,
    'reelsEnabled': true,
    'storeEnabled': true,
    'crowdEnabled': true,
  };
  final List<_AiMessage> _messages = [
    const _AiMessage(
      role: _AiRole.assistant,
      text:
          'AI Assistant جاهز. أمثلة:\n'
          '- فلتر التعليقات الخارجة\n'
          '- اديني تقرير عن أكتر الشاشات زيارة\n'
          '- احذف فيديو واخد ريبورتات كتير',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ai = CrowdAdminAiService(database: _db);
    _bootstrap();
  }

  @override
  void dispose() {
    _aiController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      setState(() {
        _checkingAdmin = false;
        _isAdmin = false;
      });
      return;
    }

    final adminSnap = await _db.ref('admins/$uid').get();
    final isAdmin = adminSnap.exists && (adminSnap.value == true || adminSnap.value == 1);
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _checkingAdmin = false;
    });
    if (!isAdmin) return;
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _busy = true);
    try {
      final players = await _repo.loadPastPlayers();
      final session = await _repo.loadCurrentSession();
      final controlsSnap = await _db.ref('app_controls').get();
      if (!mounted) return;
      setState(() {
        _players = players;
        _session = session;
        _eligible
          ..clear()
          ..addAll(session?.eligiblePlayerIds ?? const <String>{});
        if (controlsSnap.exists && controlsSnap.value is Map) {
          final m = Map<dynamic, dynamic>.from(controlsSnap.value! as Map);
          for (final key in _flags.keys) {
            final v = m[key];
            _flags[key] = v == null ? true : (v == true || v == 1);
          }
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _currentYyyymm {
    final now = DateTime.fromMillisecondsSinceEpoch(_serverTime.serverNowMs);
    final mm = now.month.toString().padLeft(2, '0');
    return '${now.year}$mm';
  }

  Future<void> _addOrEditPlayer({PastPlayerDto? player}) async {
    final nameCtrl = TextEditingController(text: player?.name ?? '');
    final cardCtrl = TextEditingController(text: player?.cardUrl ?? '');
    final posCtrl = TextEditingController(text: player?.position ?? '');
    final numCtrl = TextEditingController(text: player?.number?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF181818),
        title: Text(player == null ? 'إضافة كارت' : 'تعديل كارت'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم اللاعب')),
              TextField(controller: posCtrl, decoration: const InputDecoration(labelText: 'المركز مثل gk/cb/st')),
              TextField(controller: numCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رقم اللاعب (اختياري)')),
              TextField(controller: cardCtrl, decoration: const InputDecoration(labelText: 'رابط الكارت cardUrl')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      final updates = <String, Object?>{
        'name': name,
        'position': posCtrl.text.trim().toLowerCase(),
        'cardUrl': cardCtrl.text.trim(),
      };
      final n = int.tryParse(numCtrl.text.trim());
      if (n != null) updates['number'] = n;
      if (player == null) {
        await _repo.adminAddPlayer(
          name: name,
          cardUrl: cardCtrl.text.trim(),
          position: posCtrl.text.trim().toLowerCase(),
          number: n,
        );
      } else {
        await _repo.adminUpdatePlayer(player.id, updates);
      }
      await _loadData();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deletePlayer(PastPlayerDto p) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الكارت'),
        content: Text('هل تريد حذف كارت ${p.name}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (yes != true) return;
    await _repo.adminDeletePlayer(p.id);
    await _loadData();
  }

  Future<void> _startVoting() async {
    if (_eligible.isEmpty) return;
    await _repo.adminStartSession(
      eligiblePlayerIds: _eligible,
      yyyymm: _currentYyyymm,
      seasonId: 'season_current',
    );
    await _loadData();
  }

  Future<void> _endVoting() async {
    await _repo.adminEndSession();
    await _loadData();
  }

  Future<void> _saveControls() async {
    await _db.ref('app_controls').update(_flags);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ إعدادات التحكم العامة')));
  }

  Future<void> _sendAiPrompt() async {
    final prompt = _aiController.text.trim();
    if (prompt.isEmpty || _aiBusy) return;
    setState(() {
      _messages.add(_AiMessage(role: _AiRole.user, text: prompt));
      _aiBusy = true;
    });
    _aiController.clear();
    try {
      final res = await _ai.handlePrompt(prompt);
      if (!mounted) return;
      setState(() {
        _messages.add(_AiMessage(
          role: _AiRole.assistant,
          text: res.answer,
        ));
      });
      if (res.actionExecuted) {
        await _loadData();
      }
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAdmin) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }
    if (!_isAdmin) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('هذه الشاشة متاحة للأدمن فقط', style: TextStyle(color: Colors.white)),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(onPressed: _busy ? null : _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : () => _addOrEditPlayer(),
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSessionCard(),
          const SizedBox(height: 12),
          _buildControlsCard(),
          const SizedBox(height: 12),
          _buildAiAssistantCard(),
          const SizedBox(height: 12),
          const Text('كل الكروت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ..._players.map(
            (p) => Card(
              color: const Color(0xFF151515),
              child: ListTile(
                leading: Checkbox(
                  value: _eligible.contains(p.id),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _eligible.add(p.id);
                      } else {
                        _eligible.remove(p.id);
                      }
                    });
                  },
                ),
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${p.position ?? '-'} | votes: ${p.votes}',
                  style: const TextStyle(color: Colors.white60),
                ),
                trailing: Wrap(
                  spacing: 2,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white10,
                      child: Text(
                        (p.position ?? '-').toUpperCase(),
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _addOrEditPlayer(player: p),
                      icon: const Icon(Icons.edit, color: Colors.white70),
                    ),
                    IconButton(
                      onPressed: () => _deletePlayer(p),
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSessionCard() {
    final rem = _session == null
        ? 0
        : _serverTime.remainingVoteSeconds(_session!.startedAtServerMs).clamp(0, EgyptServerTimeService.voteWindowSeconds);
    final mm = (rem ~/ 60).toString().padLeft(2, '0');
    final ss = (rem % 60).toString().padLeft(2, '0');
    return Card(
      color: const Color(0xFF151515),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تحكم نسر المباراة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              _session == null ? 'لا توجد جلسة نشطة' : 'جلسة نشطة - متبقي $mm:$ss',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _busy ? null : _startVoting,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                    child: const Text('بدء التصويت 60 دقيقة'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy || _session == null ? null : _endVoting,
                    child: const Text('إنهاء الجلسة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsCard() {
    return Card(
      color: const Color(0xFF151515),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تحكم عام في أنماط التطبيق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ..._flags.keys.map(
              (k) => SwitchListTile(
                value: _flags[k] ?? true,
                onChanged: (v) => setState(() => _flags[k] = v),
                title: Text(k, style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveControls,
                style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
                child: const Text('حفظ التحكم العام'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAssistantCard() {
    return Card(
      color: const Color(0xFF151515),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Assistant (Gemini)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Container(
              height: 230,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i];
                  final mine = m.role == _AiRole.user;
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        color: mine ? AppColors.secondary.withValues(alpha: 0.35) : Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        m.text,
                        style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.35),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _aiController,
                    minLines: 1,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'اكتب أمر للإدارة الذكية...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendAiPrompt(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _aiBusy ? null : _sendAiPrompt,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
                  child: _aiBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('إرسال'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _AiRole { user, assistant }

class _AiMessage {
  final _AiRole role;
  final String text;

  const _AiMessage({
    required this.role,
    required this.text,
  });
}

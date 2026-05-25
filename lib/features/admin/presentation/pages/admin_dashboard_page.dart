import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/admin/presentation/utils/qr_png_export.dart';
import 'package:gomhor_alahly_clean_new/features/admin/presentation/widgets/fifa_card_manager_tab.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/crowd_rtdb_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/owner_control_room_shell.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/lineup.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/repositories/matches_repository.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/motm_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/public_arena/domain/arena_trip_qr_payload.dart';
import 'package:gomhor_alahly_clean_new/features/store/data/marketplace_repository_rtdb.dart';
import 'package:gomhor_alahly_clean_new/features/travel/data/governorates_seed.dart';
import 'package:gomhor_alahly_clean_new/features/travel/data/travel_repository_rtdb.dart';
import 'package:share_plus/share_plus.dart';

/// لوحة إدارة CMS — كروت اللاعبين، تصويت رجل المباراة، الترحال، والمساعد.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const String _adminPanelPassword = 'Mm3822reyad';
  static const String _resetEmail = 'mostafareyad772@gmail.com';
  final _db = getIt<FirebaseDatabase>();
  final _auth = getIt<FirebaseAuth>();
  final _repo = getIt<CrowdRepository>();

  bool _checking = true;
  bool _isAdmin = false;
  bool _passwordGranted = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _checking = false;
        _isAdmin = false;
      });
      return;
    }
    final snap = await _db.ref('admins/$uid').get();
    final ok = snap.exists && (snap.value == true || snap.value == 1);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _isAdmin = ok;
    });
  }

  Future<void> _unlockWithPassword() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('كلمة مرور لوحة التحكم'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ادخل كلمة المرور',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, controller.text.trim() == _adminPanelPassword);
            },
            child: const Text('دخول'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted) return;
    if (ok == true) {
      setState(() => _passwordGranted = true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('كلمة المرور غير صحيحة')),
    );
  }

  bool get _canTriggerResetByEmail {
    final email = _auth.currentUser?.email?.trim().toLowerCase();
    return email == _resetEmail;
  }

  Future<void> _triggerResetLayout() async {
    if (!_canTriggerResetByEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا الإجراء متاح لحساب الأدمن الرئيسي فقط')),
      );
      return;
    }
    await _db.ref(CrowdRtdbPaths.layoutResetSignal).set(ServerValue.timestamp);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إعادة ضبط أماكن اللاعبين بنجاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (_checking) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة التحكم')),
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة التحكم')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'غير مصرّح — يجب أن يكون حسابك في قائمة admins في Realtime Database.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!_passwordGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة التحكم')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'تحقق إضافي للأدمن مطلوب قبل فتح اللوحة.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _unlockWithPassword,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('فتح لوحة التحكم'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الإدارة CMS'),
          actions: [
            IconButton(
              tooltip: 'Reset Layout',
              onPressed: _triggerResetLayout,
              icon: const Icon(Icons.cleaning_services_outlined),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: primary,
            labelColor: primary,
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(text: 'FIFA cards'),
              Tab(text: 'Voting'),
              Tab(text: 'Travel'),
              Tab(text: 'Vendors'),
              Tab(text: 'Assistant'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FifaCardManagerTab(repo: _repo, primary: primary),
            _VotingAdminTab(primary: primary),
            _TravelAdminFormTab(primary: primary),
            _MarketplaceVendorTab(primary: primary, db: _db, auth: _auth),
            _AssistantTab(primary: primary),
          ],
        ),
      ),
    );
  }
}

// ─── تصويت MOTM أدمن ────────────────────────────────────────────────

class _VotingAdminTab extends StatefulWidget {
  const _VotingAdminTab({required this.primary});

  final Color primary;

  @override
  State<_VotingAdminTab> createState() => _VotingAdminTabState();
}

class _VotingAdminTabState extends State<_VotingAdminTab> {
  final _fixtureCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController(text: '60');
  List<LineupPlayer> _lineup = [];
  final _sel = <int>{};
  int? _sessionFixtureId;
  /// لضبط شريط التقدّم بما يتوافق مع مدة الجلسة التي اختارها الأدمن.
  int _sessionDurationMinutes = 60;
  var _busy = false;

  @override
  void dispose() {
    _fixtureCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLineup() async {
    final id = int.tryParse(_fixtureCtrl.text.trim());
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل معرف مباراة صحيحاً (رقم)')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = MatchesRepository();
      final list = await repo.getAhlyParticipants(id);
      if (!mounted) return;
      setState(() {
        _lineup = list;
        _sel
          ..clear()
          ..addAll(list.where((e) => e.id != null).map((e) => e.id!));
        _sessionFixtureId = null;
        _sessionDurationMinutes = 60;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createSession() async {
    final id = int.tryParse(_fixtureCtrl.text.trim());
    if (id == null) return;
    final minutes = int.tryParse(_minutesCtrl.text.trim()) ?? 60;
    final chosen = _lineup.where((e) => e.id != null && _sel.contains(e.id!)).toList();
    if (chosen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر لاعباً واحداً على الأقل')),
      );
      return;
    }
    setState(() => _busy = true);
    final cubit = MotmVotingCubit();
    try {
      await cubit.adminSeedMotmSession(
        fixtureId: id,
        players: chosen,
        votingDurationMinutes: minutes,
      );
      if (!mounted) return;
      setState(() {
        _sessionFixtureId = id;
        _sessionDurationMinutes = minutes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء جلسة التصويت')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      await cubit.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fid = _sessionFixtureId;

    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'جلسة رجل المباراة (motm)',
            style: TextStyle(
              color: widget.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fixtureCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'معرف المباراة fixtureId',
              hintText: 'مثال: 214835',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _minutesCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'مدة التصويت (دقائق)',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _fetchLineup,
                  style: FilledButton.styleFrom(backgroundColor: widget.primary),
                  child: const Text('جلب اللاعبين'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _createSession,
                  style: OutlinedButton.styleFrom(foregroundColor: widget.primary),
                  child: const Text('إنـشاء الجلسة'),
                ),
              ),
            ],
          ),
          if (_lineup.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('المرشحون:', style: TextStyle(color: widget.primary, fontWeight: FontWeight.w700)),
            ..._lineup.where((p) => p.id != null).map((p) {
              final on = _sel.contains(p.id!);
              return CheckboxListTile(
                value: on,
                checkColor: Colors.white,
                fillColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return widget.primary;
                  }
                  return Colors.white10;
                }),
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  '${p.position ?? ''} #${p.number ?? '—'}',
                  style: const TextStyle(color: Colors.white54),
                ),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _sel.add(p.id!);
                    } else {
                      _sel.remove(p.id!);
                    }
                  });
                },
              );
            }),
          ],
          if (fid != null) ...[
            const Divider(height: 32),
            Text(
              'الوقت المتبقي للتصويت',
              style: TextStyle(color: widget.primary, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref('motm/$fid/endsAt').onValue,
              builder: (context, snap) {
                if (!snap.hasData || !snap.data!.snapshot.exists) {
                  return const Text('لا بيانات endsAt', style: TextStyle(color: Colors.white54));
                }
                final ev = snap.data!.snapshot.value;
                final ends = ev is int ? ev : int.tryParse('$ev');
                if (ends == null) return const SizedBox.shrink();
                final left = ends - DateTime.now().millisecondsSinceEpoch;
                final sec = (left / 1000).clamp(0, 999999).floor();
                final m = (sec ~/ 60).toString().padLeft(2, '0');
                final s = (sec % 60).toString().padLeft(2, '0');
                final totalMs = _sessionDurationMinutes * 60 * 1000;
                if (totalMs <= 0) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: left > 0
                          ? (left / totalMs).clamp(0.0, 1.0)
                          : 0,
                      color: widget.primary,
                      backgroundColor: Colors.white12,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      left <= 0 ? 'انتهى الوقت' : 'متبقي: $m:$s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─── ترحال + QR ─────────────────────────────────────────────────────

class _TravelAdminFormTab extends StatefulWidget {
  const _TravelAdminFormTab({required this.primary});

  final Color primary;

  @override
  State<_TravelAdminFormTab> createState() => _TravelAdminFormTabState();
}

class _TravelAdminFormTabState extends State<_TravelAdminFormTab> {
  final _nameCtrl = TextEditingController();
  final _capCtrl = TextEditingController(text: '40');
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _govId = kGovernoratesByPopularity.first.id;
  String? _tripId;
  var _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _createTrip() async {
    final cap = int.tryParse(_capCtrl.text.trim()) ?? 0;
    if (_nameCtrl.text.trim().isEmpty || cap <= 0) return;
    setState(() => _busy = true);
    try {
      final travel = TravelRepositoryRtdb(FirebaseDatabase.instance);
      final id = await travel.adminCreateTrip(
        companyName: _nameCtrl.text.trim(),
        departureAt: _date,
        capacity: cap,
        governorateId: _govId,
      );
      if (!mounted) return;
      setState(() => _tripId = id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء الرحلة: $id')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareQr(String phase) async {
    final id = _tripId;
    if (id == null) return;
    final payload = ArenaTripQrPayload(
      tripId: id,
      companyName: _nameCtrl.text.trim(),
      phase: phase,
    );
    final json = payload.toJsonString();
    final bytes = await QrPngExport.renderQrPngBytes(json);
    final file =
        await QrPngExport.saveToTempFile(bytes, 'trip_${phase}_$id.png');
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'رمز رحلة — $phase',
    );
  }

  Future<void> _saveGallery(String phase) async {
    final id = _tripId;
    if (id == null) return;
    final payload = ArenaTripQrPayload(
      tripId: id,
      companyName: _nameCtrl.text.trim(),
      phase: phase,
    );
    final bytes = await QrPngExport.renderQrPngBytes(payload.toJsonString());
    try {
      await QrPngExport.saveToGallery(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حُفظت الصورة في المعرض')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'اسم الرحلة / الشركة'),
        ),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('تاريخ الانطلاق', style: TextStyle(color: Colors.white)),
          subtitle: Text(
            _date.toIso8601String().substring(0, 10),
            style: TextStyle(color: widget.primary),
          ),
          trailing: Icon(Icons.calendar_month_rounded, color: widget.primary),
          onTap: _pickDate,
        ),
        TextField(
          controller: _capCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'السعة'),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _govId,
          dropdownColor: const Color(0xFF222222),
          decoration: const InputDecoration(labelText: 'المحافظة'),
          items: kGovernoratesByPopularity
              .map((g) => DropdownMenuItem(value: g.id, child: Text(g.nameAr)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _govId = v);
          },
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _createTrip,
          style: FilledButton.styleFrom(backgroundColor: widget.primary),
          child: const Text('إنشاء الرحلة'),
        ),
        if (_tripId != null) ...[
          const SizedBox(height: 24),
          SelectableText(
            'tripId: $_tripId',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => _shareQr('start'),
                style: FilledButton.styleFrom(backgroundColor: widget.primary),
                child: const Text('مشاركة QR بداية'),
              ),
              FilledButton(
                onPressed: () => _shareQr('end'),
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('مشاركة QR نهاية'),
              ),
              OutlinedButton(
                onPressed: () => _saveGallery('start'),
                style: OutlinedButton.styleFrom(foregroundColor: widget.primary),
                child: const Text('حفظ بداية في المعرض'),
              ),
              OutlinedButton(
                onPressed: () => _saveGallery('end'),
                style: OutlinedButton.styleFrom(foregroundColor: widget.primary),
                child: const Text('حفظ نهاية في المعرض'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── تفعيل حسابات البائعين (سوق موحد) ───────────────────────────────

class _MarketplaceVendorTab extends StatefulWidget {
  const _MarketplaceVendorTab({
    required this.primary,
    required this.db,
    required this.auth,
  });

  final Color primary;
  final FirebaseDatabase db;
  final FirebaseAuth auth;

  @override
  State<_MarketplaceVendorTab> createState() => _MarketplaceVendorTabState();
}

class _MarketplaceVendorTabState extends State<_MarketplaceVendorTab> {
  final _uidCtrl = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _uidCtrl.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final adminUid = widget.auth.currentUser?.uid;
    final target = _uidCtrl.text.trim();
    if (adminUid == null || target.isEmpty) return;
    setState(() => _busy = true);
    try {
      final repo = MarketplaceRepositoryRtdb(widget.db);
      await repo.activateVendorAccount(targetUid: target, adminUid: adminUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تفعيل البائع: $target')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'تفعيل vendor',
          style: TextStyle(
            color: widget.primary,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'يُنشئ/يحدّث all/marketplace/vendor_accounts/{uid} ليُسمح للمستخدم بإنشاء متجر.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _uidCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'UID المستخدم',
            hintText: 'معرف Firebase Auth',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _activate,
          style: FilledButton.styleFrom(backgroundColor: widget.primary),
          child: const Text('activateVendorAccount'),
        ),
      ],
    );
  }
}

// ─── مساعد AI القديم ────────────────────────────────────────────────

class _AssistantTab extends StatelessWidget {
  const _AssistantTab({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy_rounded, size: 56, color: primary),
            const SizedBox(height: 16),
            const Text(
              'مساعد الإدارة الذكي',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primary),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OwnerControlRoomShell(),
                  ),
                );
              },
              child: const Text('فتح شاشة المساعد الكاملة'),
            ),
          ],
        ),
      ),
    );
  }
}

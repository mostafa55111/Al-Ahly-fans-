import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_runtime/owner_session_rules.dart';

class OwnerSessionBuilderPage extends StatefulWidget {
  const OwnerSessionBuilderPage({super.key, required this.theme});

  final ControlRoomTheme theme;

  @override
  State<OwnerSessionBuilderPage> createState() => _OwnerSessionBuilderPageState();
}

class _OwnerSessionBuilderPageState extends State<OwnerSessionBuilderPage> {
  int _step = 0;
  String _formation = '4-3-3';
  int _durationMin = 60;
  final _title = TextEditingController(text: 'تصويت المباراة');
  final List<String> _starters = [];
  final List<String> _bench = [];

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final cubit = context.read<MatchVotesAdminCubit>();
    final state = cubit.state;
    final server = getIt<EgyptServerTimeService>();
    await server.refreshOffset();
    final closesAt =
        server.serverNowMs + _durationMin * 60 * 1000;

    final onPitch = state.bundle.players.map((p) => p.id).toList();
    final check = OwnerSessionRules.validateNewSession(
      existing: state.match,
      formation: _formation,
      starterIds: onPitch.take(11).toList(),
      benchIds: onPitch.length > 11 ? onPitch.sublist(11) : const [],
      durationMinutes: _durationMin,
    );
    if (!check.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(check.message ?? 'تعذر النشر')),
      );
      return;
    }

    if (state.match == null || state.match!.id.isEmpty) {
      await cubit.createSession(
        title: _title.text,
        formation: _formation,
        clearPlayers: true,
        closesAt: closesAt,
      );
    } else {
      await cubit.updateActiveSession(
        state.match!.copyWith(
          formation: _formation,
          closesAt: closesAt,
          title: _title.text,
        ),
      );
    }

  await cubit.publishVoting(formation: _formation);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الجلسة مباشرة — النظام يغلق ويعلن الفائز تلقائياً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return BlocBuilder<MatchVotesAdminCubit, MatchVotesAdminState>(
      builder: (context, admin) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'بناء جلسة التصويت',
              style: TextStyle(
                color: t.primaryText,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            _steps(t),
            const SizedBox(height: 16),
            if (_step == 0) _formationStep(t),
            if (_step == 1) _lineupStep(t, admin),
            if (_step == 2) _durationStep(t),
            if (_step == 3) _previewStep(t, admin),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_step > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text('رجوع'),
                  ),
                const Spacer(),
                if (_step < 3)
                  FilledButton(
                    onPressed: () => setState(() => _step++),
                    child: const Text('التالي'),
                  )
                else
                  FilledButton(
                    onPressed: admin.busy ? null : _publish,
                    child: Text(admin.busy ? 'جاري النشر…' : 'START SESSION'),
                  ),
              ],
            ),
            if (admin.message != null) ...[
              const SizedBox(height: 8),
              Text(admin.message!, style: TextStyle(color: Colors.red[300])),
            ],
          ],
        );
      },
    );
  }

  Widget _steps(ControlRoomTheme t) {
    const labels = ['تشكيلة', 'لاعبون', 'المدة', 'معاينة'];
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i == _step;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? t.identity.primaryColor.withValues(alpha: 0.25)
                    : t.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active ? t.identity.primaryColor : t.border,
                ),
              ),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: t.primaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _formationStep(ControlRoomTheme t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: t.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _title,
            style: TextStyle(color: t.primaryText),
            decoration: const InputDecoration(labelText: 'عنوان الجلسة'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _formation,
            dropdownColor: t.surface,
            style: TextStyle(color: t.primaryText),
            decoration: const InputDecoration(labelText: 'التشكيلة'),
            items: const [
              DropdownMenuItem(value: '4-3-3', child: Text('4-3-3')),
              DropdownMenuItem(value: '4-2-3-1', child: Text('4-2-3-1')),
              DropdownMenuItem(value: '4-4-2', child: Text('4-4-2')),
              DropdownMenuItem(value: '3-4-3', child: Text('3-4-3')),
              DropdownMenuItem(value: '3-5-2', child: Text('3-5-2')),
            ],
            onChanged: (v) => setState(() => _formation = v ?? '4-3-3'),
          ),
        ],
      ),
    );
  }

  Widget _lineupStep(ControlRoomTheme t, MatchVotesAdminState admin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: t.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أساسيون: ${_starters.length}/11 · بدلاء: ${_bench.length}',
            style: TextStyle(color: t.primaryText, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر من تبويب المستودع — أساسي / بديل',
            style: TextStyle(color: t.secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'على الملعب: ${admin.bundle.players.length} لاعب',
            style: TextStyle(color: t.secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _durationStep(ControlRoomTheme t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: t.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مدة الجلسة: $_durationMin دقيقة', style: TextStyle(color: t.primaryText)),
          Slider(
            value: _durationMin.toDouble(),
            min: OwnerSessionRules.minDurationMinutes.toDouble(),
            max: OwnerSessionRules.maxDurationMinutes.toDouble(),
            divisions: 35,
            onChanged: (v) => setState(() => _durationMin = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _previewStep(ControlRoomTheme t, MatchVotesAdminState admin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: t.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title.text, style: TextStyle(color: t.primaryText, fontWeight: FontWeight.w900)),
          Text('تشكيلة $_formation', style: TextStyle(color: t.secondaryText)),
          Text('إغلاق بعد $_durationMin دقيقة', style: TextStyle(color: t.secondaryText)),
          Text('لاعبون: ${admin.bundle.players.length}', style: TextStyle(color: t.secondaryText)),
        ],
      ),
    );
  }
}

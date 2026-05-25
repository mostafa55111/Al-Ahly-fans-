import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/launch_validation/launch_validator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/operational_shortcuts/operational_shortcuts.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/quick_launch/quick_launch_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_match_template.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_match_template_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/session_drafts/owner_session_draft.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/session_drafts/owner_session_draft_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_template_writer.dart';

/// لوحة سرعة يوم المباراة — قوالب، مسودات، اختصارات.
class MatchdaySpeedPanel extends StatefulWidget {
  const MatchdaySpeedPanel({
    super.key,
    required this.theme,
    required this.formation,
    required this.durationMin,
    required this.onFormationChanged,
    required this.onDurationChanged,
    required this.onQuickLaunchReady,
  });

  final ControlRoomTheme theme;
  final String formation;
  final int durationMin;
  final ValueChanged<String> onFormationChanged;
  final ValueChanged<int> onDurationChanged;
  final VoidCallback onQuickLaunchReady;

  @override
  State<MatchdaySpeedPanel> createState() => _MatchdaySpeedPanelState();
}

class _MatchdaySpeedPanelState extends State<MatchdaySpeedPanel> {
  String? _selectedTemplateId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final appId = FanAppIdentity.registryAppId;
    final templates = getIt<OwnerMatchTemplateRepository>();
    final drafts = getIt<OwnerSessionDraftRepository>();
    final shortcuts = getIt<OperationalShortcuts>();
    final quickLaunch = getIt<QuickLaunchService>();

    return StreamBuilder<List<OwnerMatchTemplate>>(
      stream: templates.watchTemplates(appId),
      builder: (context, tplSnap) {
        final tplList = tplSnap.data ?? const [];
        return StreamBuilder<List<OwnerSessionDraft>>(
          stream: drafts.watchDrafts(appId),
          builder: (context, draftSnap) {
            final draftList = (draftSnap.data ?? const [])
                .where((d) =>
                    d.state == OwnerSessionDraftState.draft ||
                    d.state == OwnerSessionDraftState.ready)
                .toList();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: widget.theme.panelDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'إطلاق سريع',
                    style: TextStyle(
                      color: widget.theme.primaryText,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اختر قالباً → معاينة → تشغيل (< 30 ث)',
                    style: TextStyle(
                      color: widget.theme.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (tplList.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _selectedTemplateId ??
                          (tplList.isNotEmpty ? tplList.first.id : null),
                      decoration: InputDecoration(
                        labelText: 'قالب التشكيلة',
                        labelStyle: TextStyle(color: widget.theme.secondaryText),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      dropdownColor: widget.theme.surfaceElevated,
                      style: TextStyle(color: widget.theme.primaryText),
                      items: tplList
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name),
                            ),
                          )
                          .toList(),
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _selectedTemplateId = v),
                    )
                  else
                    Text(
                      'لا قوالب محفوظة — احفظ تشكيلة من الجلسة الحالية',
                      style: TextStyle(color: widget.theme.secondaryText),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(
                        label: 'آخر تشكيلة',
                        icon: Icons.history,
                        onTap: _busy
                            ? null
                            : () => _run(() => shortcuts.reuseLastLineup(
                                  context.read<MatchVotesAdminCubit>(),
                                )),
                      ),
                      _chip(
                        label: 'نسخ الجلسة',
                        icon: Icons.copy,
                        onTap: _busy
                            ? null
                            : () => _run(() => shortcuts.duplicatePreviousSession(
                                  context.read<MatchVotesAdminCubit>(),
                                )),
                      ),
                      if (draftList.isNotEmpty)
                        _chip(
                          label: 'آخر مسودة',
                          icon: Icons.drafts_outlined,
                          onTap: _busy
                              ? null
                              : () => _launchDraft(
                                    draftList.first,
                                    shortcuts,
                                    appId,
                                  ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _saveCurrentAsTemplate(context),
                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: const Text('حفظ التشكيلة الحالية كقالب'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _busy || tplList.isEmpty
                        ? null
                        : () => _quickLaunchFromTemplate(
                              tplList,
                              quickLaunch,
                              appId,
                            ),
                    icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                    label: const Text('تطبيق القالب والمعاينة'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: widget.theme.secondaryText),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: widget.theme.surfaceElevated,
      labelStyle: TextStyle(color: widget.theme.primaryText, fontSize: 12),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveCurrentAsTemplate(BuildContext context) async {
    final nameCtrl = TextEditingController(text: 'تشكيلة محفوظة');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.surface,
        title: Text('حفظ قالب', style: TextStyle(color: widget.theme.primaryText)),
        content: TextField(
          controller: nameCtrl,
          style: TextStyle(color: widget.theme.primaryText),
          decoration: const InputDecoration(labelText: 'اسم القالب'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    await _run(() async {
      final writer = getIt<OwnerTemplateWriter>();
      await writer.saveFromState(
        state: context.read<MatchVotesAdminCubit>().state,
        appId: FanAppIdentity.registryAppId,
        name: name,
      );
    });
  }

  Future<void> _quickLaunchFromTemplate(
    List<OwnerMatchTemplate> tplList,
    QuickLaunchService quickLaunch,
    String appId,
  ) async {
    final id = _selectedTemplateId ?? tplList.first.id;
    final template = tplList.firstWhere((t) => t.id == id);
    setState(() => _busy = true);
    try {
      final cubit = context.read<MatchVotesAdminCubit>();
      await quickLaunch.applyTemplate(
        cubit: cubit,
        template: template,
        appId: appId,
      );
      widget.onFormationChanged(template.formation);
      widget.onQuickLaunchReady();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('قالب «${template.name}» جاهز للمعاينة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _launchDraft(
    OwnerSessionDraft draft,
    OperationalShortcuts shortcuts,
    String appId,
  ) async {
    setState(() => _busy = true);
    try {
      final cubit = context.read<MatchVotesAdminCubit>();
      await shortcuts.launchFromLatestDraft(
        cubit: cubit,
        draft: draft,
        appId: appId,
      );
      widget.onFormationChanged(draft.formation);
      widget.onDurationChanged(draft.durationMinutes);
      widget.onQuickLaunchReady();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحميل المسودة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// يعرض نتيجة التحقق قبل الإطلاق.
class LaunchValidationBanner extends StatelessWidget {
  const LaunchValidationBanner({
    super.key,
    required this.theme,
    required this.admin,
    required this.formation,
    required this.durationMin,
  });

  final ControlRoomTheme theme;
  final MatchVotesAdminState admin;
  final String formation;
  final int durationMin;

  @override
  Widget build(BuildContext context) {
    final check = LaunchValidator.validateLaunch(
      existing: admin.match,
      formation: formation,
      players: admin.bundle.players,
      durationMinutes: durationMin,
    );
    if (check.ok) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_outlined, color: Colors.greenAccent, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'جاهز للإطلاق',
                style: TextStyle(color: theme.primaryText, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              check.message ?? 'تحقق من التشكيلة',
              style: TextStyle(color: theme.primaryText),
            ),
          ),
        ],
      ),
    );
  }
}

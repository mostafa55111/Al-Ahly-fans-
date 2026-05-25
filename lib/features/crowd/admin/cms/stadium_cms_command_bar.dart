import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_workspace_snapshot.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_session_template.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_design_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_operator_metrics.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/admin_control_visual_system.dart';

/// شريط أوامر ثابت — قوالب بنقرة واحدة + استئناف الجلسة.
class StadiumCmsCommandBar extends StatelessWidget {
  const StadiumCmsCommandBar({
    super.key,
    required this.identity,
    required this.busy,
    required this.workspaceSnapshot,
    required this.onTemplateApplied,
    required this.onResume,
    required this.onDismissResume,
    this.metrics,
    this.operatorWarning,
  });

  final CrowdAppIdentity identity;
  final bool busy;
  final StadiumCmsWorkspaceSnapshot? workspaceSnapshot;
  final VoidCallback onTemplateApplied;
  final VoidCallback onResume;
  final VoidCallback onDismissResume;
  final StadiumCmsOperatorMetrics? metrics;
  final String? operatorWarning;

  @override
  Widget build(BuildContext context) {
    final club = FanAppIdentity.registryAppId;
    final builtins = builtinStadiumSessionTemplates(club);
    final accent = identity.primaryColor;
    return AdminControlVisualSystem.glassPanel(
      identity: identity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (operatorWarning != null && operatorWarning!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: StadiumCmsDesign.spaceSm),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(StadiumCmsDesign.spaceSm),
                  decoration: BoxDecoration(
                    color: StadiumCmsDesign.semanticWarning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(StadiumCmsDesign.cardRadius),
                    border: Border.all(color: StadiumCmsDesign.semanticWarning.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    operatorWarning!,
                    style: StadiumCmsDesign.subtitle.copyWith(
                      color: StadiumCmsDesign.semanticWarning,
                      fontSize: StadiumCmsDesign.typeCaption,
                    ),
                  ),
                ),
              ),
            if (workspaceSnapshot != null && workspaceSnapshot!.updatedAt > 0)
              _ResumeBanner(
                snapshot: workspaceSnapshot!,
                busy: busy,
                accent: accent,
                onResume: onResume,
                onDismiss: onDismissResume,
              ),
            Text('جلسة بنقرة واحدة', style: StadiumCmsDesign.title(identity).copyWith(fontSize: 12)),
            StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final t in builtins)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _OneTapChip(
                        label: t.name,
                        highlight: t.id == 'builtin_derby',
                        accent: accent,
                        busy: busy,
                        onTap: () async {
                          metrics?.onAction('template_${t.id}');
                          await context.read<MatchVotesAdminCubit>().applySessionTemplate(t);
                          metrics?.onSessionReady('template_${t.id}');
                          onTemplateApplied();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تم تطبيق «${t.name}»')),
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
      ),
    );
  }
}

class _OneTapChip extends StatelessWidget {
  const _OneTapChip({
    required this.label,
    required this.highlight,
    required this.accent,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool highlight;
  final Color accent;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: highlight ? accent : accent.withValues(alpha: 0.22),
        foregroundColor: highlight ? Colors.white : accent,
        minimumSize: const Size(0, StadiumCmsDesign.chipHeight),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({
    required this.snapshot,
    required this.busy,
    required this.accent,
    required this.onResume,
    required this.onDismiss,
  });

  final StadiumCmsWorkspaceSnapshot snapshot;
  final bool busy;
  final Color accent;
  final VoidCallback onResume;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final label = snapshot.kitName.isNotEmpty
        ? snapshot.kitName
        : (snapshot.title.isNotEmpty ? snapshot.title : 'آخر جلسة');
    return Container(
      margin: const EdgeInsets.only(bottom: StadiumCmsDesign.spaceSm),
      padding: const EdgeInsets.symmetric(
        horizontal: StadiumCmsDesign.spaceSm,
        vertical: StadiumCmsDesign.spaceSm,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(StadiumCmsDesign.cardRadius),
        color: accent.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'استكمال: $label · ${snapshot.playerCount} لاعب · ${snapshot.formation}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: busy ? null : onDismiss,
            child: const Text('تجاهل', style: TextStyle(fontSize: 11)),
          ),
          FilledButton(
            onPressed: busy ? null : onResume,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: const Text('استكمال', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

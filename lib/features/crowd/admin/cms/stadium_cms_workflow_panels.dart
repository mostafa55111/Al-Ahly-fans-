import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_design_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_match_kit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_session_template.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_operator_metrics.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_cubit.dart';

/// قوالب جلسة جاهزة + مخصصة.
class StadiumSessionTemplatesPanel extends StatelessWidget {
  const StadiumSessionTemplatesPanel({
    super.key,
    required this.identity,
    required this.busy,
    required this.onApplied,
  });

  final CrowdAppIdentity identity;
  final bool busy;
  final VoidCallback onApplied;

  @override
  Widget build(BuildContext context) {
    final club = FanAppIdentity.registryAppId;
    final cms = getIt<StadiumCmsRepository>();
    final builtins = builtinStadiumSessionTemplates(club);

    return StadiumCmsDesign.surfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StadiumCmsDesign.sectionHeader('قوالب الجلسة', identity),
          StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceXs),
          Text(
            'تطبّق الفورمة، بروفايل الجمهور، والثيم — بدون FX جديدة على الكروت.',
            style: StadiumCmsDesign.caption,
          ),
          StadiumCmsDesign.sectionGap(),
          Wrap(
            spacing: StadiumCmsDesign.spaceSm,
            runSpacing: StadiumCmsDesign.spaceSm,
            children: [
              for (final t in builtins)
                ActionChip(
                  label: Text(t.name, style: const TextStyle(fontSize: 12)),
                  onPressed: busy
                      ? null
                      : () async {
                          await context.read<MatchVotesAdminCubit>().applySessionTemplate(t);
                          onApplied();
                        },
                ),
            ],
          ),
          StadiumCmsDesign.sectionGap(),
          StreamBuilder<List<StadiumSessionTemplate>>(
            stream: cms.watchCustomTemplates(club),
            builder: (context, snap) {
              final custom = snap.data ?? const [];
              if (custom.isEmpty) {
                return OutlinedButton.icon(
                  onPressed: busy ? null : () => _saveTemplate(context),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('حفظ الجلسة الحالية كقالب'),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final t in custom)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.name, style: StadiumCmsDesign.subtitle),
                      subtitle: Text('${t.formation} · ${t.fxLevel}', style: StadiumCmsDesign.caption),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow, color: StadiumCmsDesign.semanticLive),
                        onPressed: busy
                            ? null
                            : () async {
                                await context.read<MatchVotesAdminCubit>().applySessionTemplate(t);
                                onApplied();
                              },
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => _saveTemplate(context),
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('حفظ كقالب جديد'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static Future<void> _saveTemplate(BuildContext context) async {
    await context.read<MatchVotesAdminCubit>().saveSessionTemplateFromCurrent('');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ قالب الجلسة')),
      );
    }
  }
}

/// Tactical Kits — حزم هوية تكتيكية.
class StadiumQuickLineupPanel extends StatelessWidget {
  const StadiumQuickLineupPanel({
    super.key,
    required this.identity,
    required this.busy,
    required this.formation,
    required this.onFormationChanged,
    this.metrics,
  });

  final CrowdAppIdentity identity;
  final bool busy;
  final String formation;
  final ValueChanged<String> onFormationChanged;
  final StadiumCmsOperatorMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final club = FanAppIdentity.registryAppId;
    final cms = getIt<StadiumCmsRepository>();
    final cubit = context.read<MatchVotesAdminCubit>();

    return StadiumCmsDesign.surfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StadiumCmsDesign.sectionHeader('Tactical Kits', identity),
          StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceXs),
          Text(
            'تشكيلة · بدلاء · فلسفة · أجواء · نبرة الملعب · منافسة',
            style: StadiumCmsDesign.caption,
          ),
          StadiumCmsDesign.sectionGap(),
          Wrap(
            spacing: StadiumCmsDesign.spaceSm,
            runSpacing: StadiumCmsDesign.spaceSm,
            children: [
              FilledButton(
                onPressed: busy
                    ? null
                    : () async {
                        await cubit.loadLastLineup();
                        onFormationChanged(cubit.state.match?.formation ?? formation);
                      },
                style: StadiumCmsDesign.tonalButton(identity),
                child: const Text('آخر Kit'),
              ),
              FilledButton(
                onPressed: busy ? null : () => _importFromLibrary(context),
                style: StadiumCmsDesign.tonalButton(identity),
                child: const Text('من المكتبة'),
              ),
              FilledButton(
                onPressed: busy ? null : () => cubit.duplicateSession(),
                style: StadiumCmsDesign.tonalButton(identity),
                child: const Text('نسخ الجلسة'),
              ),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () {
                        metrics?.onSaveAction('kit');
                        _saveKit(context, cubit);
                      },
                child: const Text('حفظ Kit'),
              ),
            ],
          ),
          StadiumCmsDesign.sectionGap(),
          StreamBuilder<List<StadiumMatchKit>>(
            stream: cms.watchMatchKits(club),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                return StadiumCmsDesign.inlineBusy(label: 'تحميل الحزم…');
              }
              final kits = snap.data ?? const [];
              if (kits.isEmpty) {
                return StadiumCmsDesign.emptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'لا توجد Tactical Kits بعد',
                  hint: 'احفظ Kit بعد ضبط الجلسة والتشكيلة',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('حزم محفوظة', style: StadiumCmsDesign.caption),
                  for (final k in kits)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(k.name, style: StadiumCmsDesign.subtitle),
                      subtitle: Text(
                        '${k.formation} · ${k.starterSlots.length} أساسي · ${k.benchSlots.length} بديل · ${k.tacticalIdentity.rivalryMode}',
                        style: StadiumCmsDesign.caption,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.download_outlined, color: Colors.amberAccent),
                        onPressed: busy
                            ? null
                              : () async {
                                  metrics?.onAction('kit_${k.id}');
                                  await cubit.loadMatchKit(k);
                                  metrics?.onKitLoaded(k.name);
                                  onFormationChanged(k.formation);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('تم تحميل «${k.name}»')),
                                  );
                                }
                              },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static Future<void> _saveKit(BuildContext context, MatchVotesAdminCubit cubit) async {
    await cubit.saveCurrentMatchKit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ Tactical Kit')),
      );
    }
  }

  static Future<void> _importFromLibrary(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('انتقل لتبويب «مكتبة الكروت» — ملعب أو بدلاء لكل لاعب.'),
        duration: StadiumCmsDesign.motionNormal,
      ),
    );
  }
}

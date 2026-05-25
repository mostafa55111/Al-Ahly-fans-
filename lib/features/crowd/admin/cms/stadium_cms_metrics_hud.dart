import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_design_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_friction_kind.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_operator_metrics.dart';

/// HUD — TTMA + انقطاعات معرفية (قرارات UX، ليس vanity).
class StadiumCmsMetricsHud extends StatefulWidget {
  const StadiumCmsMetricsHud({
    super.key,
    required this.identity,
    required this.metrics,
  });

  final CrowdAppIdentity identity;
  final StadiumCmsOperatorMetrics metrics;

  @override
  State<StadiumCmsMetricsHud> createState() => _StadiumCmsMetricsHudState();
}

class _StadiumCmsMetricsHudState extends State<StadiumCmsMetricsHud> {
  var _expanded = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metrics;
    final elite = m.reachedEliteWindow;
    const targetSec = 90;
    final dominant = m.dominantInterruption;
    final n = m.cognitiveInterruptionCount;

    return Material(
      color: StadiumCmsDesign.surfaceElevated.withValues(alpha: 0.96),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StadiumCmsDesign.spaceMd,
              vertical: StadiumCmsDesign.spaceSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 18,
                      color: n == 0
                          ? StadiumCmsDesign.semanticLive
                          : StadiumCmsDesign.semanticWarning,
                    ),
                    const SizedBox(width: StadiumCmsDesign.spaceSm),
                    Text(
                      'TTMA ${m.elapsedLabel}',
                      style: StadiumCmsDesign.subtitle.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: StadiumCmsDesign.spaceSm),
                    Text('/ ${targetSec}s', style: StadiumCmsDesign.caption),
                    const Spacer(),
                    StadiumCmsDesign.statusChip(
                      label: '$n انقطاع',
                      semantic: n == 0 ? StadiumCmsSemantic.live : StadiumCmsSemantic.warning,
                      identity: widget.identity,
                    ),
                  ],
                ),
                if (dominant != null && n > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'الأبرز: ${dominant.labelAr}',
                      style: StadiumCmsDesign.caption.copyWith(
                        color: elite ? StadiumCmsDesign.textMuted : StadiumCmsDesign.semanticWarning,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (_expanded) ...[
                  StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
                  if (m.cognitiveInterruptions.isEmpty)
                    Text('تدفق نظيف — لا انقطاعات معرفية', style: StadiumCmsDesign.caption)
                  else
                    for (final f in m.cognitiveInterruptions.take(6))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '· ${f.kind.labelAr}${f.detail.isEmpty ? '' : ' — ${f.detail}'}',
                              style: StadiumCmsDesign.caption.copyWith(
                                color: StadiumCmsDesign.semanticWarning,
                              ),
                            ),
                            Text(
                              '  → ${f.kind.uxDecisionHint}',
                              style: StadiumCmsDesign.caption.copyWith(
                                color: StadiumCmsDesign.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                  if (m.cognitiveInterruptions.length > 6)
                    Text('… +${m.cognitiveInterruptions.length - 6}', style: StadiumCmsDesign.caption),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

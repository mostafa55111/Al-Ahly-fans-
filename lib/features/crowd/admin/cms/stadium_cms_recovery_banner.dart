import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_design_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_pending_op.dart';

/// بانر استعادة مرئي — ماذا فشل · ماذا معلّق · ماذا أُعيد.
class StadiumCmsRecoveryBanner extends StatefulWidget {
  const StadiumCmsRecoveryBanner({
    super.key,
    required this.identity,
    required this.pending,
    required this.busy,
    required this.onRetryAll,
    this.lastSyncMessage,
  });

  final CrowdAppIdentity identity;
  final List<StadiumCmsPendingOp> pending;
  final bool busy;
  final Future<void> Function() onRetryAll;
  final String? lastSyncMessage;

  @override
  State<StadiumCmsRecoveryBanner> createState() => _StadiumCmsRecoveryBannerState();
}

class _StadiumCmsRecoveryBannerState extends State<StadiumCmsRecoveryBanner> {
  var _expanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.pending.isEmpty && (widget.lastSyncMessage == null || widget.lastSyncMessage!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final uploads =
        widget.pending.where((o) => o.kind == StadiumCmsPendingOpKind.cardRegistryUpsert).toList();

    return Material(
      color: StadiumCmsDesign.semanticWarning.withValues(alpha: 0.1),
      child: AnimatedSize(
        duration: StadiumCmsDesign.motionNormal,
        curve: StadiumCmsDesign.motionEase,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            StadiumCmsDesign.spaceMd,
            StadiumCmsDesign.spaceSm,
            StadiumCmsDesign.spaceMd,
            StadiumCmsDesign.spaceSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.pending_actions, color: StadiumCmsDesign.semanticWarning, size: 20),
                  const SizedBox(width: StadiumCmsDesign.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pending.isEmpty
                              ? 'تمت المزامنة'
                              : '${widget.pending.length} عمل في الانتظار',
                          style: StadiumCmsDesign.subtitle.copyWith(
                            color: StadiumCmsDesign.semanticWarning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.lastSyncMessage != null && widget.lastSyncMessage!.isNotEmpty)
                          Text(
                            widget.lastSyncMessage!,
                            style: StadiumCmsDesign.caption.copyWith(color: StadiumCmsDesign.semanticLive),
                          )
                        else if (widget.pending.isNotEmpty)
                          Text(
                            'لم يُرفَع بعد — اضغط إعادة أو انتظر الشبكة',
                            style: StadiumCmsDesign.caption,
                          ),
                      ],
                    ),
                  ),
                  if (widget.pending.isNotEmpty)
                    IconButton(
                      tooltip: _expanded ? 'طي التفاصيل' : 'عرض التفاصيل',
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.white70),
                    ),
                  FilledButton(
                    onPressed: widget.busy || widget.pending.isEmpty ? null : widget.onRetryAll,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: widget.identity.primaryColor,
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text(widget.busy ? '…' : 'إعادة الكل', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              if (_expanded && uploads.isNotEmpty) ...[
                StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
                for (final op in uploads) _PendingRow(op: op),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.op});

  final StadiumCmsPendingOp op;

  @override
  Widget build(BuildContext context) {
    final name = op.payload['playerName']?.toString() ?? 'كرت';
    final err = op.lastError.trim();
    final shortErr = err.length > 72 ? '${err.substring(0, 72)}…' : err;

    return Container(
      margin: const EdgeInsets.only(bottom: StadiumCmsDesign.spaceXs),
      padding: const EdgeInsets.symmetric(
        horizontal: StadiumCmsDesign.spaceSm,
        vertical: StadiumCmsDesign.spaceXs,
      ),
      decoration: BoxDecoration(
        color: StadiumCmsDesign.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StadiumCmsDesign.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.image_not_supported_outlined, size: 16, color: StadiumCmsDesign.textMuted),
          const SizedBox(width: StadiumCmsDesign.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رفع كرت: $name',
                  style: StadiumCmsDesign.caption.copyWith(
                    color: StadiumCmsDesign.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'محاولات: ${op.attempts} · معلّق',
                  style: StadiumCmsDesign.caption,
                ),
                if (shortErr.isNotEmpty)
                  Text(
                    'السبب: $shortErr',
                    style: StadiumCmsDesign.caption.copyWith(color: StadiumCmsDesign.semanticDestructive),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

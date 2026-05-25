import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';

/// إجراءات خطرة تتطلب تأكيداً متعمداً.
enum CriticalOwnerAction {
  finalize,
  emergencyClose,
  deleteDraft,
  replaceActiveSession,
}

abstract final class CriticalActionProtection {
  static const Duration minimumHold = Duration(milliseconds: 600);

  static Future<bool> confirm(
    BuildContext context, {
    required ControlRoomTheme theme,
    required CriticalOwnerAction action,
    required String title,
    required String body,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: theme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CriticalConfirmSheet(
        theme: theme,
        title: title,
        body: body,
        actionLabel: _actionLabel(action),
      ),
    ).then((v) => v == true);
  }

  static String _actionLabel(CriticalOwnerAction action) => switch (action) {
        CriticalOwnerAction.finalize => 'تأكيد الإنهاء',
        CriticalOwnerAction.emergencyClose => 'إغلاق التصويت',
        CriticalOwnerAction.deleteDraft => 'حذف المسودة',
        CriticalOwnerAction.replaceActiveSession => 'استبدال الجلسة',
      };
}

class _CriticalConfirmSheet extends StatefulWidget {
  const _CriticalConfirmSheet({
    required this.theme,
    required this.title,
    required this.body,
    required this.actionLabel,
  });

  final ControlRoomTheme theme;
  final String title;
  final String body;
  final String actionLabel;

  @override
  State<_CriticalConfirmSheet> createState() => _CriticalConfirmSheetState();
}

class _CriticalConfirmSheetState extends State<_CriticalConfirmSheet> {
  bool _armed = false;
  bool _confirmed = false;
  Timer? _holdTimer;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _onHoldStart() {
    if (_confirmed) return;
    setState(() => _armed = true);
    _holdTimer?.cancel();
    _holdTimer = Timer(CriticalActionProtection.minimumHold, () {
      if (!mounted) return;
      setState(() => _confirmed = true);
    });
  }

  void _onHoldEnd() {
    _holdTimer?.cancel();
    if (!_confirmed && mounted) {
      setState(() => _armed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.theme.identity.primaryColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: widget.theme.primaryText,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.body,
            style: TextStyle(color: widget.theme.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط مطولاً للتأكيد (${CriticalActionProtection.minimumHold.inMilliseconds}ms)',
            style: TextStyle(
              color: widget.theme.secondaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTapDown: (_) => _onHoldStart(),
            onTapUp: (_) => _onHoldEnd(),
            onTapCancel: _onHoldEnd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _confirmed
                    ? Colors.green.withValues(alpha: 0.25)
                    : _armed
                        ? primary.withValues(alpha: 0.35)
                        : primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _confirmed ? Colors.greenAccent : primary,
                  width: _armed ? 2 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _confirmed ? 'تم التأكيد — اضغط تنفيذ' : widget.actionLabel,
                style: TextStyle(
                  color: widget.theme.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _confirmed
                ? () => Navigator.of(context).pop(true)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('تنفيذ', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('إلغاء', style: TextStyle(color: widget.theme.secondaryText)),
          ),
        ],
      ),
    );
  }
}

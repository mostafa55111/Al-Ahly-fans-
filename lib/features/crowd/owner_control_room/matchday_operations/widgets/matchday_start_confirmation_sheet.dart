import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_runtime/owner_session_rules.dart';

class MatchdayStartConfirmationSheet extends StatelessWidget {
  const MatchdayStartConfirmationSheet({
    super.key,
    required this.theme,
    required this.formation,
    required this.startersCount,
    required this.benchCount,
    required this.durationMinutes,
    required this.readinessOk,
    required this.readinessMessage,
    required this.onConfirm,
    required this.busy,
  });

  final ControlRoomTheme theme;
  final String formation;
  final int startersCount;
  final int benchCount;
  final int durationMinutes;
  final bool readinessOk;
  final String? readinessMessage;
  final VoidCallback onConfirm;
  final bool busy;

  static Future<void> show(
    BuildContext context, {
    required ControlRoomTheme theme,
    required String formation,
    required int startersCount,
    required int benchCount,
    required int durationMinutes,
    required bool readinessOk,
    String? readinessMessage,
    required VoidCallback onConfirm,
    bool busy = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => MatchdayStartConfirmationSheet(
        theme: theme,
        formation: formation,
        startersCount: startersCount,
        benchCount: benchCount,
        durationMinutes: durationMinutes,
        readinessOk: readinessOk,
        readinessMessage: readinessMessage,
        onConfirm: () {
          Navigator.of(ctx).pop();
          onConfirm();
        },
        busy: busy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تأكيد بدء البث',
            style: TextStyle(
              color: theme.primaryText,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _row('التشكيلة', formation),
          _row('أساسيون', '$startersCount / ${OwnerSessionRules.minStarters}'),
          _row('بدلاء', '$benchCount'),
          _row('المدة', '$durationMinutes دقيقة'),
          _row('الجاهزية', readinessOk ? 'جاهز' : 'غير جاهز'),
          if (readinessMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              readinessMessage!,
              style: TextStyle(color: Colors.orange[300], fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: readinessOk && !busy ? onConfirm : null,
            style: FilledButton.styleFrom(
              backgroundColor: theme.identity.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              busy ? 'جاري البدء…' : 'بدء البث والتصويت',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$k: ', style: TextStyle(color: theme.secondaryText)),
          Text(v, style: TextStyle(color: theme.primaryText, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

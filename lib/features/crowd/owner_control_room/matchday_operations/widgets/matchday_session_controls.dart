import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';

class MatchdaySessionControls extends StatelessWidget {
  const MatchdaySessionControls({
    super.key,
    required this.theme,
    required this.titleController,
    required this.formation,
    required this.durationMin,
    required this.onFormationChanged,
    required this.onDurationChanged,
  });

  final ControlRoomTheme theme;
  final TextEditingController titleController;
  final String formation;
  final int durationMin;
  final ValueChanged<String> onFormationChanged;
  final ValueChanged<int> onDurationChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: theme.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: titleController,
            style: TextStyle(color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'عنوان الجلسة',
              labelStyle: TextStyle(color: theme.secondaryText),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: formation,
            dropdownColor: theme.surface,
            style: TextStyle(color: theme.primaryText),
            decoration: const InputDecoration(labelText: 'التشكيلة'),
            items: const [
              DropdownMenuItem(value: '4-3-3', child: Text('4-3-3')),
              DropdownMenuItem(value: '4-2-3-1', child: Text('4-2-3-1')),
              DropdownMenuItem(value: '4-4-2', child: Text('4-4-2')),
              DropdownMenuItem(value: '3-4-3', child: Text('3-4-3')),
              DropdownMenuItem(value: '3-5-2', child: Text('3-5-2')),
            ],
            onChanged: (v) => onFormationChanged(v ?? formation),
          ),
          const SizedBox(height: 8),
          Text('المدة: $durationMin دقيقة',
              style: TextStyle(color: theme.secondaryText)),
          Slider(
            value: durationMin.toDouble(),
            min: 5,
            max: 180,
            divisions: 35,
            onChanged: (v) => onDurationChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

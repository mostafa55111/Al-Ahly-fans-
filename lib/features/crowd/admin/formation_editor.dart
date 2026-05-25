import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/formation_templates.dart';

/// ترتيب اللاعبين + اختيار تشكيلة + تطبيق على الإحداثيات في RTDB.
class FormationEditorPanel extends StatelessWidget {
  const FormationEditorPanel({
    super.key,
    required this.orderedPlayerLabels,
    required this.onReorder,
    required this.selectedFormation,
    required this.onFormationChanged,
    required this.onApply,
    required this.busy,
  });

  final List<String> orderedPlayerLabels;
  final void Function(int oldIndex, int newIndex) onReorder;
  final String selectedFormation;
  final ValueChanged<String> onFormationChanged;
  final VoidCallback onApply;
  final bool busy;

  static const formations = ['4-3-3', '4-2-3-1', '3-5-2'];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF151515),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'محرّك التشكيلة',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: formations.contains(selectedFormation) ? selectedFormation : '4-3-3',
              dropdownColor: const Color(0xFF222222),
              decoration: const InputDecoration(
                labelText: 'الفورمة',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              items: formations
                  .map(
                    (f) => DropdownMenuItem(
                      value: f,
                      child: Text(f, style: const TextStyle(color: Colors.white)),
                    ),
                  )
                  .toList(),
              onChanged: busy
                  ? null
                  : (String? v) {
                      if (v != null) onFormationChanged(v);
                    },
            ),
            const SizedBox(height: 6),
            Text(
              'اسحب لترتيب اللاعبين (الأول يأخذ مركز حارس المرمى في القالب ثم الدفاع…).',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
            ),
            const SizedBox(height: 8),
            if (orderedPlayerLabels.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'لا لاعبين بعد — أضف لاعبين ثم طبّق التشكيلة.',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: orderedPlayerLabels.length,
                onReorder: (a, b) {
                  if (!busy) onReorder(a, b);
                },
                itemBuilder: (context, i) {
                  final label = orderedPlayerLabels[i];
                  return Card(
                    key: ValueKey('$label-$i'),
                    color: const Color(0xFF1C1C1C),
                    child: ListTile(
                      leading: ReorderableDragStartListener(
                        index: i,
                        child: const Icon(Icons.drag_handle, color: Colors.white54),
                      ),
                      title: Text(
                        label,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      subtitle: Text(
                        'ترتيب ${i + 1} → ${FormationTemplates.slotsFor(selectedFormation).length} مراكز',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: busy ? null : onApply,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.grid_on_outlined),
              label: Text(busy ? 'جاري التطبيق...' : 'تطبيق على الملعب'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class FormationSlot extends Equatable {
  const FormationSlot({
    required this.dx,
    required this.dy,
    required this.positionName,
  });

  final double dx;
  final double dy;
  final String positionName;

  Offset get asOffset => Offset(dx, dy);

  static const List<FormationSlot> fallback352 = <FormationSlot>[
    FormationSlot(dx: 0.50, dy: 0.86, positionName: 'GK'),
    FormationSlot(dx: 0.27, dy: 0.70, positionName: 'CB1'),
    FormationSlot(dx: 0.50, dy: 0.68, positionName: 'CB2'),
    FormationSlot(dx: 0.73, dy: 0.70, positionName: 'CB3'),
    FormationSlot(dx: 0.14, dy: 0.52, positionName: 'LM'),
    FormationSlot(dx: 0.33, dy: 0.53, positionName: 'CM1'),
    FormationSlot(dx: 0.50, dy: 0.50, positionName: 'CM2'),
    FormationSlot(dx: 0.67, dy: 0.53, positionName: 'CM3'),
    FormationSlot(dx: 0.86, dy: 0.52, positionName: 'RM'),
    FormationSlot(dx: 0.40, dy: 0.25, positionName: 'ST1'),
    FormationSlot(dx: 0.60, dy: 0.25, positionName: 'ST2'),
  ];

  factory FormationSlot.fromMap(String fallbackName, Map<dynamic, dynamic> map) {
    final dxValue = map['dx'];
    final dyValue = map['dy'];
    final name = (map['positionName'] ?? fallbackName).toString().trim();
    final dx = dxValue is num ? dxValue.toDouble() : 0.5;
    final dy = dyValue is num ? dyValue.toDouble() : 0.5;
    return FormationSlot(
      dx: dx.clamp(0.0, 1.0),
      dy: dy.clamp(0.0, 1.0),
      positionName: name.isEmpty ? fallbackName : name,
    );
  }

  @override
  List<Object?> get props => [dx, dy, positionName];
}

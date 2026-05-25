import 'package:equatable/equatable.dart';

/// محافظة مع كود ثلاثي يُستخدم كبادئة لكود الحجز.
class GovernorateModel extends Equatable {
  const GovernorateModel({
    required this.id,
    required this.nameAr,
    required this.code3,
    required this.popularityRank,
  });

  final String id;
  final String nameAr;

  /// مثل "047" لكفر الشيخ
  final String code3;

  /// ترتيب الجماهيرية (الأصغر = أكثر جماهيرية)
  final int popularityRank;

  @override
  List<Object?> get props => [id, nameAr, code3, popularityRank];

  Map<String, dynamic> toMap() => {
        'id': id,
        'nameAr': nameAr,
        'code3': code3,
        'popularityRank': popularityRank,
      };

  factory GovernorateModel.fromMap(Map<dynamic, dynamic> map) {
    return GovernorateModel(
      id: map['id'] as String? ?? '',
      nameAr: map['nameAr'] as String? ?? '',
      code3: map['code3'] as String? ?? '000',
      popularityRank: (map['popularityRank'] as num?)?.toInt() ?? 999,
    );
  }
}

/// خلية مصفوفة الاستقرار.
class StabilityMatrixCell {
  const StabilityMatrixCell({
    required this.area,
    required this.score,
    required this.statusAr,
  });

  final String area;
  final double score;
  final String statusAr;
}

/// مصفوفة استقرار الإطلاق.
class ReleaseStabilityMatrix {
  const ReleaseStabilityMatrix({required this.cells});

  final List<StabilityMatrixCell> cells;

  bool get allAboveThreshold =>
      cells.every((c) => c.score >= 70);

  factory ReleaseStabilityMatrix.fromCategoryScores(
    Map<String, double> categories,
  ) {
    return ReleaseStabilityMatrix(
      cells: categories.entries
          .map(
            (e) => StabilityMatrixCell(
              area: e.key,
              score: e.value,
              statusAr: e.value >= 85
                  ? 'مستقر'
                  : e.value >= 70
                      ? 'مقبول'
                      : 'خطر',
            ),
          )
          .toList(),
    );
  }
}

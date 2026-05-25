import 'package:equatable/equatable.dart';

/// منتج داخل متجر تاجر.
class StoreProduct extends Equatable {
  const StoreProduct({
    required this.id,
    required this.merchantId,
    required this.ownerUid,
    required this.titleAr,
    required this.description,
    required this.priceEgp,
    required this.imageUrl,
    required this.active,
    required this.updatedAtMs,
    this.audience = 'all',
    this.viewCount = 0,
    this.salesCount = 0,
    this.popularityScore = 0,
  });

  /// شعبية مُشتقة: المبيعات تُوزن أكثر من المشاهدات (يتم تحديثها في RTDB).
  static int computePopularityScore(int sales, int views) => sales * 10 + views;

  final String id;
  final String merchantId;
  final String ownerUid;
  final String titleAr;
  final String description;
  final int priceEgp;
  final String imageUrl;
  final bool active;
  final int updatedAtMs;

  /// `all` | `zamalek` | `ahly` | … — سوق مشترك على نفس المسار.
  final String audience;

  final int viewCount;
  final int salesCount;

  /// يُخزَّن في القاعدة لترتيب الاستعلامات؛ يُحدَّث مع المشاهدات/المبيعات.
  final int popularityScore;

  bool get hasImage => imageUrl.isNotEmpty;

  /// يظهر في تطبيق زملكاوي: `all` أو `zamalek` أو غير مضبوط (يُعامل كـ all).
  bool get visibleInZamalekApp {
    final a = audience.trim().toLowerCase();
    if (a.isEmpty || a == 'all' || a == 'zamalek') return true;
    return false;
  }

  /// يظهر في تطبيق الأهلي: `all` أو `ahly` أو غير مضبوط (يُعامل كـ all).
  bool get visibleInAhlyApp {
    final a = audience.trim().toLowerCase();
    if (a.isEmpty || a == 'all' || a == 'ahly') return true;
    return false;
  }

  factory StoreProduct.fromMap(String id, Map<dynamic, dynamic> map) {
    return StoreProduct(
      id: id,
      merchantId: map['merchantId'] as String? ?? '',
      ownerUid: map['ownerUid'] as String? ?? '',
      titleAr: map['titleAr'] as String? ?? 'منتج',
      description: map['description'] as String? ?? '',
      priceEgp: (map['priceEgp'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] as String? ?? '',
      active: map['active'] == true || map['active'] == 1,
      updatedAtMs: (map['updatedAt'] as num?)?.toInt() ??
          (map['updatedAtMs'] as num?)?.toInt() ??
          0,
      audience: _parseAudience(
        map['audience'] ?? map['visibility'] ?? map['tag'] ?? map['clubTag'],
      ),
      viewCount: (map['viewCount'] as num?)?.toInt() ?? 0,
      salesCount: (map['salesCount'] as num?)?.toInt() ?? 0,
      popularityScore: (map['popularityScore'] as num?)?.toInt() ??
          computePopularityScore(
            (map['salesCount'] as num?)?.toInt() ?? 0,
            (map['viewCount'] as num?)?.toInt() ?? 0,
          ),
    );
  }

  static String _parseAudience(dynamic v) {
    if (v == null) return 'all';
    final s = v.toString().trim().toLowerCase();
    if (s.isEmpty) return 'all';
    return s;
  }

  Map<String, dynamic> toWriteMap() => {
        'merchantId': merchantId,
        'ownerUid': ownerUid,
        'titleAr': titleAr,
        'description': description,
        'priceEgp': priceEgp,
        'imageUrl': imageUrl,
        'active': active,
        'audience': audience,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'viewCount': viewCount,
        'salesCount': salesCount,
        'popularityScore': popularityScore,
      };

  @override
  List<Object?> get props => [
        id,
        merchantId,
        ownerUid,
        titleAr,
        description,
        priceEgp,
        imageUrl,
        active,
        updatedAtMs,
        audience,
        viewCount,
        salesCount,
        popularityScore,
      ];
}

import 'package:equatable/equatable.dart';

/// تاجر داخل سوق زملكاوي.
class MarketplaceMerchant extends Equatable {
  const MarketplaceMerchant({
    required this.id,
    required this.ownerUid,
    required this.nameAr,
    required this.slug,
    required this.bio,
    required this.coverUrl,
    required this.logoUrl,
    required this.audienceScore,
    required this.createdAtMs,
    this.appSource,
  });

  final String id;
  final String ownerUid;
  final String nameAr;
  final String slug;
  final String bio;
  final String coverUrl;
  final String logoUrl;

  /// كلما زاد الرقم ظهر المتجر أقرب لمقدمة السوق (متابعون/تفاعل/ترتيب إداري).
  final int audienceScore;
  final int createdAtMs;

  /// `gomhor_ahly` | `zamalekawy` | `ahly` | `zamalek` — لعرض شارة النادي بجانب التاجر.
  final String? appSource;

  bool get hasCover => coverUrl.isNotEmpty;
  bool get hasLogo => logoUrl.isNotEmpty;

  factory MarketplaceMerchant.fromMap(String id, Map<dynamic, dynamic> map) {
    return MarketplaceMerchant(
      id: id,
      ownerUid: map['ownerUid'] as String? ?? '',
      nameAr: map['nameAr'] as String? ?? 'متجر',
      slug: (map['slug'] as String? ?? '').trim(),
      bio: map['bio'] as String? ?? '',
      coverUrl: map['coverUrl'] as String? ?? '',
      logoUrl: map['logoUrl'] as String? ?? '',
      audienceScore: (map['audienceScore'] as num?)?.toInt() ?? 0,
      createdAtMs: (map['createdAt'] as num?)?.toInt() ??
          (map['createdAtMs'] as num?)?.toInt() ??
          0,
      appSource: _parseAppSource(map),
    );
  }

  static String? _parseAppSource(Map<dynamic, dynamic> map) {
    for (final key in ['appSource', 'app_source', 'clubTag', 'club_tag']) {
      final v = map[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        ownerUid,
        nameAr,
        slug,
        bio,
        coverUrl,
        logoUrl,
        audienceScore,
        createdAtMs,
        appSource,
      ];
}

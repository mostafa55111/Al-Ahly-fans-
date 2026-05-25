import 'package:equatable/equatable.dart';

/// لاعب من مسار [best_player] في Realtime Database.
///
/// **شكل العقدة في RTDB:**
/// ```
/// best_player/
///   player1/
///     name, cardUrl, votes
///     cardType: gold | silver | special
///     active: true|false
///     power: (اختياري) طاقة/تقييم للعرض
/// ```
class PastPlayerDto extends Equatable {
  final String id;
  final String name;

  /// رابط كارت اللاعب المصمَّم (FIFA-style).
  final String? cardUrl;

  final int? number;
  final String? position;
  final int? sort;

  /// عدد الأصوات التراكمي — نسر المباراة.
  final int votes;

  /// نوع الكارت: ذهبي، فضي، خاص.
  final String cardType;

  /// `false` يخفي الكارت عن واجهة الجمهور (الإدارة تظل تراه).
  final bool active;

  /// طاقة/مستوى اختياري للعرض في الواجهات.
  final int? power;

  /// فهرس مركز التشكيلة على الملعب (0–10)، يُخزَّن في RTDB.
  final int? slotIndex;

  /// موضع أفقي معيّن (0–1) على الملعب، اختياري فوق مركز الفورمة.
  final double? pitchNx;

  /// موضع عمودي معيّن (0–1) على الملعب.
  final double? pitchNy;

  /// مصغّر اختياري لقائمة/إدارة.
  final String? cardThumbnailUrl;
  final String? cardStyle;
  final String? cardRarity;
  final String? cardAnimatedOverlay;
  final String? cardTheme;
  /// `true` عندما يكون [cardUrl] من `cardImageUrl` في تصويت الملعب — لا نرسم طبقات تغطي التصميم.
  final bool matchVoteDesignedCard;

  /// Overlay متحرك (Lottie / GIF / WebP …) فوق الكرت.
  final String? cardOverlayAssetUrl;
  final bool cardOverlayEnabled;
  final String? cardOverlayBlend;
  final double? cardOverlayOpacity;

  const PastPlayerDto({
    required this.id,
    required this.name,
    this.cardUrl,
    this.number,
    this.position,
    this.sort,
    this.votes = 0,
    this.cardType = 'gold',
    this.active = true,
    this.power,
    this.slotIndex,
    this.pitchNx,
    this.pitchNy,
    this.cardThumbnailUrl,
    this.cardStyle,
    this.cardRarity,
    this.cardAnimatedOverlay,
    this.cardTheme,
    this.matchVoteDesignedCard = false,
    this.cardOverlayAssetUrl,
    this.cardOverlayEnabled = true,
    this.cardOverlayBlend,
    this.cardOverlayOpacity,
  });

  String? get photoUrl => cardUrl;

  bool get isActive => active;

  factory PastPlayerDto.fromMap(String id, Map<dynamic, dynamic> m) {
    final card = (m['cardUrl'] ?? m['photoUrl'] ?? m['image'])?.toString();
    final v = m['votes'];
    final votesInt = v is int
        ? v
        : (v is num ? v.toInt() : int.tryParse('${v ?? 0}') ?? 0);

    final ct = (m['cardType'] ?? 'gold').toString().toLowerCase().trim();
    final activeRaw = m['active'];
    final isActive =
        activeRaw == null ? true : (activeRaw == true || activeRaw == 1);

    final pow = m['power'];
    final powerInt = pow is int
        ? pow
        : (pow is num ? pow.toInt() : int.tryParse('${pow ?? ''}'));

    final si = m['slotIndex'];
    final slotIdx = si is int
        ? si
        : (si is num ? si.toInt() : int.tryParse('${si ?? ''}'));
    final nxRaw = m['pitchNx'];
    final nyRaw = m['pitchNy'];
    final pitchNx = nxRaw is num ? nxRaw.toDouble() : double.tryParse('${nxRaw ?? ''}');
    final pitchNy = nyRaw is num ? nyRaw.toDouble() : double.tryParse('${nyRaw ?? ''}');

    return PastPlayerDto(
      id: id,
      name: (m['name'] ?? m['arName'] ?? 'لاعب').toString(),
      cardUrl: (card != null && card.isNotEmpty) ? card : null,
      number: m['number'] is int
          ? m['number'] as int
          : int.tryParse('${m['number'] ?? ''}'),
      position: m['position']?.toString(),
      sort: m['sort'] is int
          ? m['sort'] as int
          : int.tryParse('${m['sort'] ?? 0}'),
      votes: votesInt,
      cardType: ct.isEmpty ? 'gold' : ct,
      active: isActive,
      power: powerInt,
      slotIndex: slotIdx != null && slotIdx >= 0 && slotIdx < 11 ? slotIdx : null,
      pitchNx: pitchNx,
      pitchNy: pitchNy,
      cardThumbnailUrl: m['cardThumbnailUrl']?.toString(),
      cardStyle: m['cardStyle']?.toString(),
      cardRarity: m['cardRarity']?.toString(),
      cardAnimatedOverlay: m['cardAnimatedOverlay']?.toString(),
      cardTheme: m['cardTheme']?.toString(),
      matchVoteDesignedCard: m['matchVoteDesignedCard'] == true || m['matchVoteDesignedCard'] == 1,
      cardOverlayAssetUrl: m['cardOverlayAssetUrl']?.toString(),
      cardOverlayEnabled: m['cardOverlayEnabled'] == null
          ? true
          : (m['cardOverlayEnabled'] == true || m['cardOverlayEnabled'] == 1),
      cardOverlayBlend: m['cardOverlayBlend']?.toString(),
      cardOverlayOpacity: (m['cardOverlayOpacity'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'cardUrl': cardUrl,
      if (number != null) 'number': number,
      if (position != null) 'position': position,
      if (sort != null) 'sort': sort,
      'votes': votes,
      'cardType': cardType,
      'active': active,
      if (power != null) 'power': power,
      if (slotIndex != null) 'slotIndex': slotIndex,
      if (pitchNx != null) 'pitchNx': pitchNx,
      if (pitchNy != null) 'pitchNy': pitchNy,
      if (cardThumbnailUrl != null) 'cardThumbnailUrl': cardThumbnailUrl,
      if (cardStyle != null) 'cardStyle': cardStyle,
      if (cardRarity != null) 'cardRarity': cardRarity,
      if (cardAnimatedOverlay != null) 'cardAnimatedOverlay': cardAnimatedOverlay,
      if (cardTheme != null) 'cardTheme': cardTheme,
      'matchVoteDesignedCard': matchVoteDesignedCard,
      if (cardOverlayAssetUrl != null) 'cardOverlayAssetUrl': cardOverlayAssetUrl,
      'cardOverlayEnabled': cardOverlayEnabled,
      if (cardOverlayBlend != null) 'cardOverlayBlend': cardOverlayBlend,
      if (cardOverlayOpacity != null) 'cardOverlayOpacity': cardOverlayOpacity,
    };
  }

  PastPlayerDto copyWith({
    String? id,
    String? name,
    String? cardUrl,
    int? number,
    String? position,
    int? sort,
    int? votes,
    String? cardType,
    bool? active,
    int? power,
    int? slotIndex,
    double? pitchNx,
    double? pitchNy,
    String? cardThumbnailUrl,
    String? cardStyle,
    String? cardRarity,
    String? cardAnimatedOverlay,
    String? cardTheme,
    bool? matchVoteDesignedCard,
    String? cardOverlayAssetUrl,
    bool? cardOverlayEnabled,
    String? cardOverlayBlend,
    double? cardOverlayOpacity,
    bool clearSlotIndex = false,
    bool clearPitch = false,
  }) {
    return PastPlayerDto(
      id: id ?? this.id,
      name: name ?? this.name,
      cardUrl: cardUrl ?? this.cardUrl,
      number: number ?? this.number,
      position: position ?? this.position,
      sort: sort ?? this.sort,
      votes: votes ?? this.votes,
      cardType: cardType ?? this.cardType,
      active: active ?? this.active,
      power: power ?? this.power,
      slotIndex: clearSlotIndex ? null : (slotIndex ?? this.slotIndex),
      pitchNx: clearPitch ? null : (pitchNx ?? this.pitchNx),
      pitchNy: clearPitch ? null : (pitchNy ?? this.pitchNy),
      cardThumbnailUrl: cardThumbnailUrl ?? this.cardThumbnailUrl,
      cardStyle: cardStyle ?? this.cardStyle,
      cardRarity: cardRarity ?? this.cardRarity,
      cardAnimatedOverlay: cardAnimatedOverlay ?? this.cardAnimatedOverlay,
      cardTheme: cardTheme ?? this.cardTheme,
      matchVoteDesignedCard: matchVoteDesignedCard ?? this.matchVoteDesignedCard,
      cardOverlayAssetUrl: cardOverlayAssetUrl ?? this.cardOverlayAssetUrl,
      cardOverlayEnabled: cardOverlayEnabled ?? this.cardOverlayEnabled,
      cardOverlayBlend: cardOverlayBlend ?? this.cardOverlayBlend,
      cardOverlayOpacity: cardOverlayOpacity ?? this.cardOverlayOpacity,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        cardUrl,
        number,
        position,
        sort,
        votes,
        cardType,
        active,
        power,
        slotIndex,
        pitchNx,
        pitchNy,
        cardThumbnailUrl,
        cardStyle,
        cardRarity,
        cardAnimatedOverlay,
        cardTheme,
        matchVoteDesignedCard,
        cardOverlayAssetUrl,
        cardOverlayEnabled,
        cardOverlayBlend,
        cardOverlayOpacity,
      ];
}

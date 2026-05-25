import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';

/// بيانات `active_match` في RTDB.
class MatchActiveSession extends Equatable {
  const MatchActiveSession({
    required this.id,
    required this.title,
    required this.votingEnabled,
    required this.formation,
    required this.createdAt,
    this.opponent = '',
    this.sessionType = 'league',
    this.closesAt = 0,
    this.openedAtServer = 0,
    this.closesAtServer = 0,
    this.closedAtServer = 0,
    this.status = 'open',
    this.awardsFinalized = false,
    this.fxLevel = 'warm',
    this.crowdProfile = 'standard',
    this.stadiumTheme = 'default',
    this.voteSharding = false,
    this.voteShardCount = 32,
    this.votingFrozen = false,
  });

  final String id;
  final String title;
  final bool votingEnabled;
  final String formation;
  final int createdAt;

  /// منافس / عنوان فرعي للجلسة (اختياري — CMS).
  final String opponent;

  /// نوع الجلسة: league | cup | friendly | other
  final String sessionType;

  /// وقت إغلاق التصويت (epoch ms)، 0 = غير محدد — توافق قديم.
  final int closesAt;

  /// طوابع خادم Firebase (ms بعد القراءة).
  final int openedAtServer;
  final int closesAtServer;
  final int closedAtServer;

  /// open | closed
  final String status;

  /// منع تكرار لقطة الجائزة.
  final bool awardsFinalized;

  /// بروفايل CMS — calm | warm | hot | inferno
  final String fxLevel;
  final String crowdProfile;
  final String stadiumTheme;

  /// عند true: الأصوات تُكتب في `match_vote_shards/` وليس `players/*/votes`.
  final bool voteSharding;

  /// عدد الشاردات (افتراضي 32).
  final int voteShardCount;

  /// إيقاف طوارئ لاستقبال أصوات جديدة (المالك فقط).
  final bool votingFrozen;

  bool get usesShardedVotes => voteSharding;

  factory MatchActiveSession.fromMap(Map<dynamic, dynamic> m) {
    return MatchActiveSession(
      id: m['id']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      votingEnabled: m['votingEnabled'] == true || m['votingEnabled'] == 1,
      formation: m['formation']?.toString() ?? '4-3-3',
      createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
      opponent: m['opponent']?.toString() ?? '',
      sessionType: m['sessionType']?.toString() ?? 'league',
      closesAt: (m['closesAt'] as num?)?.toInt() ?? 0,
      openedAtServer: (m['openedAtServer'] as num?)?.toInt() ?? 0,
      closesAtServer: (m['closesAtServer'] as num?)?.toInt() ?? 0,
      closedAtServer: (m['closedAtServer'] as num?)?.toInt() ?? 0,
      status: m['status']?.toString() ?? 'open',
      awardsFinalized:
          m['awardsFinalized'] == true || m['awardsFinalized'] == 1,
      fxLevel: m['fxLevel']?.toString() ?? 'warm',
      crowdProfile: m['crowdProfile']?.toString() ?? 'standard',
      stadiumTheme: m['stadiumTheme']?.toString() ?? 'default',
      voteSharding:
          m['voteSharding'] == true || m['voteSharding'] == 1,
      voteShardCount: (m['voteShardCount'] as num?)?.toInt() ?? 32,
      votingFrozen: m['votingFrozen'] == true || m['votingFrozen'] == 1,
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'id': id,
        'title': title,
        'votingEnabled': votingEnabled,
        'formation': formation,
        'createdAt': createdAt,
        'opponent': opponent,
        'sessionType': sessionType,
        'closesAt': closesAt,
        'openedAtServer': openedAtServer,
        'closesAtServer': closesAtServer,
        'closedAtServer': closedAtServer,
        'status': status,
        'awardsFinalized': awardsFinalized,
        'fxLevel': fxLevel,
        'crowdProfile': crowdProfile,
        'stadiumTheme': stadiumTheme,
        'voteSharding': voteSharding,
        'voteShardCount': voteShardCount,
        'votingFrozen': votingFrozen,
      };

  MatchActiveSession copyWith({
    String? id,
    String? title,
    bool? votingEnabled,
    String? formation,
    int? createdAt,
    String? opponent,
    String? sessionType,
    int? closesAt,
    int? openedAtServer,
    int? closesAtServer,
    int? closedAtServer,
    String? status,
    bool? awardsFinalized,
    String? fxLevel,
    String? crowdProfile,
    String? stadiumTheme,
    bool? voteSharding,
    int? voteShardCount,
    bool? votingFrozen,
  }) {
    return MatchActiveSession(
      id: id ?? this.id,
      title: title ?? this.title,
      votingEnabled: votingEnabled ?? this.votingEnabled,
      formation: formation ?? this.formation,
      createdAt: createdAt ?? this.createdAt,
      opponent: opponent ?? this.opponent,
      sessionType: sessionType ?? this.sessionType,
      closesAt: closesAt ?? this.closesAt,
      openedAtServer: openedAtServer ?? this.openedAtServer,
      closesAtServer: closesAtServer ?? this.closesAtServer,
      closedAtServer: closedAtServer ?? this.closedAtServer,
      status: status ?? this.status,
      awardsFinalized: awardsFinalized ?? this.awardsFinalized,
      fxLevel: fxLevel ?? this.fxLevel,
      crowdProfile: crowdProfile ?? this.crowdProfile,
      stadiumTheme: stadiumTheme ?? this.stadiumTheme,
      voteSharding: voteSharding ?? this.voteSharding,
      voteShardCount: voteShardCount ?? this.voteShardCount,
      votingFrozen: votingFrozen ?? this.votingFrozen,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        votingEnabled,
        votingFrozen,
        formation,
        createdAt,
        opponent,
        sessionType,
        closesAt,
        openedAtServer,
        closesAtServer,
        closedAtServer,
        status,
        awardsFinalized,
        fxLevel,
        crowdProfile,
        stadiumTheme,
        voteSharding,
        voteShardCount,
      ];

  /// إغلاق نهائي حسب خادم Firebase — لا [DateTime.now] للقرار.
  int get effectiveClosesAtServer =>
      closesAtServer > 0 ? closesAtServer : closesAt;

  int get effectiveOpenedAtServer =>
      openedAtServer > 0 ? openedAtServer : createdAt;

  bool isClosedByStatus(int serverNowMs) {
    if (status == 'closed' || awardsFinalized) return true;
    final end = effectiveClosesAtServer;
    return end > 0 && serverNowMs >= end;
  }
}

/// لاعب على الملعب — يُحوَّل إلى [PastPlayerDto] لعرض [FifaCardWidget].
///
/// الكرت المصمَّم يدوياً: [cardImageUrl] (PNG/WebP). [imageUrl] يبقى للتوافق مع البيانات القديمة.
class MatchPitchPlayer extends Equatable {
  const MatchPitchPlayer({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.position,
    required this.x,
    required this.y,
    required this.votes,
    required this.team,
    required this.glowColor,
    this.visible = true,
    this.highlighted = false,
    this.cardImageUrl = '',
    this.cardThumbnailUrl = '',
    this.cardStyle = '',
    this.cardRarity = '',
    this.cardAnimatedOverlay = '',
    this.cardTheme = '',
    this.cardOverlayAssetUrl = '',
    this.cardOverlayEnabled = true,
    this.cardOverlayBlend = 'screen',
    this.cardOverlayOpacity = 0.88,
  });

  final String id;
  final String name;
  /// صورة قديمة / مساعدة — إن وُجد [cardImageUrl] يُفضَّل للعرض على الملعب.
  final String imageUrl;
  final int rating;
  final String position;
  final double x;
  final double y;
  final int votes;
  final String team;
  final String glowColor;
  final bool visible;
  final bool highlighted;

  /// رابط صورة الكرت النهائية الجاهزة (يدوي من الأدمن).
  final String cardImageUrl;
  final String cardThumbnailUrl;
  final String cardStyle;
  final String cardRarity;
  /// معرف أو URL لطبقة متحركة اختيارية فوق الـ FX (لا يُرسم الكرت هنا).
  final String cardAnimatedOverlay;
  final String cardTheme;

  /// طبقة overlay متحركة (Lottie / GIF / WebP …) فوق الكرت — اختياري.
  final String cardOverlayAssetUrl;
  final bool cardOverlayEnabled;
  final String cardOverlayBlend;
  final double cardOverlayOpacity;

  String get displayCardImageUrl {
    final c = cardImageUrl.trim();
    if (c.isNotEmpty) return c;
    return imageUrl.trim();
  }

  PastPlayerDto toPastPlayerDto() {
    final url = displayCardImageUrl;
    final designed = cardImageUrl.trim().isNotEmpty;
    return PastPlayerDto(
      id: id,
      name: name,
      cardUrl: url.isEmpty ? null : url,
      votes: votes,
      position: position.isEmpty ? null : position,
      power: rating,
      pitchNx: x.clamp(0.0, 1.0),
      pitchNy: y.clamp(0.0, 1.0),
      cardThumbnailUrl: cardThumbnailUrl.trim().isEmpty ? null : cardThumbnailUrl.trim(),
      cardStyle: cardStyle.trim().isEmpty ? null : cardStyle.trim(),
      cardRarity: cardRarity.trim().isEmpty ? null : cardRarity.trim(),
      cardAnimatedOverlay: cardAnimatedOverlay.trim().isEmpty ? null : cardAnimatedOverlay.trim(),
      cardTheme: cardTheme.trim().isEmpty ? null : cardTheme.trim(),
      matchVoteDesignedCard: designed,
      cardOverlayAssetUrl: cardOverlayAssetUrl.trim().isEmpty ? null : cardOverlayAssetUrl.trim(),
      cardOverlayEnabled: cardOverlayEnabled,
      cardOverlayBlend: cardOverlayBlend.trim().isEmpty ? null : cardOverlayBlend.trim(),
      cardOverlayOpacity: cardOverlayOpacity,
    );
  }

  factory MatchPitchPlayer.fromMap(String id, Map<dynamic, dynamic> m) {
    return MatchPitchPlayer(
      id: id,
      name: m['name']?.toString() ?? '',
      imageUrl: m['imageUrl']?.toString() ?? '',
      rating: (m['rating'] as num?)?.toInt() ?? 0,
      position: m['position']?.toString() ?? '',
      x: (m['x'] as num?)?.toDouble() ?? 0.5,
      y: (m['y'] as num?)?.toDouble() ?? 0.5,
      votes: (m['votes'] as num?)?.toInt() ?? 0,
      team: m['team']?.toString() ?? '',
      glowColor: m['glowColor']?.toString() ?? 'gold',
      visible: m['visible'] == null ? true : (m['visible'] == true || m['visible'] == 1),
      highlighted: m['highlighted'] == true || m['highlighted'] == 1,
      cardImageUrl: m['cardImageUrl']?.toString() ?? '',
      cardThumbnailUrl: m['cardThumbnailUrl']?.toString() ?? '',
      cardStyle: m['cardStyle']?.toString() ?? '',
      cardRarity: m['cardRarity']?.toString() ?? '',
      cardAnimatedOverlay: m['cardAnimatedOverlay']?.toString() ?? '',
      cardTheme: m['cardTheme']?.toString() ?? '',
      cardOverlayAssetUrl: m['cardOverlayAssetUrl']?.toString() ?? '',
      cardOverlayEnabled: m['cardOverlayEnabled'] == null
          ? true
          : (m['cardOverlayEnabled'] == true || m['cardOverlayEnabled'] == 1),
      cardOverlayBlend: m['cardOverlayBlend']?.toString() ?? 'screen',
      cardOverlayOpacity: (m['cardOverlayOpacity'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.88,
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'id': id,
        'name': name,
        'imageUrl': imageUrl,
        'rating': rating,
        'position': position,
        'x': x,
        'y': y,
        'votes': votes,
        'team': team,
        'glowColor': glowColor,
        'visible': visible,
        'highlighted': highlighted,
        'cardImageUrl': cardImageUrl,
        'cardThumbnailUrl': cardThumbnailUrl,
        'cardStyle': cardStyle,
        'cardRarity': cardRarity,
        'cardAnimatedOverlay': cardAnimatedOverlay,
        'cardTheme': cardTheme,
        'cardOverlayAssetUrl': cardOverlayAssetUrl,
        'cardOverlayEnabled': cardOverlayEnabled,
        'cardOverlayBlend': cardOverlayBlend,
        'cardOverlayOpacity': cardOverlayOpacity,
      };

  MatchPitchPlayer copyWith({
    String? name,
    String? imageUrl,
    int? rating,
    String? position,
    double? x,
    double? y,
    int? votes,
    String? team,
    String? glowColor,
    bool? visible,
    bool? highlighted,
    String? cardImageUrl,
    String? cardThumbnailUrl,
    String? cardStyle,
    String? cardRarity,
    String? cardAnimatedOverlay,
    String? cardTheme,
    String? cardOverlayAssetUrl,
    bool? cardOverlayEnabled,
    String? cardOverlayBlend,
    double? cardOverlayOpacity,
  }) {
    return MatchPitchPlayer(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      position: position ?? this.position,
      x: x ?? this.x,
      y: y ?? this.y,
      votes: votes ?? this.votes,
      team: team ?? this.team,
      glowColor: glowColor ?? this.glowColor,
      visible: visible ?? this.visible,
      highlighted: highlighted ?? this.highlighted,
      cardImageUrl: cardImageUrl ?? this.cardImageUrl,
      cardThumbnailUrl: cardThumbnailUrl ?? this.cardThumbnailUrl,
      cardStyle: cardStyle ?? this.cardStyle,
      cardRarity: cardRarity ?? this.cardRarity,
      cardAnimatedOverlay: cardAnimatedOverlay ?? this.cardAnimatedOverlay,
      cardTheme: cardTheme ?? this.cardTheme,
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
        imageUrl,
        rating,
        position,
        x,
        y,
        votes,
        team,
        glowColor,
        visible,
        highlighted,
        cardImageUrl,
        cardThumbnailUrl,
        cardStyle,
        cardRarity,
        cardAnimatedOverlay,
        cardTheme,
        cardOverlayAssetUrl,
        cardOverlayEnabled,
        cardOverlayBlend,
        cardOverlayOpacity,
      ];
}

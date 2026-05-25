import 'package:equatable/equatable.dart';

/// عنصر في مكتبة الكروت الخفيفة.
class StadiumCardRegistryEntry extends Equatable {
  const StadiumCardRegistryEntry({
    required this.id,
    required this.playerName,
    required this.imageUrl,
    this.thumbUrl = '',
    this.rarity = '',
    this.tags = const [],
    this.createdAt = 0,
    this.favorite = false,
    this.lastUsedAt = 0,
    this.useCount = 0,
    this.club = '',
    this.uploadedBy = '',
    this.clubScope = '',
    this.sourceEnvironment = '',
    this.archivedAt = 0,
  });

  final String id;
  final String playerName;
  final String imageUrl;
  final String thumbUrl;
  final String rarity;
  final List<String> tags;
  final int createdAt;
  final bool favorite;
  final int lastUsedAt;
  final int useCount;

  /// فلتر نادي/مصدر — يُخزَّن كوسم أو حقل صريح.
  final String club;

  final String uploadedBy;
  final String clubScope;
  final String sourceEnvironment;
  final int archivedAt;

  bool get isArchived => archivedAt > 0;

  factory StadiumCardRegistryEntry.fromMap(String id, Map<dynamic, dynamic> m) {
    final rawTags = m['tags'];
    List<String> parsed = const [];
    if (rawTags is List) {
      parsed = rawTags.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    } else if (rawTags is String && rawTags.trim().isNotEmpty) {
      parsed = rawTags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return StadiumCardRegistryEntry(
      id: id,
      playerName: m['playerName']?.toString() ?? '',
      imageUrl: m['imageUrl']?.toString() ?? '',
      thumbUrl: m['thumbUrl']?.toString() ?? '',
      rarity: m['rarity']?.toString() ?? '',
      tags: parsed,
      createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
      favorite: m['favorite'] == true || m['favorite'] == 1,
      lastUsedAt: (m['lastUsedAt'] as num?)?.toInt() ?? 0,
      useCount: (m['useCount'] as num?)?.toInt() ?? 0,
      club: m['club']?.toString() ?? '',
      uploadedBy: m['uploadedBy']?.toString() ?? '',
      clubScope: m['clubScope']?.toString() ?? m['club']?.toString() ?? '',
      sourceEnvironment: m['sourceEnvironment']?.toString() ?? '',
      archivedAt: (m['archivedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'playerName': playerName,
        'imageUrl': imageUrl,
        'thumbUrl': thumbUrl,
        'rarity': rarity,
        'tags': tags,
        'createdAt': createdAt,
        'favorite': favorite,
        'lastUsedAt': lastUsedAt,
        'useCount': useCount,
        'club': club,
        'uploadedBy': uploadedBy,
        'clubScope': clubScope.isEmpty ? club : clubScope,
        'sourceEnvironment': sourceEnvironment,
        'archivedAt': archivedAt,
      };

  StadiumCardRegistryEntry copyWith({
    String? playerName,
    String? imageUrl,
    String? thumbUrl,
    String? rarity,
    List<String>? tags,
    int? createdAt,
    bool? favorite,
    int? lastUsedAt,
    int? useCount,
    String? club,
    String? uploadedBy,
    String? clubScope,
    String? sourceEnvironment,
    int? archivedAt,
  }) {
    return StadiumCardRegistryEntry(
      id: id,
      playerName: playerName ?? this.playerName,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      rarity: rarity ?? this.rarity,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      favorite: favorite ?? this.favorite,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      useCount: useCount ?? this.useCount,
      club: club ?? this.club,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      clubScope: clubScope ?? this.clubScope,
      sourceEnvironment: sourceEnvironment ?? this.sourceEnvironment,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        playerName,
        imageUrl,
        thumbUrl,
        rarity,
        tags,
        createdAt,
        favorite,
        lastUsedAt,
        useCount,
        club,
        uploadedBy,
        clubScope,
        sourceEnvironment,
        archivedAt,
      ];
}

/// فلاتر مكتبة الكروت.
enum StadiumCardLibraryFilter {
  all,
  favorites,
  recent,
  lastUsed,
  /// كروت مؤرشفة (حذف ناعم — استرجاع خلال 7 أيام).
  archived,
}

const stadiumCardRarities = ['common', 'rare', 'epic', 'legendary', 'mythic'];

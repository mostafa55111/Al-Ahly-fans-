import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';

/// كرت مستودع المالك — معزول لكل تطبيق.
class OwnerCardRecord extends Equatable {
  const OwnerCardRecord({
    required this.id,
    required this.playerName,
    required this.playerNumber,
    required this.position,
    required this.imageUrl,
    this.thumbnailUrl = '',
    this.dominantColor = '',
    this.createdAtServer = 0,
    this.ownerUid = '',
    this.appId = '',
    this.archivedAt = 0,
  });

  final String id;
  final String playerName;
  final int playerNumber;
  final String position;
  final String imageUrl;
  final String thumbnailUrl;
  final String dominantColor;
  final int createdAtServer;
  final String ownerUid;
  final String appId;
  final int archivedAt;

  bool get isArchived => archivedAt > 0;

  String get positionGroup => OwnerCardPositionGroups.groupFor(position);

  factory OwnerCardRecord.fromMap(String id, Map<dynamic, dynamic> m) {
    return OwnerCardRecord(
      id: id,
      playerName: m['playerName']?.toString() ?? '',
      playerNumber: (m['playerNumber'] as num?)?.toInt() ?? 0,
      position: m['position']?.toString().toUpperCase() ?? '',
      imageUrl: m['imageUrl']?.toString() ?? '',
      thumbnailUrl: m['thumbnailUrl']?.toString() ?? m['thumbUrl']?.toString() ?? '',
      dominantColor: m['dominantColor']?.toString() ?? '',
      createdAtServer: (m['createdAtServer'] as num?)?.toInt() ??
          (m['createdAt'] as num?)?.toInt() ??
          0,
      ownerUid: m['ownerUid']?.toString() ?? m['uploadedBy']?.toString() ?? '',
      appId: m['appId']?.toString() ?? m['clubScope']?.toString() ?? '',
      archivedAt: (m['archivedAt'] as num?)?.toInt() ?? 0,
    );
  }

  factory OwnerCardRecord.fromRegistry(StadiumCardRegistryEntry e, String appId) {
    var number = 0;
    var position = '';
    for (final t in e.tags) {
      if (t.startsWith('no:')) {
        number = int.tryParse(t.substring(3)) ?? number;
      } else if (t.startsWith('pos:')) {
        position = t.substring(4).toUpperCase();
      } else if (position.isEmpty && t.length <= 4) {
        position = t.toUpperCase();
      }
    }
    if (position.isEmpty && e.rarity.isNotEmpty) {
      position = e.rarity.toUpperCase();
    }
    return OwnerCardRecord(
      id: e.id,
      playerName: e.playerName,
      playerNumber: number,
      position: position,
      imageUrl: e.imageUrl,
      thumbnailUrl: e.thumbUrl,
      createdAtServer: e.createdAt,
      ownerUid: e.uploadedBy,
      appId: appId,
      archivedAt: e.archivedAt,
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'playerName': playerName,
        'playerNumber': playerNumber,
        'position': position,
        'imageUrl': imageUrl,
        'thumbnailUrl': thumbnailUrl,
        'thumbUrl': thumbnailUrl,
        'dominantColor': dominantColor,
        'createdAtServer': createdAtServer,
        'createdAt': createdAtServer,
        'ownerUid': ownerUid,
        'uploadedBy': ownerUid,
        'appId': appId,
        'clubScope': appId,
        'archivedAt': archivedAt,
      };

  StadiumCardRegistryEntry toRegistryEntry() {
    final tags = <String>[
      if (position.isNotEmpty) 'pos:$position',
      if (playerNumber > 0) 'no:$playerNumber',
    ];
    return StadiumCardRegistryEntry(
      id: id,
      playerName: playerName,
      imageUrl: imageUrl,
      thumbUrl: thumbnailUrl,
      rarity: position,
      tags: tags,
      createdAt: createdAtServer,
      club: appId,
      uploadedBy: ownerUid,
      clubScope: appId,
      archivedAt: archivedAt,
    );
  }

  OwnerCardRecord copyWith({
    String? playerName,
    int? playerNumber,
    String? position,
    String? imageUrl,
    String? thumbnailUrl,
    String? dominantColor,
    int? createdAtServer,
    int? archivedAt,
  }) {
    return OwnerCardRecord(
      id: id,
      playerName: playerName ?? this.playerName,
      playerNumber: playerNumber ?? this.playerNumber,
      position: position ?? this.position,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      dominantColor: dominantColor ?? this.dominantColor,
      createdAtServer: createdAtServer ?? this.createdAtServer,
      ownerUid: ownerUid,
      appId: appId,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  bool matchesApp(String appId) =>
      appId.isEmpty || this.appId.isEmpty || this.appId == appId;

  @override
  List<Object?> get props => [id, playerName, playerNumber, position, imageUrl];
}

abstract final class OwnerCardPositionGroups {
  static const gk = 'GK';
  static const def = 'DEF';
  static const mid = 'MID';
  static const att = 'ATT';

  static String groupFor(String position) {
    final p = position.trim().toUpperCase();
    if (p.contains('GK') || p.contains('حارس')) return gk;
    if (p.contains('DEF') ||
        p.contains('CB') ||
        p.contains('LB') ||
        p.contains('RB') ||
        p.contains('مدافع')) {
      return def;
    }
    if (p.contains('MID') ||
        p.contains('CM') ||
        p.contains('DM') ||
        p.contains('AM') ||
        p.contains('وسط')) {
      return mid;
    }
    if (p.contains('ATT') ||
        p.contains('ST') ||
        p.contains('LW') ||
        p.contains('RW') ||
        p.contains('مهاجم')) {
      return att;
    }
    return mid;
  }

  static String labelAr(String group) => switch (group) {
        gk => 'حراس المرمى',
        def => 'المدافعون',
        mid => 'لاعبو الوسط',
        att => 'المهاجمون',
        _ => 'أخرى',
      };
}

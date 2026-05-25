import 'package:equatable/equatable.dart';

/// لاعب في تشكيلة محفوظة / قالب — مرجع لمكتبة الكروت.
class StadiumLineupSlot extends Equatable {
  const StadiumLineupSlot({
    this.registryCardId = '',
    required this.playerName,
    required this.imageUrl,
    this.thumbUrl = '',
    this.position = 'CM',
    this.rarity = '',
    this.tags = const [],
  });

  final String registryCardId;
  final String playerName;
  final String imageUrl;
  final String thumbUrl;
  final String position;
  final String rarity;
  final List<String> tags;

  factory StadiumLineupSlot.fromMap(Map<dynamic, dynamic> m) {
    final rawTags = m['tags'];
    List<String> parsed = const [];
    if (rawTags is List) {
      parsed = rawTags.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return StadiumLineupSlot(
      registryCardId: m['registryCardId']?.toString() ?? '',
      playerName: m['playerName']?.toString() ?? '',
      imageUrl: m['imageUrl']?.toString() ?? '',
      thumbUrl: m['thumbUrl']?.toString() ?? '',
      position: m['position']?.toString() ?? 'CM',
      rarity: m['rarity']?.toString() ?? '',
      tags: parsed,
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'registryCardId': registryCardId,
        'playerName': playerName,
        'imageUrl': imageUrl,
        'thumbUrl': thumbUrl,
        'position': position,
        'rarity': rarity,
        'tags': tags,
      };

  StadiumLineupSlot copyFromRegistry({
    required String registryCardId,
    required String playerName,
    required String imageUrl,
    String thumbUrl = '',
    String position = 'CM',
    String rarity = '',
    List<String> tags = const [],
  }) {
    return StadiumLineupSlot(
      registryCardId: registryCardId,
      playerName: playerName,
      imageUrl: imageUrl,
      thumbUrl: thumbUrl,
      position: position,
      rarity: rarity,
      tags: tags,
    );
  }

  @override
  List<Object?> get props =>
      [registryCardId, playerName, imageUrl, thumbUrl, position, rarity, tags];
}

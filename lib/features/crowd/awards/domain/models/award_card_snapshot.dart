import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

/// نسخة ثابتة من كرت اللاعب وقت الجائزة — لا تعتمد على `players/` لاحقاً.
class AwardCardSnapshot extends Equatable {
  const AwardCardSnapshot({
    required this.playerId,
    required this.name,
    this.imageUrl = '',
    this.rating = 0,
    this.position = '',
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
    this.glowColor = 'gold',
  });

  final String playerId;
  final String name;
  final String imageUrl;
  final int rating;
  final String position;
  final String cardImageUrl;
  final String cardThumbnailUrl;
  final String cardStyle;
  final String cardRarity;
  final String cardAnimatedOverlay;
  final String cardTheme;
  final String cardOverlayAssetUrl;
  final bool cardOverlayEnabled;
  final String cardOverlayBlend;
  final double cardOverlayOpacity;
  final String glowColor;

  factory AwardCardSnapshot.fromPlayer(MatchPitchPlayer p) {
    return AwardCardSnapshot(
      playerId: p.id,
      name: p.name,
      imageUrl: p.imageUrl,
      rating: p.rating,
      position: p.position,
      cardImageUrl: p.cardImageUrl,
      cardThumbnailUrl: p.cardThumbnailUrl,
      cardStyle: p.cardStyle,
      cardRarity: p.cardRarity,
      cardAnimatedOverlay: p.cardAnimatedOverlay,
      cardTheme: p.cardTheme,
      cardOverlayAssetUrl: p.cardOverlayAssetUrl,
      cardOverlayEnabled: p.cardOverlayEnabled,
      cardOverlayBlend: p.cardOverlayBlend,
      cardOverlayOpacity: p.cardOverlayOpacity,
      glowColor: p.glowColor,
    );
  }

  factory AwardCardSnapshot.fromMap(Map<dynamic, dynamic> m) {
    return AwardCardSnapshot(
      playerId: m['playerId']?.toString() ?? m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      imageUrl: m['imageUrl']?.toString() ?? '',
      rating: (m['rating'] as num?)?.toInt() ?? 0,
      position: m['position']?.toString() ?? '',
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
      cardOverlayOpacity:
          (m['cardOverlayOpacity'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.88,
      glowColor: m['glowColor']?.toString() ?? 'gold',
    );
  }

  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'id': playerId,
        'name': name,
        'imageUrl': imageUrl,
        'rating': rating,
        'position': position,
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
        'glowColor': glowColor,
      };

  String get displayCardImageUrl {
    final c = cardImageUrl.trim();
    if (c.isNotEmpty) return c;
    return imageUrl.trim();
  }

  PastPlayerDto toPastPlayerDto({int votes = 0}) {
    final url = displayCardImageUrl;
    final designed = cardImageUrl.trim().isNotEmpty;
    return PastPlayerDto(
      id: playerId,
      name: name,
      cardUrl: url.isEmpty ? null : url,
      votes: votes,
      position: position.isEmpty ? null : position,
      power: rating,
      cardThumbnailUrl:
          cardThumbnailUrl.trim().isEmpty ? null : cardThumbnailUrl.trim(),
      cardStyle: cardStyle.trim().isEmpty ? null : cardStyle.trim(),
      cardRarity: cardRarity.trim().isEmpty ? null : cardRarity.trim(),
      cardAnimatedOverlay:
          cardAnimatedOverlay.trim().isEmpty ? null : cardAnimatedOverlay.trim(),
      cardTheme: cardTheme.trim().isEmpty ? null : cardTheme.trim(),
      matchVoteDesignedCard: designed,
      cardOverlayAssetUrl: cardOverlayAssetUrl.trim().isEmpty
          ? null
          : cardOverlayAssetUrl.trim(),
      cardOverlayEnabled: cardOverlayEnabled,
      cardOverlayBlend:
          cardOverlayBlend.trim().isEmpty ? null : cardOverlayBlend.trim(),
      cardOverlayOpacity: cardOverlayOpacity,
    );
  }

  @override
  List<Object?> get props => [
        playerId,
        name,
        imageUrl,
        rating,
        position,
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
        glowColor,
      ];
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:gomhor_alahly_clean_new/features/matches/data/models/fixture.dart';

/// كارت مباراة قادمة/منتهية بأسلوب مختصر — يستخدم في القائمة الرئيسية
class FixtureCard extends StatelessWidget {
  final Fixture fixture;
  final VoidCallback? onTap;
  final bool live;

  const FixtureCard({
    super.key,
    required this.fixture,
    this.onTap,
    this.live = false,
  });

  static const Color _ahlyRed = Color(0xFFE30613);
  static const Color _ahlyGold = Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: live
                  ? _ahlyRed.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.06),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildTeams(),
              const SizedBox(height: 12),
              if (fixture.venue != null) _buildVenue(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (fixture.leagueLogo != null)
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: fixture.leagueLogo!,
              width: 18,
              height: 18,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.sports_soccer, color: Colors.white24, size: 16),
            ),
          ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${fixture.leagueName}${fixture.round != null ? ' • ${fixture.round}' : ''}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color bg;
    Color fg;
    String text;
    switch (fixture.phase) {
      case MatchPhase.live:
        bg = _ahlyRed;
        fg = Colors.white;
        text = fixture.elapsed != null ? '${fixture.elapsed}\'' : 'مباشر';
        break;
      case MatchPhase.finished:
        bg = Colors.white12;
        fg = Colors.white70;
        text = 'انتهت';
        break;
      case MatchPhase.postponed:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber;
        text = fixture.phase.arabic;
        break;
      case MatchPhase.upcoming:
        bg = _ahlyGold.withValues(alpha: 0.15);
        fg = _ahlyGold;
        text = fixture.timeLabel;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTeams() {
    return Row(
      children: [
        Expanded(child: _team(fixture.home)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Text(
                fixture.goals.hasScore
                    ? '${fixture.goals.home}  -  ${fixture.goals.away}'
                    : 'VS',
                style: TextStyle(
                  color: fixture.goals.hasScore ? Colors.white : _ahlyGold,
                  fontWeight: FontWeight.w900,
                  fontSize: fixture.goals.hasScore ? 22 : 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fixture.dateLabel,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
        Expanded(child: _team(fixture.away, alignEnd: true)),
      ],
    );
  }

  Widget _team(FixtureTeam team, {bool alignEnd = false}) {
    final children = [
      ClipOval(
        child: team.logo != null
            ? CachedNetworkImage(
                imageUrl: team.logo!,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.shield, color: Colors.white24, size: 30),
              )
            : const Icon(Icons.shield, color: Colors.white24, size: 30),
      ),
      const SizedBox(height: 6),
      Text(
        team.name,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    ];
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.center : CrossAxisAlignment.center,
      children: children,
    );
  }

  Widget _buildVenue() {
    return Row(
      children: [
        const Icon(Icons.stadium_rounded, color: Colors.white38, size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${fixture.venue!.name}${fixture.venue!.city.isNotEmpty ? ' • ${fixture.venue!.city}' : ''}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (fixture.venue!.isInEgypt)
          const Icon(Icons.map_outlined, color: _ahlyGold, size: 14),
      ],
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gomhor_alahly_clean_new/features/matches/data/datasources/football_api_service.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/fixture.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/league_table_entry.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/lineup.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/matches_cubit.dart';

/// Bottom sheet كامل التفاصيل لأي مباراة:
/// ‣ ملخص + موعد + استاد (مع خرائط جوجل لو في مصر)
/// ‣ جدول ترتيب عند توفر [leagueId] (TheSportsDB)
/// ‣ تشكيلة الفريقين (إن وُجدت في lookuplineup)
class FixtureDetailsSheet extends StatefulWidget {
  final Fixture fixture;
  final MatchesCubit cubit;

  const FixtureDetailsSheet({
    super.key,
    required this.fixture,
    required this.cubit,
  });

  static Future<void> show(BuildContext context, Fixture fixture) {
    final cubit = context.read<MatchesCubit>();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FixtureDetailsSheet(fixture: fixture, cubit: cubit),
    );
  }

  @override
  State<FixtureDetailsSheet> createState() => _FixtureDetailsSheetState();
}

class _FixtureDetailsSheetState extends State<FixtureDetailsSheet> {
  static const Color _ahlyRed = Color(0xFFE30613);
  static const Color _ahlyGold = Color(0xFFC5A059);

  late final Future<List<TeamLineup>> _lineupsFuture;
  late final Future<List<LeagueTableEntry>?> _tableFuture;

  @override
  void initState() {
    super.initState();
    _lineupsFuture = widget.cubit.ensureLineups(widget.fixture.id);
    _tableFuture = widget.cubit.loadLeagueTableFor(widget.fixture);
  }

  Future<void> _openMaps() async {
    final url = Uri.parse(widget.fixture.venue!.googleMapsQuery);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildMatchInfo(),
                const SizedBox(height: 12),
                _buildCompetitionContext(),
                const SizedBox(height: 12),
                _buildLeagueTableSection(),
                const SizedBox(height: 16),
                if (widget.fixture.venue != null) _buildVenueCard(),
                const SizedBox(height: 16),
                _buildLineupsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final f = widget.fixture;
    return Column(
      children: [
        Text(
          f.leagueName,
          style: const TextStyle(color: _ahlyGold, fontSize: 13),
        ),
        if (f.round != null)
          Text(
            f.round!,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _teamHeader(f.home),
            Column(
              children: [
                Text(
                  f.goals.hasScore
                      ? '${f.goals.home}   :   ${f.goals.away}'
                      : 'VS',
                  style: TextStyle(
                    color: f.goals.hasScore ? Colors.white : _ahlyGold,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                Text(
                  f.phase.arabic,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            _teamHeader(f.away),
          ],
        ),
      ],
    );
  }

  Widget _teamHeader(FixtureTeam team) {
    return Column(
      children: [
        ClipOval(
          child: team.logo != null
              ? CachedNetworkImage(
                  imageUrl: team.logo!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.shield, color: Colors.white24, size: 50),
                )
              : const Icon(Icons.shield, color: Colors.white24, size: 50),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 100,
          child: Text(
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
        ),
      ],
    );
  }

  Widget _buildMatchInfo() {
    final f = widget.fixture;
    return _Card(
      child: Column(
        children: [
          _infoRow(Icons.calendar_today_rounded, 'الموعد',
              '${f.dateLabel} • ${f.timeLabel}'),
          if (f.referee != null && f.referee!.isNotEmpty)
            _infoRow(Icons.sports_rounded, 'الحكم', f.referee!),
        ],
      ),
    );
  }

  /// موسم + مجموعة (دوري أبطال أفريقيا / كأس العالم للأندية)
  Widget _buildCompetitionContext() {
    final f = widget.fixture;
    if ((f.seasonKey == null || f.seasonKey!.isEmpty) &&
        (f.groupName == null || f.groupName!.isEmpty)) {
      return const SizedBox.shrink();
    }
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (f.seasonKey != null && f.seasonKey!.isNotEmpty)
            _infoRow(Icons.event_note_rounded, 'الموسم', f.seasonKey!),
          if (f.groupName != null && f.groupName!.isNotEmpty)
            _infoRow(Icons.grid_view_rounded, 'المجموعة / المرحلة', f.groupName!),
        ],
      ),
    );
  }

  /// جدول ترتيب الأندية (TheSportsDB — لا هدافين/تمريرات لاعب-بلاعب في الخطة المجانية)
  Widget _buildLeagueTableSection() {
    return FutureBuilder<List<LeagueTableEntry>?>(
      future: _tableFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: _ahlyRed,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }
        final rows = snap.data;
        if (rows == null || rows.isEmpty) {
          return _Card(
            child: Text(
              widget.fixture.leagueId != null
                  ? 'لا يوجد جدول ترتيب مُرجَع من الـ API لهذه المسابقة / الموسم. الهدافون والتمريرات حسب لاعب غير متاحين في TheSportsDB المجاني — يُقترح API رياضي مدفوع للأرقام الرسمية.'
                  : 'لا يوجد مُعرف للمسابقة لجلب جدول الترتيب.',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          );
        }
        // إبراز صف الأهلي
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'جدول الترتيب (أندية)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'إحصائيات لاعبية (أهداف/أسيست) غير مدمجة في هذا الـ API.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < rows.length && i < 18; i++) ...[
                if (i > 0) const Divider(color: Colors.white10, height: 12),
                _tableRowWidget(rows[i]),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _tableRowWidget(LeagueTableEntry e) {
    final ahly = e.teamId == FootballApiService.alAhlyTeamId;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: ahly
          ? BoxDecoration(
              color: _ahlyRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${e.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ahly ? _ahlyGold : Colors.white60,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          if (e.badgeUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: e.badgeUrl!,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: Colors.white24,
                ),
              ),
            )
          else
            const Icon(Icons.shield_outlined, size: 20, color: Colors.white24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              e.teamName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ahly ? Colors.white : Colors.white70,
                fontWeight: ahly ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            '${e.points ?? "—"}',
            style: TextStyle(
              color: ahly ? _ahlyGold : Colors.white60,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueCard() {
    final v = widget.fixture.venue!;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stadium_rounded, color: _ahlyGold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      [v.city, v.country].where((s) => s != null && s.isNotEmpty).join(' • '),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (v.isInEgypt) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _openMaps,
                style: FilledButton.styleFrom(
                  backgroundColor: _ahlyRed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.map_outlined, color: Colors.white),
                label: const Text(
                  'فتح الموقع على خرائط جوجل',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLineupsSection() {
    return FutureBuilder<List<TeamLineup>>(
      future: _lineupsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: CircularProgressIndicator(color: _ahlyRed)),
          );
        }
        if (snap.hasError || (snap.data?.isEmpty ?? true)) {
          return _Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: const [
                    Icon(Icons.info_outline,
                        color: Colors.white38, size: 28),
                    SizedBox(height: 8),
                    Text(
                      'التشكيلة غير متاحة بعد — سيتم نشرها قبل المباراة',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final lineups = snap.data!;
        return Column(
          children: lineups.map(_buildTeamLineupCard).toList(),
        );
      },
    );
  }

  Widget _buildTeamLineupCard(TeamLineup l) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (l.teamLogo != null)
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: l.teamLogo!,
                      width: 26,
                      height: 26,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.teamName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _ahlyGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'تشكيل ${l.formation}',
                    style: const TextStyle(
                      color: _ahlyGold,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'الأساسيون',
              style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  l.startXI.map((p) => _PlayerChip(player: p)).toList(),
            ),
            if (l.substitutes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'البدلاء',
                style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: l.substitutes
                    .map((p) => _PlayerChip(player: p, sub: true))
                    .toList(),
              ),
            ],
            if (l.coachName != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      color: Colors.white38, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'المدرّب: ${l.coachName}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: _ahlyGold, size: 18),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final LineupPlayer player;
  final bool sub;
  const _PlayerChip({required this.player, this.sub = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: sub
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: sub ? Colors.white12 : const Color(0xFFE30613).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player.number != null)
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE30613),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                '${player.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (player.number != null) const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

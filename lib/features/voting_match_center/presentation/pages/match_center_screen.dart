import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/voting_match_center/presentation/widgets/eagle_of_match_overlay.dart';
import 'package:gomhor_alahly_clean_new/features/voting_match_center/data/models/match_model.dart';
import 'package:gomhor_alahly_clean_new/features/voting_match_center/data/models/player_model.dart';

class MatchCenterScreen extends StatefulWidget {
  const MatchCenterScreen({super.key});

  @override
  State<MatchCenterScreen> createState() => _MatchCenterScreenState();
}

class _MatchCenterScreenState extends State<MatchCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<MatchModel>> _getMockMatches(bool isNext) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    final now = DateTime.now();
    return [
      MatchModel(
        id: '1',
        homeTeam: 'Al Ahly',
        awayTeam: 'Zamalek',
        matchTime: isNext ? now.add(const Duration(days: 3)) : now.subtract(const Duration(days: 7)),
        status: isNext ? 'scheduled' : 'finished',
        homeScore: isNext ? null : '2',
        awayScore: isNext ? null : '1',
        tournament: 'Egyptian Premier League',
        homeTeamLogo: 'https://example.com/alahly.png',
        awayTeamLogo: 'https://example.com/zamalek.png',
        homeTeamLineup: ['Player1', 'Player2', 'Player3'],
        awayTeamLineup: ['Player4', 'Player5', 'Player6'],
        isFinished: !isNext,
      ),
      MatchModel(
        id: '2',
        homeTeam: 'Al Ahly',
        awayTeam: 'Pyramids FC',
        matchTime: isNext ? now.add(const Duration(days: 7)) : now.subtract(const Duration(days: 14)),
        status: isNext ? 'scheduled' : 'finished',
        homeScore: isNext ? null : '3',
        awayScore: isNext ? null : '0',
        tournament: 'Egyptian Premier League',
        homeTeamLogo: 'https://example.com/alahly.png',
        awayTeamLogo: 'https://example.com/pyramids.png',
        homeTeamLineup: ['Player7', 'Player8', 'Player9'],
        awayTeamLineup: ['Player10', 'Player11', 'Player12'],
        isFinished: !isNext,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'مركز المباريات',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'المباريات القادمة'),
            Tab(text: 'النتائج الأخيرة'),
            Tab(text: 'تصويت اللاعبين'),
            Tab(text: 'نسر المباراة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMatchesTab(isNext: true),
          _buildMatchesTab(isNext: false),
          _buildStandingsTab(),
          _buildVotingTab(),
        ],
      ),
    );
  }

  Widget _buildMatchesTab({required bool isNext}) {
    return FutureBuilder<List<MatchModel>>(
      future: _getMockMatches(isNext),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary));
        }

        final matches = (snapshot.data ?? []).where(_isAlAhlyMatch).toList();
        if (snapshot.hasError || matches.isEmpty) {
          return const Center(
            child: Text('No Al Ahly matches available',
                style: TextStyle(color: Colors.white54)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final match = matches[index];
            return FadeInUp(
              child: Card(
                color: Theme.of(context).colorScheme.surface,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Text(
                        match.tournament ?? 'Egyptian Premier League',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: match.homeTeamLogo ?? '',
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  match.homeTeam,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                isNext
                                    ? match.status
                                    : "${match.homeScore ?? '0'} - ${match.awayScore ?? '0'}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "${match.startTime.day}/${match.startTime.month}/${match.startTime.year}",
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: match.awayTeamLogo ?? '',
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  match.awayTeam,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStandingsTab() {
    return FutureBuilder<List<MatchModel>>(
      future: _getMockMatches(false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        }

        final matches = (snapshot.data ?? []).where(_isAlAhlyMatch).toList();
        if (snapshot.hasError || matches.isEmpty) {
          return const Center(
            child: Text('لا توجد مباريات منتهية للأهلي حالياً',
                style: TextStyle(color: Colors.white54)),
          );
        }

        final latestMatch = _findLatestFinishedMatch(matches);
        if (latestMatch == null) {
          return const Center(
            child: Text('لا توجد مباراة منتهية حالياً',
                style: TextStyle(color: Colors.white54)),
          );
        }

        return _buildPlayerVotingCards(latestMatch);
      },
    );
  }

  /// Build player voting cards
  Widget _buildPlayerVotingCards(MatchModel match) {
    final playerNames = match.homeTeamLineup ?? [];
    final players = playerNames.map((name) => Player(
      id: name.hashCode.toString(),
      name: name,
      position: null,
      imageUrl: null,
      jerseyNumber: null,
      team: match.homeTeam,
    )).where((player) => player.name.isNotEmpty).toList();

    if (players.isEmpty) {
      return const Center(
        child: Text('No player data available',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'تصويت نسر المباراة - ${match.homeTeam} vs ${match.awayTeam}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return _buildPlayerCard(player, match.id);
            },
          ),
        ),
      ],
    );
  }

  /// بناء كارت اللاعب للتصويت
  Widget _buildPlayerCard(Player player, String matchId) {
    return GestureDetector(
      onTap: () => _voteForPlayer(player, matchId),
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage: player.imageUrl != null && player.imageUrl!.isNotEmpty
                    ? NetworkImage(player.imageUrl!)
                    : null,
                child: player.imageUrl == null || player.imageUrl!.isEmpty
                    ? Text(
                        player.jerseyNumber?.toString() ?? '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                player.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // isCaptain property not available in current Player model
            ],
          ),
        ),
      ),
    );
  }

  /// التصويت للاعب
  void _voteForPlayer(Player player, String matchId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('التصويت لنسر المباراة',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'هل تريد التصويت للاعب ${player.name} كنسر المباراة؟',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              _submitVote(player, matchId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد التصويت'),
          ),
        ],
      ),
    );
  }

  /// إرسال التصويت
  void _submitVote(Player player, String matchId) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول للتصويت')),
      );
      return;
    }

    final voteRef = FirebaseDatabase.instance.ref('votes/$matchId/$userId');

    voteRef.set({
      'playerId': player.id,
      'playerName': player.name,
      'playerNumber': player.jerseyNumber,
      'votedAt': DateTime.now().toIso8601String(),
    }).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم التصويت للاعب ${player.name} بنجاح'),
          backgroundColor: const Color(0xFFD4AF37),
        ),
      );
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في التصويت: $error')),
      );
    });
  }

  Widget _buildVotingTab() {
    return FutureBuilder<List<MatchModel>>(
      future: _getMockMatches(false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.red));
        }

        final matches = (snapshot.data ?? []).where(_isAlAhlyMatch).toList();
        if (snapshot.hasError || matches.isEmpty) {
          return const Center(
            child: Text('تعذر تحميل بيانات تصويت الأهلي حالياً',
                style: TextStyle(color: Colors.white54)),
          );
        }

        final latestFinished = _findLatestFinishedMatch(matches);
        if (latestFinished == null) {
          return const Center(
            child: Text('لا توجد مباراة منتهية حالياً للتصويت',
                style: TextStyle(color: Colors.white54)),
          );
        }

        final String fixtureId = latestFinished.id;
        final DateTime finishedAt = _estimateMatchEnd(latestFinished);
        final DateTime voteEndAt = finishedAt.add(const Duration(hours: 1));

        return FutureBuilder<void>(
          future: _ensureVotingSession(
            fixtureId: fixtureId,
            match: latestFinished,
            finishedAt: finishedAt,
            voteEndAt: voteEndAt,
          ),
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl:
                      'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&q=80&w=1200',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.black),
                  errorWidget: (context, url, error) =>
                      Container(color: Colors.black),
                ),
                EagleOfMatchOverlay(fixtureId: fixtureId),
              ],
            );
          },
        );
      },
    );
  }

  bool _isAlAhlyMatch(MatchModel match) {
    final home = match.homeTeam.toLowerCase();
    final away = match.awayTeam.toLowerCase();
    return home.contains('al ahly') ||
        away.contains('al ahly') ||
        home.contains('الأهلي') ||
        away.contains('الأهلي');
  }

  MatchModel? _findLatestFinishedMatch(List<MatchModel> matches) {
    for (final match in matches) {
      if (match.status.toLowerCase() == 'finished' || match.isFinished) {
        return match;
      }
    }
    return null;
  }

  DateTime _estimateMatchEnd(MatchModel match) {
    final DateTime kickoff = match.startTime;
    // تقدير وقت انتهاء المباراة بـ 105 دقيقة بعد الركلة الأولى
    return kickoff.add(const Duration(minutes: 105));
  }

  Future<void> _ensureVotingSession({
    required String fixtureId,
    required MatchModel match,
    required DateTime finishedAt,
    required DateTime voteEndAt,
  }) async {
    final sessionRef = FirebaseDatabase.instance.ref("votings/$fixtureId");
    final snapshot = await sessionRef.get();

    if (!snapshot.exists) {
      await sessionRef.set({
        'matchId': fixtureId,
        'homeTeam': match.homeTeam,
        'awayTeam': match.awayTeam,
        'homeTeamLogo': match.homeTeamLogo,
        'awayTeamLogo': match.awayTeamLogo,
        'finishedAt': finishedAt.toIso8601String(),
        'voteEndAt': voteEndAt.toIso8601String(),
        'status': 'open',
      });
    } else {
      final now = DateTime.now();
      if (now.isAfter(voteEndAt)) {
        await sessionRef.update({'status': 'closed'});
      }
    }
  }
}

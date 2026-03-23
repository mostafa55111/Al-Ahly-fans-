import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/services/sports_api_service.dart';
import 'package:gomhor_alahly_clean_new/features/voting_match_center/presentation/widgets/eagle_of_match_overlay.dart';

class MatchCenterScreen extends StatefulWidget {
  const MatchCenterScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<MatchCenterScreen> createState() => _MatchCenterScreenState();
}

class _MatchCenterScreenState extends State<MatchCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SportsApiService _sportsApi = SportsApiService();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "مركز المباريات",
          style: TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          labelColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: "المباريات"),
            Tab(text: "النتائج"),
            Tab(text: "الترتيب"),
            Tab(text: "التصويت"),
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: isNext ? _sportsApi.getNextMatches() : _sportsApi.getLastMatches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد بيانات حالياً', style: TextStyle(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final match = snapshot.data![index];
            return FadeInUp(
              child: Card(
                color: Colors.white.withValues(alpha: 0.05),
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Text(match['competition'] ?? 'دوري', style: const TextStyle(color: Color(0xFFC5A059), fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTeamInfo(match['homeTeam'], match['homeLogo']),
                          Column(
                            children: [
                              if (!isNext)
                                Text("${match['homeScore']} - ${match['awayScore']}", 
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
                              else
                                const Text("VS", style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Text(_sportsApi.getMatchStatus(match['status']), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            ],
                          ),
                          _buildTeamInfo(match['awayTeam'], match['awayLogo']),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(_sportsApi.formatISODateTime(match['utcDate']), style: const TextStyle(color: Colors.white70, fontSize: 12)),
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

  Widget _buildTeamInfo(String? name, String? logo) {
    return Expanded(
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: logo ?? '',
            width: 50,
            placeholder: (context, url) => const Icon(Icons.sports_soccer, color: Colors.white24),
            errorWidget: (context, url, error) => const Icon(Icons.sports_soccer, color: Colors.white24),
          ),
          const SizedBox(height: 5),
          Text(name ?? 'فريق', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStandingsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _sportsApi.getLeagueStandings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد بيانات للترتيب حالياً', style: TextStyle(color: Colors.white54)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final team = snapshot.data![index];
            final isAhly = team['team']['id'].toString() == '1035';
            return Container(
              color: isAhly ? Colors.red.withValues(alpha: 0.1) : Colors.transparent,
              child: ListTile(
                leading: Text("${team['rank']}", style: TextStyle(color: isAhly ? Colors.red : Colors.white)),
                title: Row(
                  children: [
                    CachedNetworkImage(imageUrl: team['team']['logo'], width: 25),
                    const SizedBox(width: 10),
                    Text(team['team']['name'], style: TextStyle(color: isAhly ? Colors.red : Colors.white, fontSize: 14)),
                  ],
                ),
                trailing: Text("${team['points']} نقطة", style: const TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVotingTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _sportsApi.getLastMatches(),
      builder: (context, matchesSnapshot) {
        if (matchesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }

        if (matchesSnapshot.hasError || !matchesSnapshot.hasData || matchesSnapshot.data!.isEmpty) {
          return const Center(
            child: Text('تعذر تحميل بيانات التصويت حالياً', style: TextStyle(color: Colors.white54)),
          );
        }

        final Map<String, dynamic>? latestFinished = _findLatestFinishedMatch(matchesSnapshot.data!);
        if (latestFinished == null) {
          return const Center(
            child: Text('لا توجد مباراة منتهية حالياً للتصويت', style: TextStyle(color: Colors.white54)),
          );
        }

        final String fixtureId = latestFinished['id'].toString();
        final DateTime finishedAt = _estimateMatchEnd(latestFinished);
        final DateTime voteEndAt = finishedAt.add(const Duration(hours: 1));

        return FutureBuilder<void>(
          future: _ensureVotingSession(fixtureId: fixtureId, match: latestFinished, finishedAt: finishedAt, voteEndAt: voteEndAt),
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Background image to simulate video feel
                CachedNetworkImage(
                  imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&q=80&w=1200',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.black),
                  errorWidget: (context, url, error) => Container(color: Colors.black),
                ),
                EagleOfMatchOverlay(fixtureId: fixtureId),
              ],
            );
          },
        );
      },
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic>? _findLatestFinishedMatch(List<Map<String, dynamic>> matches) {
    for (final match in matches) {
      final String shortStatus = (match['statusShort'] ?? '').toString().toUpperCase();
      final String longStatus = (match['status'] ?? '').toString().toUpperCase();
      final bool isFinished = shortStatus == 'FT' || shortStatus == 'AET' || shortStatus == 'PEN' || longStatus.contains('FINISHED');
      if (isFinished) return match;
    }
    return null;
  }

  /// تقدير وقت صافرة النهاية لتفعيل التصويت لمدة ساعة بعدها فقط.
  DateTime _estimateMatchEnd(Map<String, dynamic> match) {
    final String utcDate = match['utcDate']?.toString() ?? '';
    final DateTime kickoff = DateTime.tryParse(utcDate)?.toLocal() ?? DateTime.now();
    final int elapsed = _toInt(match['elapsed']);
    final String short = (match['statusShort'] ?? '').toString().toUpperCase();
    final bool finished = short == 'FT' || short == 'AET' || short == 'PEN';

    if (finished) {
      if (elapsed > 0) return kickoff.add(Duration(minutes: elapsed));
      return kickoff.add(const Duration(minutes: 105));
    }
    if (elapsed > 0) return kickoff.add(Duration(minutes: elapsed));
    return kickoff.add(const Duration(minutes: 120));
  }

  Future<void> _ensureVotingSession({
    required String fixtureId,
    required Map<String, dynamic> match,
    required DateTime finishedAt,
    required DateTime voteEndAt,
  }) async {
    final ref = _database.ref('man_of_match_sessions/$fixtureId');
    final snapshot = await ref.get();
    if (snapshot.exists) return;

    await ref.set({
      'fixtureId': fixtureId,
      'homeTeam': match['homeTeam'],
      'awayTeam': match['awayTeam'],
      'finishedAt': finishedAt.toIso8601String(),
      'voteStartAt': finishedAt.toIso8601String(),
      'voteEndAt': voteEndAt.toIso8601String(),
      'status': 'open',
      'totalVotes': 0,
      'playerVotes': {},
      'userVotes': {},
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}

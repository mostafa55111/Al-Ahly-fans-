import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:gomhor_alahly_clean_new/core/services/voting_cloud_functions_service.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/eagle_vote_pill.dart';

class EagleOfMatchOverlay extends StatefulWidget {
  final String fixtureId;
  final VoidCallback? onClose;

  const EagleOfMatchOverlay({
    super.key,
    required this.fixtureId,
    this.onClose,
  });

  @override
  State<EagleOfMatchOverlay> createState() => _EagleOfMatchOverlayState();
}

class _EagleOfMatchOverlayState extends State<EagleOfMatchOverlay> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _timer;
  final VotingCloudFunctionsService _functionsService =
      VotingCloudFunctionsService();

  DateTime? _voteEndAt;
  Duration _timeLeft = Duration.zero;
  bool _isVotingOpen = false;
  String _sessionStatus = 'open';
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();

          final endAt = _voteEndAt;
          if (endAt != null) {
            _timeLeft = endAt.difference(_now);
            _isVotingOpen = _timeLeft.inSeconds > 0;
          }

          // Auto-close if backend still says open but time is over.
          if (!_isVotingOpen && _sessionStatus == 'open') {
            _sessionStatus = 'closed';
            _database.ref('man_of_match_sessions/${widget.fixtureId}').update({
              'status': 'closed',
              'updatedAt': DateTime.now().toIso8601String(),
            });
          }
        });
      }
    });
  }

  Future<void> _submitVote(
      String playerId, Map<String, dynamic> session) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('سجل الدخول أولاً للتصويت'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (!_isVotingOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('التصويت مغلق حالياً'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    // محاولة الإرسال عبر Cloud Function (server-side validation/close).
    // لو فشلت (دالة غير موجودة/خطأ)، نرجع fallback للـ Realtime Database.
    try {
      await _functionsService.submitEagleOfTheMatchVote(
        fixtureId: widget.fixtureId,
        playerId: playerId,
        userId: user.uid,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم تسجيل تصويتك بنجاح 🦅'),
            backgroundColor: Colors.green),
      );
      return;
    } catch (e) {
      debugPrint(
          'Callable submitEagleOfTheMatchVote failed, fallback to DB. error=$e');
    }

    final userVotes = session['userVotes'] is Map
        ? Map<String, dynamic>.from(session['userVotes'] as Map)
        : <String, dynamic>{};
    if (userVotes[user.uid] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لقد قمت بالتصويت بالفعل')),
      );
      return;
    }

    final playerVotes = session['playerVotes'] is Map
        ? Map<String, dynamic>.from(session['playerVotes'] as Map)
        : <String, dynamic>{};
    final int current = (playerVotes[playerId] ?? 0) as int;
    playerVotes[playerId] = current + 1;
    userVotes[user.uid] = playerId;

    int totalVotes = 0;
    playerVotes.forEach((_, v) => totalVotes += (v as int));

    await _database.ref('man_of_match_sessions/${widget.fixtureId}').update({
      'playerVotes': playerVotes,
      'userVotes': userVotes,
      'totalVotes': totalVotes,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم تسجيل تصويتك بنجاح 🦅'),
            backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream:
          _database.ref('man_of_match_sessions/${widget.fixtureId}').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const SizedBox.shrink();
        }

        final session =
            Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final DateTime voteEndAt =
            DateTime.tryParse(session['voteEndAt']?.toString() ?? '') ??
                DateTime.now();
        _voteEndAt = voteEndAt;
        _sessionStatus = session['status']?.toString() ?? 'open';

        _timeLeft = voteEndAt.difference(_now);
        _isVotingOpen = _timeLeft.inSeconds > 0;

        return Stack(
          children: [
            // Dark overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildVotingSection(session),
                  const SizedBox(height: 100), // Space for reel actions
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: _voteEndAt == null
          ? const SizedBox.shrink()
          : EagleVotePill(
              title: 'نسر المباراة',
              voteEndAt: _voteEndAt!,
              nowOverride: _now,
              icon: Icons.emoji_events_outlined,
            ),
    );
  }

  Widget _buildVotingSection(Map<String, dynamic> session) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getPlayers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final players = snapshot.data!;
        final playerVotes = session['playerVotes'] is Map
            ? Map<String, dynamic>.from(session['playerVotes'] as Map)
            : <String, dynamic>{};
        final int totalVotes = (session['totalVotes'] ?? 0) as int;

        return FadeInUp(
          child: Container(
            height: 220,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                final String playerId = player['id'].toString();
                final int votes = (playerVotes[playerId] ?? 0) as int;
                final double percent =
                    totalVotes == 0 ? 0 : (votes / totalVotes);

                return _buildPlayerCard(player, percent, votes, session);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player, double percent,
      int votes, Map<String, dynamic> session) {
    final String playerId = player['id'].toString();
    final user = _auth.currentUser;
    final userVotes = session['userVotes'] is Map
        ? Map<String, dynamic>.from(session['userVotes'] as Map)
        : <String, dynamic>{};
    final bool hasVotedForThis = userVotes[user?.uid] == playerId;

    return GestureDetector(
      onTap: () => _submitVote(playerId, session),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 15),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasVotedForThis
                      ? Colors.red
                      : Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (player['photo'] != null &&
                            player['photo'].toString().isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: player['photo'],
                            fit: BoxFit.cover,
                          )
                        else
                          const Icon(Icons.person,
                              color: Colors.white30, size: 50),

                        // Percentage overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.8),
                                  Colors.transparent
                                ],
                              ),
                            ),
                            alignment: Alignment.bottomCenter,
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              '${(percent * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 5)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          player['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 5)
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_isVotingOpen)
                          const Icon(Icons.touch_app_outlined,
                              color: Colors.white, size: 16)
                        else
                          Text(
                            '$votes صوت',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getPlayers() async {
    // This logic should match match_center_screen.dart _getParticipatedPlayers
    final roots = [
      'match_players/${widget.fixtureId}',
      'matches/${widget.fixtureId}/players',
      'man_of_match_players/${widget.fixtureId}',
    ];

    for (final root in roots) {
      final snapshot = await _database.ref(root).get();
      if (!snapshot.exists ||
          snapshot.value == null ||
          snapshot.value is! Map) {
        continue;
      }

      final Map<dynamic, dynamic> map = snapshot.value as Map<dynamic, dynamic>;
      final players = <Map<String, dynamic>>[];
      map.forEach((key, value) {
        if (value is! Map) {
          return;
        }
        final data = Map<String, dynamic>.from(value);
        final bool participated = data['participated'] == true ||
            data['played'] == true ||
            data['isParticipant'] == true ||
            data['minutes'] != null;
        if (!participated) {
          return;
        }
        players.add({
          'id': data['id']?.toString() ?? key.toString(),
          'name': data['name'] ?? data['playerName'] ?? 'لاعب',
          'position': data['position'] ?? '—',
          'photo': data['photo'] ?? '',
          'number': data['number'] ?? '',
        });
      });
      if (players.isNotEmpty) {
        return players;
      }
    }
    return [];
  }
}

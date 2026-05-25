import 'dart:ui' show ImageFilter;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/design_system/theme/app_colors.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/crowd_rtdb_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/cubit/crowd_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/cubit/crowd_state.dart';

/// عرض نتائج النسور: `eagles_results` + المجمّعات الحية كاحتياط.
class EaglesResultsPanel extends StatelessWidget {
  const EaglesResultsPanel({super.key});

  static String _yyyymmFromServerMs(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    final mm = d.month.toString().padLeft(2, '0');
    return '${d.year}$mm';
  }

  static String? _leaderIdFromVotesMap(dynamic raw) {
    if (raw is! Map) return null;
    final tally = <String, int>{};
    Map<dynamic, dynamic>.from(raw).forEach((_, v) {
      final id = v?.toString();
      if (id == null || id.isEmpty) return;
      tally[id] = (tally[id] ?? 0) + 1;
    });
    if (tally.isEmpty) return null;
    return tally.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static String? _leaderIdFromCountMap(dynamic raw) {
    if (raw is! Map) return null;
    var bestId = '';
    var best = -1;
    Map<dynamic, dynamic>.from(raw).forEach((k, v) {
      final id = k.toString();
      final n = v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
      if (n > best) {
        best = n;
        bestId = id;
      }
    });
    return bestId.isEmpty ? null : bestId;
  }

  static int _votesForPlayerIdFromCountMap(dynamic raw, String playerId) {
    if (raw is! Map) return 0;
    final v = Map<dynamic, dynamic>.from(raw)[playerId];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  /// لقطة [eagles_results/...] بعد إغلاق جلسة؛ إن لم تُكتب بعد نقرأ المجمّع الحي.
  static Widget _monthEagleChild({
    required FirebaseDatabase db,
    required String ym,
    required String Function(String?) nameForId,
  }) {
    return StreamBuilder<DatabaseEvent>(
      stream: db.ref(CrowdRtdbPaths.eaglesResultsMonth(ym)).onValue,
      builder: (context, er) {
        final raw = er.data?.snapshot.value;
        if (raw is Map) {
          final m = Map<dynamic, dynamic>.from(raw);
          final pid = m['playerId']?.toString();
          if (pid != null && pid.isNotEmpty) {
            final votes = m['votes'] is int
                ? m['votes'] as int
                : (m['votes'] is num ? (m['votes'] as num).toInt() : 0);
            return _WinnerRow(
              name: nameForId(pid),
              votes: votes,
              votesLabel: votes > 0
                  ? 'تراكمي — $votes صوت (بعد آخر جلسة)'
                  : 'بعد آخر جلسة',
            );
          }
        }
        return StreamBuilder<DatabaseEvent>(
          stream: db.ref(CrowdRtdbPaths.monthAggregate(ym)).onValue,
          builder: (context, snap) {
            final id = _leaderIdFromCountMap(snap.data?.snapshot.value);
            if (id == null) {
              return const Text(
                'لا بيانات تجميع لهذا الشهر بعد.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              );
            }
            final n = _votesForPlayerIdFromCountMap(snap.data?.snapshot.value, id);
            return _WinnerRow(
              name: nameForId(id),
              votes: n,
              votesLabel: 'تراكمي مباشر — $n صوت',
            );
          },
        );
      },
    );
  }

  static Widget _seasonEagleChild({
    required FirebaseDatabase db,
    required String seasonId,
    required String Function(String?) nameForId,
  }) {
    return StreamBuilder<DatabaseEvent>(
      stream: db.ref(CrowdRtdbPaths.eaglesResultsSeason(seasonId)).onValue,
      builder: (context, er) {
        final raw = er.data?.snapshot.value;
        if (raw is Map) {
          final m = Map<dynamic, dynamic>.from(raw);
          final pid = m['playerId']?.toString();
          if (pid != null && pid.isNotEmpty) {
            final votes = m['votes'] is int
                ? m['votes'] as int
                : (m['votes'] is num ? (m['votes'] as num).toInt() : 0);
            return _WinnerRow(
              name: nameForId(pid),
              votes: votes,
              votesLabel: votes > 0
                  ? 'تراكمي — $votes صوت (بعد آخر جلسة)'
                  : 'بعد آخر جلسة',
            );
          }
        }
        return StreamBuilder<DatabaseEvent>(
          stream: db.ref(CrowdRtdbPaths.seasonAggregate(seasonId)).onValue,
          builder: (context, snap) {
            final id = _leaderIdFromCountMap(snap.data?.snapshot.value);
            if (id == null) {
              return const Text(
                'لا بيانات موسمية بعد.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              );
            }
            final n = _votesForPlayerIdFromCountMap(snap.data?.snapshot.value, id);
            return _WinnerRow(
              name: nameForId(id),
              votes: n,
              votesLabel: 'تراكمي مباشر — $n صوت',
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = getIt<FirebaseDatabase>();
    final serverTime = getIt<EgyptServerTimeService>();
    final ym = _yyyymmFromServerMs(serverTime.serverNowMs);

    return BlocBuilder<CrowdCubit, CrowdState>(
      builder: (context, crowd) {
        String nameForId(String? id) {
          if (id == null || id.isEmpty) return '—';
          try {
            return crowd.players.firstWhere((e) => e.id == id).name;
          } catch (_) {
            return id;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GlassResultCard(
                title: 'نسر المباراة',
                subtitle: 'آخر جلسة أُغلقت',
                child: StreamBuilder<DatabaseEvent>(
                  stream: db.ref(CrowdRtdbPaths.eaglesResultsMatchLast).onValue,
                  builder: (context, snap) {
                    final v = snap.data?.snapshot.value;
                    if (v is! Map) {
                      return const Text(
                        'لا توجد نتيجة مسجّلة بعد.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      );
                    }
                    final m = Map<dynamic, dynamic>.from(v);
                    final pid = m['playerId']?.toString();
                    final votes = m['votes'] is int
                        ? m['votes'] as int
                        : (m['votes'] is num ? (m['votes'] as num).toInt() : 0);
                    return _WinnerRow(
                      name: nameForId(pid),
                      votes: votes,
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              _GlassResultCard(
                title: 'نسر الشهر',
                subtitle: ym,
                child: _monthEagleChild(db: db, ym: ym, nameForId: nameForId),
              ),
              const SizedBox(height: 14),
              _GlassResultCard(
                title: 'نسر الموسم',
                subtitle: 'حسب موسم آخر جلسة مُسجّلة',
                child: StreamBuilder<DatabaseEvent>(
                  stream: db.ref(CrowdRtdbPaths.eaglesResultsMatchLast).onValue,
                  builder: (context, lastSnap) {
                    var seasonId = 'default';
                    final raw = lastSnap.data?.snapshot.value;
                    if (raw is Map) {
                      final m = Map<dynamic, dynamic>.from(raw);
                      final s = (m['seasonId'] ?? 'default').toString().trim();
                      if (s.isNotEmpty) seasonId = s;
                    }
                    return _seasonEagleChild(
                      db: db,
                      seasonId: seasonId,
                      nameForId: nameForId,
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              StreamBuilder<DatabaseEvent>(
                stream: db.ref(CrowdRtdbPaths.sessionCurrent).onValue,
                builder: (context, sess) {
                  final sid = sess.data?.snapshot.child('id').value?.toString();
                  if (sid == null || sid.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return _GlassResultCard(
                    title: 'الجلسة الحالية',
                    subtitle: 'ترتيب مؤقت',
                    child: StreamBuilder<DatabaseEvent>(
                      stream: db.ref(CrowdRtdbPaths.sessionVotes(sid)).onValue,
                      builder: (context, vs) {
                        final lid = _leaderIdFromVotesMap(vs.data?.snapshot.value);
                        if (lid == null) {
                          return const Text(
                            'لا أصوات بعد في هذه الجلسة.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          );
                        }
                        return _WinnerRow(
                          name: nameForId(lid),
                          votesLabel: 'صدارة مؤقتة',
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WinnerRow extends StatelessWidget {
  const _WinnerRow({
    required this.name,
    this.votes = 0,
    this.votesLabel,
  });

  final String name;
  final int votes;
  final String? votesLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.85),
                AppColors.secondary.withValues(alpha: 0.75),
              ],
            ),
          ),
          child: const Icon(Icons.military_tech, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                votesLabel ?? '$votes صوت في الجلسة',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassResultCard extends StatelessWidget {
  const _GlassResultCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

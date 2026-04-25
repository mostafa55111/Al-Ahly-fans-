import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gomhor_alahly_clean_new/features/matches/data/models/fixture.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/models/lineup.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/matches_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/matches_state.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/motm_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/cubit/motm_voting_state.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/widgets/fixture_card.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/widgets/fixture_details_sheet.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/widgets/next_match_focus_section.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/widgets/motm_countdown.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/widgets/motm_player_card.dart';

/// ═════════════════════════════════════════════════════════════════
/// MatchesHomePage — الشاشة الرئيسية للمباريات (تبويبتين)
/// ═════════════════════════════════════════════════════════════════
/// التبويب الأول: مباريات الأهلي (قادمة + لايف + سابقة + تشكيل + استاد).
/// التبويب الثاني: تصويت رجل المباراة (بعد صافرة الحكم بـ 60 دقيقة).
class MatchesHomePage extends StatelessWidget {
  const MatchesHomePage({super.key});

  static const Color _ahlyRed = Color(0xFFE30613);
  static const Color _ahlyGold = Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MatchesCubit()..loadAll()),
        BlocProvider(create: (_) => MotmVotingCubit()..bootstrap()),
      ],
      child: const _MatchesHomeBody(),
    );
  }
}

class _MatchesHomeBody extends StatelessWidget {
  const _MatchesHomeBody();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'المباريات',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: () {
                context.read<MatchesCubit>().loadAll(force: true);
                context.read<MotmVotingCubit>().bootstrap();
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: MatchesHomePage._ahlyRed,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: [
              Tab(
                icon: Icon(Icons.calendar_month_rounded, size: 20),
                text: 'مباريات الأهلي',
              ),
              Tab(
                icon: Icon(Icons.emoji_events_rounded, size: 20),
                text: 'رجل المباراة',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AhlyMatchesTab(),
            _MotmTab(),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// MARK: Tab 1 — مباريات الأهلي
// ════════════════════════════════════════════════════════════════════

class _AhlyMatchesTab extends StatelessWidget {
  const _AhlyMatchesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchesCubit, MatchesState>(
      builder: (context, mState) {
        if (mState.status == MatchesStatus.loading &&
            mState.upcoming.isEmpty &&
            mState.recent.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: MatchesHomePage._ahlyRed),
          );
        }

        if (mState.status == MatchesStatus.error &&
            mState.upcoming.isEmpty &&
            mState.recent.isEmpty) {
          return _ErrorState(
            message: mState.errorMessage ?? 'حدث خطأ',
            onRetry: () => context.read<MatchesCubit>().loadAll(force: true),
          );
        }

        return BlocListener<MotmVotingCubit, MotmVotingState>(
          listenWhen: (p, c) =>
              c.isVotingActive &&
              c.fixture != null &&
              (!p.isVotingActive || p.fixture?.id != c.fixture?.id),
          listener: (context, s) {
            if (s.fixture != null) {
              context.read<MatchesCubit>().ensureLineups(s.fixture!.id);
            }
          },
          child: BlocBuilder<MotmVotingCubit, MotmVotingState>(
            builder: (context, motm) {
              final voting = motm.isVotingActive && motm.fixture != null;
              Fixture? featured;
              if (voting) {
                featured = motm.fixture;
              } else if (mState.upcoming.isNotEmpty) {
                featured = mState.upcoming.first;
              } else if (mState.recent.isNotEmpty) {
                featured = mState.recent.first;
              } else {
                featured = null;
              }

              final moreFixtures = <Fixture>[];
              if (voting) {
                moreFixtures.addAll(mState.upcoming);
              } else {
                if (mState.upcoming.length > 1) {
                  moreFixtures.addAll(mState.upcoming.sublist(1));
                }
              }

              final focusFixture = featured;

              return RefreshIndicator(
                color: MatchesHomePage._ahlyRed,
                onRefresh: () => context.read<MatchesCubit>().loadAll(
                      force: true,
                    ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  children: [
                    if (mState.noticeMessage != null) ...[
                      _NoticeBanner(text: mState.noticeMessage!),
                      const SizedBox(height: 14),
                    ],
                    if (mState.live != null) ...[
                      _SectionTitle(
                        icon: Icons.fiber_manual_record_rounded,
                        iconColor: MatchesHomePage._ahlyRed,
                        title: 'مباشرة الآن',
                      ),
                      const SizedBox(height: 8),
                      FixtureCard(
                        fixture: mState.live!,
                        live: true,
                        onTap: () => FixtureDetailsSheet.show(
                            context, mState.live!),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (focusFixture != null) ...[
                      NextMatchFocusSection(
                        match: focusFixture,
                        isMotmVotingWindow: voting,
                        motmRemainingSeconds: voting
                            ? motm.remainingSeconds
                            : null,
                        onOpenDetails: () =>
                            FixtureDetailsSheet.show(context, focusFixture),
                        onOpenMotmTab: voting
                            ? () => DefaultTabController.of(context)
                                .animateTo(1)
                            : null,
                      ),
                      const SizedBox(height: 18),
                    ],
                    // تظهر فقط ومعها «قادم» — تجنب تكرار البطاقة لما الـ focus يعرض نفس «آخر مباراة» لعدم قادم
                    if (!voting &&
                        mState.recent.isNotEmpty &&
                        mState.upcoming.isNotEmpty) ...[
                      _SectionTitle(
                        icon: Icons.emoji_events_rounded,
                        iconColor: MatchesHomePage._ahlyGold,
                        title: 'آخر مباراة',
                      ),
                      const SizedBox(height: 8),
                      FixtureCard(
                        fixture: mState.recent.first,
                        onTap: () => FixtureDetailsSheet.show(
                          context,
                          mState.recent.first,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (moreFixtures.isNotEmpty) ...[
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(top: 8),
                          title: const Row(
                            children: [
                              Icon(Icons.unfold_more_rounded,
                                  color: MatchesHomePage._ahlyGold, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'باقي جدول الموسم',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'عدد ${moreFixtures.length} — اضغط للتوسيع',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                          children: [
                            for (final f in moreFixtures)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: FixtureCard(
                                  fixture: f,
                                  onTap: () =>
                                      FixtureDetailsSheet.show(context, f),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (mState.recent.length > 1) ...[
                      const SizedBox(height: 8),
                      _SectionTitle(
                        icon: Icons.history_rounded,
                        iconColor: Colors.white60,
                        title: 'مباريات سابقة',
                      ),
                      const SizedBox(height: 8),
                      ...mState.recent.skip(1).map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FixtureCard(
                            fixture: f,
                            onTap: () =>
                                FixtureDetailsSheet.show(context, f),
                          ),
                        ),
                      ),
                    ],
                    if (mState.upcoming.isEmpty && mState.recent.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.sports_soccer_rounded,
                                color: Colors.white24,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'لا توجد مباريات للأهلي حالياً',
                                style: TextStyle(color: Colors.white54),
                              ),
                              if (mState.loadedSeason != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'موسم ${mState.loadedSeason}',
                                  style: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// MARK: Tab 2 — تصويت رجل المباراة
// ════════════════════════════════════════════════════════════════════

class _MotmTab extends StatelessWidget {
  const _MotmTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MotmVotingCubit, MotmVotingState>(
      builder: (context, state) {
        switch (state.status) {
          case MotmStatus.loading:
          case MotmStatus.initial:
            return const Center(
              child: CircularProgressIndicator(
                  color: MatchesHomePage._ahlyRed),
            );

          case MotmStatus.waitingWhistle:
            return _WaitingWhistleView(fixture: state.fixture);

          case MotmStatus.error:
            return _ErrorState(
              message: state.errorMessage ?? 'حدث خطأ',
              onRetry: () => context.read<MotmVotingCubit>().bootstrap(),
              hint:
                  'لو الموسم الحالي مش متاح على API، التصويت بيشتغل على آخر مباراة منتهية في موسم متاح.',
            );

          case MotmStatus.open:
          case MotmStatus.closed:
            return _MotmVotingView(state: state);
        }
      },
    );
  }
}

class _WaitingWhistleView extends StatelessWidget {
  final Fixture? fixture;
  const _WaitingWhistleView({this.fixture});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF141414),
                border: Border.all(
                    color: MatchesHomePage._ahlyGold.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.sports_rounded,
                  color: MatchesHomePage._ahlyGold, size: 56),
            ),
            const SizedBox(height: 18),
            const Text(
              'في انتظار صافرة النهاية',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fixture != null
                  ? 'سيُفتح تصويت رجل المباراة لمدة 60 دقيقة بعد انتهاء مباراة\n${fixture!.home.name} × ${fixture!.away.name}'
                  : 'سيُفتح تصويت رجل المباراة لمدة 60 دقيقة بعد انتهاء أي مباراة للأهلي.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white60, height: 1.5, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotmVotingView extends StatelessWidget {
  final MotmVotingState state;
  const _MotmVotingView({required this.state});

  @override
  Widget build(BuildContext context) {
    final closed = state.status == MotmStatus.closed;
    final winner = state.winnerPlayerId != null
        ? state.players.firstWhere(
            (p) => p.id == state.winnerPlayerId,
            orElse: () => state.players.first,
          )
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _MatchSummary(fixture: state.fixture),
        const SizedBox(height: 12),
        MotmCountdown(
          remainingSeconds: state.remainingSeconds,
          closed: closed,
        ),
        const SizedBox(height: 16),
        if (closed && winner != null) _WinnerBanner(winner: winner),
        if (closed && winner != null) const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              closed ? 'النتائج النهائية' : 'اختر رجل المباراة',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14),
            ),
            Text(
              'إجمالي الأصوات: ${state.totalVotes}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.players.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.74,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, i) {
            final p = state.players[i];
            final votes = state.votesByPlayerId[p.id ?? -1] ?? 0;
            final isMyVote = state.myVotedPlayerId == p.id;
            final isWinner = closed && winner?.id == p.id;
            return MotmPlayerCard(
              player: p,
              votes: votes,
              totalVotes: state.totalVotes,
              isMyVote: isMyVote,
              isWinner: isWinner,
              enabled: !closed,
              onTap: () {
                if (p.id == null) return;
                context.read<MotmVotingCubit>().vote(p.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 2),
                    backgroundColor: MatchesHomePage._ahlyRed,
                    content: Text('تم اختيار ${p.name} كرجل للمباراة 🦅'),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 14),
        const _RulesNote(),
      ],
    );
  }
}

class _MatchSummary extends StatelessWidget {
  final Fixture? fixture;
  const _MatchSummary({this.fixture});

  @override
  Widget build(BuildContext context) {
    if (fixture == null) return const SizedBox.shrink();
    final f = fixture!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          if (f.home.logo != null)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: f.home.logo!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '${f.home.name}  ${f.goals.hasScore ? f.goals.home : '-'}  :  ${f.goals.hasScore ? f.goals.away : '-'}  ${f.away.name}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${f.leagueName} • ${f.dateLabel}',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (f.away.logo != null)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: f.away.logo!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}

class _WinnerBanner extends StatelessWidget {
  final LineupPlayer winner;
  const _WinnerBanner({required this.winner});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC5A059), Color(0xFF8B6B3F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipOval(
            child: winner.photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: winner.photoUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 56,
                    height: 56,
                    color: Colors.black26,
                    child: const Icon(Icons.person, color: Colors.white70),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'رجل المباراة 🏆',
                  style: TextStyle(color: Colors.black87, fontSize: 12),
                ),
                Text(
                  winner.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RulesNote extends StatelessWidget {
  const _RulesNote();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.white38, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'يفتح التصويت لمدة 60 دقيقة بعد صافرة الحكم. تقدر تصوّت أو تغيّر صوتك في أي وقت قبل غلق التصويت. يظهر هنا فقط اللاعبون اللي شاركوا في المباراة (أساسي + بدلاء نزلوا).',
              style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// MARK: Common widgets
// ════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  const _SectionTitle(
      {required this.icon, required this.iconColor, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  final String text;
  const _NoticeBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MatchesHomePage._ahlyGold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: MatchesHomePage._ahlyGold.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: MatchesHomePage._ahlyGold, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String? hint;
  const _ErrorState({
    required this.message,
    required this.onRetry,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, height: 1.5),
            ),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 11, height: 1.5),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                  backgroundColor: MatchesHomePage._ahlyRed),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('إعادة المحاولة',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

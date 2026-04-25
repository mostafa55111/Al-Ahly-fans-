import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/design_system/theme/app_colors.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/cubit/crowd_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/cubit/crowd_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/cubit/eagle_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/cubit/eagle_voting_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/pages/crowd_admin_page.dart';

// ═══════════════════════════════════════════════════════════════════════
// شاشة الجمهور — تصميم عصري بهوية النادي الأهلي (أحمر ملكي + ذهبي)
// ═══════════════════════════════════════════════════════════════════════
//
// التبويبات:
//   1) الملعب          — تشكيل تفاعلي (FIFA-style) بسحب كروت اللاعبين
//   2) نسر المباراة    — يحتوي تبويبين فرعيين:
//        a) كل الكروت  — معرض كل اللاعبين من `best_player`
//        b) التصويت    — اللاعبون المختارون من جلسة الأدمن للتصويت
//
// التوقيت:
//   - يبدأ العدّ من `eagle_nesr/session_current/startedAt` المسجَّل على الخادم.
//   - التطبيق يقارن [EgyptServerTimeService.serverNowMs] مع
//     `startedAt + EgyptServerTimeService.voteWindowMs`.
// ═══════════════════════════════════════════════════════════════════════

class CrowdScreen extends StatelessWidget {
  const CrowdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CrowdCubit(
            repository: getIt<CrowdRepository>(),
            serverTime: getIt<EgyptServerTimeService>(),
            auth: getIt<FirebaseAuth>(),
          )..init(),
        ),
        BlocProvider(
          create: (_) => EagleVotingCubit(
            repository: getIt<CrowdRepository>(),
            serverTime: getIt<EgyptServerTimeService>(),
            auth: getIt<FirebaseAuth>(),
          ),
        ),
      ],
      child: const _CrowdBody(),
    );
  }
}

class _CrowdBody extends StatefulWidget {
  const _CrowdBody();

  @override
  State<_CrowdBody> createState() => _CrowdBodyState();
}

class _CrowdBodyState extends State<_CrowdBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = context.read<CrowdCubit>().state;
      if (c.players.isNotEmpty) {
        context.read<EagleVotingCubit>().setAllPlayers(c.players);
        context.read<EagleVotingCubit>().syncSessionAndListenVote();
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CrowdCubit, CrowdState>(
      listenWhen: (p, c) => p.players != c.players,
      listener: (context, state) {
        context.read<EagleVotingCubit>().setAllPlayers(state.players);
        context.read<EagleVotingCubit>().syncSessionAndListenVote();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFF050505),
        body: Stack(
          children: [
            const _AhlyAmbientBackdrop(),
            SafeArea(
              child: Column(
                children: [
                  const _CrowdHeader(),
                  _ModernTabBar(controller: _tabs),
                  Expanded(
                    child: TabBarView(
          controller: _tabs,
          children: const [
            _PitchTab(),
            _NesrTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// خلفية فخمة — تدرّج داكن + هالة ذهبية/حمراء خفيفة
// ═══════════════════════════════════════════════════════════════════════
class _AhlyAmbientBackdrop extends StatelessWidget {
  const _AhlyAmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A0606),
                    Color(0xFF050505),
                    Color(0xFF000000),
                  ],
                  stops: [0, 0.45, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: -90,
            left: -60,
            child: _GlowBlob(
              color: AppColors.secondary.withValues(alpha: 0.55),
              size: 260,
            ),
          ),
          Positioned(
            top: 120,
            right: -80,
            child: _GlowBlob(
              color: AppColors.primary.withValues(alpha: 0.35),
              size: 220,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// شريط علوي مخصّص — عنوان + عدّاد لاعبين
// ═══════════════════════════════════════════════════════════════════════
class _CrowdHeader extends StatelessWidget {
  const _CrowdHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onLongPress: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CrowdAdminPage()),
              );
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary,
                    AppColors.secondary.withValues(alpha: 0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.4),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_moon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'شاشة الجمهور',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ملعب الأهلي ونسر المباراة',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<CrowdCubit, CrowdState>(
            buildWhen: (p, c) => p.players.length != c.players.length,
            builder: (context, state) {
              return _CountBadge(count: state.players.length);
            },
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.55)),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            '$count كارت',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// شريط تبويبات عصري بكبسولة منزلقة
// ═══════════════════════════════════════════════════════════════════════
class _ModernTabBar extends StatelessWidget {
  const _ModernTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: TabBar(
          controller: controller,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: const LinearGradient(
              colors: [AppColors.secondary, Color(0xFFB91D1D)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.45),
                blurRadius: 14,
              ),
            ],
          ),
          indicatorPadding: const EdgeInsets.all(4),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'الملعب'),
            Tab(text: 'نسر المباراة'),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// تبويب الملعب — سحب كروت اللاعبين
// ═══════════════════════════════════════════════════════════════════════

/// مواضع نسبية على الملعب (تشكيل قريبة من 4-3-3)
const _kSlots = <(String id, double x, double y)>[
  ('gk', 0.5, 0.90),
  ('lb', 0.12, 0.68),
  ('cb_l', 0.38, 0.72),
  ('cb_r', 0.62, 0.72),
  ('rb', 0.88, 0.68),
  ('cm_l', 0.28, 0.48),
  ('cm_c', 0.5, 0.42),
  ('cm_r', 0.72, 0.48),
  ('lw', 0.14, 0.24),
  ('st', 0.5, 0.16),
  ('rw', 0.86, 0.24),
];

class _PitchTab extends StatefulWidget {
  const _PitchTab();

  @override
  State<_PitchTab> createState() => _PitchTabState();
}

class _PitchTabState extends State<_PitchTab> {
  String? _selectedSlotId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CrowdCubit, CrowdState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return _PitchErrorView(
            message: state.error!,
            onRetry: () => context.read<CrowdCubit>().init(),
          );
        }
        if (state.players.isEmpty) {
          return _PitchEmptyView(
            onRetry: () => context.read<CrowdCubit>().init(),
          );
        }
        return Column(
          children: [
            _FormationModeRow(state: state),
            const SizedBox(height: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: LayoutBuilder(
                  builder: (context, c) {
                    return _PitchField(
                      width: c.maxWidth,
                      height: c.maxHeight,
                      state: state,
                      selectedSlotId: _selectedSlotId,
                      onSlotTap: (slotId) {
                        setState(() => _selectedSlotId = slotId);
                        _showPositionPlayersSheet(
                          context,
                          players: state.players,
                          slotId: slotId,
                          onPick: (playerId) {
                            context.read<CrowdCubit>().assignPlayerToSlot(slotId, playerId);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// شريط أعلى الملعب: نوع التشكيلة + زر مسح + زر «عرض كل اللاعبين» (bottom sheet).
class _FormationModeRow extends StatelessWidget {
  const _FormationModeRow({required this.state});

  final CrowdState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Row(
                children: [
          _ModeChip(
            label: 'المباراة',
                    selected: state.formationMode == 'match',
            onTap: () => context.read<CrowdCubit>().setMode('match'),
                  ),
                  const SizedBox(width: 8),
          _ModeChip(
            label: 'الموسم',
                    selected: state.formationMode == 'season',
            onTap: () => context.read<CrowdCubit>().setMode('season'),
                  ),
                  const Spacer(),
          IconButton(
            tooltip: 'مسح التشكيلة',
            onPressed: () => context.read<CrowdCubit>().clearPitch(),
            icon: const Icon(
              Icons.cleaning_services,
              color: Colors.white60,
              size: 20,
            ),
                  ),
                ],
              ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFB8941F)],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// الملعب الفعلي مع الكروت السحابية وبادج رقم اللاعبين الموضوعين.
class _PitchField extends StatelessWidget {
  const _PitchField({
    required this.width,
    required this.height,
    required this.state,
    required this.onSlotTap,
    required this.selectedSlotId,
  });

  final double width;
  final double height;
  final CrowdState state;
  final ValueChanged<String> onSlotTap;
  final String? selectedSlotId;

  @override
  Widget build(BuildContext context) {
    final placedCount = state.slotToPlayerId.length;
                    return Container(
                      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E4222), Color(0xFF072E16)],
        ),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.4,
                        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 8),
                      ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
          CustomPaint(
            size: Size(width, height),
            painter: _AhlyPitchFieldPainter(
              line: Colors.white.withValues(alpha: 0.30),
            ),
          ),
          Positioned(
            top: 8,
            right: 10,
                            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                '$placedCount / 11',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
                            ),
                          ),
                          ..._kSlots.map((s) {
                            final pid = state.slotToPlayerId[s.$1];
                            PastPlayerDto? p;
                            if (pid != null) {
                              try {
                p = state.players.firstWhere((e) => e.id == pid);
                              } catch (_) {}
                            }
                            return Positioned(
              left: width * s.$2 - 32,
              top: height * s.$3 - 42,
                              child: DragTarget<String>(
                                onWillAcceptWithDetails: (_) => true,
                                onAcceptWithDetails: (d) {
                  context
                      .read<CrowdCubit>()
                      .assignPlayerToSlot(s.$1, d.data);
                                },
                                builder: (ctx, cand, _) {
                                  return _SlotChip(
                                    label: s.$1,
                                    player: p,
                                    highlighted: cand.isNotEmpty,
                                    active: selectedSlotId == s.$1,
                                    onTap: () => onSlotTap(s.$1),
                    onClear: p == null
                        ? null
                        : () => context
                            .read<CrowdCubit>()
                            .assignPlayerToSlot(s.$1, null),
                                  );
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    );
  }
}

String _normalizedSlotPosition(String slotId) {
  final s = slotId.trim().toLowerCase();
  if (s.startsWith('cb') || s == 'cbl' || s == 'cbr') return 'cb';
  if (s.startsWith('cm') || s == 'cdm' || s == 'cam') return 'cm';
  if (s == 'st' || s == 'cf' || s == 'ss') return 'st';
  if (s == 'rw' || s == 'rm') return 'rw';
  if (s == 'lw' || s == 'lm') return 'lw';
  if (s == 'rb' || s == 'rwb') return 'rb';
  if (s == 'lb' || s == 'lwb') return 'lb';
  if (s == 'gk' || s == 'goalkeeper' || s == 'keeper') return 'gk';
  return s;
}

String _normalizedPlayerPosition(String? position) {
  final p = (position ?? '').trim().toLowerCase();
  if (p.isEmpty) return '';
  if (p.startsWith('cb') ||
      p.contains('center back') ||
      p.contains('centre back') ||
      p == 'defender') {
    return 'cb';
  }
  if (p.startsWith('cm') ||
      p == 'midfielder' ||
      p == 'cdm' ||
      p == 'cam') {
    return 'cm';
  }
  if (p == 'st' ||
      p == 'striker' ||
      p == 'forward' ||
      p == 'cf' ||
      p == 'ss') {
    return 'st';
  }
  if (p == 'goalkeeper' || p == 'keeper' || p == 'gk') return 'gk';
  if (p == 'right wing' || p == 'rw' || p == 'rm') return 'rw';
  if (p == 'left wing' || p == 'lw' || p == 'lm') return 'lw';
  if (p == 'right back' || p == 'rb' || p == 'rwb') return 'rb';
  if (p == 'left back' || p == 'lb' || p == 'lwb') return 'lb';
  return p;
}

void _showPositionPlayersSheet(
  BuildContext context, {
  required List<PastPlayerDto> players,
  required String slotId,
  required ValueChanged<String> onPick,
}) {
  final position = _normalizedSlotPosition(slotId);
  final filtered = players
      .where((p) => _normalizedPlayerPosition(p.position) == position)
      .toList();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.35,
        maxChildSize: 0.93,
        builder: (_, scrollCtrl) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F0F0F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(
                top: BorderSide(color: Color(0xFF2A2A2A), width: 1),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'كروت مركز ${slotId.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      _CountBadge(count: filtered.length),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'لا توجد كروت مطابقة لهذا المركز حالياً.',
                              style: TextStyle(color: Colors.white60),
                            ),
                          ),
                        )
                      : GridView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.all(14),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final p = filtered[i];
                            return GestureDetector(
                              onTap: () {
                                onPick(p.id);
                                Navigator.of(context).pop();
                              },
                              child: _PlayerCardLarge(p: p),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// واجهة فارغة عند خلو `best_player`.
class _PitchEmptyView extends StatelessWidget {
  const _PitchEmptyView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            const Text(
              'لا توجد كروت لاعبين بعد',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'مسار "best_player" فارغ في Realtime Database.\n'
              'سيقوم الأدمن بإضافة اللاعبين من لوحة التحكم.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, height: 1.5),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PitchErrorView extends StatelessWidget {
  const _PitchErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.redAccent, size: 56),
            const SizedBox(height: 12),
            const Text(
              'تعذّر تحميل اللاعبين',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// خانة على الملعب — تعرض الكارت المصمَّم بالكامل عند تخصيص لاعب لها،
/// أو تسمية مختصرة للمركز عند الفراغ، مع زر مسح صغير.
class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.player,
    required this.highlighted,
    required this.active,
    this.onTap,
    this.onClear,
  });

  final String label;
  final PastPlayerDto? player;
  final bool highlighted;
  final bool active;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    if (player != null) {
      return GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 64,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: active ? Border.all(color: AppColors.primary, width: 1.4) : null,
                boxShadow: [
                  BoxShadow(
                    color: (highlighted || active ? AppColors.primary : Colors.black)
                        .withValues(alpha: 0.55),
                    blurRadius: (highlighted || active) ? 14 : 8,
                    spreadRadius: (highlighted || active) ? 1 : 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _CardImageOrFallback(
                  url: player!.cardUrl,
                  name: player!.name,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (onClear != null)
              Positioned(
                right: -6,
                top: -6,
                child: GestureDetector(
                  onTap: onClear,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black87,
                      border: Border.all(
                        color: AppColors.secondary,
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.4),
          border: Border.all(
            color: active
                ? AppColors.secondary
                : AppColors.primary.withValues(alpha: 0.85),
            width: active ? 2 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: (active ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.20),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
        ),
      ),
    );
  }
}

/// كارت لاعب كبير لـ grid (في bottom sheet أو تبويب «كل الكروت»).
class _PlayerCardLarge extends StatelessWidget {
  const _PlayerCardLarge({required this.p});

  final PastPlayerDto p;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
        children: [
            _CardImageOrFallback(
              url: p.cardUrl,
              name: p.name,
                fit: BoxFit.cover,
              ),
            if (p.votes > 0)
              Positioned(
                top: 6,
                right: 6,
                child: _VotesPill(votes: p.votes),
              ),
          ],
        ),
      ),
    );
  }
}

class _VotesPill extends StatelessWidget {
  const _VotesPill({required this.votes});

  final int votes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.thumb_up, size: 11, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            '$votes',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// عرض كارت اللاعب — صورة كاملة، أو placeholder متدرّج فيه الاسم.
class _CardImageOrFallback extends StatelessWidget {
  const _CardImageOrFallback({
    required this.url,
    required this.name,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final String name;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: fit,
        placeholder: (_, __) => Container(
          color: Colors.black26,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _Placeholder(name: name),
      );
    }
    return _Placeholder(name: name);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: Text(
        name,
        textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// تبويب «نسر المباراة» — يحوي تبويبين فرعيين: كل الكروت + التصويت
// ═══════════════════════════════════════════════════════════════════════
class _NesrTab extends StatefulWidget {
  const _NesrTab();

  @override
  State<_NesrTab> createState() => _NesrTabState();
}

class _NesrTabState extends State<_NesrTab>
    with SingleTickerProviderStateMixin {
  late TabController _innerTabs;

  @override
  void initState() {
    super.initState();
    _innerTabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _innerTabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SubTabsBar(controller: _innerTabs),
        Expanded(
          child: TabBarView(
            controller: _innerTabs,
            children: const [
              _AllCardsSubTab(),
              _VotingSubTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubTabsBar extends StatelessWidget {
  const _SubTabsBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: TabBar(
          controller: controller,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFFB8941F)],
            ),
          ),
          indicatorPadding: const EdgeInsets.all(3),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          tabs: const [
            Tab(text: 'كل الكروت'),
            Tab(text: 'التصويت'),
          ],
        ),
      ),
    );
  }
}

// ─── التبويب الفرعي A: كل الكروت ───────────────────────────────────────
class _AllCardsSubTab extends StatelessWidget {
  const _AllCardsSubTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CrowdCubit, CrowdState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.players.isEmpty) {
          return _PitchEmptyView(
            onRetry: () => context.read<CrowdCubit>().init(),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(14),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: state.players.length,
          itemBuilder: (_, i) => _PlayerCardLarge(p: state.players[i]),
        );
      },
    );
  }
}

// ─── التبويب الفرعي B: التصويت ─────────────────────────────────────────
class _VotingSubTab extends StatelessWidget {
  const _VotingSubTab();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EagleVotingCubit, EagleVotingState>(
      listener: (context, state) {
        if (state.error != null && state.error!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.session == null) {
          return const _NoSessionView();
        }
        return _ActiveVotingView(state: state);
      },
    );
  }
}

class _NoSessionView extends StatelessWidget {
  const _NoSessionView();

  @override
  Widget build(BuildContext context) {
    return Center(
            child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.25),
                    AppColors.secondary.withValues(alpha: 0.25),
                  ],
                ),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.how_to_vote,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'لا توجد جلسة تصويت حالياً',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'الأدمن سيحدّد اللاعبين المشاركين في تصويت\n'
              '"نسر المباراة" ووقت البدء من لوحة التحكم.\n\n'
              'يمكنك تصفّح كل الكروت من تبويب «كل الكروت».',
                textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, height: 1.6),
            ),
          ],
              ),
            ),
          );
        }
}

class _ActiveVotingView extends StatelessWidget {
  const _ActiveVotingView({required this.state});

  final EagleVotingState state;

  @override
  Widget build(BuildContext context) {
        final rem = state.remainingSeconds;
        final mm = (rem ~/ 60).toString().padLeft(2, '0');
        final ss = (rem % 60).toString().padLeft(2, '0');

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _VotingHeader(state: state, mm: mm, ss: ss),
        ),
        if (state.eligiblePlayers.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'لم يُحدَّد لاعبون مؤهّلون بعد في هذه الجلسة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            sliver: SliverList.separated(
              itemCount: state.eligiblePlayers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final pl = state.eligiblePlayers[i];
                final sel = state.myVotePlayerId == pl.id;
                return _NesrPlayerTile(
                  player: pl,
                  selected: sel,
                  windowOpen: state.windowOpen,
                  onVote: () =>
                      context.read<EagleVotingCubit>().vote(pl.id),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: _VotingFooter()),
      ],
    );
  }
}

class _VotingHeader extends StatelessWidget {
  const _VotingHeader({
    required this.state,
    required this.mm,
    required this.ss,
  });

  final EagleVotingState state;
  final String mm;
  final String ss;

  @override
  Widget build(BuildContext context) {
    const voteMinutes = EgyptServerTimeService.voteWindowMs ~/ 60000;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
                    colors: [
              AppColors.secondary.withValues(alpha: 0.45),
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.2),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
                ),
                child: Row(
                  children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.35),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Icon(
                      state.windowOpen ? Icons.timer : Icons.lock_clock,
                      color: AppColors.primary,
                size: 26,
                    ),
            ),
            const SizedBox(width: 12),
                    Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                        state.windowOpen
                        ? 'النافذة مفتوحة'
                        : 'انتهى التصويت لهذه الجلسة',
                        style: const TextStyle(
                          color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.windowOpen
                        ? 'متبقٍ $mm:$ss من $voteMinutes دقيقة (وقت الخادم)'
                        : '$voteMinutes دقيقة من بدء التصويت',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  if (state.myVotePlayerId != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 13, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'تم تسجيل صوتك',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VotingFooter extends StatelessWidget {
  const _VotingFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: Text(
        'يُحسب نسر الشهر/الموسم من مجموع الأصوات التراكمي،\n'
        'وليس من عدد مرات الفوز بأفضل لاعب في مباراة.',
                        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 11,
          height: 1.5,
        ),
      ),
    );
  }
}

/// عنصر لاعب في تبويب التصويت — كارت كامل + اسم + عدد الأصوات + زر «صوّت».
class _NesrPlayerTile extends StatelessWidget {
  const _NesrPlayerTile({
    required this.player,
    required this.selected,
    required this.windowOpen,
    required this.onVote,
  });

  final PastPlayerDto player;
  final bool selected;
  final bool windowOpen;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
                        return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : const Color(0xFF131313),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: windowOpen && !selected ? onVote : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.06),
              width: selected ? 1.4 : 1,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 86,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _CardImageOrFallback(
                    url: player.cardUrl,
                    name: player.name,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _VotesPill(votes: player.votes),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 30,
                  ),
                )
              else
                FilledButton(
                  onPressed: windowOpen ? onVote : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'صوّت',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
            ],
                ),
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// رسم خطوط الملعب — مظهر قريب من ألعاب التشكيل (FIFA-style)
// ═══════════════════════════════════════════════════════════════════════
class _AhlyPitchFieldPainter extends CustomPainter {
  _AhlyPitchFieldPainter({required this.line});

  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 12.0;
    final r = Rect.fromLTWH(
      pad,
      pad,
      size.width - 2 * pad,
      size.height - 2 * pad,
    );
    final p = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(10)),
      p,
    );

    final midY = r.center.dy;
    canvas.drawLine(Offset(r.left, midY), Offset(r.right, midY), p);

    final center = Offset(r.center.dx, midY);
    canvas.drawCircle(center, r.width * 0.14, p);
    canvas.drawCircle(center, 3, Paint()..color = line);

    final boxW = r.width * 0.34;
    final boxH = r.height * 0.22;
    final topBox = Rect.fromCenter(
      center: Offset(r.center.dx, r.top + boxH / 2 + 4),
      width: boxW,
      height: boxH,
    );
    final botBox = Rect.fromCenter(
      center: Offset(r.center.dx, r.bottom - boxH / 2 - 4),
      width: boxW,
      height: boxH,
    );
    canvas.drawRect(topBox, p);
    canvas.drawRect(botBox, p);

    // منطقتي المرمى الصغيرتين
    final goalW = r.width * 0.18;
    final goalH = r.height * 0.10;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(r.center.dx, r.top + goalH / 2 + 4),
        width: goalW,
        height: goalH,
      ),
      p,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(r.center.dx, r.bottom - goalH / 2 - 4),
        width: goalW,
        height: goalH,
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _AhlyPitchFieldPainter oldDelegate) =>
      oldDelegate.line != line;
}

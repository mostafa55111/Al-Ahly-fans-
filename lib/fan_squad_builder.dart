import 'dart:async';
import 'dart:math' show pi, sin;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/models/past_player_dto.dart';
import 'package:gomhor_alahly_clean_new/features/public_arena/domain/formation_slot.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/fifa_card_widget.dart';

typedef SquadPitchCommit = Future<void> Function(
  String playerId,
  int slotIndex,
  double pitchNx,
  double pitchNy,
);

typedef SquadPitchClear = Future<void> Function(String playerId);

/// لوحة تشكيل تفاعلية (أسلوب قريب من FC Mobile): سحب من لوحة جانبية زجاجية
/// وإفلات على مراكز الملعب مع حفظ في RTDB عبر [onSquadSlotCommitted].
class FanSquadBuilder extends StatefulWidget {
  const FanSquadBuilder({
    super.key,
    required this.players,
    this.formation = '3-5-2',
    this.initialSlots = FormationSlot.fallback352,
    this.layoutResetSignal = 0,
    this.votingMode = false,
    this.myVotedPlayerId,
    this.onVote,
    this.onSquadSlotCommitted,
    this.onSquadPlayerClearLayout,
    this.allowPitchDrag = false,
    this.immersivePitchBackdrop = false,
    this.votingBenchEligibleIds,
    this.votingAmbientPulse = false,
  });

  final List<PastPlayerDto> players;
  final String formation;
  final List<FormationSlot> initialSlots;
  final int layoutResetSignal;
  final bool votingMode;
  final String? myVotedPlayerId;
  final ValueChanged<PastPlayerDto>? onVote;
  final SquadPitchCommit? onSquadSlotCommitted;
  final SquadPitchClear? onSquadPlayerClearLayout;

  /// تعديل التشكيلة بالسحب (أدمن فقط). المشجع يرى التشكيلة ويصوّت بالضغط فقط.
  final bool allowPitchDrag;

  /// عند `true` تقلّ طبقة التعتيم فوق الملعب ليظهر [SquadFieldPage] خلفها.
  final bool immersivePitchBackdrop;

  /// في وضع التصويت: لو حُدّدت، تُعرض في لوحة الاحتياط فقط اللاعبون المؤهّلون للتصويت.
  final Set<String>? votingBenchEligibleIds;

  /// حلقة كهرمانية نابضة حول كروت الملعب أثناء التصويت.
  final bool votingAmbientPulse;

  @override
  State<FanSquadBuilder> createState() => _FanSquadBuilderState();
}

class _FanSquadBuilderState extends State<FanSquadBuilder>
    with TickerProviderStateMixin {
  final Map<String, int> _pulseTicks = <String, int>{};
  final TextEditingController _searchCtrl = TextEditingController();
  late final _SquadBoardController _board = _SquadBoardController();
  late final AnimationController _ambientPulse;

  @override
  void initState() {
    super.initState();
    _ambientPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _syncPulseAnimation();
    _syncBoard(force: true);
  }

  void _syncPulseAnimation() {
    if (widget.votingAmbientPulse && widget.votingMode) {
      if (!_ambientPulse.isAnimating) {
        _ambientPulse.repeat(reverse: true);
      }
    } else {
      _ambientPulse.stop();
      _ambientPulse.reset();
    }
  }

  void _fireVote(PastPlayerDto p) {
    HapticFeedback.lightImpact();
    setState(() {
      _pulseTicks[p.id] = (_pulseTicks[p.id] ?? 0) + 1;
    });
    widget.onVote?.call(p);
  }

  @override
  void didUpdateWidget(covariant FanSquadBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layoutResetSignal != widget.layoutResetSignal ||
        !identical(oldWidget.players, widget.players) ||
        oldWidget.initialSlots != widget.initialSlots ||
        oldWidget.allowPitchDrag != widget.allowPitchDrag) {
      _syncBoard(force: oldWidget.layoutResetSignal != widget.layoutResetSignal);
    }
    if (oldWidget.votingMode != widget.votingMode ||
        oldWidget.votingAmbientPulse != widget.votingAmbientPulse) {
      _syncPulseAnimation();
    }
  }

  void _syncBoard({required bool force}) {
    final scoped = _scopedPlayers(widget.players);
    _board.hydrate(
      scoped,
      widget.initialSlots,
      force: force,
    );
  }

  @override
  void dispose() {
    _ambientPulse.dispose();
    _searchCtrl.dispose();
    _board.dispose();
    super.dispose();
  }

  List<PastPlayerDto> _scopedPlayers(List<PastPlayerDto> raw) {
    return raw.where(_belongsToCurrentApp).where((e) => e.active).toList();
  }

  bool _belongsToCurrentApp(PastPlayerDto p) {
    final marker = FanAppIdentity.registryAppId;
    final id = p.id.toLowerCase();
    if (id.contains('ahly') || id.contains('zamalek')) {
      return id.contains(marker);
    }
    return true;
  }

  FormationSlot _slotDef(int index) {
    final slots = widget.initialSlots;
    if (index >= 0 && index < slots.length) return slots[index];
    if (index < FormationSlot.fallback352.length) {
      return FormationSlot.fallback352[index];
    }
    return const FormationSlot(dx: 0.5, dy: 0.5, positionName: '?');
  }

  Offset _displayOffsetForSlot(int index, PastPlayerDto p) {
    final def = _slotDef(index);
    final nx = p.pitchNx ?? def.dx;
    final ny = p.pitchNy ?? def.dy;
    return Offset(nx, ny);
  }

  Future<void> _persistSlot(int slotIndex, PastPlayerDto p) async {
    if (!widget.allowPitchDrag || widget.votingMode) return;
    final c = widget.onSquadSlotCommitted;
    if (c == null) return;
    final def = _slotDef(slotIndex);
    final nx = p.pitchNx ?? def.dx;
    final ny = p.pitchNy ?? def.dy;
    await c(p.id, slotIndex, nx, ny);
  }

  Future<void> _persistClear(String playerId) async {
    if (!widget.allowPitchDrag || widget.votingMode) return;
    final clear = widget.onSquadPlayerClearLayout;
    if (clear != null) {
      await clear(playerId);
    }
  }

  Future<void> _applyBenchToSlot(int targetSlot, PastPlayerDto incoming) async {
    final displaced = _board.slots[targetSlot];
    _board.setSlot(targetSlot, incoming);
    await _persistSlot(targetSlot, incoming);
    if (displaced != null && displaced.id != incoming.id) {
      await _persistClear(displaced.id);
    }
  }

  Future<void> _applySlotMove(int targetSlot, int fromSlot, PastPlayerDto incoming) async {
    if (fromSlot == targetSlot) return;
    final atTarget = _board.slots[targetSlot];
    if (atTarget == null) {
      _board.setSlot(fromSlot, null);
      _board.setSlot(targetSlot, incoming);
      await _persistSlot(targetSlot, incoming);
      return;
    }
    _board.swapSlots(fromSlot, targetSlot);
    await _persistSlot(fromSlot, atTarget);
    await _persistSlot(targetSlot, incoming);
  }

  Future<void> _onSlotDrop(int targetSlot, _FcDragData data) async {
    if (!widget.allowPitchDrag || widget.votingMode) return;
    final incoming = data.player;
    if (data.fromSlotIndex == null) {
      await _applyBenchToSlot(targetSlot, incoming);
    } else {
      await _applySlotMove(targetSlot, data.fromSlotIndex!, incoming);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoped = _scopedPlayers(widget.players);
    if (scoped.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد كروت متاحة حالياً لهذا النادي.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight <= 0 ? 520.0 : constraints.maxHeight;
        final pitchH = h * 0.72;
        final fieldPlayers = _board.slots.whereType<PastPlayerDto>().toList();
        final ovr = fieldPlayers.isEmpty
            ? 0
            : (fieldPlayers.map((e) => e.power ?? 100).reduce((a, b) => a + b) /
                    fieldPlayers.length)
                .round();
        final layoutEditing = widget.allowPitchDrag && !widget.votingMode;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Expanded(
                  child: ListenableBuilder(
                    listenable: _board,
                    builder: (context, _) {
                      return RepaintBoundary(
                        child: DragTarget<_FcDragData>(
                          onWillAcceptWithDetails: (_) => layoutEditing,
                          onAcceptWithDetails: (details) {
                            if (!layoutEditing || details.data.fromSlotIndex == 0) return;
                            final box = context.findRenderObject() as RenderBox?;
                            if (box == null) return;
                            final local = box.globalToLocal(details.offset);
                            final nx = (local.dx / constraints.maxWidth).clamp(0.06, 0.94);
                            final ny = (local.dy / pitchH).clamp(0.08, 0.88);
                            final from = details.data.fromSlotIndex;
                            if (from == null || from == 0) return;
                            final p = _board.slots[from];
                            if (p == null) return;
                            final updated = p.copyWith(pitchNx: nx, pitchNy: ny);
                            _board.setSlot(from, updated);
                            unawaited(_persistSlot(from, updated));
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: widget.immersivePitchBackdrop
                                              ? null
                                              : LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.black.withValues(alpha: 0.04),
                                                    Colors.black.withValues(alpha: 0.12),
                                                  ],
                                                ),
                                          color: widget.immersivePitchBackdrop
                                              ? Colors.black.withValues(alpha: 0.06)
                                              : null,
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _PitchPainter(
                                          lineColor: Colors.white.withValues(alpha: 0.28),
                                        ),
                                      ),
                                    ),
                                    ...List.generate(_board.slotCount, (slotIndex) {
                                      final def = _slotDef(slotIndex);
                                      final cx = def.dx * constraints.maxWidth;
                                      final cy = def.dy * pitchH;
                                      return Positioned(
                                        left: cx - 36,
                                        top: cy - 44,
                                        child: RepaintBoundary(
                                          child: DragTarget<_FcDragData>(
                                            onWillAcceptWithDetails: (_) => layoutEditing,
                                            onAcceptWithDetails: (d) {
                                              unawaited(_onSlotDrop(slotIndex, d.data));
                                            },
                                            builder: (context, cand, rej) {
                                              final active = cand.isNotEmpty;
                                              return AnimatedContainer(
                                                duration: const Duration(milliseconds: 160),
                                                width: 72,
                                                height: 88,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: active
                                                        ? Colors.amberAccent.withValues(alpha: 0.85)
                                                        : Colors.white.withValues(alpha: 0.12),
                                                    width: active ? 2.2 : 1,
                                                  ),
                                                  color: Colors.white.withValues(alpha: active ? 0.12 : 0.04),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    }),
                                    Positioned(
                                      top: 10,
                                      left: 10,
                                      child: RepaintBoundary(
                                        child: _GlassTeamInfo(ovr: ovr, formation: widget.formation),
                                      ),
                                    ),
                                    ...List.generate(_board.slotCount, (index) {
                                      final p = _board.slots[index];
                                      if (p == null) return const SizedBox.shrink();
                                      final target = _displayOffsetForSlot(index, p);
                                      final left = target.dx * constraints.maxWidth - 31;
                                      final top = target.dy * pitchH - 43;
                                      final voted =
                                          widget.myVotedPlayerId != null && widget.myVotedPlayerId == p.id;
                                      Widget card = FifaCardWidget(
                                        player: p,
                                        selected: voted,
                                        highlighted: widget.votingMode,
                                        isVotingMode: widget.votingMode,
                                        pulseTrigger: _pulseTicks[p.id] ?? 0,
                                        onTap: widget.votingMode ? () => _fireVote(p) : null,
                                      );
                                      if (widget.votingMode &&
                                          widget.votingAmbientPulse &&
                                          !layoutEditing) {
                                        card = _AmbientAmberVoteRing(
                                          animation: _ambientPulse,
                                          child: card,
                                        );
                                      }
                                      if (layoutEditing && index != 0) {
                                        card = LongPressDraggable<_FcDragData>(
                                          data: _FcDragData(player: p, fromSlotIndex: index),
                                          feedback: Material(
                                            color: Colors.transparent,
                                            elevation: 8,
                                            child: SizedBox(
                                              width: 62,
                                              height: 86,
                                              child: FifaCardWidget(player: p, highlighted: true),
                                            ),
                                          ),
                                          childWhenDragging: Opacity(opacity: 0.35, child: card),
                                          child: card,
                                        );
                                      }
                                      return Positioned(
                                        key: ValueKey<String>('starter_${p.id}_$index'),
                                        left: left,
                                        top: top,
                                        child: RepaintBoundary(child: card),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            PositionedDirectional(
              end: 4,
              top: 48,
              bottom: 12,
              child: RepaintBoundary(
                child: _FloatingGlassSquadPanel(
                  board: _board,
                  scopedPlayers: scoped,
                  votingMode: widget.votingMode,
                  allowPitchDrag: widget.allowPitchDrag,
                  votingBenchEligibleIds: widget.votingBenchEligibleIds,
                  onVote: widget.votingMode ? _fireVote : null,
                  myVotedPlayerId: widget.myVotedPlayerId,
                  searchCtrl: _searchCtrl,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FcDragData {
  const _FcDragData({required this.player, this.fromSlotIndex});
  final PastPlayerDto player;
  final int? fromSlotIndex;
}

/// حلقة توهج كهرماني حول كرت التصويت — [RepaintBoundary] للأداء.
class _AmbientAmberVoteRing extends StatelessWidget {
  const _AmbientAmberVoteRing({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = (sin(animation.value * 2 * pi) + 1) / 2;
          return Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(
                    const Color(0xFFFFB300),
                    const Color(0xFFFF6F00),
                    t,
                  )!.withValues(alpha: 0.38 + 0.42 * t),
                  blurRadius: 8 + 10 * t,
                  spreadRadius: 0.15 + 0.55 * t,
                ),
              ],
            ),
            child: child,
          );
        },
      ),
    );
  }
}

class _SquadBoardController extends ChangeNotifier {
  static const int _kMaxSlots = 11;

  List<PastPlayerDto?> _slots = List<PastPlayerDto?>.filled(_kMaxSlots, null);

  List<PastPlayerDto?> get slots => _slots;
  int get slotCount => _kMaxSlots;

  void hydrate(
    List<PastPlayerDto> scopedActive,
    List<FormationSlot> formation,
    {required bool force,
  }) {
    if (!force && listEquals(_slots, _deriveSlots(scopedActive, formation))) {
      return;
    }
    _slots = _deriveSlots(scopedActive, formation);
    notifyListeners();
  }

  List<PastPlayerDto?> _deriveSlots(
    List<PastPlayerDto> scopedActive,
    List<FormationSlot> formation,
  ) {
    final n = formation.length < _kMaxSlots ? formation.length : _kMaxSlots;
    final out = List<PastPlayerDto?>.filled(_kMaxSlots, null);
    final used = <String>{};

    for (final p in scopedActive) {
      final si = p.slotIndex;
      if (si != null && si >= 0 && si < n && out[si] == null) {
        out[si] = p;
        used.add(p.id);
      }
    }

    final pool = _gkFirstPool(scopedActive);
    for (final p in pool) {
      if (used.contains(p.id)) continue;
      final empty = out.indexWhere((e) => e == null);
      if (empty >= 0 && empty < n) {
        out[empty] = p;
        used.add(p.id);
      }
    }
    return out;
  }

  List<PastPlayerDto> _gkFirstPool(List<PastPlayerDto> scoped) {
    final sorted = List<PastPlayerDto>.from(scoped)
      ..sort((a, b) => (b.power ?? 0).compareTo(a.power ?? 0));
    final gkIndex = sorted.indexWhere((p) => (p.position ?? '').toLowerCase().contains('gk'));
    final gk = gkIndex >= 0 ? sorted.removeAt(gkIndex) : sorted.removeAt(0);
    return [gk, ...sorted];
  }

  void setSlot(int index, PastPlayerDto? player) {
    if (index < 0 || index >= _kMaxSlots) return;
    _slots = List<PastPlayerDto?>.from(_slots);
    _slots[index] = player;
    notifyListeners();
  }

  void swapSlots(int a, int b) {
    if (a < 0 || b < 0 || a >= _kMaxSlots || b >= _kMaxSlots) return;
    _slots = List<PastPlayerDto?>.from(_slots);
    final t = _slots[a];
    _slots[a] = _slots[b];
    _slots[b] = t;
    notifyListeners();
  }

  Set<String> get onFieldIds => {
        for (final p in _slots)
          if (p != null) p.id,
      };

  List<PastPlayerDto> benchList(List<PastPlayerDto> scoped) {
    final on = onFieldIds;
    final rest = scoped.where((p) => !on.contains(p.id)).toList()
      ..sort((a, b) => (b.power ?? 0).compareTo(a.power ?? 0));
    return rest.take(7).toList();
  }

  List<PastPlayerDto> reservesList(List<PastPlayerDto> scoped) {
    final on = onFieldIds;
    final rest = scoped.where((p) => !on.contains(p.id)).toList()
      ..sort((a, b) => (b.power ?? 0).compareTo(a.power ?? 0));
    return rest.skip(7).toList();
  }
}

class _GlassTeamInfo extends StatelessWidget {
  const _GlassTeamInfo({required this.ovr, required this.formation});
  final int ovr;
  final String formation;

  @override
  Widget build(BuildContext context) {
    final isAhly = FanAppIdentity.registryAppId == 'ahly';
    final teamName = isAhly ? 'الأهلي' : 'الزمالك';
    final color = isAhly ? const Color(0xFFC8102E) : const Color(0xFFD90429);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 134,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: color,
                    child: const Icon(Icons.flag, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('OVR $ovr', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
              Text(formation, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingGlassSquadPanel extends StatefulWidget {
  const _FloatingGlassSquadPanel({
    required this.board,
    required this.scopedPlayers,
    required this.votingMode,
    required this.allowPitchDrag,
    required this.searchCtrl,
    this.votingBenchEligibleIds,
    this.onVote,
    this.myVotedPlayerId,
  });

  final _SquadBoardController board;
  final List<PastPlayerDto> scopedPlayers;
  final bool votingMode;
  final bool allowPitchDrag;
  final TextEditingController searchCtrl;
  final Set<String>? votingBenchEligibleIds;
  final ValueChanged<PastPlayerDto>? onVote;
  final String? myVotedPlayerId;

  @override
  State<_FloatingGlassSquadPanel> createState() => _FloatingGlassSquadPanelState();
}

class _FloatingGlassSquadPanelState extends State<_FloatingGlassSquadPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = !widget.votingMode;
  }

  @override
  void didUpdateWidget(covariant _FloatingGlassSquadPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.votingMode && widget.votingMode) {
      setState(() => _expanded = false);
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.board,
      builder: (context, _) {
        var bench = widget.board.benchList(widget.scopedPlayers);
        var reserves = widget.board.reservesList(widget.scopedPlayers);
        if (widget.votingMode && widget.votingBenchEligibleIds != null) {
          final allow = widget.votingBenchEligibleIds!;
          bench = bench.where((p) => allow.contains(p.id)).toList();
          reserves = reserves.where((p) => allow.contains(p.id)).toList();
        }
        final reserveCount = bench.length + reserves.length;

        if (!_expanded) {
          return _ReservesPeekTab(
            reserveCount: reserveCount,
            onOpen: () => setState(() => _expanded = true),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: 178,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(-4, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tab,
                        indicatorColor: Colors.amberAccent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                        tabs: const [
                          Tab(text: 'البدلاء'),
                          Tab(text: 'الاحتياط'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tab,
                          children: [
                            _BenchTab(
                              bench: bench,
                              votingMode: widget.votingMode,
                              allowPitchDrag: widget.allowPitchDrag,
                              onVote: widget.onVote,
                              myVotedPlayerId: widget.myVotedPlayerId,
                            ),
                            _ReservesTab(
                              reserves: reserves,
                              searchCtrl: widget.searchCtrl,
                              votingMode: widget.votingMode,
                              allowPitchDrag: widget.allowPitchDrag,
                              onVote: widget.onVote,
                              myVotedPlayerId: widget.myVotedPlayerId,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 4,
              start: 4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _expanded = false),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left
                          : Icons.chevron_right,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// تبويب جانبي عائم صغير — يفتح لوحة الاحتياط الزجاجية.
class _ReservesPeekTab extends StatelessWidget {
  const _ReservesPeekTab({
    required this.reserveCount,
    required this.onOpen,
  });

  final int reserveCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 44,
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.groups_2_outlined, color: Colors.amberAccent, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    'احتياط',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      height: 1.1,
                    ),
                  ),
                  if (reserveCount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$reserveCount',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BenchTab extends StatelessWidget {
  const _BenchTab({
    required this.bench,
    required this.votingMode,
    required this.allowPitchDrag,
    this.onVote,
    this.myVotedPlayerId,
  });
  final List<PastPlayerDto> bench;
  final bool votingMode;
  final bool allowPitchDrag;
  final ValueChanged<PastPlayerDto>? onVote;
  final String? myVotedPlayerId;

  @override
  Widget build(BuildContext context) {
    if (bench.isEmpty) {
      return const Center(
        child: Text('لا يوجد بدلاء', style: TextStyle(color: Colors.white54, fontSize: 11)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      itemCount: bench.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = bench[i];
        final voted = myVotedPlayerId != null && myVotedPlayerId == p.id;
        Widget card = FifaCardWidget(
          player: p,
          width: 48,
          height: 66,
          highlighted: false,
          selected: voted,
          isVotingMode: votingMode,
          onTap: votingMode && onVote != null ? () => onVote!(p) : null,
        );
        if (votingMode || !allowPitchDrag) return card;
        return LongPressDraggable<_FcDragData>(
          data: _FcDragData(player: p, fromSlotIndex: null),
          feedback: Material(
            color: Colors.transparent,
            elevation: 10,
            child: SizedBox(width: 52, height: 72, child: FifaCardWidget(player: p, highlighted: true)),
          ),
          childWhenDragging: Opacity(opacity: 0.4, child: card),
          child: card,
        );
      },
    );
  }
}

class _ReservesTab extends StatefulWidget {
  const _ReservesTab({
    required this.reserves,
    required this.searchCtrl,
    required this.votingMode,
    required this.allowPitchDrag,
    this.onVote,
    this.myVotedPlayerId,
  });
  final List<PastPlayerDto> reserves;
  final TextEditingController searchCtrl;
  final bool votingMode;
  final bool allowPitchDrag;
  final ValueChanged<PastPlayerDto>? onVote;
  final String? myVotedPlayerId;

  @override
  State<_ReservesTab> createState() => _ReservesTabState();
}

class _ReservesTabState extends State<_ReservesTab> {
  @override
  Widget build(BuildContext context) {
    final q = widget.searchCtrl.text.trim().toLowerCase();
    final filtered = widget.reserves
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
          child: TextField(
            controller: widget.searchCtrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'بحث',
              hintStyle: const TextStyle(color: Colors.white54, fontSize: 11),
              prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 18),
              isDense: true,
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.28),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('لا نتائج', style: TextStyle(color: Colors.white54, fontSize: 11)),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(6),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    final voted =
                        widget.myVotedPlayerId != null && widget.myVotedPlayerId == p.id;
                    Widget card = FifaCardWidget(
                      player: p,
                      width: 46,
                      height: 64,
                      highlighted: false,
                      selected: voted,
                      isVotingMode: widget.votingMode,
                      onTap: widget.votingMode && widget.onVote != null
                          ? () => widget.onVote!(p)
                          : null,
                    );
                    if (widget.votingMode || !widget.allowPitchDrag) return card;
                    return LongPressDraggable<_FcDragData>(
                      data: _FcDragData(player: p, fromSlotIndex: null),
                      feedback: Material(
                        color: Colors.transparent,
                        elevation: 10,
                        child: SizedBox(
                          width: 50,
                          height: 70,
                          child: FifaCardWidget(player: p, highlighted: true),
                        ),
                      ),
                      childWhenDragging: Opacity(opacity: 0.4, child: card),
                      child: card,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter({required this.lineColor});
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRect(Rect.fromLTWH(8, 8, size.width - 16, size.height - 16), p);
    canvas.drawLine(Offset(size.width / 2, 8), Offset(size.width / 2, size.height - 8), p);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 34, p);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.30, 8, size.width * 0.40, 58), p);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.30, size.height - 66, size.width * 0.40, 58), p);
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) => oldDelegate.lineColor != lineColor;
}

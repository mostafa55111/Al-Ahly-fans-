import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/presentation/widgets/awards_voting_shell.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner/owner_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_auth/owner_control_room_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/read_pressure/visibility_subscription_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/runtime/crowd_navigation_runtime_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/identity/club_award_labels.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/presentation/widgets/hall_of_fame_panel.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/broadcast_calibration/broadcast_visual_calibrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/cinematic_atmosphere/cinematic_atmosphere_layer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_atmosphere_controller.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_visual_tokens.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/squad_field_page.dart';

/// تبويبا الجمهور العائمان: تصويت على الملعب + عرض النسور.
class CrowdFanImmersiveShell extends StatefulWidget {
  const CrowdFanImmersiveShell({
    super.key,
    this.initialTopTab = 0,
  });

  /// 0 = التصويت، 1 = قاعة الشرف
  final int initialTopTab;

  @override
  State<CrowdFanImmersiveShell> createState() => _CrowdFanImmersiveShellState();
}

class _CrowdFanImmersiveShellState extends State<CrowdFanImmersiveShell>
    with SingleTickerProviderStateMixin {
  late final TabController _top = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTopTab.clamp(0, 1),
  );

  /// يزداد عند فتح تبويب قاعة الشرف — لإعادة تحميل الجوائز.
  final ValueNotifier<int> _hallTabOpens = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    CrowdNavigationRuntimeGuard.instance.registerImmersiveShell();
    _top.addListener(_onTopTabChanged);
    if (_top.index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _hallTabOpens.value++;
      });
    }
  }

  void _onTopTabChanged() {
    if (_top.indexIsChanging) return;
    VisibilitySubscriptionGuard.instance.setVisibleTab(_top.index);
    if (_top.index == 1) {
      _hallTabOpens.value++;
    }
  }

  @override
  void dispose() {
    CrowdNavigationRuntimeGuard.instance.unregisterImmersiveShell();
    _top.removeListener(_onTopTabChanged);
    _top.dispose();
    _hallTabOpens.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _top,
        builder: (context, _) {
          final hallActive = _top.index == 1;
          return StadiumAtmosphereController(
            hallTabActive: hallActive,
            child: CinematicAtmosphereLayer(
              hallTabActive: hallActive,
              child: BroadcastVisualCalibrator(
                hallTabActive: hallActive,
                child: SquadFieldPage(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: TabBarView(
                          controller: _top,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            const _VotingLayer(),
                            HallOfFamePanel(tabOpens: _hallTabOpens),
                          ],
                        ),
                      ),
                      SafeArea(
                        bottom: false,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                            child: _GlassTopTabs(controller: _top),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: bottomInset + 12,
                        child: const _OwnerBroadcastFab(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VotingLayer extends StatelessWidget {
  const _VotingLayer();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top + 56;
    final bottomPad = MediaQuery.paddingOf(context).bottom + 8;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, topPad, 0, bottomPad),
      child: const AwardsVotingShell(),
    );
  }
}

class _GlassTopTabs extends StatelessWidget {
  const _GlassTopTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = StadiumVisualTokens.of(null);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final blurSigma = tokens.isAhly ? 18.0 : 16.0;
        return GestureDetector(
          onLongPress: () => _openOwnerGateIfAllowed(context),
          child: ClipRRect(
          borderRadius: tokens.tabRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: tokens.tabRadius,
                border: Border.all(color: tokens.glassBorder),
              ),
              child: TabBar(
                controller: controller,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: tokens.pillRadius,
                  color: tokens.activeTabFill,
                  boxShadow: [
                    BoxShadow(
                      color: tokens.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: tokens.tabLabelActive,
                unselectedLabelStyle: tokens.tabLabelInactive,
                tabs: [
                  const Tab(text: 'التصويت'),
                  Tab(text: ClubAwardLabels.hallOfFameTab),
                ],
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  Future<void> _openOwnerGateIfAllowed(BuildContext context) async {
    final ok = await getIt<OwnerGuard>().canAccessAdmin();
    if (!ok || !context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const OwnerControlRoomGate(),
      ),
    );
  }
}

/// مدخل بث المالك — يظهر للمالك المعتمد فقط.
class _OwnerBroadcastFab extends StatefulWidget {
  const _OwnerBroadcastFab();

  @override
  State<_OwnerBroadcastFab> createState() => _OwnerBroadcastFabState();
}

class _OwnerBroadcastFabState extends State<_OwnerBroadcastFab> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await getIt<OwnerGuard>().canAccessAdmin();
    if (mounted) setState(() => _visible = ok);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return FloatingActionButton(
      heroTag: 'crowd_owner_broadcast_fab',
      tooltip: 'غرفة البث',
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      onPressed: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const OwnerControlRoomGate(),
          ),
        ).then((_) => _check());
      },
      child: const Icon(Icons.cell_tower_rounded),
    );
  }
}

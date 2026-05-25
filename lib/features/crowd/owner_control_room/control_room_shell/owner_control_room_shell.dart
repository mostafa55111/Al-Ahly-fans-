import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/admin_surface_isolation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/card_repository/owner_card_repository_page.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/matchday_timeline/matchday_timeline_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_operations/operational_surface/matchday_operational_surface.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/live_session_persistence.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_reliability_bundle.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_reliability/matchday_reliability_scope.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_auth/owner_auth_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/models/owner_card_record.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/release_readiness/release_readiness_owner_panel.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/soft_launch_operations/soft_launch_owner_ops_strip.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// غرفة تحكم البث — مالك فقط.
class OwnerControlRoomShell extends StatefulWidget {
  const OwnerControlRoomShell({super.key});

  @override
  State<OwnerControlRoomShell> createState() => _OwnerControlRoomShellState();
}

class _OwnerControlRoomShellState extends State<OwnerControlRoomShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabs;
  late final MatchVotesAdminCubit _adminCubit;
  late final MatchdayReliabilityBundle _reliability;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reliability = MatchdayReliabilityBundle(
      prefs: getIt<SharedPreferences>(),
    );
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
    _adminCubit = MatchVotesAdminCubit(
      repository: getIt<MatchVotesRepository>(),
      cmsRepository: getIt<StadiumCmsRepository>(),
      serverTime: getIt<EgyptServerTimeService>(),
      clubTag: FanAppIdentity.registryAppId,
    )..start();
    _restoreOperationalContext();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _adminCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResume();
    }
  }

  Future<void> _restoreOperationalContext() async {
    final snap = _reliability.persistence.load(FanAppIdentity.registryAppId);
    if (snap.hasLiveContext && snap.operationalTabIndex == 1) {
      _tabs.index = 1;
    }
    await _onResume();
  }

  Future<void> _onResume() async {
    final network = await _reliability.network.evaluate();
    final admin = _adminCubit.state;
    _reliability.lastResumeReport = await _reliability.resumeRecovery.onAppResumed(
      network: network,
      adminSession: admin.match,
      playerCount: admin.bundle.players.length,
      operatorWarning: admin.operatorWarning,
    );
    if (mounted && _reliability.lastResumeReport!.restoreTabIndex == 1) {
      _tabs.index = 1;
    }
    if (mounted) setState(() {});
  }

  void _onTabChanged() {
    if (!_tabs.indexIsChanging) {
      _persistTab(_tabs.index);
    }
  }

  Future<void> _persistTab(int index) async {
    final session = _adminCubit.state.match;
    final phase = MatchdayTimelineResolver.resolve(
      session: session,
      serverNowMs: getIt<EgyptServerTimeService>().serverNowMs,
    );
    await _reliability.persistence.save(
      clubTag: FanAppIdentity.registryAppId,
      snapshot: LiveSessionPersistenceSnapshot(
        activeMatchId: session?.id ?? '',
        phaseWire: phase.name,
        formation: session?.formation ?? '4-3-3',
        operationalTabIndex: index,
      ),
    );
  }

  void _onCardPitch(OwnerCardRecord card) {
    _adminCubit.addRegistryCardToPitch(card.toRegistryEntry());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${card.playerName} → أساسي')),
    );
  }

  void _onCardBench(OwnerCardRecord card) {
    _adminCubit.addRegistryCardToBench(card.toRegistryEntry());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${card.playerName} → بديل')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ControlRoomTheme.of(null);

    return AdminSurfaceIsolation(
      child: MatchdayReliabilityScope(
        bundle: _reliability,
        child: BlocProvider.value(
          value: _adminCubit,
          child: Scaffold(
            backgroundColor: theme.scaffold,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(gradient: theme.headerGradient),
              ),
              title: Text(
                'غرفة التحكم',
                style: TextStyle(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w900,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'تسجيل الخروج',
                  icon: Icon(Icons.logout, color: theme.secondaryText),
                  onPressed: () async {
                    await getIt<OwnerAuthService>().signOut();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabs,
                indicatorColor: theme.identity.primaryColor,
                labelColor: theme.primaryText,
                unselectedLabelColor: theme.secondaryText,
                tabs: const [
                  Tab(text: 'المستودع'),
                  Tab(text: 'يوم المباراة'),
                ],
              ),
            ),
          body: Column(
            children: [
              ReleaseReadinessOwnerPanel(theme: theme),
              SoftLaunchOwnerOpsStrip(theme: theme),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    OwnerCardRepositoryPage(
                      theme: theme,
                      onAddToPitch: _onCardPitch,
                      onAddToBench: _onCardBench,
                    ),
                    MatchdayOperationalSurface(theme: theme),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

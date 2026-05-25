import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_sync.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_upload_coordinator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_command_bar.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_design_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_pending_op.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_recovery_banner.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_operator_metrics.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_metrics_hud.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_workspace_snapshot.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_formation_preview.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_workflow_panels.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_smart_card_library_tab.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/formation_editor.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_state.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/player_editor_dialog.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/data/match_votes_rtdb_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/cubit/match_voting_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_card_stadium_preview_dialog.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/owner_recovery_mode.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/widgets/owner_operations_panel.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/widgets/session_status_timeline_widget.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/admin_control_visual_system.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/presentation/widgets/match_stadium_voting_layer.dart';
/// مركز تحكم الملعب — جلسة، تشكيلة، مكتبة كروت، معاينة حية، تفعيل.
class StadiumCmsPage extends StatefulWidget {
  const StadiumCmsPage({super.key});

  @override
  State<StadiumCmsPage> createState() => _StadiumCmsPageState();
}

class _StadiumCmsPageState extends State<StadiumCmsPage>
    with SingleTickerProviderStateMixin {
  late final MatchVotesAdminCubit _cubit;
  late final TabController _tabs;
  late final CrowdAppIdentity _identity;

  String _formationPick = '4-3-3';
  final _titleCtrl = TextEditingController();
  final _opponentCtrl = TextEditingController();
  String _sessionType = 'league';
  DateTime? _closesAt;
  String _fxLevel = 'warm';
  String _crowdProfile = 'standard';
  String _stadiumTheme = 'default';
  StadiumCmsWorkspaceSnapshot? _workspaceSnapshot;
  bool _hideResumeBanner = false;
  String? _lastPendingSyncMessage;
  late final StadiumCmsOperatorMetrics _metrics;

  @override
  void initState() {
    super.initState();
    _identity = CrowdAppIdentity.current;
    final club = FanAppIdentity.registryAppId;
    _metrics = StadiumCmsOperatorMetrics(
      cms: getIt<StadiumCmsRepository>(),
      clubTag: club,
    )..onCmsOpened();
    _cubit = MatchVotesAdminCubit(
      repository: getIt<MatchVotesRepository>(),
      cmsRepository: getIt<StadiumCmsRepository>(),
      serverTime: getIt<EgyptServerTimeService>(),
      clubTag: club,
    )..start();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadWorkspaceSnapshot();
      await _flushPendingOps();
    });
  }

  void _onTabChanged() {
    if (!_tabs.indexIsChanging) {
      _metrics.onTabChanged(_tabs.index);
      if (_tabs.index == 2) {
        _metrics.onPreviewTab(playerCount: _cubit.state.bundle.players.length);
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _flushPendingOps() async {
    final club = FanAppIdentity.registryAppId;
    final cms = getIt<StadiumCmsRepository>();
    final before = await cms.readAllPendingOps(club);
    final synced = await getIt<StadiumCardUploadCoordinator>().flushPending(club);
    final after = await cms.readAllPendingOps(club);
    if (!mounted) return;
    setState(() {
      if (before.isEmpty) {
        _lastPendingSyncMessage = null;
      } else if (synced > 0 && after.isEmpty) {
        _lastPendingSyncMessage = 'تم إرسال $synced عمل — الطابور فارغ الآن';
      } else if (synced > 0) {
        _lastPendingSyncMessage = 'أُعيد $synced · بقي ${after.length} معلّقاً';
      } else {
        _lastPendingSyncMessage = 'لم يُنجح الإرسال — ${after.length} ما زال معلّقاً';
      }
    });
    if (synced > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lastPendingSyncMessage ?? 'تمت المزامنة'),
          duration: StadiumCmsDesign.motionNormal,
        ),
      );
    }
  }

  Future<void> _loadWorkspaceSnapshot() async {
    final snap = await _cubit.readWorkspaceSnapshot();
    if (!mounted) return;
    setState(() => _workspaceSnapshot = snap);
  }

  @override
  void dispose() {
    _metrics.persist(abandoned: true);
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _titleCtrl.dispose();
    _opponentCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  void _syncSessionFields(MatchActiveSession? m) {
    if (m == null || m.id.isEmpty) return;
    _titleCtrl.text = m.title;
    _opponentCtrl.text = m.opponent;
    _sessionType = _sessionTypes.contains(m.sessionType) ? m.sessionType : 'league';
    _formationPick = FormationEditorPanel.formations.contains(m.formation) ? m.formation : _formationPick;
    _closesAt = m.closesAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(m.closesAt)
        : null;
    _fxLevel = m.fxLevel;
    _crowdProfile = m.crowdProfile;
    _stadiumTheme = m.stadiumTheme;
  }

  static const _sessionTypes = ['league', 'cup', 'friendly', 'other'];

  String _sessionTypeLabel(String t) {
    switch (t) {
      case 'cup':
        return 'كأس';
      case 'friendly':
        return 'ودي';
      case 'other':
        return 'أخرى';
      default:
        return 'دوري';
    }
  }

  String _labelForId(MatchVotesAdminState state, String id) {
    for (final p in state.bundle.players) {
      if (p.id == id) return '${p.name} (${p.position})';
    }
    return id;
  }

  Future<void> _saveSessionMeta(MatchVotesAdminState state) async {
    final m = state.match;
    if (m == null || m.id.isEmpty) return;
    await _cubit.updateActiveSession(
      m.copyWith(
        title: _titleCtrl.text.trim().isEmpty ? m.title : _titleCtrl.text.trim(),
        opponent: _opponentCtrl.text.trim(),
        sessionType: _sessionType,
        formation: _formationPick,
        closesAt: _closesAt?.millisecondsSinceEpoch ?? 0,
        fxLevel: _fxLevel,
        crowdProfile: _crowdProfile,
        stadiumTheme: _stadiumTheme,
      ),
    );
  }

  Future<void> _createSession({bool clearPlayers = false}) async {
    _metrics.onAction('session_create');
    await _cubit.createSession(
      title: _titleCtrl.text,
      formation: _formationPick,
      clearPlayers: clearPlayers,
    );
    if (!mounted) return;
    final m = _cubit.state.match;
    if (m != null) {
      await _cubit.updateActiveSession(
        m.copyWith(
          opponent: _opponentCtrl.text.trim(),
          sessionType: _sessionType,
          closesAt: _closesAt?.millisecondsSinceEpoch ?? 0,
          fxLevel: _fxLevel,
          crowdProfile: _crowdProfile,
          stadiumTheme: _stadiumTheme,
        ),
      );
    }
    _metrics.onSessionReady(clearPlayers ? 'created_clear' : 'created');
  }

  Future<void> _withCardUse(
    StadiumCardRegistryEntry entry,
    Future<void> Function() action,
  ) async {
    await getIt<StadiumCardRegistryRepository>()
        .recordCardUse(clubTag: FanAppIdentity.registryAppId, entry: entry);
    await action();
  }

  Future<void> _replaceRegistryCard(StadiumCardRegistryEntry entry) async {
    final state = _cubit.state;
    final starters = state.formationOrder.take(11).toList();
    if (starters.isEmpty) {
      await _withCardUse(entry, () => _cubit.addRegistryCardToPitch(entry));
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF181818),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'استبدال من يخرج؟',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              for (final id in starters)
                ListTile(
                  title: Text(
                    _labelForId(state, id),
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(ctx, id),
                ),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    await _withCardUse(
      entry,
      () async {
        _metrics.onAction('card_replace');
        await _cubit.replacePitchPlayerWithRegistry(playerId: picked, entry: entry);
        _metrics.onPlayerEdit();
      },
    );
  }

  Future<void> _disableVoting() async {
    _metrics.onAction('disable_voting');
    await _cubit.setVotingEnabled(false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إيقاف التصويت للجمهور')),
    );
  }

  Future<void> _publishVoting() async {
    _metrics.onAction('publish_voting');
    try {
      await _cubit.publishVoting(
        formation: _formationPick,
        applyFormationFirst: true,
        resetVotesFirst: false,
      );
    } catch (e) {
      if (mounted) {
        OwnerRecoveryMode.showPublishInterrupted(context, e.toString());
      }
      rethrow;
    }
    _metrics.onVotingPublished();
    await _metrics.persist(abandoned: false);
    if (!mounted) return;
    final elite = _metrics.reachedEliteWindow;
    final n = _metrics.cognitiveInterruptionCount;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          elite
              ? 'مفعّل — ${_metrics.elapsedLabel} · $n انقطاع (تدفق قوي)'
              : 'مفعّل — ${_metrics.elapsedLabel} · $n انقطاع (راجع الـ HUD)',
        ),
        duration: StadiumCmsDesign.motionNormal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final club = FanAppIdentity.registryAppId;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _metrics.onBackNavigation();
      },
      child: BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<MatchVotesAdminCubit, MatchVotesAdminState>(
        listenWhen: (p, c) => p.message != c.message || p.match?.id != c.match?.id,
        listener: (context, state) {
          final m = state.message;
          if (m != null && m.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
            _cubit.clearFeedback();
          }
          if (state.match != null && state.match!.id.isNotEmpty) {
            _syncSessionFields(state.match);
          }
        },
        builder: (context, state) {
          final cubit = context.read<MatchVotesAdminCubit>();
          final m = state.match;
          if (m != null && m.formation.isNotEmpty) {
            _formationPick = FormationEditorPanel.formations.contains(m.formation)
                ? m.formation
                : _formationPick;
          }
          final orderLabels =
              state.formationOrder.map((id) => _labelForId(state, id)).toList();
          final hasSession = m != null && m.id.isNotEmpty;

          final resumeSnap =
              _hideResumeBanner ? null : _workspaceSnapshot;

          return Theme(
            data: ThemeData(
              cardTheme: StadiumCmsDesign.cardTheme(),
              scaffoldBackgroundColor: Colors.transparent,
            ),
            child: DecoratedBox(
            decoration: AdminControlVisualSystem.scaffoldDecoration(_identity),
            child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AdminControlVisualSystem.cmsAppBar(
              identity: _identity,
              title: 'مركز المباراة · ${_identity.appName}',
              bottom: state.busy
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(3),
                      child: LinearProgressIndicator(minHeight: 3),
                    )
                  : null,
            ),
            floatingActionButton: _tabs.index == 0
                ? FloatingActionButton.extended(
                    onPressed: state.busy
                        ? null
                        : () => showMatchVotePlayerEditor(
                              context: context,
                              onSave: (p) async {
                                await cubit.upsertPlayer(p);
                                _metrics.onPlayerEdit();
                                final cards = await getIt<StadiumCardRegistryRepository>()
                                    .watchCards(club)
                                    .first;
                                await syncMatchPitchPlayerToCardRegistry(
                                  registry: getIt<StadiumCardRegistryRepository>(),
                                  clubTag: club,
                                  player: p,
                                  existing: cards,
                                );
                              },
                            ),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('لاعب'),
                  )
                : null,
            body: Column(
              children: [
                AdminControlVisualSystem.glassTabBar(
                  controller: _tabs,
                  identity: _identity,
                  labels: const [
                    'لوحة التحكم',
                    'مكتبة الكروت',
                    'معاينة وتفعيل',
                  ],
                ),
                StreamBuilder<List<StadiumCmsPendingOp>>(
                  stream: getIt<StadiumCmsRepository>().watchPendingOps(club),
                  builder: (context, pendingSnap) {
                    final pending = pendingSnap.data ?? const [];
                    return StadiumCmsRecoveryBanner(
                      identity: _identity,
                      pending: pending,
                      busy: state.busy,
                      lastSyncMessage: _lastPendingSyncMessage,
                      onRetryAll: () async {
                        await _flushPendingOps();
                      },
                    );
                  },
                ),
                StadiumCmsCommandBar(
                  identity: _identity,
                  busy: state.busy,
                  operatorWarning: state.operatorWarning,
                  workspaceSnapshot: resumeSnap,
                  metrics: _metrics,
                  onTemplateApplied: () {
                    final sm = _cubit.state.match;
                    if (sm != null) _syncSessionFields(sm);
                    _loadWorkspaceSnapshot();
                  },
                  onResume: () async {
                    _metrics.onAction('session_resume');
                    await _cubit.resumeWorkspace();
                    _metrics.onSessionReady('restored');
                    if (!mounted) return;
                    final sm = _cubit.state.match;
                    if (sm != null) _syncSessionFields(sm);
                    await _loadWorkspaceSnapshot();
                  },
                  onDismissResume: () => setState(() => _hideResumeBanner = true),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                ListView(
                  padding: StadiumCmsDesign.pagePadding,
                  children: [
                SessionStatusTimelineWidget(match: m),
                StadiumCmsDesign.sectionGap(),
                OwnerOperationsPanel(
                  match: m,
                  clubTag: club,
                ),
                StadiumCmsDesign.sectionGap(),
                _SessionTab(
                  identity: _identity,
                  busy: state.busy,
                  hasSession: hasSession,
                  match: m,
                  titleCtrl: _titleCtrl,
                  opponentCtrl: _opponentCtrl,
                  sessionType: _sessionType,
                  sessionTypes: _sessionTypes,
                  sessionTypeLabel: _sessionTypeLabel,
                  formationPick: _formationPick,
                  closesAt: _closesAt,
                  clubPath: MatchVotesRtdbPaths.root(club),
                  registryPath: StadiumCardRegistryPaths.root(club),
                  onSessionType: (v) => setState(() => _sessionType = v),
                  onFormation: (f) => setState(() => _formationPick = f),
                  onPickClose: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _closesAt ?? now.add(const Duration(hours: 3)),
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 30)),
                    );
                    if (picked == null || !mounted) return;
                    if (!context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_closesAt ?? picked),
                    );
                    if (time == null) return;
                    setState(() {
                      _closesAt = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                  onClearClose: () => setState(() => _closesAt = null),
                  onCreate: _createSession,
                  onSaveMeta: () => _saveSessionMeta(state),
                  onSetVoting: null,
                  onResetVotes: null,
                  fxLevel: _fxLevel,
                  crowdProfile: _crowdProfile,
                  stadiumTheme: _stadiumTheme,
                  onFxLevel: (v) => setState(() => _fxLevel = v),
                  onCrowdProfile: (v) => setState(() => _crowdProfile = v),
                  onStadiumTheme: (v) => setState(() => _stadiumTheme = v),
                  onTemplateApplied: () {
                    final sm = _cubit.state.match;
                    if (sm != null) _syncSessionFields(sm);
                  },
                  onDuplicateSession: cubit.duplicateSession,
                  onCreateClearPlayers: () => _createSession(clearPlayers: true),
                ),
                    StadiumCmsDesign.sectionGap(),
                    StadiumQuickLineupPanel(
                      identity: _identity,
                      busy: state.busy,
                      formation: _formationPick,
                      metrics: _metrics,
                      onFormationChanged: (f) => setState(() => _formationPick = f),
                    ),
                    StadiumCmsDesign.sectionGap(),
                    StadiumCmsFormationPreview(
                      formation: _formationPick,
                      accent: _identity.tacticalLineAccent,
                    ),
                    StadiumCmsDesign.sectionGap(),
                    FormationEditorPanel(
                      orderedPlayerLabels: orderLabels,
                      onReorder: cubit.reorderFormation,
                      selectedFormation: _formationPick,
                      onFormationChanged: (f) => setState(() => _formationPick = f),
                      onApply: () => cubit.applyFormation(_formationPick),
                      busy: state.busy,
                    ),
                    StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceLg),
                    StadiumCmsDesign.sectionHeader('التشكيلة والبدلاء', _identity),
                    StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
                    if (state.bundle.players.isEmpty)
                      StadiumCmsDesign.emptyState(
                        icon: Icons.groups_outlined,
                        title: 'لا لاعبين على الملعب',
                        hint: 'أضف من المكتبة (ملعب/بدلاء) أو اضغط + لاعب',
                      )
                    else ...[
                      ..._starters(state).map(
                        (p) => _PlayerTile(
                          identity: _identity,
                          player: p,
                          busy: state.busy,
                          badge: 'أساسي',
                          onPreview: () => showMatchCardStadiumPreview(
                            context: context,
                            player: p.toPastPlayerDto(),
                          ),
                          onEdit: () => showMatchVotePlayerEditor(
                            context: context,
                            existing: p,
                            onSave: (np) async {
                              await cubit.upsertPlayer(np);
                              _metrics.onPlayerEdit();
                              final cards = await getIt<StadiumCardRegistryRepository>()
                                  .watchCards(club)
                                  .first;
                              await syncMatchPitchPlayerToCardRegistry(
                                registry: getIt<StadiumCardRegistryRepository>(),
                                clubTag: club,
                                player: np,
                                existing: cards,
                              );
                            },
                          ),
                          onDelete: () async {
                            _metrics.onAction('player_delete');
                            await cubit.removePlayer(p.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('حُذف ${p.name}')),
                              );
                            }
                          },
                        ),
                      ),
                      StadiumCmsDesign.sectionGap(),
                      Text('البدلاء', style: StadiumCmsDesign.caption.copyWith(color: StadiumCmsDesign.textSecondary)),
                      StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
                      if (_bench(state).isEmpty)
                        StadiumCmsDesign.emptyState(
                          icon: Icons.event_seat_outlined,
                          title: 'لا بدلاء بعد',
                          hint: 'من المكتبة اضغط أيقونة المقعد',
                        )
                      else
                        ..._bench(state).map(
                          (p) => _PlayerTile(
                            identity: _identity,
                            player: p,
                            busy: state.busy,
                            badge: 'بديل',
                            onPreview: () => showMatchCardStadiumPreview(
                              context: context,
                              player: p.toPastPlayerDto(),
                            ),
                            onEdit: () => showMatchVotePlayerEditor(
                              context: context,
                              existing: p,
                              onSave: (np) async {
                                await cubit.upsertPlayer(np);
                                final cards = await getIt<StadiumCardRegistryRepository>()
                                    .watchCards(club)
                                    .first;
                                await syncMatchPitchPlayerToCardRegistry(
                                  registry: getIt<StadiumCardRegistryRepository>(),
                                  clubTag: club,
                                  player: np,
                                  existing: cards,
                                );
                              },
                            ),
                            onDelete: () async {
                              await cubit.removePlayer(p.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('حُذف ${p.name}')),
                                );
                              }
                            },
                          ),
                        ),
                    ],
                  ],
                ),
                StadiumSmartCardLibraryTab(
                  clubTag: club,
                  busy: state.busy,
                  onLibrarySearch: _metrics.onLibrarySearch,
                  onCardUploadAttempt: _metrics.onCardUploadAttempt,
                  onPitch: (e) => _withCardUse(e, () async {
                    _metrics.onAction('card_pitch');
                    await cubit.addRegistryCardToPitch(e);
                    _metrics.onPlayerEdit();
                  }),
                  onBench: (e) => _withCardUse(e, () async {
                    _metrics.onAction('card_bench');
                    await cubit.addRegistryCardToBench(e);
                    _metrics.onPlayerEdit();
                  }),
                  onReplace: (e) => _replaceRegistryCard(e),
                  onFavorite: (e) => getIt<StadiumCardRegistryRepository>()
                      .toggleFavorite(clubTag: club, entry: e),
                ),
                _PreviewTab(
                  identity: _identity,
                  hasSession: hasSession,
                  match: m,
                  playerCount: state.bundle.players.length,
                  votingEnabled: m?.votingEnabled ?? false,
                  busy: state.busy,
                  onPublish: _publishVoting,
                  onDisable: _disableVoting,
                ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: StadiumCmsMetricsHud(
              identity: _identity,
              metrics: _metrics,
            ),
            ),
          ),
          );
        },
      ),
    ),
    );
  }

  List<MatchPitchPlayer> _starters(MatchVotesAdminState state) {
    final byId = {for (final p in state.bundle.players) p.id: p};
    final out = <MatchPitchPlayer>[];
    for (final id in state.formationOrder.take(11)) {
      final p = byId[id];
      if (p != null) out.add(p);
    }
    for (final p in state.bundle.players) {
      if (!out.contains(p) && out.length < 11) out.add(p);
    }
    return out;
  }

  List<MatchPitchPlayer> _bench(MatchVotesAdminState state) {
    final starterIds = state.formationOrder.take(11).toSet();
    return state.bundle.players.where((p) => !starterIds.contains(p.id)).toList();
  }
}

class _SessionTab extends StatelessWidget {
  const _SessionTab({
    required this.identity,
    required this.busy,
    required this.hasSession,
    required this.match,
    required this.titleCtrl,
    required this.opponentCtrl,
    required this.sessionType,
    required this.sessionTypes,
    required this.sessionTypeLabel,
    required this.formationPick,
    required this.closesAt,
    required this.clubPath,
    required this.registryPath,
    required this.onSessionType,
    required this.onFormation,
    required this.onPickClose,
    required this.onClearClose,
    required this.onCreate,
    required this.onSaveMeta,
    this.onSetVoting,
    this.onResetVotes,
    required this.fxLevel,
    required this.crowdProfile,
    required this.stadiumTheme,
    required this.onFxLevel,
    required this.onCrowdProfile,
    required this.onStadiumTheme,
    required this.onTemplateApplied,
    required this.onDuplicateSession,
    required this.onCreateClearPlayers,
  });

  final CrowdAppIdentity identity;
  final bool busy;
  final bool hasSession;
  final MatchActiveSession? match;
  final TextEditingController titleCtrl;
  final TextEditingController opponentCtrl;
  final String sessionType;
  final List<String> sessionTypes;
  final String Function(String) sessionTypeLabel;
  final String formationPick;
  final DateTime? closesAt;
  final String clubPath;
  final String registryPath;
  final ValueChanged<String> onSessionType;
  final ValueChanged<String> onFormation;
  final VoidCallback onPickClose;
  final VoidCallback onClearClose;
  final VoidCallback onCreate;
  final VoidCallback onSaveMeta;
  final ValueChanged<bool>? onSetVoting;
  final Future<void> Function()? onResetVotes;
  final String fxLevel;
  final String crowdProfile;
  final String stadiumTheme;
  final ValueChanged<String> onFxLevel;
  final ValueChanged<String> onCrowdProfile;
  final ValueChanged<String> onStadiumTheme;
  final VoidCallback onTemplateApplied;
  final Future<void> Function() onDuplicateSession;
  final VoidCallback onCreateClearPlayers;

  static const _fxLevels = ['calm', 'warm', 'hot', 'inferno'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasSession)
          StadiumCmsDesign.emptyState(
            icon: Icons.event_busy_outlined,
            title: 'لا توجد جلسة نشطة',
            hint: 'اختر قالباً أعلاه أو أنشئ جلسة هنا',
          ),
        StadiumCmsDesign.surfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hasSession ? 'جلسة نشطة' : 'إعداد جلسة',
                      style: StadiumCmsDesign.title(identity),
                    ),
                  ),
                  if (hasSession && match!.votingEnabled)
                    StadiumCmsDesign.statusChip(
                      label: 'مباشر',
                      semantic: StadiumCmsSemantic.live,
                      identity: identity,
                      pulse: true,
                    )
                  else if (hasSession)
                    StadiumCmsDesign.statusChip(
                      label: 'مسودة',
                      semantic: StadiumCmsSemantic.transient,
                      identity: identity,
                    ),
                ],
              ),
              if (hasSession && match != null)
                Padding(
                  padding: const EdgeInsets.only(top: StadiumCmsDesign.spaceXs),
                  child: Text('معرف: ${match!.id}', style: StadiumCmsDesign.caption),
                ),
              StadiumCmsDesign.sectionGap(),
              TextField(
                controller: titleCtrl,
                enabled: !busy,
                decoration: StadiumCmsDesign.fieldDecoration('اسم المباراة / العنوان'),
              ),
              StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
              TextField(
                controller: opponentCtrl,
                enabled: !busy,
                decoration: StadiumCmsDesign.fieldDecoration('الفريق المنافس'),
              ),
              StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
              DropdownButtonFormField<String>(
                  value: sessionTypes.contains(sessionType) ? sessionType : 'league',
                  dropdownColor: StadiumCmsDesign.surfaceElevated,
                  decoration: StadiumCmsDesign.fieldDecoration('نوع الجلسة'),
                  items: sessionTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(sessionTypeLabel(t))))
                      .toList(),
                  onChanged: busy ? null : (v) => onSessionType(v ?? 'league'),
                ),
              StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
              DropdownButtonFormField<String>(
                value: FormationEditorPanel.formations.contains(formationPick)
                    ? formationPick
                    : '4-3-3',
                dropdownColor: StadiumCmsDesign.surfaceElevated,
                decoration: StadiumCmsDesign.fieldDecoration('التشكيلة الافتراضية'),
                items: FormationEditorPanel.formations
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: busy ? null : (v) => onFormation(v ?? '4-3-3'),
              ),
              StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  closesAt == null
                      ? 'وقت الإغلاق: غير محدد'
                      : 'إغلاق: ${closesAt!.toLocal()}',
                  style: StadiumCmsDesign.subtitle,
                ),
                trailing: Wrap(
                  spacing: StadiumCmsDesign.spaceXs,
                  children: [
                    TextButton(onPressed: busy ? null : onPickClose, child: const Text('تحديد')),
                    if (closesAt != null)
                      TextButton(onPressed: busy ? null : onClearClose, child: const Text('مسح')),
                  ],
                ),
              ),
              StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
              DropdownButtonFormField<String>(
                value: _fxLevels.contains(fxLevel) ? fxLevel : 'warm',
                dropdownColor: StadiumCmsDesign.surfaceElevated,
                decoration: StadiumCmsDesign.fieldDecoration('مستوى FX (مرجع CMS)'),
                items: _fxLevels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: busy ? null : (v) => onFxLevel(v ?? 'warm'),
              ),
              StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
              TextFormField(
                key: ValueKey('crowd_$crowdProfile'),
                enabled: !busy,
                initialValue: crowdProfile,
                decoration: StadiumCmsDesign.fieldDecoration('بروفايل الجمهور'),
                onChanged: onCrowdProfile,
              ),
              StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
              TextFormField(
                key: ValueKey('theme_$stadiumTheme'),
                enabled: !busy,
                initialValue: stadiumTheme,
                decoration: StadiumCmsDesign.fieldDecoration('ثيم الملعب'),
                onChanged: onStadiumTheme,
              ),
              StadiumCmsDesign.sectionGap(),
              if (hasSession) ...[
                FilledButton.icon(
                  onPressed: busy ? null : onSaveMeta,
                  style: StadiumCmsDesign.primaryButton(identity),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('حفظ بيانات الجلسة'),
                ),
                if (onSetVoting != null)
                  SwitchListTile(
                    value: match!.votingEnabled,
                    onChanged: busy ? null : onSetVoting,
                    title: Text('التصويت مفتوح', style: StadiumCmsDesign.subtitle),
                  ),
              ] else ...[
                FilledButton.icon(
                  onPressed: busy ? null : onCreate,
                  style: StadiumCmsDesign.primaryButton(identity),
                  icon: const Icon(Icons.fiber_new_outlined),
                  label: const Text('إنشاء جلسة'),
                ),
                TextButton(
                  onPressed: busy ? null : onCreateClearPlayers,
                  child: const Text('جلسة جديدة + مسح اللاعبين'),
                ),
              ],
              if (onResetVotes != null) ...[
                StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
                OutlinedButton(
                  onPressed: busy || !hasSession ? null : () => onResetVotes!(),
                  style: StadiumCmsDesign.destructiveOutlined(),
                  child: const Text('تصفير الأصوات'),
                ),
              ],
              if (hasSession) ...[
                StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
                OutlinedButton.icon(
                  onPressed: busy ? null : onDuplicateSession,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('نسخ الجلسة الحالية'),
                ),
              ],
              if (busy) StadiumCmsDesign.inlineBusy(),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.identity,
    required this.player,
    required this.busy,
    required this.badge,
    required this.onPreview,
    required this.onEdit,
    required this.onDelete,
  });

  final CrowdAppIdentity identity;
  final MatchPitchPlayer player;
  final bool busy;
  final String badge;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: StadiumCmsDesign.spaceSm),
      child: StadiumCmsDesign.surfaceCard(
        elevation: StadiumCmsDesign.elevationFlat,
        padding: const EdgeInsets.symmetric(horizontal: StadiumCmsDesign.spaceSm, vertical: 4),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: StadiumCmsDesign.statusChip(
            label: badge,
            semantic: badge == 'أساسي' ? StadiumCmsSemantic.primary : StadiumCmsSemantic.idle,
            identity: identity,
          ),
          title: Text(player.name, style: StadiumCmsDesign.subtitle.copyWith(color: StadiumCmsDesign.textPrimary)),
          subtitle: Text(
            '${player.position} · ${player.votes} صوت'
            '${player.cardImageUrl.trim().isNotEmpty ? ' · كرت' : ''}',
            style: StadiumCmsDesign.caption,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.stadium_outlined, color: StadiumCmsDesign.textSecondary, size: 20),
                onPressed: busy ? null : onPreview,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: StadiumCmsDesign.textSecondary, size: 20),
                onPressed: busy ? null : onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: StadiumCmsDesign.semanticDestructive, size: 20),
                onPressed: busy ? null : onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewTab extends StatefulWidget {
  const _PreviewTab({
    required this.identity,
    required this.hasSession,
    required this.match,
    required this.playerCount,
    required this.votingEnabled,
    required this.busy,
    required this.onPublish,
    this.onDisable,
  });

  final CrowdAppIdentity identity;
  final bool hasSession;
  final MatchActiveSession? match;
  final int playerCount;
  final bool votingEnabled;
  final bool busy;
  final VoidCallback onPublish;
  final VoidCallback? onDisable;

  @override
  State<_PreviewTab> createState() => _PreviewTabState();
}

class _PreviewTabState extends State<_PreviewTab> {
  late final MatchVotingCubit _previewCubit;

  @override
  void initState() {
    super.initState();
    _previewCubit = MatchVotingCubit(
      repository: getIt<MatchVotesRepository>(),
      auth: getIt<FirebaseAuth>(),
      serverTime: getIt<EgyptServerTimeService>(),
      clubTag: FanAppIdentity.registryAppId,
    )..start();
  }

  @override
  void dispose() {
    _previewCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.identity;

    if (!widget.hasSession) {
      return ListView(
        padding: StadiumCmsDesign.pagePadding,
        children: [
          StadiumCmsDesign.emptyState(
            icon: Icons.sports_soccer_outlined,
            title: 'لا جلسة للمعاينة',
            hint: 'أنشئ جلسة من لوحة التحكم أو طبّق قالباً سريعاً',
          ),
        ],
      );
    }

    return ListView(
      padding: StadiumCmsDesign.pagePadding,
      children: [
        Wrap(
          spacing: StadiumCmsDesign.spaceSm,
          runSpacing: StadiumCmsDesign.spaceSm,
          children: [
            StadiumCmsDesign.statusChip(
              label: 'جلسة جاهزة',
              semantic: StadiumCmsSemantic.primary,
              identity: id,
            ),
            StadiumCmsDesign.statusChip(
              label: '${widget.playerCount} لاعب',
              semantic: widget.playerCount > 0 ? StadiumCmsSemantic.primary : StadiumCmsSemantic.warning,
              identity: id,
            ),
            StadiumCmsDesign.statusChip(
              label: widget.votingEnabled ? 'تصويت مباشر' : 'تصويت مغلق',
              semantic: widget.votingEnabled ? StadiumCmsSemantic.live : StadiumCmsSemantic.idle,
              identity: id,
              pulse: widget.votingEnabled,
            ),
          ],
        ),
        StadiumCmsDesign.sectionGap(),
        AdminControlVisualSystem.cmsPitchPreview(
          identity: id,
          child: BlocProvider.value(
            value: _previewCubit,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const MatchStadiumVotingLayer(),
                if (widget.playerCount == 0)
                  Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: StadiumCmsDesign.emptyState(
                      icon: Icons.person_off_outlined,
                      title: 'أضف لاعبين قبل التفعيل',
                      hint: 'من لوحة التحكم أو المكتبة',
                    ),
                  ),
              ],
            ),
          ),
        ),
        StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceLg),
        FilledButton.icon(
          onPressed: widget.busy || widget.playerCount == 0 ? null : widget.onPublish,
          style: StadiumCmsDesign.liveButton(),
          icon: const Icon(Icons.play_circle_fill),
          label: const Text('ابدأ التصويت للجمهور'),
        ),
        if (widget.onDisable != null) ...[
          StadiumCmsDesign.sectionGap(StadiumCmsDesign.spaceSm),
          OutlinedButton(
            onPressed: widget.busy || !widget.votingEnabled
                ? null
                : widget.onDisable,
            style: StadiumCmsDesign.destructiveOutlined(),
            child: const Text('إيقاف التصويت'),
          ),
        ],
        StadiumCmsDesign.sectionGap(),
        Text(
          'معاينة حية = نفس RTDB للجمهور. الكروت اليدوية بدون طبقات تغطي التصميم.',
          style: StadiumCmsDesign.caption,
        ),
        if (widget.busy) StadiumCmsDesign.inlineBusy(),
      ],
    );
  }
}

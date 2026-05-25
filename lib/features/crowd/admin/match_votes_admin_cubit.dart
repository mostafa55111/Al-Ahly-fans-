import 'dart:async';
import 'dart:ui' show Offset;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_lineup_slot.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_workspace_snapshot.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_match_kit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_session_template.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_tactical_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_tactical_presets.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/formation_templates.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_state.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/voting_session_guard_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/owner_audit_log.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/session_publish_preflight.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';
import 'package:uuid/uuid.dart';

class MatchVotesAdminCubit extends Cubit<MatchVotesAdminState> {
  MatchVotesAdminCubit({
    required MatchVotesRepository repository,
    required StadiumCmsRepository cmsRepository,
    required EgyptServerTimeService serverTime,
    required String clubTag,
  })  : _repository = repository,
        _cms = cmsRepository,
        _serverTime = serverTime,
        _clubTag = clubTag.trim().toLowerCase(),
        super(const MatchVotesAdminState());

  final MatchVotesRepository _repository;
  final StadiumCmsRepository _cms;
  final EgyptServerTimeService _serverTime;
  final String _clubTag;
  final _uuid = const Uuid();
  final VotingSessionGuardService _guard = VotingSessionGuardService();
  final SessionPublishPreflight _preflight = SessionPublishPreflight();

  StreamSubscription<MatchVotesBundle>? _sub;

  void start() {
    _sub?.cancel();
    _sub = _repository.watchBundle(_clubTag).listen(
      (bundle) {
        final warning = _guard
            .validateLiveSessionConflict(bundle.match)
            .warning;
        emit(
          state.copyWith(
            bundle: bundle,
            formationOrder: _mergeOrder(state.formationOrder, bundle.players),
            operatorWarning: warning,
          ),
        );
      },
      onError: (Object e, _) {
        emit(state.copyWith(message: e.toString()));
      },
    );
  }

  List<String> _mergeOrder(List<String> prev, List<MatchPitchPlayer> players) {
    final ids = players.map((e) => e.id).toSet();
    final kept = prev.where(ids.contains).toList();
    for (final p in players) {
      if (!kept.contains(p.id)) kept.add(p.id);
    }
    return kept;
  }

  void reorderFormation(int oldIndex, int newIndex) {
    final list = List<String>.from(state.formationOrder);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    emit(state.copyWith(formationOrder: list));
  }

  Future<void> _runBusy(Future<void> Function() job) async {
    emit(state.copyWith(busy: true, message: null));
    try {
      await job();
      emit(state.copyWith(busy: false));
    } catch (e) {
      emit(state.copyWith(busy: false, message: e.toString()));
    }
  }

  Future<void> createSession({
    required String title,
    required String formation,
    bool clearPlayers = false,
    String opponent = '',
    String sessionType = 'league',
    int closesAt = 0,
    String fxLevel = 'warm',
    String crowdProfile = 'standard',
    String stadiumTheme = 'default',
  }) {
    return _runBusy(() async {
      if (clearPlayers) {
        await _repository.adminRemoveAllPlayers(_clubTag);
      }
      final id = _uuid.v4();
      final session = MatchActiveSession(
        id: id,
        title: title.trim().isEmpty ? 'تصويت المباراة' : title.trim(),
        votingEnabled: false,
        formation: formation,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        opponent: opponent,
        sessionType: sessionType,
        closesAt: closesAt,
        fxLevel: fxLevel,
        crowdProfile: crowdProfile,
        stadiumTheme: stadiumTheme,
      );
      await _repository.adminSetActiveMatch(
        clubTag: _clubTag,
        session: session,
      );
      await _persistWorkspaceSnapshot();
    });
  }

  Future<void> setVotingEnabled(bool v) {
    return _runBusy(() => _repository.adminSetVotingEnabled(_clubTag, v));
  }

  Future<void> resetVotes() {
    return _runBusy(() => _repository.adminResetVotes(_clubTag));
  }

  Future<void> upsertPlayer(MatchPitchPlayer p) {
    return _runBusy(() async {
      await _repository.adminUpsertPlayer(clubTag: _clubTag, player: p);
      await _persistLastLineupSnapshot();
      await _persistWorkspaceSnapshot();
    });
  }

  Future<void> removePlayer(String id) {
    return _runBusy(() => _repository.adminRemovePlayer(_clubTag, id));
  }

  Future<void> applyFormation(String formation) {
    return _runBusy(() async {
      await _repository.adminApplyFormation(
        clubTag: _clubTag,
        formation: formation,
        orderedPlayerIds: state.formationOrder,
      );
      await _persistLastLineupSnapshot();
    });
  }

  Future<void> updateActiveSession(MatchActiveSession session) {
    return _runBusy(() => _repository.adminSetActiveMatch(
          clubTag: _clubTag,
          session: session,
        ));
  }

  Future<void> publishVoting({
    required String formation,
    bool applyFormationFirst = true,
    bool resetVotesFirst = false,
  }) {
    return _runBusy(() async {
      final m = state.match;
      if (m == null || m.id.isEmpty) {
        throw StateError('أنشئ جلسة أولاً');
      }
      final preflight = _preflight.evaluate(
        bundle: state.bundle,
        formationOrder: state.formationOrder,
        serverTime: _serverTime,
      );
      if (!preflight.ok) {
        throw StateError(preflight.blockers.join(' · '));
      }
      if (applyFormationFirst) {
        await _repository.adminApplyFormation(
          clubTag: _clubTag,
          formation: formation,
          orderedPlayerIds: state.formationOrder,
        );
      }
      if (resetVotesFirst) {
        await _repository.adminResetVotes(_clubTag);
      }
      await _serverTime.refreshOffset();
      final closesAtServer = m.closesAt > 0
          ? m.closesAt
          : _serverTime.serverNowMs + EgyptServerTimeService.voteWindowMs;
      await _repository.adminOpenVotingSession(
        clubTag: _clubTag,
        closesAtServerMs: closesAtServer,
      );
      if (getIt.isRegistered<OwnerAuditLog>()) {
        await getIt<OwnerAuditLog>().logSessionPublish(m.id);
        await getIt<OwnerAuditLog>().logLineupPublish(m.id);
      }
      await _persistLastLineupSnapshot();
      await _persistWorkspaceSnapshot();
    });
  }

  /// نسخ الجلسة الحالية (لاعبون جدد + جلسة جديدة، تصويت مغلق).
  Future<void> duplicateSession() {
    return _runBusy(() async {
      final m = state.match;
      if (m == null || m.id.isEmpty) throw StateError('لا جلسة لنسخها');
      final newSession = m.copyWith(
        id: _uuid.v4(),
        votingEnabled: false,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        title: '${m.title} (نسخة)',
      );
      final newOrder = <String>[];
      for (final p in state.bundle.players) {
        final nid = _uuid.v4();
        newOrder.add(nid);
        await _repository.adminUpsertPlayer(
          clubTag: _clubTag,
          player: MatchPitchPlayer(
            id: nid,
            name: p.name,
            imageUrl: p.imageUrl,
            rating: p.rating,
            position: p.position,
            x: p.x,
            y: p.y,
            votes: 0,
            team: p.team,
            glowColor: p.glowColor,
            visible: p.visible,
            highlighted: p.highlighted,
            cardImageUrl: p.cardImageUrl,
            cardThumbnailUrl: p.cardThumbnailUrl,
            cardStyle: p.cardStyle,
            cardRarity: p.cardRarity,
            cardAnimatedOverlay: p.cardAnimatedOverlay,
            cardTheme: p.cardTheme,
            cardOverlayAssetUrl: p.cardOverlayAssetUrl,
            cardOverlayEnabled: p.cardOverlayEnabled,
            cardOverlayBlend: p.cardOverlayBlend,
            cardOverlayOpacity: p.cardOverlayOpacity,
          ),
        );
      }
      await _repository.adminSetActiveMatch(clubTag: _clubTag, session: newSession);
      emit(state.copyWith(formationOrder: newOrder));
    });
  }

  Future<void> applySessionTemplate(StadiumSessionTemplate template) {
    return _runBusy(() async {
      var m = state.match;
      final title = template.defaultTitle.isEmpty ? template.name : template.defaultTitle;
      final identity = template.isBuiltin
          ? StadiumTacticalPresets.forTemplateId(template.id)
          : StadiumTacticalIdentity.fromSessionContext(
              formation: template.formation,
              sessionType: template.sessionType,
              opponent: template.opponent,
              fxLevel: template.fxLevel,
              crowdProfile: template.crowdProfile,
              stadiumTheme: template.stadiumTheme,
              overlaysProfile: 'default',
            );
      final fields = identity.sessionFields();
      if (m == null || m.id.isEmpty) {
        final session = MatchActiveSession(
          id: _uuid.v4(),
          title: title,
          votingEnabled: false,
          formation: template.formation,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          opponent: template.opponent,
          sessionType: template.sessionType,
          fxLevel: template.fxLevel,
          crowdProfile: fields.crowdProfile,
          stadiumTheme: fields.stadiumTheme,
        );
        await _repository.adminSetActiveMatch(clubTag: _clubTag, session: session);
      } else {
        await _repository.adminSetActiveMatch(
          clubTag: _clubTag,
          session: m.copyWith(
            title: title,
            formation: template.formation,
            opponent: template.opponent.isEmpty ? m.opponent : template.opponent,
            sessionType: template.sessionType,
            fxLevel: template.fxLevel,
            crowdProfile: fields.crowdProfile,
            stadiumTheme: fields.stadiumTheme,
            votingEnabled: false,
          ),
        );
      }
      if (template.lineupSlots.isNotEmpty) {
        await _importLineupCore(
          formation: template.formation,
          slots: template.lineupSlots,
          replaceExisting: true,
        );
      } else {
        await _persistWorkspaceSnapshot();
      }
    });
  }

  /// إضافة كرت للملعب — أقرب مركز تكتيكي تلقائياً.
  Future<void> addRegistryCardToPitch(StadiumCardRegistryEntry entry) {
    return _runBusy(() async {
      final formation = state.match?.formation ?? '4-3-3';
      final order = List<String>.from(state.formationOrder);
      if (order.length >= 11) {
        throw StateError('التشكيلة مكتملة (11)');
      }
      final anchors = FormationTemplates.slotsFor(formation);
      final idx = order.length.clamp(0, anchors.length - 1);
      final pos = anchors[idx];
      final p = _playerFromRegistry(entry, pos);
      order.add(p.id);
      await _repository.adminUpsertPlayer(clubTag: _clubTag, player: p);
      emit(state.copyWith(formationOrder: order));
      await _persistLastLineupSnapshot();
      await _persistWorkspaceSnapshot();
    });
  }

  /// إضافة للبدلاء — خارج ترتيب الـ 11 الأساسيين.
  Future<void> addRegistryCardToBench(StadiumCardRegistryEntry entry) {
    return _runBusy(() async {
      final benchIndex = state.bundle.players.length;
      final x = (0.08 + (benchIndex % 7) * 0.13).clamp(0.05, 0.92);
      final p = _playerFromRegistry(entry, Offset(x, 0.94));
      await _repository.adminUpsertPlayer(clubTag: _clubTag, player: p);
      await _persistLastLineupSnapshot();
      await _persistWorkspaceSnapshot();
    });
  }

  Future<void> replacePitchPlayerWithRegistry({
    required String playerId,
    required StadiumCardRegistryEntry entry,
  }) {
    return _runBusy(() async {
      MatchPitchPlayer? existing;
      for (final p in state.bundle.players) {
        if (p.id == playerId) {
          existing = p;
          break;
        }
      }
      if (existing == null) throw StateError('اللاعب غير موجود');
      final pos = entry.tags.isNotEmpty ? entry.tags.first : existing.position;
      final updated = MatchPitchPlayer(
        id: existing.id,
        name: entry.playerName.trim().isEmpty ? existing.name : entry.playerName.trim(),
        imageUrl: existing.imageUrl,
        rating: existing.rating,
        position: pos,
        x: existing.x,
        y: existing.y,
        votes: existing.votes,
        team: existing.team,
        glowColor: existing.glowColor,
        visible: existing.visible,
        highlighted: existing.highlighted,
        cardImageUrl: entry.imageUrl,
        cardThumbnailUrl: entry.thumbUrl,
        cardStyle: existing.cardStyle,
        cardRarity: entry.rarity,
        cardAnimatedOverlay: existing.cardAnimatedOverlay,
        cardTheme: existing.cardTheme,
        cardOverlayAssetUrl: existing.cardOverlayAssetUrl,
        cardOverlayEnabled: existing.cardOverlayEnabled,
        cardOverlayBlend: existing.cardOverlayBlend,
        cardOverlayOpacity: existing.cardOverlayOpacity,
      );
      await _repository.adminUpsertPlayer(clubTag: _clubTag, player: updated);
      await _persistLastLineupSnapshot();
      await _persistWorkspaceSnapshot();
    });
  }

  MatchPitchPlayer _playerFromRegistry(StadiumCardRegistryEntry entry, Offset pos) {
    return MatchPitchPlayer(
      id: _uuid.v4(),
      name: entry.playerName.trim().isEmpty ? 'لاعب' : entry.playerName.trim(),
      imageUrl: '',
      rating: 80,
      position: entry.tags.isNotEmpty ? entry.tags.first : 'CM',
      x: pos.dx.clamp(0.0, 1.0),
      y: pos.dy.clamp(0.0, 1.0),
      votes: 0,
      team: '',
      glowColor: 'gold',
      visible: true,
      cardImageUrl: entry.imageUrl,
      cardThumbnailUrl: entry.thumbUrl,
      cardRarity: entry.rarity,
    );
  }

  Future<StadiumCmsWorkspaceSnapshot?> readWorkspaceSnapshot() {
    return _cms.readWorkspaceSnapshot(_clubTag);
  }

  Future<void> resumeWorkspace() {
    return _runBusy(() async {
      final snap = await _cms.readWorkspaceSnapshot(_clubTag);
      final last = await _cms.readLastLineup(_clubTag);
      if (last != null && last.starterSlots.isNotEmpty) {
        await loadMatchKit(last);
        return;
      }
      if (snap == null || snap.sessionId.isEmpty) {
        throw StateError('لا جلسة محفوظة للاستئناف');
      }
      var m = state.match;
      if (m == null || m.id.isEmpty) {
        final session = MatchActiveSession(
          id: snap.sessionId,
          title: snap.title,
          votingEnabled: false,
          formation: snap.formation,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          opponent: snap.opponent,
          sessionType: snap.sessionType,
          fxLevel: snap.fxLevel,
          crowdProfile: snap.crowdProfile,
          stadiumTheme: snap.stadiumTheme,
        );
        await _repository.adminSetActiveMatch(clubTag: _clubTag, session: session);
      } else if (m.id == snap.sessionId) {
        await _repository.adminSetActiveMatch(
          clubTag: _clubTag,
          session: m.copyWith(
            title: snap.title,
            formation: snap.formation,
            opponent: snap.opponent,
            sessionType: snap.sessionType,
            fxLevel: snap.fxLevel,
            crowdProfile: snap.crowdProfile,
            stadiumTheme: snap.stadiumTheme,
          ),
        );
      }
    });
  }

  Future<void> importLineup({
    required String formation,
    required List<StadiumLineupSlot> slots,
    bool replaceExisting = true,
  }) {
    return _runBusy(() => _importLineupCore(
          formation: formation,
          slots: slots,
          replaceExisting: replaceExisting,
        ));
  }

  Future<void> _importLineupCore({
    required String formation,
    required List<StadiumLineupSlot> slots,
    required bool replaceExisting,
  }) async {
    if (replaceExisting) {
      await _repository.adminRemoveAllPlayers(_clubTag);
    }
    final anchors = FormationTemplates.slotsFor(formation);
    final order = <String>[];
    final n = slots.length < anchors.length ? slots.length : anchors.length;
    for (var i = 0; i < n; i++) {
      final s = slots[i];
      final id = _uuid.v4();
      order.add(id);
      final pos = anchors[i];
      await _repository.adminUpsertPlayer(
        clubTag: _clubTag,
        player: MatchPitchPlayer(
          id: id,
          name: s.playerName,
          imageUrl: '',
          rating: 80,
          position: s.position,
          x: pos.dx.clamp(0.0, 1.0),
          y: pos.dy.clamp(0.0, 1.0),
          votes: 0,
          team: '',
          glowColor: 'gold',
          visible: true,
          cardImageUrl: s.imageUrl,
          cardThumbnailUrl: s.thumbUrl,
          cardRarity: s.rarity,
        ),
      );
    }
    emit(state.copyWith(formationOrder: order));
    await _repository.adminApplyFormation(
      clubTag: _clubTag,
      formation: formation,
      orderedPlayerIds: order,
    );
    final m = state.match;
    if (m != null && m.id.isNotEmpty) {
      await _repository.adminSetActiveMatch(
        clubTag: _clubTag,
        session: m.copyWith(formation: formation, votingEnabled: false),
      );
    }
    await _persistLastLineupSnapshot(name: 'آخر تشكيلة');
    await _persistWorkspaceSnapshot();
  }

  Future<void> loadSavedLineup(StadiumMatchKit lineup) => loadMatchKit(lineup);

  Future<void> loadMatchKit(StadiumMatchKit kit) => _runBusy(() => _applyMatchKit(kit));

  Future<void> _applyMatchKit(StadiumMatchKit kit) async {
      var m = state.match;
      final title = kit.defaultTitle.isEmpty ? kit.name : kit.defaultTitle;
      final fields = kit.tacticalIdentity.sessionFields();
      if (m == null || m.id.isEmpty) {
        await _repository.adminSetActiveMatch(
          clubTag: _clubTag,
          session: MatchActiveSession(
            id: _uuid.v4(),
            title: title,
            votingEnabled: false,
            formation: kit.formation,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            opponent: kit.opponent,
            sessionType: kit.sessionType,
            fxLevel: kit.fxLevel,
            crowdProfile: fields.crowdProfile,
            stadiumTheme: fields.stadiumTheme,
          ),
        );
      } else {
        await _repository.adminSetActiveMatch(
          clubTag: _clubTag,
          session: m.copyWith(
            title: title,
            formation: kit.formation,
            opponent: kit.opponent.isEmpty ? m.opponent : kit.opponent,
            sessionType: kit.sessionType,
            fxLevel: kit.fxLevel,
            crowdProfile: fields.crowdProfile,
            stadiumTheme: fields.stadiumTheme,
            votingEnabled: false,
          ),
        );
      }
      if (kit.starterSlots.isNotEmpty) {
        await _importLineupCore(
          formation: kit.formation,
          slots: kit.starterSlots,
          replaceExisting: true,
        );
      }
      if (kit.benchSlots.isNotEmpty) {
        await _importBenchSlots(kit.benchSlots);
      }
      await _persistWorkspaceSnapshot(kitName: kit.name);
  }

  Future<void> _importBenchSlots(List<StadiumLineupSlot> slots) async {
    var i = 0;
    for (final s in slots) {
      final x = (0.08 + (i % 7) * 0.13).clamp(0.05, 0.92);
      final id = _uuid.v4();
      await _repository.adminUpsertPlayer(
        clubTag: _clubTag,
        player: MatchPitchPlayer(
          id: id,
          name: s.playerName,
          imageUrl: '',
          rating: 80,
          position: s.position,
          x: x,
          y: 0.94,
          votes: 0,
          team: '',
          glowColor: 'gold',
          visible: true,
          cardImageUrl: s.imageUrl,
          cardThumbnailUrl: s.thumbUrl,
          cardRarity: s.rarity,
        ),
      );
      i++;
    }
  }

  Future<void> loadLastLineup() {
    return _runBusy(() async {
      final last = await _cms.readLastLineup(_clubTag);
      if (last == null || last.starterSlots.isEmpty) {
        throw StateError('لا توجد تشكيلة سابقة');
      }
      await _applyMatchKit(last);
    });
  }

  Future<void> saveCurrentLineupAs(String name) => saveCurrentMatchKit(name: name);

  Future<void> saveCurrentMatchKit({String? name}) {
    return _runBusy(() async {
      final starters = _currentLineupSlots();
      if (starters.isEmpty) throw StateError('لا لاعبين لحفظهم');
      final m = state.match;
      final formation = m?.formation ?? '4-3-3';
      final kitName = (name ?? '').trim().isEmpty
          ? 'Kit ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}'
          : name!.trim();
      final identity = StadiumTacticalIdentity.fromSessionContext(
        formation: formation,
        sessionType: m?.sessionType ?? 'league',
        opponent: m?.opponent ?? '',
        fxLevel: m?.fxLevel ?? 'warm',
        crowdProfile: m?.crowdProfile ?? 'standard',
        stadiumTheme: m?.stadiumTheme ?? 'default',
        overlaysProfile: 'default',
      );
      final fields = identity.sessionFields();
      final kit = StadiumMatchKit(
        id: _uuid.v4(),
        name: kitName,
        formation: formation,
        starterSlots: starters,
        benchSlots: _currentBenchSlots(),
        tacticalIdentity: identity,
        defaultTitle: m?.title ?? '',
        opponent: m?.opponent ?? '',
        sessionType: m?.sessionType ?? 'league',
        fxLevel: m?.fxLevel ?? 'warm',
        crowdProfile: fields.crowdProfile,
        stadiumTheme: fields.stadiumTheme,
        overlaysProfile: fields.overlaysProfile,
        savedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _cms.upsertMatchKit(clubTag: _clubTag, kit: kit);
      await _persistWorkspaceSnapshot(kitName: kitName);
    });
  }

  Future<void> saveSessionTemplateFromCurrent(String name) {
    return _runBusy(() async {
      final m = state.match;
      if (m == null || m.id.isEmpty) throw StateError('أنشئ جلسة أولاً');
      final templateName = name.trim().isEmpty ? m.title : name.trim();
      await _cms.upsertSessionTemplate(
        clubTag: _clubTag,
        template: StadiumSessionTemplate(
          id: _uuid.v4(),
          name: templateName,
          formation: m.formation,
          sessionType: m.sessionType,
          defaultTitle: m.title,
          opponent: m.opponent,
          fxLevel: m.fxLevel,
          crowdProfile: m.crowdProfile,
          stadiumTheme: m.stadiumTheme,
          lineupSlots: _currentLineupSlots(),
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }

  List<StadiumLineupSlot> _currentLineupSlots() {
    final order = state.formationOrder;
    final byId = {for (final p in state.bundle.players) p.id: p};
    final slots = <StadiumLineupSlot>[];
    for (final id in order) {
      final p = byId[id];
      if (p == null) continue;
      slots.add(
        StadiumLineupSlot(
          playerName: p.name,
          imageUrl: p.cardImageUrl.trim().isNotEmpty ? p.cardImageUrl : p.imageUrl,
          thumbUrl: p.cardThumbnailUrl,
          position: p.position,
          rarity: p.cardRarity,
        ),
      );
    }
    return slots;
  }

  List<StadiumLineupSlot> _currentBenchSlots() {
    final starters = state.formationOrder.take(11).toSet();
    final out = <StadiumLineupSlot>[];
    for (final p in state.bundle.players) {
      if (starters.contains(p.id)) continue;
      out.add(
        StadiumLineupSlot(
          playerName: p.name,
          imageUrl: p.cardImageUrl.trim().isNotEmpty ? p.cardImageUrl : p.imageUrl,
          thumbUrl: p.cardThumbnailUrl,
          position: p.position,
          rarity: p.cardRarity,
        ),
      );
    }
    return out;
  }

  Future<void> _persistLastLineupSnapshot({String name = 'آخر تشكيلة'}) async {
    final starters = _currentLineupSlots();
    if (starters.isEmpty) return;
    final m = state.match;
    final formation = m?.formation ?? '4-3-3';
    final identity = StadiumTacticalIdentity.fromSessionContext(
      formation: formation,
      sessionType: m?.sessionType ?? 'league',
      opponent: m?.opponent ?? '',
      fxLevel: m?.fxLevel ?? 'warm',
      crowdProfile: m?.crowdProfile ?? 'standard',
      stadiumTheme: m?.stadiumTheme ?? 'default',
      overlaysProfile: 'default',
    );
    final fields = identity.sessionFields();
    await _cms.writeLastLineup(
      clubTag: _clubTag,
      kit: StadiumMatchKit(
        id: 'last',
        name: name,
        formation: formation,
        starterSlots: starters,
        benchSlots: _currentBenchSlots(),
        tacticalIdentity: identity,
        defaultTitle: m?.title ?? '',
        opponent: m?.opponent ?? '',
        sessionType: m?.sessionType ?? 'league',
        fxLevel: m?.fxLevel ?? 'warm',
        crowdProfile: fields.crowdProfile,
        stadiumTheme: fields.stadiumTheme,
        overlaysProfile: fields.overlaysProfile,
        savedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _persistWorkspaceSnapshot({String kitName = ''}) async {
    final m = state.match;
    if (m == null || m.id.isEmpty) return;
    await _cms.writeWorkspaceSnapshot(
      clubTag: _clubTag,
      snapshot: StadiumCmsWorkspaceSnapshot(
        sessionId: m.id,
        title: m.title,
        formation: m.formation,
        opponent: m.opponent,
        sessionType: m.sessionType,
        fxLevel: m.fxLevel,
        crowdProfile: m.crowdProfile,
        stadiumTheme: m.stadiumTheme,
        overlaysProfile: 'default',
        playerCount: state.bundle.players.length,
        votingEnabled: m.votingEnabled,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        kitName: kitName,
      ),
    );
  }

  void clearFeedback() {
    if (state.message != null) {
      emit(state.copyWith(message: null));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

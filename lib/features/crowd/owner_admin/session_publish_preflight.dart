import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/voting_session_guard_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/card_integrity_validator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/duplicate_session_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';

class SessionPublishPreflightResult {
  const SessionPublishPreflightResult({required this.ok, this.blockers = const []});

  final bool ok;
  final List<String> blockers;
}

/// فحص ما قبل النشر — 11 أساسي، كروت صالحة، سلطة جاهزة.
class SessionPublishPreflight {
  SessionPublishPreflight({
    VotingSessionGuardService? guard,
    CardIntegrityValidator? cards,
    DuplicateSessionGuard? duplicateGuard,
  })  : _guard = guard ?? VotingSessionGuardService(),
        _cards = cards ?? const CardIntegrityValidator(),
        _duplicate = duplicateGuard ?? DuplicateSessionGuard();

  final VotingSessionGuardService _guard;
  final CardIntegrityValidator _cards;
  final DuplicateSessionGuard _duplicate;

  SessionPublishPreflightResult evaluate({
    required MatchVotesBundle bundle,
    required List<String> formationOrder,
    required EgyptServerTimeService serverTime,
    int maxStarters = 11,
  }) {
    final blockers = <String>[];

    final base = _guard.validatePublish(
      bundle: bundle,
      formationOrder: formationOrder,
      serverTime: serverTime,
    );
    if (!base.ok) {
      blockers.add(base.warning ?? 'فشل فحص الجلسة');
    }

    final dup = _duplicate.validate(bundle.match);
    if (!dup.ok) blockers.add(dup.warning ?? 'جلسة مكررة');

    if (formationOrder.length > maxStarters) {
      blockers.add('التشكيلة الأساسية تتجاوز $maxStarters لاعباً');
    }

    if (formationOrder.isEmpty) {
      blockers.add('أضف لاعباً في التشكيلة الأساسية');
    }

    final formation = bundle.match?.formation ?? '4-3-3';
    if (formation.trim().isEmpty) {
      blockers.add('حدّد نظام اللعب');
    }

    final starterIds = formationOrder.toSet();
    for (final id in starterIds) {
      final p = bundle.players.where((e) => e.id == id).firstOrNull;
      if (p == null) {
        blockers.add('لاعب غير موجود في التشكيلة');
        continue;
      }
      final cardCheck = _cards.validatePlayerCard(p);
      if (!cardCheck.ok) {
        blockers.add('كرت ${p.name}: ${cardCheck.message ?? "غير صالح"}');
      }
    }

    if (getIt.isRegistered<AuthorityOrchestrator>()) {
      // orchestrator registered = authority stack ready
    } else {
      blockers.add('سلطة التصنيف غير جاهزة');
    }

    final m = bundle.match;
    final closes = m?.closesAt ?? 0;
    final closesServer = m?.closesAtServer ?? 0;
    if (closes <= 0 && closesServer <= 0) {
      blockers.add('حدّد وقت إغلاق التصويت');
    }

    return SessionPublishPreflightResult(
      ok: blockers.isEmpty,
      blockers: blockers,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}

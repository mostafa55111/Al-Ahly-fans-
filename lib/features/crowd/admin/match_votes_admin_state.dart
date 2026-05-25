import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

class MatchVotesAdminState extends Equatable {
  const MatchVotesAdminState({
    this.bundle = const MatchVotesBundle(),
    this.formationOrder = const [],
    this.busy = false,
    this.message,
    this.operatorWarning,
  });

  final MatchVotesBundle bundle;
  final List<String> formationOrder;
  final bool busy;
  final String? message;
  final String? operatorWarning;

  MatchActiveSession? get match => bundle.match;

  MatchVotesAdminState copyWith({
    MatchVotesBundle? bundle,
    List<String>? formationOrder,
    bool? busy,
    Object? message = _sentinel,
    Object? operatorWarning = _sentinel,
  }) {
    return MatchVotesAdminState(
      bundle: bundle ?? this.bundle,
      formationOrder: formationOrder ?? this.formationOrder,
      busy: busy ?? this.busy,
      message: identical(message, _sentinel) ? this.message : message as String?,
      operatorWarning: identical(operatorWarning, _sentinel)
          ? this.operatorWarning
          : operatorWarning as String?,
    );
  }

  static const _sentinel = Object();

  @override
  List<Object?> get props => [bundle, formationOrder, busy, message, operatorWarning];
}

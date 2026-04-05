import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/datasources/best_player_remote_data_source.dart';

/// Matches BLoC for managing best players state
class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  final BestPlayerRemoteDataSource _dataSource;

  MatchesBloc({required BestPlayerRemoteDataSource dataSource})
      : _dataSource = dataSource,
        super(const MatchesInitial()) {
    on<LoadBestPlayersEvent>((event, emit) async {
      emit(const MatchesLoading());
      
      try {
        debugPrint('🔄 MATCHES BLOC: Loading best players...');
        final players = await _dataSource.fetchBestPlayers();
        
        debugPrint('✅ MATCHES BLOC: Loaded ${players.length} players');
        emit(MatchesLoaded(players));
      } catch (e, stackTrace) {
        debugPrint('❌ MATCHES BLOC ERROR: Failed to load best players: $e');
        debugPrint('❌ MATCHES BLOC Stack trace: $stackTrace');
        emit(MatchesError('Failed to load best players: ${e.toString()}'));
      }
    });
  }
}

/// Matches Events
abstract class MatchesEvent extends Equatable {
  const MatchesEvent();
  
  @override
  List<Object> get props => [];
}

class LoadBestPlayersEvent extends MatchesEvent {
  const LoadBestPlayersEvent();
  
  @override
  List<Object> get props => [];
}

/// Matches States
abstract class MatchesState extends Equatable {
  const MatchesState();
  
  @override
  List<Object> get props => [];
}

class MatchesInitial extends MatchesState {
  const MatchesInitial();
  
  @override
  List<Object> get props => [];
}

class MatchesLoading extends MatchesState {
  const MatchesLoading();
  
  @override
  List<Object> get props => [];
}

class MatchesLoaded extends MatchesState {
  final List<BestPlayerModel> players;

  const MatchesLoaded(this.players);
  
  @override
  List<Object> get props => [players];
}

class MatchesError extends MatchesState {
  final String message;

  const MatchesError(this.message);
  
  @override
  List<Object> get props => [message];
}

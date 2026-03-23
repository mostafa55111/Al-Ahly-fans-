import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/achievements/domain/repositories/achievement_repository.dart';

/// Events للـ Achievements Bloc
abstract class AchievementEvent {
  const AchievementEvent();
}

class LoadAllAchievementsEvent extends AchievementEvent {
  const LoadAllAchievementsEvent();
}

class LoadUserAchievementsEvent extends AchievementEvent {
  const LoadUserAchievementsEvent();
}

class LoadAchievementByIdEvent extends AchievementEvent {
  final String achievementId;
  const LoadAchievementByIdEvent(this.achievementId);
}

class UpdateAchievementProgressEvent extends AchievementEvent {
  final String achievementId;
  final int progress;
  const UpdateAchievementProgressEvent({
    required this.achievementId,
    required this.progress,
  });
}

class UnlockAchievementEvent extends AchievementEvent {
  final String achievementId;
  const UnlockAchievementEvent(this.achievementId);
}

class PinAchievementEvent extends AchievementEvent {
  final String achievementId;
  const PinAchievementEvent(this.achievementId);
}

class UnpinAchievementEvent extends AchievementEvent {
  final String achievementId;
  const UnpinAchievementEvent(this.achievementId);
}

class GetAchievementsByTypeEvent extends AchievementEvent {
  final String type;
  const GetAchievementsByTypeEvent(this.type);
}

class GetBadgesEvent extends AchievementEvent {
  const GetBadgesEvent();
}

class GetUserBadgesEvent extends AchievementEvent {
  const GetUserBadgesEvent();
}

/// States للـ Achievements Bloc
abstract class AchievementState {
  const AchievementState();
}

class AchievementInitial extends AchievementState {
  const AchievementInitial();
}

class AchievementLoading extends AchievementState {
  const AchievementLoading();
}

class AllAchievementsLoaded extends AchievementState {
  final List achievements;
  const AllAchievementsLoaded(this.achievements);
}

class UserAchievementsLoaded extends AchievementState {
  final List achievements;
  const UserAchievementsLoaded(this.achievements);
}

class AchievementDetailLoaded extends AchievementState {
  final dynamic achievement;
  const AchievementDetailLoaded(this.achievement);
}

class AchievementProgressUpdated extends AchievementState {
  final dynamic achievement;
  const AchievementProgressUpdated(this.achievement);
}

class AchievementUnlocked extends AchievementState {
  final dynamic achievement;
  const AchievementUnlocked(this.achievement);
}

class AchievementPinned extends AchievementState {
  final String achievementId;
  const AchievementPinned(this.achievementId);
}

class AchievementUnpinned extends AchievementState {
  final String achievementId;
  const AchievementUnpinned(this.achievementId);
}

class BadgesLoaded extends AchievementState {
  final List badges;
  const BadgesLoaded(this.badges);
}

class UserBadgesLoaded extends AchievementState {
  final List badges;
  const UserBadgesLoaded(this.badges);
}

class AchievementError extends AchievementState {
  final String message;
  const AchievementError(this.message);
}

/// Bloc للـ Achievements
class AchievementBloc extends Bloc<AchievementEvent, AchievementState> {
  final AchievementRepository _repository;

  AchievementBloc({required AchievementRepository repository})
      : _repository = repository,
        super(const AchievementInitial()) {
    on<LoadAllAchievementsEvent>(_onLoadAllAchievements);
    on<LoadUserAchievementsEvent>(_onLoadUserAchievements);
    on<LoadAchievementByIdEvent>(_onLoadAchievementById);
    on<UpdateAchievementProgressEvent>(_onUpdateProgress);
    on<UnlockAchievementEvent>(_onUnlockAchievement);
    on<PinAchievementEvent>(_onPinAchievement);
    on<UnpinAchievementEvent>(_onUnpinAchievement);
    on<GetBadgesEvent>(_onGetBadges);
    on<GetUserBadgesEvent>(_onGetUserBadges);
  }

  Future<void> _onLoadAllAchievements(
    LoadAllAchievementsEvent event,
    Emitter<AchievementState> emit,
  ) async {
    emit(const AchievementLoading());
    final result = await _repository.getAllAchievements();
    result.fold(
      (exception) => emit(AchievementError(exception.message)),
      (achievements) => emit(AllAchievementsLoaded(achievements)),
    );
  }

  Future<void> _onLoadUserAchievements(
    LoadUserAchievementsEvent event,
    Emitter<AchievementState> emit,
  ) async {
    emit(const AchievementLoading());
    final result = await _repository.getUserAchievements();
    result.fold(
      (exception) => emit(AchievementError(exception.message)),
      (achievements) => emit(UserAchievementsLoaded(achievements)),
    );
  }

  Future<void> _onLoadAchievementById(
    LoadAchievementByIdEvent event,
    Emitter<AchievementState> emit,
  ) async {
    emit(const AchievementLoading());
    final result = await _repository.getAchievementById(event.achievementId);
    result.fold(
      (exception) => emit(AchievementError(exception.message)),
      (achievement) => emit(AchievementDetailLoaded(achievement)),
    );
  }

  Future<void> _onUpdateProgress(
    UpdateAchievementProgressEvent event,
    Emitter<AchievementState> emit,
  ) async {
    emit(const AchievementLoading());
    final result = await _repository.updateAchievementProgress(
      achievementId: event.achievementId,
      progress: event.progress,
    );
    result.fold(
      (exception) => emit(AchievementError(exception.message)),
      (achievement) => emit(AchievementProgressUpdated(achievement)),
    );
  }

  Future<void> _onUnlockAchievement(
    UnlockAchievementEvent event,
    Emitter<AchievementState> emit,
  ) async {
    emit(const AchievementLoading());
    final result = await _repository.unlockAchievement(event.achievementId);
    result.fold(
      (exception) => emit(AchievementError(exception.message)),
      (achievement) => emit(AchievementUnlocked(achievement)),
    );
  }

  Future<void> _onPinAchievement(
    PinAchievementEvent event,
    Emitter<AchievementState> emit,
  ) async {
    emit(const AchievementLoading());
    final result = await _repository.pinAchievement(event.achievementId);
    result.fold(
      (exception) => emit(AchievementError(exception.message)),
      (success) => emit(AchievementPinned(event.achievementId)),
    );
  }

  Future<void> _onUnpinAchievement(
    UnpinAchievementEvent event,
    Emitter<AchievementState> emit,
  ) async {
    emit(const AchievementLoading());
    final result = await _repository.unpinAchievement(event.achievementId);
    result.fold(
      (exception) => emit(AchievementError(exception.message)),
      (success) => emit(AchievementUnpinned(event.achievementId)),
    );
  }

  Future<void> _onGetBadges(
    GetBadgesEvent event,
    Emitter<AchievementState> emit,
  ) async {
    emit(const AchievementLoading());
    final result = await _repository.getBadges();
    result.fold(
      (exception) => emit(AchievementError(exception.message)),
      (badges) => emit(BadgesLoaded(badges)),
    );
  }

  Future<void> _onGetUserBadges(
    GetUserBadgesEvent event,
    Emitter<AchievementState> emit,
  ) async {
    emit(const AchievementLoading());
    final result = await _repository.getUserBadges();
    result.fold(
      (exception) => emit(AchievementError(exception.message)),
      (badges) => emit(UserBadgesLoaded(badges)),
    );
  }
}

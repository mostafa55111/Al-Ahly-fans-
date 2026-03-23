import 'package:dartz/dartz.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/core/usecases/usecase.dart';
import 'package:gomhor_alahly_clean_new/features/follow_system/domain/repositories/follow_repository.dart';

class FollowUserUseCase implements UseCase<bool, FollowUserParams> {
  final FollowRepository repository;

  FollowUserUseCase({required this.repository});

  @override
  Future<Either<AppException, bool>> call(FollowUserParams params) async {
    return await repository.followUser(
      currentUserId: params.currentUserId,
      targetUserId: params.targetUserId,
    );
  }
}

class FollowUserParams {
  final String currentUserId;
  final String targetUserId;

  FollowUserParams({
    required this.currentUserId,
    required this.targetUserId,
  });
}

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/core/usecases/usecase.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/domain/entities/post_entity.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/domain/repositories/social_feed_repository.dart';

/// Use Case للحصول على منشورات الفيد
/// يتعامل مع منطق الحصول على المنشورات مع Pagination
class GetFeedPostsUseCase implements UseCase<List<PostEntity>, GetFeedPostsParams> {
  final SocialFeedRepository repository;

  GetFeedPostsUseCase(this.repository);

  @override
  Future<Either<AppException, List<PostEntity>>> call(GetFeedPostsParams params) async {
    return await repository.getFeedPosts(
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}

/// معاملات Use Case للحصول على منشورات الفيد
class GetFeedPostsParams extends Equatable {
  /// رقم الصفحة (يبدأ من 1)
  final int page;
  
  /// عدد المنشورات في الصفحة الواحدة
  final int pageSize;

  const GetFeedPostsParams({
    required this.page,
    this.pageSize = 10,
  });

  @override
  List<Object?> get props => [page, pageSize];
}

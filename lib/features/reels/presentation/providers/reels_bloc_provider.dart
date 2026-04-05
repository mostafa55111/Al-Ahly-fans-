import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/bloc/reels_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/repositories/video_repository.dart';

class ReelsBlocProvider extends StatelessWidget {
  final Widget child;

  const ReelsBlocProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        // Get repository from service locator or inject it
        final videoRepository = RepositoryProvider.of<VideoRepository>(context);
        return ReelsBloc(videoRepository: videoRepository);
      },
      child: child,
    );
  }
}

// Extension for easier access to ReelsBloc
extension ReelsBlocContext on BuildContext {
  ReelsBloc get reelsBloc => read<ReelsBloc>();
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/providers/reels_bloc_provider.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/repositories/video_repository_impl.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/datasources/video_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/reels_screen.dart';

class ReelsScreenExample extends StatelessWidget {
  const ReelsScreenExample({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) {
        // Replace with your actual repository implementation
        return VideoRepositoryImpl(
          remoteDataSource: VideoRemoteDataSource(),
          cloudinaryService: CloudinaryService(),
        );
      },
      child: const ReelsBlocProvider(
        child: ReelsScreen(),
      ),
    );
  }
}

// If you want to use it in a MaterialApp:
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reels App',
      theme: ThemeData.dark(),
      home: const ReelsScreenExample(),
      debugShowCheckedModeBanner: false,
    );
  }
}

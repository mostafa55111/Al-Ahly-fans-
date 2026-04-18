import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/repositories/api_reels_repository.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/entities/reel.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/repositories/reels_repository.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/widgets/reel_player.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late final ReelsRepository _reelsRepository;
  late Future<List<Reel>> _reelsFuture;

  @override
  void initState() {
    super.initState();
    _reelsRepository = ApiReelsRepository();
    _reelsFuture = _reelsRepository.getReels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Reel>>(
        future: _reelsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No reels available.'));
          } else {
            final reels = snapshot.data!;
            return PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: reels.length,
              itemBuilder: (context, index) {
                return ReelPlayer(
                  reel: reels[index],
                  onLike: () {},
                  onComment: () {},
                  onFollow: () {},
                );
              },
            );
          }
        },
      ),
    );
  }
}

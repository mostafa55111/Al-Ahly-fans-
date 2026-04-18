import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/entities/reel.dart';
import 'package:video_player/video_player.dart';

class ReelPlayer extends StatefulWidget {
  final Reel reel;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onFollow;

  const ReelPlayer({
    super.key,
    required this.reel,
    required this.onLike,
    required this.onComment,
    required this.onFollow,
  });

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const Center(child: CircularProgressIndicator()),
        _buildOverlay(),
      ],
    );
  }

  Widget _buildOverlay() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '@${widget.reel.userName}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onFollow,
                child: Text(
                  widget.reel.isFollowed ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.reel.isFollowed ? Colors.grey : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.reel.caption,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      widget.reel.isLiked
                          ? FontAwesomeIcons.solidHeart
                          : FontAwesomeIcons.heart,
                      color: widget.reel.isLiked ? Colors.red : Colors.white,
                    ),
                    onPressed: widget.onLike,
                  ),
                  Text(widget.reel.likes.toString()),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(FontAwesomeIcons.comment),
                    onPressed: widget.onComment,
                  ),
                   Text(widget.reel.comments.toString()),
                ],
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.share),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

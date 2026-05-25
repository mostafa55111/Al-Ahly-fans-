import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// صورة كرت تصويت الملعب: كاش أعلى + fade + shimmer + إعادة المحاولة.
class MatchVoteCardImage extends StatefulWidget {
  const MatchVoteCardImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.memCacheWidth = 420,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final double width;
  final double height;
  final int memCacheWidth;
  final BoxFit fit;

  @override
  State<MatchVoteCardImage> createState() => _MatchVoteCardImageState();
}

class _MatchVoteCardImageState extends State<MatchVoteCardImage> {
  var _reloadKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _warmCache());
  }

  @override
  void didUpdateWidget(MatchVoteCardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _warmCache());
    }
  }

  Future<void> _warmCache() async {
    final url = widget.imageUrl.trim();
    if (url.isEmpty || !mounted) return;
    await precacheImage(CachedNetworkImageProvider(url), context);
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey('mvc_${widget.imageUrl}_$_reloadKey'),
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        memCacheWidth: widget.memCacheWidth,
        maxWidthDiskCache: widget.memCacheWidth * 2,
        fadeInDuration: const Duration(milliseconds: 320),
        fadeOutDuration: const Duration(milliseconds: 120),
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: const Color(0xFF222222),
          highlightColor: const Color(0xFF353535),
          child: Container(
            width: widget.width,
            height: widget.height,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        errorWidget: (context, url, error) => Material(
          color: const Color(0xFF1E1E1E),
          child: InkWell(
            onTap: () => setState(() => _reloadKey++),
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_outlined, color: Colors.white38, size: 22),
                  SizedBox(height: 6),
                  Text('إعادة', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

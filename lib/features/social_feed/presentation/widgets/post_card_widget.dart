import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/domain/entities/post_entity.dart';

/// Widget لعرض بطاقة المنشور
/// يعرض المنشور مع الصور والتفاعلات
class PostCardWidget extends StatefulWidget {
  /// بيانات المنشور
  final PostEntity post;
  
  /// callback عند الإعجاب
  final Function(String postId)? onLike;
  
  /// callback عند إلغاء الإعجاب
  final Function(String postId)? onUnlike;
  
  /// callback عند التعليق
  final Function(String postId)? onComment;
  
  /// callback عند المشاركة
  final Function(String postId)? onShare;
  
  /// callback عند الضغط على المنشور
  final Function(String postId)? onPostTap;

  const PostCardWidget({
    super.key,
    required this.post,
    this.onLike,
    this.onUnlike,
    this.onComment,
    this.onShare,
    this.onPostTap,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByCurrentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس المنشور (صورة المستخدم والاسم)
          _buildPostHeader(),
          
          // محتوى المنشور
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                widget.post.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          
          // الصور
          if (widget.post.imageUrls.isNotEmpty)
            _buildImageGallery(),
          
          // الفيديو
          if (widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty)
            _buildVideoPreview(),
          
          // الهاشتاجات
          if (widget.post.hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: widget.post.hashtags
                    .map((tag) => Text(
                          '#$tag',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 12,
                          ),
                        ))
                    .toList(),
              ),
            ),
          
          // الإحصائيات
          _buildStats(),
          
          // الأزرار (إعجاب، تعليق، مشاركة)
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// بناء رأس المنشور
  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // صورة المستخدم
          CircleAvatar(
            radius: 24,
            backgroundImage: CachedNetworkImageProvider(
              widget.post.userProfileImage,
            ),
            backgroundColor: Colors.grey[700],
          ),
          const SizedBox(width: 12),
          
          // اسم المستخدم والوقت
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatTime(widget.post.createdAt),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // زر المزيد
          PopupMenuButton(
            color: const Color(0xFF1A1A1A),
            itemBuilder: (context) => [
              const PopupMenuItem(
                child: Text(
                  'حفظ',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const PopupMenuItem(
                child: Text(
                  'إبلاغ',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء معرض الصور
  Widget _buildImageGallery() {
    if (widget.post.imageUrls.length == 1) {
      return CachedNetworkImage(
        imageUrl: widget.post.imageUrls[0],
        fit: BoxFit.cover,
        width: double.infinity,
        height: 300,
        placeholder: (context, url) => Container(
          color: Colors.grey[800],
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCC0000)),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[800],
          child: const Icon(Icons.error, color: Colors.red),
        ),
      );
    }
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.post.imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: widget.post.imageUrls[index],
                fit: BoxFit.cover,
                width: 150,
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// بناء معاينة الفيديو
  Widget _buildVideoPreview() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.play_circle_outline,
          color: Color(0xFFCC0000),
          size: 64,
        ),
      ),
    );
  }

  /// بناء الإحصائيات
  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${widget.post.likesCount} إعجاب',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              Text(
                '${widget.post.commentsCount} تعليق',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${widget.post.sharesCount} مشاركة',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء أزرار التفاعل
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // زر الإعجاب
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: 'إعجاب',
            color: _isLiked ? const Color(0xFFCC0000) : Colors.grey,
            onTap: () {
              setState(() => _isLiked = !_isLiked);
              if (_isLiked) {
                widget.onLike?.call(widget.post.id);
              } else {
                widget.onUnlike?.call(widget.post.id);
              }
            },
          ),
          
          // زر التعليق
          _buildActionButton(
            icon: Icons.comment_outlined,
            label: 'تعليق',
            color: Colors.grey,
            onTap: () => widget.onComment?.call(widget.post.id),
          ),
          
          // زر المشاركة
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'مشاركة',
            color: Colors.grey,
            onTap: () => widget.onShare?.call(widget.post.id),
          ),
        ],
      ),
    );
  }

  /// بناء زر التفاعل
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// تنسيق الوقت
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

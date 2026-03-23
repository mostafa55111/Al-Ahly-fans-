import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/presentation/bloc/social_feed_bloc.dart';

/// شاشة التعليقات
class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({
    super.key,
    required this.postId,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  late TextEditingController _commentController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _scrollController = ScrollController();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadComments() {
    context.read<SocialFeedBloc>().add(
          GetPostCommentsEvent(widget.postId),
        );
  }

  void _addComment() {
    if (_commentController.text.isEmpty) return;

    context.read<SocialFeedBloc>().add(
          AddCommentEvent(
            postId: widget.postId,
            content: _commentController.text,
          ),
        );

    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التعليقات'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // قائمة التعليقات
          Expanded(
            child: BlocBuilder<SocialFeedBloc, SocialFeedState>(
              builder: (context, state) {
                if (state is SocialFeedLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is PostCommentsLoaded) {
                  if (state.comments.isEmpty) {
                    return const Center(
                      child: Text('لا توجد تعليقات بعد'),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: state.comments.length,
                    itemBuilder: (context, index) {
                      final comment = state.comments[index];
                      return _buildCommentItem(comment);
                    },
                  );
                } else if (state is SocialFeedError) {
                  return Center(
                    child: Text('خطأ: ${state.message}'),
                  );
                }

                return const Center(
                  child: Text('لا توجد بيانات'),
                );
              },
            ),
          ),
          // حقل إدخال التعليق
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'اكتب تعليقاً...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(dynamic comment) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: comment.userProfileImage != null
                ? NetworkImage(comment.userProfileImage!)
                : null,
            child: comment.userProfileImage == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName ?? 'مستخدم',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'منذ ${_getTimeAgo(comment.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content ?? ''),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        context.read<SocialFeedBloc>().add(
                              LikeCommentEvent(comment.id),
                            );
                      },
                      icon: Icon(
                        comment.isLiked ?? false
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 16,
                      ),
                      label: Text('${comment.likesCount ?? 0}'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // الرد على التعليق
                      },
                      icon: const Icon(Icons.reply, size: 16),
                      label: const Text('رد'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                child: Text('حذف'),
              ),
              const PopupMenuItem(
                child: Text('تقرير'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(String? dateTime) {
    if (dateTime == null) return 'الآن';
    
    final date = DateTime.tryParse(dateTime);
    if (date == null) return 'الآن';

    final difference = DateTime.now().difference(date);

    if (difference.inSeconds < 60) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return 'منذ ${(difference.inDays / 7).floor()} أسبوع';
    }
  }
}

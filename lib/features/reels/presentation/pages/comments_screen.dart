import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/bloc/reels_bloc.dart';

class CommentsScreen extends StatefulWidget {
  final String videoId;

  const CommentsScreen({super.key, required this.videoId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user';

  @override
  void initState() {
    super.initState();
    context.read<ReelsBloc>().add(FetchCommentsEvent(videoId: widget.videoId));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    final commentText = _commentController.text.trim();
    if (commentText.isNotEmpty) {
      context.read<ReelsBloc>().add(
        AddCommentEvent(
          videoId: widget.videoId,
          userId: _currentUserId,
          commentText: commentText,
        ),
      );
      _commentController.clear();
      context.read<ReelsBloc>().add(FetchCommentsEvent(videoId: widget.videoId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التعليقات'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ReelsBloc, ReelsState>(
              builder: (context, state) {
                if (state is ReelsComments) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: Colors.red));
                  }
                  if (state.errorMessage != null) {
                    return Center(child: Text(state.errorMessage!, style: const TextStyle(color: Colors.white)));
                  }
                  if (state.comments.isEmpty) {
                    return const Center(child: Text('لا توجد تعليقات حتى الآن.', style: TextStyle(color: Colors.white)));
                  }
                  return ListView.builder(
                    itemCount: state.comments.length,
                    itemBuilder: (context, index) {
                      final comment = state.comments[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(comment['uid'] ?? 'مستخدم مجهول', style: const TextStyle(color: Colors.white)),
                        subtitle: Text(comment['text'] ?? '', style: const TextStyle(color: Colors.white70)),
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator(color: Colors.red));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'أضف تعليقاً...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: _addComment,
                  mini: true,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

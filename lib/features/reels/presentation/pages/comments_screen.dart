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
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = true;
  String? _errorMessage;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user';

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    setState(() {
      _isLoadingComments = true;
      _errorMessage = null;
    });
    try {
      // Assuming you have a method in your repository to get comments
      final comments = await context.read<ReelsBloc>().getComments(widget.videoId);
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load comments: ${e.toString()}';
        _isLoadingComments = false;
      });
    }
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
      // Optimistically add comment to UI or refetch
      _fetchComments(); // Refetch to get the latest comments including the new one
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
            child: _isLoadingComments
                ? const Center(child: CircularProgressIndicator(color: Colors.red))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)))
                    : _comments.isEmpty
                        ? const Center(child: Text('لا توجد تعليقات حتى الآن.', style: TextStyle(color: Colors.white)))
                        : ListView.builder(
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              return ListTile(
                                leading: const CircleAvatar(
                                  // You might want to display user profile pic here
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(comment['uid'] ?? 'مستخدم مجهول', style: const TextStyle(color: Colors.white)),
                                subtitle: Text(comment['text'] ?? '', style: const TextStyle(color: Colors.white70)),
                                // You can add timestamp here if available
                              );
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/stories/presentation/bloc/stories_bloc.dart';

/// شاشة القصص (Stories)
class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  @override
  void initState() {
    super.initState();
    _loadFollowingStories();
  }

  void _loadFollowingStories() {
    context.read<StoriesBloc>().add(const LoadFollowingStoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القصص'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showCreateStoryDialog();
            },
          ),
        ],
      ),
      body: BlocBuilder<StoriesBloc, StoriesState>(
        builder: (context, state) {
          if (state is StoriesLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is FollowingStoriesLoaded) {
            if (state.stories.isEmpty) {
              return const Center(
                child: Text('لا توجد قصص جديدة'),
              );
            }

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.stories.length,
              itemBuilder: (context, index) {
                final story = state.stories[index];
                return _buildStoryItem(story);
              },
            );
          } else if (state is StoriesError) {
            return Center(
              child: Text('خطأ: ${state.message}'),
            );
          }

          return const Center(
            child: Text('لا توجد بيانات'),
          );
        },
      ),
    );
  }

  Widget _buildStoryItem(dynamic story) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: InkWell(
        onTap: () {
          _showStoryViewer(story);
        },
        child: Stack(
          children: [
            // الصورة الخلفية
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(story.mediaUrl ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // التدرج العلوي
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(128),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // بيانات المستخدم
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.userName ?? 'مستخدم',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'منذ قليل',
                          style: TextStyle(
                            color: Colors.white.withAlpha(178),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // عدد المشاهدات
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${story.viewsCount ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${story.reactionsCount ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryViewer(dynamic story) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              // الصورة
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(story.mediaUrl ?? ''),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // زر الإغلاق
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // بيانات المستخدم
              Positioned(
                top: 16,
                left: 16,
                right: 56,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.userName ?? 'مستخدم',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'منذ قليل',
                            style: TextStyle(
                              color: Colors.white.withAlpha(178),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // أزرار التفاعل
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border,
                          color: Colors.white, size: 28),
                      onPressed: () {
                        context.read<StoriesBloc>().add(
                              AddStoryReactionEvent(
                                storyId: story.id,
                                reaction: 'like',
                              ),
                            );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white, size: 28),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert,
                          color: Colors.white, size: 28),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateStoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء قصة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقط صورة'),
              onTap: () {
                Navigator.pop(context);
                // فتح الكاميرا
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('اختر من المعرض'),
              onTap: () {
                Navigator.pop(context);
                // فتح المعرض
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('التقط فيديو'),
              onTap: () {
                Navigator.pop(context);
                // فتح الكاميرا للفيديو
              },
            ),
          ],
        ),
      ),
    );
  }
}

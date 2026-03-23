import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/follow_system/presentation/bloc/follow_bloc.dart';

/// شاشة بروفايل المستخدم
class UserProfileScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    context.read<FollowBloc>().add(
          GetUserProfileEvent(widget.userId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البروفايل'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (widget.isCurrentUser)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // الانتقال إلى الإعدادات
              },
            ),
        ],
      ),
      body: BlocBuilder<FollowBloc, FollowState>(
        builder: (context, state) {
          if (state is FollowLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is UserProfileLoaded) {
            final user = state.user;
            return CustomScrollView(
              slivers: [
                // رأس البروفايل
                SliverToBoxAdapter(
                  child: _buildProfileHeader(user),
                ),
                // الإحصائيات
                SliverToBoxAdapter(
                  child: _buildStatistics(user),
                ),
                // الـ Bio
                SliverToBoxAdapter(
                  child: _buildBio(user),
                ),
                // الـ Tabs
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  bottom: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'المنشورات'),
                      Tab(text: 'الإنجازات'),
                      Tab(text: 'الصور'),
                    ],
                  ),
                ),
                // محتوى الـ Tabs
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostsTab(user),
                      _buildAchievementsTab(user),
                      _buildPhotosTab(user),
                    ],
                  ),
                ),
              ],
            );
          } else if (state is FollowError) {
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

  Widget _buildProfileHeader(dynamic user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // صورة البروفايل
          CircleAvatar(
            radius: 50,
            backgroundImage: user.profileImage != null
                ? NetworkImage(user.profileImage!)
                : null,
            child: user.profileImage == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          // اسم المستخدم
          Text(
            user.userName ?? 'مستخدم',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          if (user.isVerified ?? false)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.verified, color: Colors.blue, size: 16),
            ),
          const SizedBox(height: 8),
          // الـ Handle
          Text(
            '@${user.handle ?? "user"}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // أزرار الإجراءات
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isCurrentUser)
                ElevatedButton(
                  onPressed: () {
                    // تعديل البروفايل
                  },
                  child: const Text('تعديل البروفايل'),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    context.read<FollowBloc>().add(
                          FollowUserEvent(widget.userId),
                        );
                  },
                  child: const Text('متابعة'),
                ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  // إرسال رسالة
                },
                child: const Text('رسالة'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('المنشورات', '${user.postsCount ?? 0}'),
          _buildStatItem('المتابعون', '${user.followersCount ?? 0}'),
          _buildStatItem('المتابعة', '${user.followingCount ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBio(dynamic user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            Text(
              user.bio!,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
          ],
          if (user.location != null && user.location!.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(user.location!),
              ],
            ),
          if (user.website != null && user.website!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.link, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(user.website!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostsTab(dynamic user) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text('منشور ${index + 1}'),
            subtitle: const Text('وصف المنشور'),
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab(dynamic user) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const Card(
          child: Center(
            child: Icon(
              Icons.star,
              color: Colors.amber,
              size: 40,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotosTab(dynamic user) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image),
        );
      },
    );
  }
}

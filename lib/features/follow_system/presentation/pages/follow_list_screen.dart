import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/follow_system/presentation/bloc/follow_bloc.dart';

/// شاشة قائمة المتابعين والمتابعة
class FollowListScreen extends StatefulWidget {
  final String userId;
  final String listType; // 'followers' أو 'following'

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.listType,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadFollowList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadFollowList() {
    if (widget.listType == 'followers') {
      context.read<FollowBloc>().add(
            GetUserFollowersEvent(widget.userId),
          );
    } else {
      context.read<FollowBloc>().add(
            GetUserFollowingEvent(widget.userId),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listType == 'followers' ? 'المتابعون' : 'المتابعة'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن مستخدم...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          _loadFollowList();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.isNotEmpty) {
                  context.read<FollowBloc>().add(
                        SearchFollowersEvent(value),
                      );
                } else {
                  _loadFollowList();
                }
              },
            ),
          ),
          // قائمة المستخدمين
          Expanded(
            child: BlocBuilder<FollowBloc, FollowState>(
              builder: (context, state) {
                if (state is FollowLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is UserFollowersLoaded ||
                    state is UserFollowingLoaded ||
                    state is SearchResultsLoaded) {
                  final users = state is UserFollowersLoaded
                      ? state.followers
                      : state is UserFollowingLoaded
                          ? state.following
                          : (state as SearchResultsLoaded).results;

                  if (users.isEmpty) {
                    return const Center(
                      child: Text('لا توجد نتائج'),
                    );
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildFollowUserItem(user);
                    },
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
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUserItem(dynamic user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.profileImage != null
              ? NetworkImage(user.profileImage!)
              : null,
          child: user.profileImage == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(user.userName ?? 'مستخدم'),
        subtitle: Text(user.bio ?? ''),
        trailing: _buildFollowButton(user),
        onTap: () {
          // الانتقال إلى صفحة البروفايل
        },
      ),
    );
  }

  Widget _buildFollowButton(dynamic user) {
    return BlocBuilder<FollowBloc, FollowState>(
      builder: (context, state) {
        final isFollowing = user.isFollowing ?? false;

        return ElevatedButton(
          onPressed: () {
            if (isFollowing) {
              context.read<FollowBloc>().add(
                    UnfollowUserEvent(user.id),
                  );
            } else {
              context.read<FollowBloc>().add(
                    FollowUserEvent(user.id),
                  );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.grey : Colors.blue,
          ),
          child: Text(isFollowing ? 'متابع' : 'متابعة'),
        );
      },
    );
  }
}

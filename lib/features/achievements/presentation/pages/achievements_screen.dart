import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/achievements/presentation/bloc/achievement_bloc.dart';

/// شاشة الإنجازات والشارات
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAchievements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAchievements() {
    context.read<AchievementBloc>().add(
          const LoadUserAchievementsEvent(),
        );
  }

  void _loadBadges() {
    context.read<AchievementBloc>().add(
          const GetUserBadgesEvent(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإنجازات والشارات'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الإنجازات'),
            Tab(text: 'الشارات'),
          ],
          onTap: (index) {
            if (index == 1) {
              _loadBadges();
            } else {
              _loadAchievements();
            }
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAchievementsView(),
          _buildBadgesView(),
        ],
      ),
    );
  }

  Widget _buildAchievementsView() {
    return BlocBuilder<AchievementBloc, AchievementState>(
      builder: (context, state) {
        if (state is AchievementLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is UserAchievementsLoaded) {
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: state.achievements.length,
            itemBuilder: (context, index) {
              final achievement = state.achievements[index];
              return _buildAchievementCard(achievement);
            },
          );
        } else if (state is AchievementError) {
          return Center(
            child: Text('خطأ: ${state.message}'),
          );
        }

        return const Center(
          child: Text('لا توجد إنجازات'),
        );
      },
    );
  }

  Widget _buildBadgesView() {
    return BlocBuilder<AchievementBloc, AchievementState>(
      builder: (context, state) {
        if (state is AchievementLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is UserBadgesLoaded) {
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: state.badges.length,
            itemBuilder: (context, index) {
              final badge = state.badges[index];
              return _buildBadgeCard(badge);
            },
          );
        } else if (state is AchievementError) {
          return Center(
            child: Text('خطأ: ${state.message}'),
          );
        }

        return const Center(
          child: Text('لا توجد شارات'),
        );
      },
    );
  }

  Widget _buildAchievementCard(dynamic achievement) {
    final isUnlocked = achievement.isUnlocked ?? false;
    final progress = achievement.progress ?? 0;
    final maxProgress = achievement.maxProgress ?? 100;
    final progressPercent = (progress / maxProgress * 100).toInt();

    return Card(
      child: InkWell(
        onTap: () {
          _showAchievementDetails(achievement);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked ? Colors.amber : Colors.grey[300],
              ),
              child: Center(
                child: Icon(
                  Icons.star,
                  color: isUnlocked ? Colors.white : Colors.grey,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title ?? 'إنجاز',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            if (!isUnlocked)
              Text(
                '$progressPercent%',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(dynamic badge) {
    final isEarned = badge.isEarned ?? false;

    return Card(
      child: InkWell(
        onTap: () {
          _showBadgeDetails(badge);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEarned ? Colors.blue : Colors.grey[300],
              ),
              child: Center(
                child: Icon(
                  Icons.shield,
                  color: isEarned ? Colors.white : Colors.grey,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name ?? 'شارة',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetails(dynamic achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.title ?? 'إنجاز'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description ?? ''),
            const SizedBox(height: 16),
            Text('النقاط: ${achievement.points ?? 0}'),
            Text('الصعوبة: ${achievement.difficulty ?? "سهل"}'),
            Text('النوع: ${achievement.type ?? "عام"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showBadgeDetails(dynamic badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(badge.name ?? 'شارة'),
        content: Text(badge.description ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

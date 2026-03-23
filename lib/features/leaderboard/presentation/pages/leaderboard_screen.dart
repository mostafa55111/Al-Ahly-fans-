import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';

/// شاشة لوحة المتصدرين
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOverallLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadOverallLeaderboard() {
    context.read<LeaderboardBloc>().add(
          const LoadOverallLeaderboardEvent(page: 1),
        );
  }

  void _loadWeeklyLeaderboard() {
    context.read<LeaderboardBloc>().add(
          const LoadWeeklyLeaderboardEvent(page: 1),
        );
  }

  void _loadMonthlyLeaderboard() {
    context.read<LeaderboardBloc>().add(
          const LoadMonthlyLeaderboardEvent(page: 1),
        );
  }

  void _loadFriendsLeaderboard() {
    context.read<LeaderboardBloc>().add(
          const LoadFriendsLeaderboardEvent(page: 1),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المتصدرين'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'هذا الأسبوع'),
            Tab(text: 'هذا الشهر'),
            Tab(text: 'الأصدقاء'),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                _loadOverallLeaderboard();
                break;
              case 1:
                _loadWeeklyLeaderboard();
                break;
              case 2:
                _loadMonthlyLeaderboard();
                break;
              case 3:
                _loadFriendsLeaderboard();
                break;
            }
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardView(const LoadOverallLeaderboardEvent()),
          _buildLeaderboardView(const LoadWeeklyLeaderboardEvent()),
          _buildLeaderboardView(const LoadMonthlyLeaderboardEvent()),
          _buildLeaderboardView(const LoadFriendsLeaderboardEvent()),
        ],
      ),
    );
  }

  Widget _buildLeaderboardView(LeaderboardEvent event) {
    return BlocBuilder<LeaderboardBloc, LeaderboardState>(
      builder: (context, state) {
        if (state is LeaderboardLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is OverallLeaderboardLoaded ||
            state is WeeklyLeaderboardLoaded ||
            state is MonthlyLeaderboardLoaded ||
            state is FriendsLeaderboardLoaded) {
          final leaderboard = state is OverallLeaderboardLoaded
              ? state.leaderboard
              : state is WeeklyLeaderboardLoaded
                  ? state.leaderboard
                  : state is MonthlyLeaderboardLoaded
                      ? state.leaderboard
                      : (state as FriendsLeaderboardLoaded).leaderboard;

          return ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final item = leaderboard[index];
              return _buildLeaderboardItem(item, index + 1);
            },
          );
        } else if (state is LeaderboardError) {
          return Center(
            child: Text('خطأ: ${state.message}'),
          );
        }

        return const Center(
          child: Text('لا توجد بيانات'),
        );
      },
    );
  }

  Widget _buildLeaderboardItem(dynamic item, int rank) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getRankColor(rank),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(item.userName ?? 'مستخدم'),
        subtitle: Text('${item.totalPoints ?? 0} نقطة'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.isVerified ?? false)
              const Icon(Icons.verified, color: Colors.blue, size: 16),
            Text(
              'المستوى ${item.level ?? 1}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        onTap: () {
          // الانتقال إلى صفحة ملف المستخدم
        },
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

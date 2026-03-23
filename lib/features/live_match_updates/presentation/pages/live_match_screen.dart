import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/live_match_updates/presentation/bloc/match_bloc.dart';

/// شاشة المباريات المباشرة
class LiveMatchScreen extends StatefulWidget {
  const LiveMatchScreen({super.key});

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  @override
  void initState() {
    super.initState();
    _loadLiveMatches();
  }

  void _loadLiveMatches() {
    context.read<MatchBloc>().add(const LoadLiveMatchesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المباريات المباشرة'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLiveMatches,
          ),
        ],
      ),
      body: BlocBuilder<MatchBloc, MatchState>(
        builder: (context, state) {
          if (state is MatchLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is LiveMatchesLoaded) {
            if (state.liveMatches.isEmpty) {
              return const Center(
                child: Text('لا توجد مباريات مباشرة حالياً'),
              );
            }

            return ListView.builder(
              itemCount: state.liveMatches.length,
              itemBuilder: (context, index) {
                final match = state.liveMatches[index];
                return _buildMatchCard(match);
              },
            );
          } else if (state is MatchError) {
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

  Widget _buildMatchCard(dynamic match) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: InkWell(
        onTap: () {
          _showMatchDetails(match);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // رأس المباراة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          match.homeTeam ?? 'فريق',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          match.tournament ?? 'بطولة',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // الشعار والنتيجة
                  Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: Center(
                          child: Text(
                            match.homeTeamLogo ?? 'H',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${match.homeScore ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // الوقت
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          \"${match.currentMinute ?? 0}'\",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Icon(Icons.circle, color: Colors.red, size: 8),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // النتيجة والشعار
                  Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: Center(
                          child: Text(
                            match.awayTeamLogo ?? 'A',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${match.awayScore ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // الفريق الثاني
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.awayTeam ?? 'فريق',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          match.stadium ?? 'ملعب',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // الإحصائيات
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('الحيازة', '${match.homeTeamStats?.possession ?? 0}%'),
                  _buildStatItem('التسديدات', '${match.homeTeamStats?.shots ?? 0}'),
                  _buildStatItem('الزوايا', '${match.homeTeamStats?.corners ?? 0}'),
                  _buildStatItem('الأخطاء', '${match.homeTeamStats?.fouls ?? 0}'),
                ],
              ),
            ],
          ),
        ),
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
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  void _showMatchDetails(dynamic match) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${match.homeTeam} vs ${match.awayTeam}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Text('الملعب: ${match.stadium ?? "غير محدد"}'),
            Text('الحكم: ${match.referee ?? "غير محدد"}'),
            Text('البطولة: ${match.tournament ?? "غير محددة"}'),
            Text('الموسم: ${match.season ?? "غير محدد"}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // الانتقال إلى صفحة تفاصيل المباراة
                },
                child: const Text('عرض التفاصيل الكاملة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

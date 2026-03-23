import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/social_feed/presentation/bloc/social_feed_bloc.dart';

/// شاشة البحث
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  String _selectedFilter = 'all'; // all, users, posts, hashtags

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    context.read<SocialFeedBloc>().add(
          SearchPostsEvent(query),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث'),
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
                hintText: 'ابحث عن منشورات أو مستخدمين...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
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
                  _performSearch(value);
                }
              },
              onSubmitted: _performSearch,
            ),
          ),
          // فلاتر البحث
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('الكل', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('المستخدمين', 'users'),
                  const SizedBox(width: 8),
                  _buildFilterChip('المنشورات', 'posts'),
                  const SizedBox(width: 8),
                  _buildFilterChip('الهاشتاجات', 'hashtags'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // نتائج البحث
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        if (_searchController.text.isNotEmpty) {
          _performSearch(_searchController.text);
        }
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return _buildTrendingSection();
    }

    return BlocBuilder<SocialFeedBloc, SocialFeedState>(
      builder: (context, state) {
        if (state is SocialFeedLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is SearchResultsLoaded) {
          if (state.results.isEmpty) {
            return const Center(
              child: Text('لا توجد نتائج'),
            );
          }

          return ListView.builder(
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              final result = state.results[index];
              return _buildSearchResultItem(result);
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
    );
  }

  Widget _buildTrendingSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'الترندات الآن',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildTrendingItem(
                '#الأهلي${index + 1}',
                '${(index + 1) * 1000}K منشور',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingItem(String trend, String count) {
    return ListTile(
      title: Text(trend),
      subtitle: Text(count),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        _searchController.text = trend;
        _performSearch(trend);
      },
    );
  }

  Widget _buildSearchResultItem(dynamic result) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            result.runtimeType.toString().contains('User')
                ? Icons.person
                : Icons.article,
          ),
        ),
        title: Text(result.title ?? result.userName ?? 'نتيجة'),
        subtitle: Text(result.description ?? result.bio ?? ''),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          // الانتقال إلى التفاصيل
        },
      ),
    );
  }
}

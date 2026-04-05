import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_database/firebase_database.dart';

/// شاشة البحث المتقدم - للبحث عن المباريات واللاعبين والريلز
class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _selectedCategory = 'الكل'; // الكل، المباريات، اللاعبين، الريلز

  final List<String> _categories = ['الكل', 'المباريات', 'اللاعبين', 'الريلز'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// البحث المتقدم
  Future<void> _performAdvancedSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = <Map<String, dynamic>>[];

      // البحث في المباريات
      if (_selectedCategory == 'الكل' || _selectedCategory == 'المباريات') {
        final matchesSnapshot = await _database.ref('Matches').get();
        if (matchesSnapshot.exists) {
          final matchesData =
              Map<String, dynamic>.from(matchesSnapshot.value as Map);
          matchesData.forEach((key, value) {
            final match = Map<String, dynamic>.from(value as Map);
            final homeTeam = (match['homeTeam'] ?? '').toString().toLowerCase();
            final awayTeam = (match['awayTeam'] ?? '').toString().toLowerCase();
            final competition =
                (match['competition'] ?? '').toString().toLowerCase();

            if (homeTeam.contains(query.toLowerCase()) ||
                awayTeam.contains(query.toLowerCase()) ||
                competition.contains(query.toLowerCase())) {
              results.add({
                'type': 'مباراة',
                'title': '${match['homeTeam']} vs ${match['awayTeam']}',
                'subtitle': match['competition'] ?? 'دوري مصري',
                'date': match['utcDate'] ?? 'تاريخ غير محدد',
                'icon': '⚽',
                'data': match,
              });
            }
          });
        }
      }

      // البحث في اللاعبين
      if (_selectedCategory == 'الكل' || _selectedCategory == 'اللاعبين') {
        final playersSnapshot = await _database.ref('Players').get();
        if (playersSnapshot.exists) {
          final playersData =
              Map<String, dynamic>.from(playersSnapshot.value as Map);
          playersData.forEach((key, value) {
            final player = Map<String, dynamic>.from(value as Map);
            final name = (player['name'] ?? '').toString().toLowerCase();
            final position =
                (player['position'] ?? '').toString().toLowerCase();

            if (name.contains(query.toLowerCase()) ||
                position.contains(query.toLowerCase())) {
              results.add({
                'type': 'لاعب',
                'title': player['name'] ?? 'لاعب غير معروف',
                'subtitle': player['position'] ?? 'موضع غير محدد',
                'number': player['number'] ?? '-',
                'icon': '👤',
                'data': player,
              });
            }
          });
        }
      }

      // البحث في الريلز
      if (_selectedCategory == 'الكل' || _selectedCategory == 'الريلز') {
        final reelsSnapshot = await _database.ref('Reels').get();
        if (reelsSnapshot.exists) {
          final reelsData =
              Map<String, dynamic>.from(reelsSnapshot.value as Map);
          reelsData.forEach((key, value) {
            final reel = Map<String, dynamic>.from(value as Map);
            final caption = (reel['caption'] ?? '').toString().toLowerCase();
            final userName = (reel['userName'] ?? '').toString().toLowerCase();

            if (caption.contains(query.toLowerCase()) ||
                userName.contains(query.toLowerCase())) {
              results.add({
                'type': 'ريل',
                'title': reel['userName'] ?? 'مستخدم غير معروف',
                'subtitle': reel['caption'] ?? 'بدون وصف',
                'likes': reel['likes'] ?? 0,
                'views': reel['views'] ?? 0,
                'icon': '🎬',
                'data': reel,
              });
            }
          });
        }
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('خطأ في البحث: $e');
      setState(() {
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ في البحث: $e')),
        );
      }
    }
  }

  /// بناء عنصر النتيجة
  Widget _buildSearchResultItem(Map<String, dynamic> result) {
    return FadeInUp(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                result['icon'] ?? '📌',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          title: Text(
            result['title'] ?? 'بدون عنوان',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A0E27),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                result['subtitle'] ?? 'بدون وصف',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF687076),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (result['type'] == 'ريل') ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.favorite,
                        size: 14, color: Color(0xFFDC143C)),
                    const SizedBox(width: 4),
                    Text(
                      '${result['likes'] ?? 0}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.visibility,
                        size: 14, color: Color(0xFF0A0E27)),
                    const SizedBox(width: 4),
                    Text(
                      '${result['views'] ?? 0}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDC143C).withAlpha(51),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              result['type'] ?? 'غير محدد',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDC143C),
              ),
            ),
          ),
          onTap: () {
            // التعامل مع النقر على النتيجة
            _handleSearchResultTap(result);
          },
        ),
      ),
    );
  }

  /// معالجة النقر على نتيجة البحث
  void _handleSearchResultTap(Map<String, dynamic> result) {
    final type = result['type'];

    switch (type) {
      case 'مباراة':
        // الانتقال إلى تفاصيل المباراة
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فتح تفاصيل المباراة: ${result['title']}')),
        );
        break;
      case 'لاعب':
        // الانتقال إلى ملف اللاعب
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فتح ملف اللاعب: ${result['title']}')),
        );
        break;
      case 'ريل':
        // الانتقال إلى الريل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فتح الريل من ${result['title']}')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'البحث المتقدم',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // شريط البحث
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.all(16),
            child: FadeInDown(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  _performAdvancedSearch(value);
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن مباراة أو لاعب أو ريل...',
                  hintStyle: const TextStyle(color: Color(0xFF9BA1A6)),
                  prefixIcon: Icon(Icons.search,
                      color: Theme.of(context).colorScheme.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: Theme.of(context).colorScheme.primary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                ),
                style: const TextStyle(color: Color(0xFFECEDEE)),
              ),
            ),
          ),

          // فلاتر الفئات
          Container(
            color: const Color(0xFF0A0E27),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        _performAdvancedSearch(_searchController.text);
                      },
                      backgroundColor: const Color(0xFF1E2022),
                      selectedColor: const Color(0xFFDC143C),
                      labelStyle: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFFDC143C)
                            : const Color(0xFFD4AF37),
                        width: 1,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // نتائج البحث
          Expanded(
            child: _isSearching
                ? Center(
                    child: FadeInUp(
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFD4AF37)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'جاري البحث...',
                            style: TextStyle(
                              color: Color(0xFF0A0E27),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: FadeInUp(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _searchController.text.isEmpty
                                    ? 'ابدأ البحث الآن'
                                    : 'لم يتم العثور على نتائج',
                                style: const TextStyle(
                                  color: Color(0xFF687076),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'ابحث عن مباراة أو لاعب أو ريل'
                                    : 'حاول البحث بكلمات مختلفة',
                                style: const TextStyle(
                                  color: Color(0xFF9BA1A6),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          return _buildSearchResultItem(_searchResults[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

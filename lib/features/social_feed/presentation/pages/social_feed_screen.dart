import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'جمهور الأهلي 🦅',
          style: TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFFC5A059)),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder(
        // جلب المنشورات (الكروت) من مسار Posts في Firebase
        stream: _database.ref('Posts').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('خطأ في جلب البيانات', style: TextStyle(color: Colors.white54)));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add, color: Colors.white24, size: 64),
                  SizedBox(height: 16),
                  Text('لا توجد منشورات حالياً', style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }

          // معالجة بيانات المنشورات
          final dynamic rawData = snapshot.data!.snapshot.value;
          List<Map<String, dynamic>> posts = [];
          
          if (rawData is Map) {
            posts = rawData.entries.map((e) {
              final data = Map<String, dynamic>.from(e.value as Map);
              data['id'] = e.key;
              return data;
            }).toList();
          } else if (rawData is List) {
            posts = rawData.asMap().entries
                .where((e) => e.value != null)
                .map((e) {
                  final data = Map<String, dynamic>.from(e.value as Map);
                  data['id'] = e.key.toString();
                  return data;
                }).toList();
          }

          // الترتيب حسب الأحدث
          posts.sort((a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return FadeInUp(
                duration: Duration(milliseconds: 300 + (index * 100)),
                child: _buildPostCard(post),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          // سيتم إضافة واجهة إنشاء منشور لاحقاً
        },
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس الكارت
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red,
              backgroundImage: post['userProfilePic'] != null && post['userProfilePic'].isNotEmpty
                  ? CachedNetworkImageProvider(post['userProfilePic'])
                  : null,
              child: post['userProfilePic'] == null || post['userProfilePic'].isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: Text(post['userName'] ?? 'مشجع أهلاوي', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(post['timeAgo'] ?? 'منذ قليل', 
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: const Icon(Icons.more_vert, color: Colors.white54),
          ),
          
          // محتوى النص
          if (post['content'] != null && post['content'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Text(post['content'], 
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          
          // الصورة (إن وجدت)
          if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: post['imageUrl'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(height: 200, color: Colors.white10),
                  errorWidget: (context, url, error) => const SizedBox(),
                ),
              ),
            ),
            
          // أزرار التفاعل
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInteractionButton(Icons.favorite_border, post['likes']?.toString() ?? '0', Colors.red),
                _buildInteractionButton(Icons.comment_outlined, post['comments']?.toString() ?? '0', Colors.white54),
                _buildInteractionButton(Icons.share_outlined, 'مشاركة', Colors.white54),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/user_profile_view_page.dart';

/// ═════════════════════════════════════════════════════════════════
/// شاشة زوار البروفايل
/// ═════════════════════════════════════════════════════════════════
/// تعرض قائمة الزوار اللي زاروا بروفايل المستخدم الحالي.
/// المصدر: `users/{myUid}/visitors/{visitorUid}/ts`
/// لكل visitor نقرأ بياناته من `users/{visitorUid}` (الاسم/الصورة).
class ProfileVisitorsPage extends StatefulWidget {
  const ProfileVisitorsPage({super.key});

  @override
  State<ProfileVisitorsPage> createState() => _ProfileVisitorsPageState();
}

class _ProfileVisitorsPageState extends State<ProfileVisitorsPage> {
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final myUid = _uid;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'زوار بروفايلك',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: myUid == null
          ? const _Placeholder(message: 'سجّل الدخول لعرض الزوار')
          : StreamBuilder<DatabaseEvent>(
              stream:
                  FirebaseDatabase.instance.ref('users/$myUid/visitors').onValue,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFFE2C55)));
                }
                final raw = snap.data?.snapshot.value;
                if (raw is! Map || raw.isEmpty) {
                  return const _Placeholder(
                    icon: Icons.directions_walk_rounded,
                    message:
                        'لا يوجد زوار حتى الآن.\nشارك بروفايلك ليبدأ الجمهور بزيارته!',
                  );
                }

                // نحوّل الـ map لقائمة مرتبة (الأحدث أولاً)
                final entries = <_VisitorEntry>[];
                raw.forEach((k, v) {
                  final ts = (v is Map ? v['ts'] : null);
                  final ms = ts is int
                      ? ts
                      : int.tryParse(ts?.toString() ?? '') ?? 0;
                  entries.add(_VisitorEntry(uid: k.toString(), timestamp: ms));
                });
                entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, i) => _VisitorTile(entry: entries[i]),
                );
              },
            ),
    );
  }
}

class _VisitorEntry {
  final String uid;
  final int timestamp;
  _VisitorEntry({required this.uid, required this.timestamp});
}

class _VisitorTile extends StatelessWidget {
  final _VisitorEntry entry;
  const _VisitorTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DataSnapshot>(
      future: FirebaseDatabase.instance.ref('users/${entry.uid}').get(),
      builder: (context, snap) {
        Map<dynamic, dynamic> data = {};
        if (snap.hasData && snap.data!.value is Map) {
          data = Map<dynamic, dynamic>.from(snap.data!.value as Map);
        }
        final name = (data['name'] ?? 'مشجع أهلاوي').toString();
        final handle = (data['username'] ?? '').toString();
        final pic = (data['profilePic'] ?? '').toString();

        return ListTile(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserProfileViewPage(
                  userId: entry.uid,
                  fallbackName: name,
                  fallbackAvatar: pic,
                ),
              ),
            );
          },
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1A1A1A),
            backgroundImage:
                pic.isNotEmpty ? CachedNetworkImageProvider(pic) : null,
            child: pic.isEmpty
                ? const Icon(Icons.person, color: Colors.white38, size: 26)
                : null,
          ),
          title: Text(name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          subtitle: Text(
            handle.isNotEmpty
                ? '@$handle • ${_formatTime(entry.timestamp)}'
                : _formatTime(entry.timestamp),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_left,
              color: Colors.white24, size: 22),
        );
      },
    );
  }

  String _formatTime(int ms) {
    if (ms <= 0) return 'منذ فترة';
    final diff =
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    return 'منذ ${(diff.inDays / 7).floor()} أسبوع';
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;
  final String message;
  const _Placeholder({
    this.icon = Icons.info_outline,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

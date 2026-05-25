import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gomhor_alahly_clean_new/core/navigation/app_navigator_key.dart';
import 'package:gomhor_alahly_clean_new/core/navigation/open_tiktok_reels_direct.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/user_profile_view_page.dart';

/// مركز الإشعارات — إعجاب، تعليق، متابعة، ترند (من Firestore).
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.accentColor,
  });

  /// لون الهوية: أحمر للأهلي / أزرق للزمالك.
  final Color accentColor;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static final DateFormat _df = DateFormat('dd/MM • HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markAllRead());
  }

  Future<void> _markAllRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final fs = FirebaseFirestore.instance;
      final unread = await fs
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .limit(100)
          .get();
      final batch = fs.batch();
      for (final d in unread.docs) {
        batch.update(d.reference, {'read': true});
      }
      batch.set(
        fs.collection('users').doc(uid),
        {'notificationsUnreadCount': 0},
        SetOptions(merge: true),
      );
      await batch.commit();
    } catch (e) {
      debugPrint('[Notifications] mark read: $e');
    }
  }

  /// أيقونة ولون حسب نوع الإشعار لعرض أوضح في القائمة.
  ({IconData icon, String label}) _typeMeta(String type) {
    switch (type) {
      case 'comment':
        return (icon: Icons.chat_bubble_outline_rounded, label: 'تعليق');
      case 'follow':
        return (icon: Icons.person_add_alt_1_rounded, label: 'متابعة جديدة');
      case 'trending':
        return (icon: Icons.trending_up_rounded, label: 'ترند');
      case 'reel':
        return (icon: Icons.play_circle_outline_rounded, label: 'ريل');
      case 'like':
      default:
        return (icon: Icons.favorite_rounded, label: 'إعجاب');
    }
  }

  /// معرّف الريل من مستند الإشعار — يدعم حقولًا متعددة (`videoId` / `reelId`).
  String _notificationReelId(Map<String, dynamic> data) {
    for (final key in ['videoId', 'reelId', 'reel_id']) {
      final v = data[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  /// مؤلف/مالك الريل لإشعارات «فيديو جديد» — يُمرَّر كـ [profileOnlyUserId] عند فتح الريلز.
  String? _notificationAuthorScopeUid(
    String type,
    Map<String, dynamic> data,
  ) {
    if (!isAuthorScopedReelNotificationType(type)) return null;
    for (final key in ['authorUid', 'ownerId', 'owner_uid']) {
      final v = data[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  void _handleTap(
    BuildContext context, {
    required String type,
    required String videoId,
    required String actorUid,
    String? profileOnlyUserId,
  }) {
    if (type == 'follow' && actorUid.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => UserProfileViewPage(
            userId: actorUid,
            fallbackName: '',
            fallbackAvatar: '',
          ),
        ),
      );
      return;
    }
    if (videoId.isNotEmpty) {
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = appNavigatorKey.currentContext;
        if (ctx == null || !ctx.mounted) return;
        pushTikTokReelsDirect(
          ctx,
          initialReelId: videoId,
          profileOnlyUserId: profileOnlyUserId,
        );
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'الإشعارات',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            shadows: [
              Shadow(
                color: widget.accentColor.withValues(alpha: 0.45),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.accentColor,
                  widget.accentColor.withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
        ),
      ),
      body: uid == null
          ? const Center(
              child: Text(
                'سجّل الدخول لعرض الإشعارات',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .limit(80)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'تعذّر تحميل الإشعارات\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: widget.accentColor),
                  );
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 56,
                          color: widget.accentColor.withValues(alpha: 0.5),
                        ),
                        const Text(
                          'لا توجد إشعارات بعد',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final body = data['body']?.toString() ?? '';
                    final type = data['type']?.toString().trim() ?? 'like';
                    final videoId = _notificationReelId(data);
                    final actorUid =
                        data['actorUid']?.toString().trim() ?? '';
                    final avatar =
                        data['actorAvatarUrl']?.toString().trim() ?? '';
                    final ts = data['createdAt'];
                    Timestamp? created;
                    if (ts is Timestamp) created = ts;
                    final timeStr =
                        created != null ? _df.format(created.toDate()) : '';
                    final meta = _typeMeta(type);

                    final tappable = type == 'follow'
                        ? actorUid.isNotEmpty
                        : videoId.isNotEmpty;

                    return ListTile(
                      onTap: !tappable
                          ? null
                          : () => _handleTap(
                                context,
                                type: type,
                                videoId: videoId,
                                actorUid: actorUid,
                                profileOnlyUserId:
                                    _notificationAuthorScopeUid(type, data),
                              ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: type == 'trending'
                          ? CircleAvatar(
                              radius: 26,
                              backgroundColor:
                                  widget.accentColor.withValues(alpha: 0.35),
                              child: Icon(
                                meta.icon,
                                color: Colors.white,
                                size: 28,
                              ),
                            )
                          : CircleAvatar(
                              radius: 26,
                              backgroundColor:
                                  widget.accentColor.withValues(alpha: 0.25),
                              backgroundImage: avatar.isNotEmpty
                                  ? CachedNetworkImageProvider(avatar)
                                  : null,
                              child: avatar.isEmpty
                                  ? Icon(meta.icon,
                                      color: widget.accentColor, size: 28)
                                  : null,
                            ),
                      title: Text(
                        body,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: widget.accentColor
                                    .withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                meta.label,
                                style: TextStyle(
                                  color:
                                      widget.accentColor.withValues(alpha: 1),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color:
                                    widget.accentColor.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

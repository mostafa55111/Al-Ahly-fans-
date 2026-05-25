import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/core/widgets/club_badge.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/user_profile_view_page.dart';

/// نوع القائمة داخل مركز المتابعة.
enum SocialGraphListKind {
  followers,
  following,
  friends,
}

/// مركز واحد: متابعون، يتابعهم، أصدقاء (من Firestore `social_graph`).
class SocialGraphHubPage extends StatelessWidget {
  const SocialGraphHubPage({
    super.key,
    required this.uid,
    this.initialKind = SocialGraphListKind.followers,
  });

  final String uid;
  final SocialGraphListKind initialKind;

  @override
  Widget build(BuildContext context) {
    final initialIndex = switch (initialKind) {
      SocialGraphListKind.followers => 0,
      SocialGraphListKind.following => 1,
      SocialGraphListKind.friends => 2,
    };

    return DefaultTabController(
      initialIndex: initialIndex,
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(
          backgroundColor: const Color(0xFF101115),
          title: Text(
            'المتابعة والأصدقاء',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.mediumGray,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: 'متابعون'),
              Tab(text: 'يتابع'),
              Tab(text: 'أصدقاء'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SocialGraphListBody(uid: uid, kind: SocialGraphListKind.followers),
            _SocialGraphListBody(uid: uid, kind: SocialGraphListKind.following),
            _SocialGraphListBody(uid: uid, kind: SocialGraphListKind.friends),
          ],
        ),
      ),
    );
  }
}

class _SocialGraphListBody extends StatelessWidget {
  const _SocialGraphListBody({
    required this.uid,
    required this.kind,
  });

  final String uid;
  final SocialGraphListKind kind;

  CollectionReference<Map<String, dynamic>> get _col {
    final root =
        FirebaseFirestore.instance.collection('social_graph').doc(uid);
    switch (kind) {
      case SocialGraphListKind.followers:
        return root.collection('followers');
      case SocialGraphListKind.following:
      case SocialGraphListKind.friends:
        return root.collection('following');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _col.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.royalBlue),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'تعذّر التحميل.\n${snap.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(color: AppColors.mediumGray),
              ),
            ),
          );
        }
        var docs =
            snap.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (kind == SocialGraphListKind.friends) {
          docs = docs
              .where((d) => (d.data()['is_friend'] as bool?) == true)
              .toList();
        }
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'لا يوجد عناصر هنا بعد.',
              style: GoogleFonts.cairo(color: AppColors.mediumGray),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          separatorBuilder: (_, __) =>
              const Divider(color: Colors.white10, height: 1),
          itemBuilder: (context, i) {
            final d = docs[i];
            final peerUid = d.id;
            final edgeSource = d.data()['app_source'] as String?;
            return _SocialUserTile(
              peerUid: peerUid,
              edgeAppSource: edgeSource,
            );
          },
        );
      },
    );
  }
}

class _SocialUserTile extends StatelessWidget {
  const _SocialUserTile({
    required this.peerUid,
    required this.edgeAppSource,
  });

  final String peerUid;
  final String? edgeAppSource;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(peerUid).snapshots(),
      builder: (context, userSnap) {
        final data = userSnap.data?.data();
        final name = (data?['name'] ??
                data?['displayName'] ??
                data?['username'] ??
                peerUid)
            .toString();
        final pic = (data?['profilePic'] ?? data?['photoURL'] ?? '').toString();
        final userSrc = (data?['fcmAppSource'] ??
                data?['firestoreAppSource'] ??
                data?['app_source'])
            .toString()
            .trim();
        final appSrc = edgeAppSource?.isNotEmpty == true
            ? edgeAppSource
            : (userSrc.isNotEmpty ? userSrc : null);
        final handle = (data?['username'] ?? '').toString().trim();

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.mediumBlack,
            backgroundImage:
                pic.isNotEmpty ? CachedNetworkImageProvider(pic) : null,
            child: pic.isEmpty
                ? const Icon(Icons.person_rounded, color: AppColors.mediumGray)
                : null,
          ),
          title: UserNameWithClubBadge(
            name: name,
            appSource: appSrc,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              fontSize: 15,
            ),
            badgeSize: 16,
          ),
          subtitle: handle.isEmpty
              ? null
              : Text(
                  '@$handle',
                  style:
                      GoogleFonts.cairo(color: AppColors.mediumGray, fontSize: 12),
                ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => UserProfileViewPage(
                  userId: peerUid,
                  fallbackName: name,
                  fallbackAvatar: pic,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

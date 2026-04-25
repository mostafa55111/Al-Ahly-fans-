import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/features/auth/presentation/pages/login_page.dart';
import 'package:gomhor_alahly_clean_new/features/profile/presentation/pages/profile_visitors_page.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';

/// ═════════════════════════════════════════════════════════════════
/// شاشة البروفايل (TikTok-style) — تصميم النادي الأهلي
/// ═════════════════════════════════════════════════════════════════
/// الترتيب من فوق لتحت:
/// 1. AppBar: زر زوار البروفايل (قدمين) + مشاركة + قائمة الإعدادات (3 نقط).
/// 2. صورة شخصية مع زر (+) لتغيير الصورة.
/// 3. الاسم بجانبه قلم لتعديله، وتحته اليوزر نيم.
/// 4. صف الإحصاءات (يتابع / متابعون / إعجابات).
/// 5. سيرة ذاتية اختيارية (Bio).
/// 6. 5 تبويبات أيقونية:
///    - عام (الريلز المتاحة للجميع)
///    - خاص (ريلز محدش يشوفها غير المالك)
///    - ترحال (Placeholder)
///    - محفوظات (الريلز اللي حفظها المستخدم)
///    - متجر (Placeholder)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // ألوان النادي الأهلي
  static const Color _ahlyRed = Color(0xFFFF2E4D);
  static const Color _ahlyGold = Color(0xFFC5A059);

  final user = FirebaseAuth.instance.currentUser;
  late DatabaseReference dbRef;
  late TabController _tabController;
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();

  @override
  void initState() {
    super.initState();
    dbRef = FirebaseDatabase.instance.ref('users/${user?.uid}');
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════
  // MARK: Settings / Edit / Share / Logout
  // ══════════════════════════════════════════════════════════════════

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _openVisitors() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileVisitorsPage()),
    );
  }

  void _shareProfile(Map<String, dynamic> userData) {
    final name = userData['name']?.toString() ?? 'جمهور الأهلي';
    final handle = userData['username']?.toString() ?? 'ahly_fan';
    final uid = user?.uid ?? '';
    final link = 'https://gomhor-alahly.app/u/$uid';
    Share.share(
      '$name (@$handle) — تطبيق جمهور الأهلي 🦅\n$link',
      subject: name,
    );
  }

  void _openSettings(Map<String, dynamic> userData) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101010),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 14),
            _settingsTile(
              ctx,
              icon: Icons.alternate_email_rounded,
              title: 'تعديل اسم المستخدم',
              onTap: () => _editProfileField(
                fieldKey: 'username',
                title: 'اسم المستخدم (بدون @)',
                currentValue: userData['username']?.toString() ?? '',
              ),
            ),
            _settingsTile(
              ctx,
              icon: Icons.notifications_none_rounded,
              title: 'الإشعارات',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('إعدادات الإشعارات قريباً')),
              ),
            ),
            _settingsTile(
              ctx,
              icon: Icons.shield_outlined,
              title: 'الخصوصية والأمان',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('قريباً')),
              ),
            ),
            _settingsTile(
              ctx,
              icon: Icons.help_outline_rounded,
              title: 'مساعدة وآراء',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('قريباً')),
              ),
            ),
            _settingsTile(
              ctx,
              icon: Icons.info_outline_rounded,
              title: 'عن جمهور الأهلي',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'جمهور الأهلي',
                applicationVersion: '2.0.0',
                applicationIcon: const Icon(Icons.shield, color: _ahlyRed),
              ),
            ),
            const Divider(color: Colors.white10, height: 18),
            _settingsTile(
              ctx,
              icon: Icons.logout_rounded,
              title: 'تسجيل الخروج',
              danger: true,
              onTap: _handleLogout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext ctx, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? _ahlyRed : Colors.white;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
    );
  }

  Future<void> _editProfileField({
    required String fieldKey,
    required String title,
    required String currentValue,
  }) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: fieldKey == 'bio' ? 3 : 1,
          maxLength: fieldKey == 'bio' ? 80 : 30,
          decoration: const InputDecoration(
            hintText: 'اكتب هنا',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _ahlyRed),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == null || user == null) return;
    await FirebaseDatabase.instance
        .ref('users/${user!.uid}/$fieldKey')
        .set(result);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم التعديل بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _changeProfilePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (image == null || user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('جاري رفع الصورة...'),
        backgroundColor: Colors.blueGrey,
      ),
    );

    try {
      final url = await _cloudinary.uploadImage(File(image.path));
      if (url.isEmpty) throw Exception('رابط الصورة فارغ');

      await FirebaseDatabase.instance
          .ref('users/${user!.uid}/profilePic')
          .set(url);
      await user!.updatePhotoURL(url);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم تحديث صورة البروفايل بنجاح! 🦅'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('خطأ في رفع الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // MARK: Build
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('سجّل الدخول لعرض البروفايل',
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder(
        stream: dbRef.onValue,
        builder: (context, snapshot) {
          final userData = (snapshot.hasData &&
                  snapshot.data!.snapshot.value is Map)
              ? Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map)
              : <String, dynamic>{};

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(userData),
              SliverToBoxAdapter(child: _buildProfileHeader(userData)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(_buildTabBar()),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _PublicReelsTab(uid: user!.uid),
                _PrivateReelsTab(uid: user!.uid),
                const _PlaceholderTab(
                  icon: Icons.flight_takeoff_rounded,
                  title: 'حجوزات الترحال',
                  subtitle:
                      'هنا تظهر تذاكر ومواعيد الرحلات اللي حجزتها.\nقريباً نطوّر شاشة الترحال 🌍',
                ),
                _SavedReelsTab(uid: user!.uid),
                const _PlaceholderTab(
                  icon: Icons.shopping_bag_outlined,
                  title: 'مشترياتك من المتجر',
                  subtitle:
                      'هنا تظهر شحناتك وموعد الاستلام.\nقريباً نطوّر شاشة المتجر 🛒',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // AppBar: ثلاث أزرار (قدمين / مشاركة / إعدادات)
  // ──────────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(Map<String, dynamic> userData) {
    return SliverAppBar(
      backgroundColor: Colors.black,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        '@${userData['username']?.toString() ?? 'ahly_fan'}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
      centerTitle: true,
      // الـ leading فيه زرّين: زوار البروفايل + مشاركة
      leading: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 👣 زوّار البروفايل
          IconButton(
            tooltip: 'زوار البروفايل',
            icon: const Icon(Icons.directions_walk_rounded,
                color: Colors.white, size: 26),
            onPressed: _openVisitors,
          ),
        ],
      ),
      leadingWidth: 56,
      actions: [
        // 🔗 مشاركة لينك البروفايل
        IconButton(
          tooltip: 'مشاركة الملف',
          icon: const Icon(Icons.ios_share_rounded,
              color: Colors.white, size: 24),
          onPressed: () => _shareProfile(userData),
        ),
        // ⋮ قائمة الإعدادات (تسجيل خروج + كل الإعدادات)
        IconButton(
          tooltip: 'الإعدادات',
          icon: const Icon(Icons.more_vert_rounded,
              color: Colors.white, size: 26),
          onPressed: () => _openSettings(userData),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Header: صورة + اسم + إحصاءات + بايو
  // ──────────────────────────────────────────────────────────────────
  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    final pic = userData['profilePic']?.toString() ?? '';
    final name = userData['name']?.toString() ?? 'مشجع أهلاوي';
    final bio = userData['bio']?.toString() ?? '';
    final uid = user?.uid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // الصورة + زر +
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_ahlyRed, _ahlyGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFF161616),
                    backgroundImage: pic.isNotEmpty
                        ? CachedNetworkImageProvider(pic)
                        : null,
                    child: pic.isEmpty
                        ? const Icon(Icons.person,
                            color: Colors.white38, size: 56)
                        : null,
                  ),
                ),
                // زر (+) لتغيير الصورة، تحت الصورة في الوسط
                Positioned(
                  bottom: -2,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Material(
                      color: _ahlyRed,
                      shape: const CircleBorder(),
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _changeProfilePhoto,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.add,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // الاسم بجانبه قلم لتعديله
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _editProfileField(
                  fieldKey: 'name',
                  title: 'تعديل الاسم',
                  currentValue: name,
                ),
                icon: const Icon(Icons.edit_outlined,
                    color: Colors.white60, size: 18),
              ),
            ],
          ),

          // اليوزر نيم
          Text(
            '@${userData['username']?.toString() ?? 'ahly_fan'}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),

          const SizedBox(height: 16),

          // إحصاءات حية من Firebase
          if (uid != null) _LiveProfileStats(uid: uid),

          const SizedBox(height: 16),

          // البايو (اختياري) — اضغط لتعديل
          InkWell(
            onTap: () => _editProfileField(
              fieldKey: 'bio',
              title: 'سيرة ذاتية (اختياري)',
              currentValue: bio,
            ),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                bio.isNotEmpty
                    ? bio
                    : '+ أضف سيرة ذاتية (اختياري)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: bio.isNotEmpty ? Colors.white70 : Colors.white38,
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // TabBar — 5 أيقونات
  // ──────────────────────────────────────────────────────────────────
  TabBar _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.white,
      indicatorWeight: 2,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white38,
      tabs: const [
        Tab(icon: Icon(Icons.favorite_border_rounded, size: 22)), // عام
        Tab(icon: Icon(Icons.lock_outline_rounded, size: 22)), // خاص
        Tab(icon: Icon(Icons.flight_takeoff_rounded, size: 22)), // ترحال
        Tab(icon: Icon(Icons.bookmark_border_rounded, size: 22)), // محفوظات
        Tab(icon: Icon(Icons.shopping_bag_outlined, size: 22)), // متجر
      ],
    );
  }
}

/// ═════════════════════════════════════════════════════════════════
/// TabBar Persistent Header Delegate
/// ═════════════════════════════════════════════════════════════════
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}

// ════════════════════════════════════════════════════════════════════
// MARK: Tabs implementations
// ════════════════════════════════════════════════════════════════════

/// تبويب الريلز العامة: الريلز اللي رفعها المستخدم وغير خاصة (للجميع)
class _PublicReelsTab extends StatelessWidget {
  final String uid;
  const _PublicReelsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return _ReelsGridStream(
      stream: FirebaseDatabase.instance
          .ref('reels')
          .orderByChild('userId')
          .equalTo(uid)
          .onValue,
      filter: (m) => m.userId == uid && !m.isPrivate,
      emptyMessage:
          'لم ترفع أي ريل عام بعد.\nانتقل للريلز واضغط +',
    );
  }
}

/// تبويب الريلز الخاصة: ريلز الـ user الخاصة (`isPrivate == true`)
class _PrivateReelsTab extends StatelessWidget {
  final String uid;
  const _PrivateReelsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return _ReelsGridStream(
      stream: FirebaseDatabase.instance
          .ref('reels')
          .orderByChild('userId')
          .equalTo(uid)
          .onValue,
      filter: (m) => m.userId == uid && m.isPrivate,
      emptyMessage:
          'لا توجد ريلز خاصة.\nعند رفع ريل، فعّل خيار "ريل خاص" ليظهر هنا فقط.',
      lockBadge: true,
    );
  }
}

/// تبويب المحفوظات: ريلز محفوظة في `users/$uid/savedVideos`
class _SavedReelsTab extends StatelessWidget {
  final String uid;
  const _SavedReelsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('users/$uid/savedVideos').onValue,
      builder: (context, savedSnap) {
        if (savedSnap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFE2C55)));
        }
        final raw = savedSnap.data?.snapshot.value;
        final ids = <String>{};
        if (raw is Map) {
          raw.forEach((k, _) => ids.add(k.toString()));
        }
        if (ids.isEmpty) {
          return const _PlaceholderTab(
            icon: Icons.bookmark_border_rounded,
            title: 'لا توجد ريلز محفوظة',
            subtitle:
                'احفظ ريلز من زر الحفظ في شاشة الريلز لتظهر هنا.',
          );
        }
        return _ReelsGridStream(
          stream: FirebaseDatabase.instance.ref('reels').onValue,
          filter: (m) => ids.contains(m.id),
          emptyMessage: 'لم تُعثر على الريلز المحفوظة',
        );
      },
    );
  }
}

class _LiveProfileStats extends StatelessWidget {
  const _LiveProfileStats({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('follows/$uid').onValue,
      builder: (context, followingSnap) {
        final followingCount = _countMapChildren(followingSnap.data?.snapshot.value);
        return StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('follows').onValue,
          builder: (context, followsSnap) {
            final followersCount = _countFollowersFromFollows(
              followsSnap.data?.snapshot.value,
              uid,
            );
            return StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance
                  .ref('reels')
                  .orderByChild('userId')
                  .equalTo(uid)
                  .onValue,
              builder: (context, reelsSnap) {
                final likes = _sumLikesFromUserReels(reelsSnap.data?.snapshot.value);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stat('$followingCount', 'يتابع'),
                    _divider(),
                    _stat('$followersCount', 'متابعون'),
                    _divider(),
                    _stat('$likes', 'إعجابات'),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  static int _countMapChildren(dynamic v) {
    if (v is Map) return v.length;
    return 0;
  }

  static int _countFollowersFromFollows(dynamic v, String userId) {
    if (v is! Map) return 0;
    int count = 0;
    final root = Map<dynamic, dynamic>.from(v);
    for (final entry in root.entries) {
      final followingMap = entry.value;
      if (followingMap is! Map) continue;
      final row = Map<dynamic, dynamic>.from(followingMap);
      if (row.containsKey(userId)) count++;
    }
    return count;
  }

  static int _sumLikesFromUserReels(dynamic v) {
    if (v is! Map) return 0;
    int sum = 0;
    final rows = Map<dynamic, dynamic>.from(v);
    for (final reel in rows.values) {
      if (reel is! Map) continue;
      final map = Map<dynamic, dynamic>.from(reel);
      final likesMap = map['likes'];
      if (likesMap is Map) {
        sum += likesMap.length;
      } else {
        final likesCount = map['likesCount'];
        if (likesCount is int) sum += likesCount;
      }
    }
    return sum;
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(width: 1, height: 26, color: Colors.white12),
      );
}

/// شبكة ريلز عامة بفلتر — للاستخدام في كل التبويبات.
class _ReelsGridStream extends StatelessWidget {
  final Stream<DatabaseEvent> stream;
  final bool Function(VideoModel) filter;
  final String emptyMessage;
  final bool lockBadge;

  const _ReelsGridStream({
    required this.stream,
    required this.filter,
    required this.emptyMessage,
    this.lockBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFE2C55)));
        }
        final raw = snap.data?.snapshot.value;
        final list = <VideoModel>[];
        if (raw is Map) {
          raw.forEach((k, v) {
            if (v is Map) {
              try {
                final m = VideoModel.fromJson(
                  Map<String, dynamic>.from(v),
                  k.toString(),
                );
                if (m.videoUrl.isEmpty) return;
                if (filter(m)) list.add(m);
              } catch (_) {}
            }
          });
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }

        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, height: 1.5),
              ),
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1.0,
            mainAxisSpacing: 1.0,
            childAspectRatio: 0.68,
          ),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final r = list[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileReelPlayerPage(
                      reels: list,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: r.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.white10,
                      child: const Center(
                        child: Icon(Icons.play_circle_outline,
                            color: Colors.white24, size: 24),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(Icons.error_outline,
                            color: Colors.white24, size: 20),
                      ),
                    ),
                  ),
                  // شارة قفل للريلز الخاصة
                  if (lockBadge)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.lock_rounded,
                          color: Colors.white, size: 14),
                    ),
                  // عداد المشاهدات
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Row(
                      children: [
                        const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          _formatCount(r.viewsCount > 0
                              ? r.viewsCount
                              : r.likesCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

/// تبويب فاضي مع رسالة (للترحال والمتجر مؤقتاً)
class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: Colors.white12),
              ),
              child: Icon(icon, color: Colors.white60, size: 42),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// MARK: Reel Player (used from grid taps)
// ════════════════════════════════════════════════════════════════════

/// تشغيل فيديو بملء الشاشة من البروفايل (تمرير عمودي بين فيديوهات الشبكة).
class ProfileReelPlayerPage extends StatefulWidget {
  final List<VideoModel> reels;
  final int initialIndex;
  final String? displayName;

  const ProfileReelPlayerPage({
    super.key,
    required this.reels,
    this.initialIndex = 0,
    this.displayName,
  });

  @override
  State<ProfileReelPlayerPage> createState() => _ProfileReelPlayerPageState();
}

class _ProfileReelPlayerPageState extends State<ProfileReelPlayerPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(parent: PageScrollPhysics()),
            itemCount: widget.reels.length,
            itemBuilder: (context, index) {
              final url = widget.reels[index].videoUrl;
              return _SingleReelPlayer(videoUrl: url);
            },
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                if (widget.displayName != null)
                  Expanded(
                    child: Text(
                      widget.displayName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleReelPlayer extends StatefulWidget {
  final String videoUrl;
  const _SingleReelPlayer({required this.videoUrl});

  @override
  State<_SingleReelPlayer> createState() => _SingleReelPlayerState();
}

class _SingleReelPlayerState extends State<_SingleReelPlayer> {
  VideoPlayerController? _c;
  bool _ready = false;
  bool _err = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.isEmpty) {
      _err = true;
      return;
    }
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          ..setLooping(true);
    _c = controller;
    controller.initialize().then((_) {
      if (mounted) {
        setState(() => _ready = true);
        controller.play();
      }
    }).catchError((_) {
      if (mounted) setState(() => _err = true);
    });
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_err || _c == null) {
      return const Center(
          child: Icon(Icons.error_outline, color: Colors.white38, size: 48));
    }
    if (!_ready) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return GestureDetector(
      onTap: () {
        if (_c!.value.isPlaying) {
          _c!.pause();
        } else {
          _c!.play();
        }
        setState(() {});
      },
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _c!.value.size.width,
          height: _c!.value.size.height,
          child: VideoPlayer(_c!),
        ),
      ),
    );
  }
}

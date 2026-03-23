import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/features/profile/presentation/pages/login_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

/// بروفايل بأسلوب TikTok: رأس مركزي، إحصائيات، أزرار، تبويب فيديوهات / محفوظات، شبكة بلا فراغات.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  late DatabaseReference dbRef;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    dbRef = FirebaseDatabase.instance.ref("users/${user?.uid}");
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Set<String> _savedIdsFromEvent(DatabaseEvent? ev) {
    final ids = <String>{};
    final v = ev?.snapshot.value;
    if (v is Map) {
      v.forEach((k, val) {
        if (val == true) ids.add(k.toString());
      });
    }
    return ids;
  }

  void _showAdvancedSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "البحث المتقدم",
                style: TextStyle(color: Color(0xFFC5A059), fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "ابحث عن مشجعين، منشورات، أو أخبار...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFC5A059)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: const [
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text(
                          "ابدأ البحث لاستكشاف عالم الأهلي",
                          style: TextStyle(color: Colors.white24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "الإشعارات",
              style: TextStyle(color: Color(0xFFC5A059), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Icon(Icons.notifications_off_outlined, color: Colors.grey, size: 50),
            SizedBox(height: 10),
            Text("لا توجد إشعارات جديدة حالياً", style: TextStyle(color: Colors.white70)),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _addNewAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showAlMaredAssistant() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', width: 30, errorBuilder: (c, e, s) => const Icon(Icons.bolt, color: Colors.red)),
            const SizedBox(width: 10),
            const Text("المارد الأهلاوي", style: TextStyle(color: Color(0xFFC5A059))),
          ],
        ),
        content: const Text(
          "أنا المارد الأهلاوي، مساعدك الذكي. كيف يمكنني مساعدتك اليوم في تشجيع نادي القرن؟",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("شكراً يا مارد", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
          decoration: const InputDecoration(hintText: 'اكتب هنا', hintStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty || user == null) return;
    await FirebaseDatabase.instance.ref('users/${user!.uid}/$fieldKey').set(result);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم التعديل بنجاح'), backgroundColor: Colors.green),
    );
  }

  Future<void> _changeProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (image == null || user == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري رفع الصورة...'),
          backgroundColor: Colors.blue,
        ),
      );

      final result = await _cloudinaryService.uploadImage(
        imageFile: File(image.path),
        userId: user!.uid,
        userName: user!.displayName ?? 'مشجع أهلاوي',
      );

      if (result != null && result['success'] == true) {
        final imageUrl = result['url']?.toString();
        if (imageUrl != null) {
          await FirebaseDatabase.instance.ref('users/${user!.uid}/profilePic').set(imageUrl);
          await user!.updatePhotoURL(imageUrl);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث صورة البروفايل بنجاح! 🦅'),
              backgroundColor: Colors.green,
            ),
          );
          
          if (mounted) setState(() {});
        }
      } else {
        throw result?['error'] ?? 'فشل الرفع';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في رفع الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addStory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('القصص قريباً — تابع التحديثات'),
        backgroundColor: Color(0xFF2374E1),
      ),
    );
  }

  void _showEditProfileMenu(Map<String, dynamic> userData) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.badge_outlined, color: Colors.white70),
              title: const Text('تعديل الاسم', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _editProfileField(
                  fieldKey: 'name',
                  title: 'تعديل الاسم',
                  currentValue: userData['name']?.toString() ?? '',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notes_rounded, color: Colors.white70),
              title: const Text('تعديل النبذة', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _editProfileField(
                  fieldKey: 'bio',
                  title: 'نبذة عنك',
                  currentValue: userData['bio']?.toString() ?? '',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.alternate_email, color: Colors.white70),
              title: const Text('تعديل اسم المستخدم', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _editProfileField(
                  fieldKey: 'username',
                  title: 'اسم المستخدم (بدون @)',
                  currentValue: userData['username']?.toString() ?? '',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareProfile(Map<String, dynamic> userData) {
    final name = userData['name']?.toString() ?? 'جمهور الأهلي';
    final handle = userData['username']?.toString() ?? 'ahly_fan';
    Share.share('$name (@$handle) — تطبيق جمهور الأهلي 🦅', subject: name);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('سجّل الدخول لعرض البروفايل', style: TextStyle(color: Colors.white70))),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      endDrawer: Drawer(
        backgroundColor: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0A0A0A)),
              child: Center(
                child: Text(
                  "إعدادات الحساب",
                  style: TextStyle(color: Color(0xFFC5A059), fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
              title: const Text("إضافة حساب جديد", style: TextStyle(color: Colors.white)),
              onTap: _addNewAccount,
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text("تسجيل الخروج", style: TextStyle(color: Colors.red)),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          user!.displayName ?? 'جمهور الأهلي',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.person_add_outlined, color: Colors.white, size: 26),
          onPressed: _addNewAccount,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 26),
            onPressed: _showAdvancedSearch,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
            onPressed: _showNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: dbRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFE2C55)));
          }
          final currentUser = user!;
          final userData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 350),
                    child: Column(
                      children: [
                        _buildTikTokProfileCenter(userData),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _tikTokOutlineButton(
                                  label: 'إضافة قصة',
                                  onTap: _addStory,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _tikTokOutlineButton(
                                  label: 'المارد',
                                  onTap: _showAlMaredAssistant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 44,
                                width: 44,
                                child: OutlinedButton(
                                  onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white24),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Icon(Icons.more_horiz, size: 22),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildBioBlock(userData),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              Material(
                color: Colors.black,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 2,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on_rounded, size: 22)),
                    Tab(icon: Icon(Icons.bookmark_border, size: 22)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyVideosTab(currentUser.uid, userData),
                    _buildSavedVideosTab(currentUser.uid),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTikTokProfileCenter(Map<String, dynamic> userData) {
    final pic = userData['profilePic']?.toString() ?? '';
    final name = userData['name']?.toString() ?? 'مشجع أهلاوي';
    final handle = userData['username']?.toString() ?? 'ahly_fan';
    final followers = '${userData['followers'] ?? 0}';
    final following = '${userData['following'] ?? 0}';
    final likes = '${userData['likes'] ?? 0}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFF161616),
                backgroundImage: pic.isNotEmpty ? CachedNetworkImageProvider(pic) : null,
                child: pic.isEmpty ? const Icon(Icons.person, color: Colors.white38, size: 52) : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: const Color(0xFFFE2C55),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _changeProfilePhoto,
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => _editProfileField(
                  fieldKey: 'name',
                  title: 'تعديل الاسم',
                  currentValue: userData['name']?.toString() ?? '',
                ),
                icon: const Icon(Icons.edit, color: Colors.white38, size: 18),
              ),
            ],
          ),
          Text(
            '@$handle',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tikTokStatColumn(following, 'يتابع'),
              _tikTokDivider(),
              _tikTokStatColumn(followers, 'متابِعون'),
              _tikTokDivider(),
              _tikTokStatColumn(likes, 'إعجابات'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _tikTokPrimaryButton(
                  label: 'تعديل الملف الشخصي',
                  filled: true,
                  onTap: () => _showEditProfileMenu(userData),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tikTokPrimaryButton(
                  label: 'مشاركة الملف',
                  filled: false,
                  onTap: () => _shareProfile(userData),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tikTokDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(width: 1, height: 28, color: Colors.white12),
    );
  }

  Widget _tikTokStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
        ),
      ],
    );
  }

  Widget _tikTokOutlineButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }

  Widget _tikTokPrimaryButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 44,
      child: filled
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF252525),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
    );
  }

  Widget _buildBioBlock(Map<String, dynamic> userData) {
    final bio = userData['bio']?.toString() ?? '';
    return Align(
      alignment: Alignment.center,
      child: InkWell(
        onTap: () => _editProfileField(
          fieldKey: 'bio',
          title: 'تعديل النبذة',
          currentValue: bio,
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            bio.isNotEmpty ? bio : 'أضف نبذة عنك — اضغط للتعديل',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: bio.isNotEmpty ? Colors.white70 : Colors.white30,
              fontSize: 14,
              height: 1.35,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildMyVideosTab(String uid, Map<String, dynamic> userData) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _cloudinaryService.getUserReelsStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFE2C55)));
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const Center(
            child: Text(
              'لم ترفع أي فيديو بعد.\nانتقل للريلز واضغط +',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, height: 1.4),
            ),
          );
        }
        return _reelsGrid(
          list: list,
          onCellTap: (index) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProfileReelPlayerPage(
                  reels: list,
                  initialIndex: index,
                  displayName: userData['name']?.toString(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedVideosTab(String uid) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('users/$uid/savedReels').onValue,
      builder: (context, savedSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _cloudinaryService.getReelsStream(),
          builder: (context, reelsSnap) {
            final ids = _savedIdsFromEvent(savedSnap.data);
            final all = reelsSnap.data ?? [];
            final list = all.where((r) => ids.contains(r['id']?.toString())).toList();
            list.sort((a, b) {
              final da = a['createdAt']?.toString() ?? '';
              final db = b['createdAt']?.toString() ?? '';
              return db.compareTo(da);
            });
            if (reelsSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFE2C55)));
            }
            if (list.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'احفظ ريلز من زر الحفظ في الشاشة الرئيسية للريلز',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, height: 1.4),
                  ),
                ),
              );
            }
            return _reelsGrid(
              list: list,
              onCellTap: (index) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileReelPlayerPage(
                      reels: list,
                      initialIndex: index,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _reelsGrid({
    required List<Map<String, dynamic>> list,
    required void Function(int index) onCellTap,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.72,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final r = list[index];
        final thumb = r['thumbnail']?.toString() ?? '';
        final likes = r['likes'] ?? 0;
        return GestureDetector(
          onTap: () => onCellTap(index),
          child: Container(
            color: const Color(0xFF0F0F0F),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (thumb.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: thumb,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.play_circle_outline, color: Colors.white24, size: 36),
                    ),
                  )
                else
                  Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Icon(Icons.play_circle_outline, color: Colors.white24, size: 36),
                  ),
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: Row(
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 15),
                      Text(
                        '$likes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// تشغيل فيديو بملء الشاشة من البروفايل (تمرير عمودي بين فيديوهات الشبكة).
class ProfileReelPlayerPage extends StatefulWidget {
  final List<Map<String, dynamic>> reels;
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
              final url = widget.reels[index]['videoUrl']?.toString() ?? '';
              return _SingleReelPlayer(videoUrl: url);
            },
          ),
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
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
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))..setLooping(true);
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
      return const Center(child: Icon(Icons.error_outline, color: Colors.white38, size: 48));
    }
    if (!_ready) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
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

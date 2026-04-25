import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';
import 'package:gomhor_alahly_clean_new/features/profile/presentation/pages/profile_screen.dart'
    show ProfileReelPlayerPage;

/// ═══════════════════════════════════════════════════════════════════
/// صفحة عرض بروفايل مستخدم آخر (Read-only)
/// ═══════════════════════════════════════════════════════════════════
/// ‣ تُفتح عند الضغط على الصورة/الاسم داخل الريل.
/// ‣ تعرض: صورة البروفايل، الاسم، الـ bio، الإحصاءات، وشبكة الريلز الخاصة به.
/// ‣ تدعم زر "متابعة/إلغاء متابعة" عبر عقدة `follows/{me}/{target}`.
/// ‣ تصميم بألوان النادي الأهلي (أحمر ملكي + ذهبي).
class UserProfileViewPage extends StatefulWidget {
  final String userId;
  final String? fallbackName;
  final String? fallbackAvatar;

  const UserProfileViewPage({
    super.key,
    required this.userId,
    this.fallbackName,
    this.fallbackAvatar,
  });

  @override
  State<UserProfileViewPage> createState() => _UserProfileViewPageState();
}

class _UserProfileViewPageState extends State<UserProfileViewPage> {
  final _db = FirebaseDatabase.instance;
  bool _isFollowing = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _checkIsFollowing();
    _logVisit();
  }

  /// تسجيل الزيارة في `users/{target}/visitors/{me}` عشان صاحب البروفايل
  /// يقدر يشوف مين زاره. لا نسجّل لو الزائر هو نفس المالك.
  Future<void> _logVisit() async {
    if (_myUid == null || _isSelf) return;
    try {
      await _db
          .ref('users/${widget.userId}/visitors/$_myUid')
          .set({'ts': ServerValue.timestamp});
    } catch (e) {
      debugPrint('logVisit error: $e');
    }
  }

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;
  bool get _isSelf => _myUid != null && _myUid == widget.userId;

  Future<void> _checkIsFollowing() async {
    if (_myUid == null || _isSelf) return;
    try {
      final snap = await _db
          .ref('follows/$_myUid/${widget.userId}')
          .get()
          .timeout(const Duration(seconds: 5));
      if (mounted) setState(() => _isFollowing = snap.exists);
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    if (_myUid == null || _isSelf || _isBusy) return;
    setState(() => _isBusy = true);
    final willFollow = !_isFollowing;
    final myFollowingRef = _db.ref('follows/$_myUid/${widget.userId}');
    final targetFollowersRef = _db.ref('followers/${widget.userId}/$_myUid');
    try {
      if (willFollow) {
        await myFollowingRef.set({'ts': ServerValue.timestamp});
        await targetFollowersRef.set({'ts': ServerValue.timestamp});
      } else {
        await myFollowingRef.remove();
        await targetFollowersRef.remove();
      }
      if (mounted) setState(() => _isFollowing = willFollow);
    } catch (e) {
      debugPrint('toggleFollow error: $e');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _db.ref('users/${widget.userId}').onValue,
        builder: (context, userSnap) {
          final userData = (userSnap.data?.snapshot.value is Map)
              ? Map<dynamic, dynamic>.from(
                  userSnap.data!.snapshot.value as Map)
              : <dynamic, dynamic>{};

          final name = (userData['name'] ??
                  userData['displayName'] ??
                  widget.fallbackName ??
                  'مستخدم')
              .toString();
          final handle = (userData['username'] ?? 'ahly_fan').toString();
          final bio = (userData['bio'] ?? '').toString();
          final avatar = (userData['profilePic'] ??
                  userData['photoURL'] ??
                  widget.fallbackAvatar ??
                  '')
              .toString();
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildAvatar(avatar),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@$handle',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                _buildLiveStats(),
                const SizedBox(height: 16),
                if (bio.isNotEmpty) _buildBio(bio),
                const SizedBox(height: 14),
                if (!_isSelf) _buildFollowButton(),
                const SizedBox(height: 14),
                const Divider(color: Colors.white10, height: 1),
                _buildUserReelsGrid(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String url) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.luminousGold, width: 2),
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _placeholder(),
                placeholder: (_, __) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF161616),
        child: const Icon(Icons.person, color: Colors.white38, size: 52),
      );

  Widget _buildLiveStats() {
    return StreamBuilder<DatabaseEvent>(
      stream: _db.ref('follows/${widget.userId}').onValue,
      builder: (context, followingSnap) {
        final following = _countMap(followingSnap.data?.snapshot.value);
        return StreamBuilder<DatabaseEvent>(
          stream: _db.ref('followers/${widget.userId}').onValue,
          builder: (context, followersSnap) {
            final followers = _countMap(followersSnap.data?.snapshot.value);
            return StreamBuilder<DatabaseEvent>(
              stream: _db
                  .ref('reels')
                  .orderByChild('userId')
                  .equalTo(widget.userId)
                  .onValue,
              builder: (context, reelsSnap) {
                final likes = _sumLikes(reelsSnap.data?.snapshot.value);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stat('$following', 'يتابع'),
                    _divider(),
                    _stat('$followers', 'متابِعون'),
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

  int _countMap(dynamic v) => v is Map ? v.length : 0;

  int _sumLikes(dynamic v) {
    if (v is! Map) return 0;
    int sum = 0;
    final rows = Map<dynamic, dynamic>.from(v);
    for (final reel in rows.values) {
      if (reel is! Map) continue;
      final map = Map<dynamic, dynamic>.from(reel);
      final likes = map['likes'];
      if (likes is Map) {
        sum += likes.length;
      } else if (map['likesCount'] is int) {
        sum += map['likesCount'] as int;
      }
    }
    return sum;
  }

  Widget _stat(String v, String label) {
    return Column(
      children: [
        Text(v,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        color: Colors.white12,
      );

  Widget _buildBio(String bio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        bio,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
      ),
    );
  }

  Widget _buildFollowButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        width: double.infinity,
        height: 42,
        child: FilledButton(
          onPressed: _isBusy ? null : _toggleFollow,
          style: FilledButton.styleFrom(
            backgroundColor:
                _isFollowing ? Colors.white10 : AppColors.royalRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: _isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  _isFollowing ? 'تتابع' : 'متابعة',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
        ),
      ),
    );
  }

  /// شبكة ريلز المستخدم — تُجلب مباشرة من `/reels` ومرشّحة حسب userId.
  Widget _buildUserReelsGrid() {
    return StreamBuilder<DatabaseEvent>(
      stream: _db.ref('reels').orderByChild('userId').equalTo(widget.userId).onValue,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.royalRed),
            ),
          );
        }
        final raw = snap.data?.snapshot.value;
        final list = <VideoModel>[];
        if (raw is Map) {
          raw.forEach((k, v) {
            if (v is Map) {
              try {
                final model = VideoModel.fromJson(
                  Map<String, dynamic>.from(v),
                  k.toString(),
                );
                if (model.userId == widget.userId &&
                    model.videoUrl.isNotEmpty) {
                  list.add(model);
                }
              } catch (_) {}
            }
          });
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }

        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text(
                'لا توجد ريلز بعد',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
            childAspectRatio: 0.68,
          ),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final r = list[i];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileReelPlayerPage(
                      reels: list,
                      initialIndex: i,
                      displayName: widget.fallbackName,
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
                    placeholder: (_, __) => Container(color: Colors.white10),
                    errorWidget: (_, __, ___) =>
                        Container(color: Colors.black26),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 2),
                          Text(
                            _formatCount(r.likesCount),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
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

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

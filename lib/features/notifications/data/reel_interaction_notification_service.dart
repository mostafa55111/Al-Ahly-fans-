import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';

/// إرسال إشعار لتفاعل على ريل (يتطلّب نشر Cloud Function `sendReelInteractionNotification`).
class ReelInteractionNotificationService {
  ReelInteractionNotificationService({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  Future<void> notifyLike(VideoModel reel) =>
      _send(reel: reel, kind: _InteractionKind.like);

  Future<void> notifyComment(VideoModel reel) =>
      _send(reel: reel, kind: _InteractionKind.comment);

  /// إشعار متابعة جديدة لصاحب الحساب المستهدف.
  /// **ملاحظة:** مسار المتابعة الحالي يمرّ عبر Firestore `social_graph`؛ الإشعار الفوري
  /// يُرسل من Cloud Function [onSocialGraphNewFollower]. لا تستدعِ هذه الدالة من مسار المتابعة
  /// لتفادي الإشعار المضاعف — احتفظ بها للتوافق مع استدعاءات قديمة أو أدوات إدارية.
  Future<void> notifyNewFollow(String targetUserId) async {
    final actor = _auth.currentUser;
    if (actor == null) return;
    if (targetUserId.isEmpty || targetUserId == actor.uid) return;

    final actorName = _resolveActorName(actor);
    final body = ReelNotificationCopy.followBody(actorName);

    try {
      final callable =
          _functions.httpsCallable('sendReelInteractionNotification');
      await callable.call({
        'targetUserId': targetUserId,
        'title': AppConfig.appName,
        'body': body,
        'actorUid': actor.uid,
        'actorName': actorName,
        'actorAvatarUrl': actor.photoURL ?? '',
        'type': 'follow',
        'videoId': '',
      });
    } catch (e, st) {
      debugPrint('[Push] notifyNewFollow failed: $e\n$st');
    }
  }

  Future<void> _send({
    required VideoModel reel,
    required _InteractionKind kind,
  }) async {
    final actor = _auth.currentUser;
    if (actor == null) return;
    if (reel.userId.isEmpty || reel.userId == actor.uid) return;

    final actorName = _resolveActorName(actor);
    final body = switch (kind) {
      _InteractionKind.like => ReelNotificationCopy.likeBody(actorName),
      _InteractionKind.comment => ReelNotificationCopy.commentBody(actorName),
    };

    try {
      final callable =
          _functions.httpsCallable('sendReelInteractionNotification');
      await callable.call({
        'targetUserId': reel.userId,
        'title': AppConfig.appName,
        'body': body,
        'actorUid': actor.uid,
        'actorName': actorName,
        'actorAvatarUrl': actor.photoURL ?? '',
        'type': kind.name,
        'videoId': reel.id,
      });
    } catch (e, st) {
      debugPrint('[Push] sendReelInteractionNotification failed: $e\n$st');
    }
  }

  String _resolveActorName(User u) {
    final dn = u.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    final em = u.email;
    if (em != null && em.contains('@')) {
      return em.split('@').first;
    }
    return 'مشجع';
  }
}

enum _InteractionKind { like, comment }

/// نصوص الإشعار حسب هوية التطبيق (أهلي / زمالك).
class ReelNotificationCopy {
  ReelNotificationCopy._();

  static String likeBody(String actorName) {
    if (AppConfig.reelsFirestoreClubTag == 'ahly') {
      return 'نادي القرن: $actorName أعجب بالفيديو الخاص بك';
    }
    return 'الملكي: $actorName أعجب بالفيديو الخاص بك';
  }

  static String commentBody(String actorName) {
    if (AppConfig.reelsFirestoreClubTag == 'ahly') {
      return 'نادي القرن: $actorName ترك تعليقاً على الريل الخاص بك';
    }
    return 'الملكي: $actorName ترك تعليقاً على الريل الخاص بك';
  }

  static String followBody(String actorName) {
    if (AppConfig.reelsFirestoreClubTag == 'ahly') {
      return 'نادي القرن: $actorName بدأ يتابعك';
    }
    return 'الملكي: $actorName بدأ يتابعك';
  }
}

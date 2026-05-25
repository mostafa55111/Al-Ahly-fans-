import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';

/// رسم بياني اجتماعي في Firestore تحت [social_graph] مع مزامنة [follows]/[followers] في RTDB
/// حتى تظل شاشة الريلز والبروفايل تعمل كما هي.
///
/// البنية:
/// - `social_graph/{uid}/following/{peerUid}` — المستخدم يتابع peer
/// - `social_graph/{uid}/followers/{peerUid}` — peer يتابع المستخدم
/// الحقول: `peerUid`, `followedAt`, `is_friend`, `app_source`
class SocialGraphService {
  SocialGraphService._();

  static final FirebaseFirestore _fs = FirebaseFirestore.instance;
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  static DocumentReference<Map<String, dynamic>> _followingDoc(
    String uid,
    String peerUid,
  ) =>
      _fs.collection('social_graph').doc(uid).collection('following').doc(peerUid);

  static DocumentReference<Map<String, dynamic>> _followersDoc(
    String uid,
    String peerUid,
  ) =>
      _fs.collection('social_graph').doc(uid).collection('followers').doc(peerUid);

  /// متابعة مستخدم: يحدّث Firestore + RTDB، ويضبط [is_friend] للطرفين عند التبادل.
  static Future<void> followUser(String targetUid) async {
    final current = FirebaseAuth.instance.currentUser?.uid;
    if (current == null || targetUid.isEmpty || current == targetUid) return;

    final appSource = AppConfig.firestoreAppSource;
    final now = FieldValue.serverTimestamp();

    // هل المستهدف يتابعني بالفعل؟ إن نعم، تصبح صداقة متبادلة بعد هذه الخطوة.
    final reverseSnap = await _followingDoc(targetUid, current).get();
    final mutual = reverseSnap.exists;

    final batch = _fs.batch();

    batch.set(_followingDoc(current, targetUid), <String, dynamic>{
      'peerUid': targetUid,
      'followedAt': now,
      'is_friend': mutual,
      'app_source': appSource,
    });
    batch.set(_followersDoc(targetUid, current), <String, dynamic>{
      'peerUid': current,
      'followedAt': now,
      'is_friend': mutual,
      'app_source': appSource,
    });

    // تحديث الحواف العكسية القائمة عند المتابعة المتبادلة
    if (mutual) {
      batch.update(_followingDoc(targetUid, current), {'is_friend': true});
      batch.update(_followersDoc(current, targetUid), {'is_friend': true});
    }

    await batch.commit();

    await _db.ref('follows/$current/$targetUid').set({
      'ts': ServerValue.timestamp,
    });
    await _db.ref('followers/$targetUid/$current').set({
      'ts': ServerValue.timestamp,
    });

    debugPrint('[SocialGraph] follow $current → $targetUid (mutual=$mutual)');
  }

  /// إلغاء المتابعة: يزيل حافة A→B ويُسقِط علَم الصداقة من الحافة B→A إن وُجدت.
  static Future<void> unfollowUser(String targetUid) async {
    final current = FirebaseAuth.instance.currentUser?.uid;
    if (current == null || targetUid.isEmpty) return;

    final reverseSnap = await _followingDoc(targetUid, current).get();

    final batch = _fs.batch();
    batch.delete(_followingDoc(current, targetUid));
    batch.delete(_followersDoc(targetUid, current));

    if (reverseSnap.exists) {
      batch.update(_followingDoc(targetUid, current), {'is_friend': false});
      batch.update(_followersDoc(current, targetUid), {'is_friend': false});
    }

    await batch.commit();

    await _db.ref('follows/$current/$targetUid').remove();
    await _db.ref('followers/$targetUid/$current').remove();

    debugPrint('[SocialGraph] unfollow $current ✕ $targetUid');
  }
}

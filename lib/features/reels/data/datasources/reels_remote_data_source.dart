import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/core/firebase/shared_firebase_collections.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/models/video_model.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/reels_algorithm.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/reels_hashtag_utils.dart';

/// مصدر بيانات ريلز Firestore — استعلامات الخوارزمية ومزامنة حقول [score] و [engagement_count].
class ReelsRemoteDataSource {
  static const String fieldAppSource = 'app_source';
  static const String fieldScore = 'score';
  static const String fieldTimestamp = 'timestamp';
  static const String fieldEngagementCount = 'engagement_count';

  final FirebaseFirestore _firestore;

  ReelsRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(SharedFirebaseCollections.reels);

  /// جلب مستند ريل واحد بالمعرّف — للدخول المباشر من إشعار أو رابط.
  Future<DocumentSnapshot<Map<String, dynamic>>?> fetchReelDocById(
      String reelId) async {
    if (reelId.isEmpty) return null;
    try {
      final doc = await _collection.doc(reelId).get();
      return doc.exists ? doc : null;
    } catch (e) {
      debugPrint('ReelsRemoteDataSource.fetchReelDocById: $e');
      return null;
    }
  }

  /// ريلز مستخدم واحد (ترتيب زمني) — للتصفّح داخل بروفايل كامل في شاشة الريلز.
  /// يتطلّب فهرساً مركّباً: `userId` + `timestamp` (+ `app_source` في الوضع المحلي).
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchReelsByUserId({
    required String userId,
    required bool isGlobal,
    int limit = 30,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    if (userId.isEmpty) return [];
    try {
      Query<Map<String, dynamic>> q =
          _collection.where('userId', isEqualTo: userId);
      if (!isGlobal) {
        q = q.where(fieldAppSource, isEqualTo: AppConfig.reelsFirestoreClubTag);
      }
      q = q.orderBy(fieldTimestamp, descending: true).limit(limit);
      if (startAfter != null) {
        q = q.startAfterDocument(startAfter);
      }
      final snap = await q.get();
      return snap.docs;
    } catch (e) {
      debugPrint('ReelsRemoteDataSource.fetchReelsByUserId: $e');
      return [];
    }
  }

  /// تصفية ريلز تحتوي الهاشتاج في مصفوفة [hashtags] (Firestore).
  /// يتطلّب فهرساً مركّباً: `hashtags` + `app_source` + `timestamp` عند استخدام فلتر النادي.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchReelsByHashtag({
    required String rawTag,
    required bool isGlobal,
    int limit = 50,
  }) async {
    final tag = ReelsHashtagUtils.normalizeTag(rawTag);
    if (tag.isEmpty) return [];
    try {
      Query<Map<String, dynamic>> q =
          _collection.where('hashtags', arrayContains: tag);
      if (!isGlobal) {
        q = q.where(fieldAppSource, isEqualTo: AppConfig.reelsFirestoreClubTag);
      }
      q = q.orderBy(fieldTimestamp, descending: true).limit(limit);
      final snap = await q.get();
      return snap.docs;
    } catch (e) {
      debugPrint('ReelsRemoteDataSource.fetchReelsByHashtag: $e');
      return [];
    }
  }

  /// زيادة [watch_count] الذرّية — مشاهدة مؤهّلة (مثلاً ≥70% من المدة).
  Future<void> incrementWatchCount(String reelId) async {
    try {
      await _collection.doc(reelId).set(
        {'watch_count': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('ReelsRemoteDataSource.incrementWatchCount err: $e');
    }
  }

  /// أفضل [limit] ريل حسب score تنازلياً ثم الأحدث.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchTopReels({
    required bool isGlobal,
    int limit = 50,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> q = _collection;
    if (!isGlobal) {
      q = q.where(fieldAppSource, isEqualTo: AppConfig.reelsFirestoreClubTag);
    }
    q = q
        .orderBy(fieldScore, descending: true)
        .orderBy(fieldTimestamp, descending: true)
        .limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snapshot = await q.get();
    return snapshot.docs;
  }

  /// إنشاء/دمج مستند كامل بعد الرفع.
  Future<void> upsertFullReelDoc(
    VideoModel model, {
    Map<String, dynamic>? extraFields,
  }) async {
    final tags = ReelsHashtagUtils.extractTags(model.caption);
    final score = ReelsAlgorithm.computeRankingScore(
      likes: model.likesCount,
      comments: model.commentsCount,
      views: model.viewsCount,
      watchCount: model.watchCount,
      uploadedAt: model.timestamp,
    );
    final engagement = ReelsAlgorithm.computeEngagementCount(
      likes: model.likesCount,
      comments: model.commentsCount,
      views: model.viewsCount,
      watchCount: model.watchCount,
    );
    final club = model.appSource.isNotEmpty
        ? model.appSource
        : AppConfig.reelsFirestoreClubTag;

    await _collection.doc(model.id).set({
      ...model.toFirestoreFlatMap(),
      'hashtags': tags,
      'watch_count': model.watchCount,
      // يُستخدم لتجميع صفحة الصوت (نفس القيمة مع videoUrl للصوت الأصلي).
      'audioUrl': model.audioUrl.isNotEmpty ? model.audioUrl : model.videoUrl,
      fieldAppSource: club,
      fieldScore: score,
      fieldEngagementCount: engagement,
      fieldTimestamp: model.timestamp.millisecondsSinceEpoch,
      if (extraFields != null) ...extraFields,
    }, SetOptions(merge: true));
  }

  /// زيادة ذرّية لـ [engagement_count] — آمنة مع تفاعل متزامن من عدة مستخدمين.
  Future<void> incrementEngagementCount(String reelId, {required int delta}) async {
    if (delta == 0) return;
    try {
      await _collection.doc(reelId).set(
        {fieldEngagementCount: FieldValue.increment(delta)},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('ReelsRemoteDataSource.incrementEngagementCount err: $e');
    }
  }

  /// تحديث score والعدادات الأساسية بعد تفاعل — بدون الكتابة المباشرة على [engagement_count]
  /// (يُحدَّث ذلك عبر [incrementEngagementCount] بـ `FieldValue.increment`).
  Future<void> updateRankingOnly(VideoModel model) async {
    final score = ReelsAlgorithm.computeRankingScore(
      likes: model.likesCount,
      comments: model.commentsCount,
      views: model.viewsCount,
      watchCount: model.watchCount,
      uploadedAt: model.timestamp,
    );

    try {
      await _collection.doc(model.id).set(
        {
          fieldScore: score,
          'likesCount': model.likesCount,
          'commentsCount': model.commentsCount,
          'viewsCount': model.viewsCount,
          'watch_count': model.watchCount,
          fieldAppSource: model.appSource.isNotEmpty
              ? model.appSource
              : AppConfig.reelsFirestoreClubTag,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('ReelsRemoteDataSource.updateRankingOnly err: $e');
    }
  }

  /// ريلز بنفس المقطع الصوتي — يدمج استعلامي `audioUrl` و`videoUrl` لدعم المستندات القديمة.
  /// الترتيب حسب `score` ثم الأحدث (يُكمَّل في الواجهة عبر [VideoModel.score] إن لزم).
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchReelsByAudioUrl({
    required String audioUrl,
    required bool isGlobal,
    int perQueryLimit = 60,
  }) async {
    if (audioUrl.isEmpty) return [];
    final merged = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    Future<void> collect(Query<Map<String, dynamic>> raw) async {
      try {
        Query<Map<String, dynamic>> q = raw;
        if (!isGlobal) {
          q = q.where(fieldAppSource, isEqualTo: AppConfig.reelsFirestoreClubTag);
        }
        final snap = await q.limit(perQueryLimit).get();
        for (final d in snap.docs) {
          merged.putIfAbsent(d.id, () => d);
        }
      } catch (e) {
        debugPrint('ReelsRemoteDataSource.fetchReelsByAudioUrl: $e');
      }
    }

    await collect(_collection.where('audioUrl', isEqualTo: audioUrl));
    await collect(_collection.where('videoUrl', isEqualTo: audioUrl));

    final list = merged.values.toList();
    list.sort((a, b) {
      num scoreOf(QueryDocumentSnapshot<Map<String, dynamic>> d) {
        final m = d.data();
        final ts = (m[fieldTimestamp] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch;
        final uploaded = DateTime.fromMillisecondsSinceEpoch(ts);
        return ReelsAlgorithm.computeRankingScore(
          likes: (m['likesCount'] as num?)?.toInt() ?? 0,
          comments: (m['commentsCount'] as num?)?.toInt() ?? 0,
          views: (m['viewsCount'] as num?)?.toInt() ?? 0,
          watchCount: (m['watch_count'] as num?)?.toInt() ?? 0,
          uploadedAt: uploaded,
        );
      }

      final cmp = scoreOf(b).compareTo(scoreOf(a));
      if (cmp != 0) return cmp;
      final ta = (a.data()[fieldTimestamp] as num?)?.toInt() ?? 0;
      final tb = (b.data()[fieldTimestamp] as num?)?.toInt() ?? 0;
      return tb.compareTo(ta);
    });
    return list;
  }
}

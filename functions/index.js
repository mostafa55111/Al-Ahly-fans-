/**
 * Cloud Functions — إشعارات الجمهور (FCM + مركز الإشعارات في Firestore).
 *
 * النشر:
 *   cd functions && npm install
 *   firebase deploy --only functions:sendReelInteractionNotification,functions:onReelWatchTrend
 *
 * يتطلب خطة Blaze لتشغيل محفّزات Firestore.
 */
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const crowdAuthority = require('./crowd_authority');
exports.finalizeVotingSession = crowdAuthority.finalizeVotingSession;
exports.aggregateShardedVotes = crowdAuthority.aggregateShardedVotes;
exports.publishAwardsSnapshot = crowdAuthority.publishAwardsSnapshot;

const db = admin.firestore();

/**
 * كتابة الإشعار في `users/{uid}/notifications` وإرسال FCM إن وُجد توكن.
 * @param {object} p
 */
async function deliverUserNotification(p) {
  const {
    targetUserId,
    title,
    body,
    type,
    videoId,
    actorUid,
    actorName,
    actorAvatarUrl,
  } = p;

  const userRef = db.collection('users').doc(targetUserId);
  const userSnap = await userRef.get();
  const token = userSnap.exists ? userSnap.get('fcmToken') : null;

  const notifCol = userRef.collection('notifications');
  await notifCol.add({
    title: title || 'إشعار',
    body,
    actorUid: actorUid || '',
    actorName: actorName || '',
    actorAvatarUrl: actorAvatarUrl || '',
    type: type || 'like',
    videoId: videoId || '',
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await userRef.set(
    {
      notificationsUnreadCount: admin.firestore.FieldValue.increment(1),
    },
    { merge: true },
  );

  if (token && typeof token === 'string' && token.length > 0) {
    try {
      await admin.messaging().send({
        token,
        notification: {
          title: title || 'إشعار',
          body,
        },
        data: {
          type: String(type || ''),
          videoId: String(videoId || ''),
          actorUid: String(actorUid || ''),
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'reels_interactions_v1',
            color: '#C7102E',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      });
    } catch (e) {
      console.error('FCM send error', e);
    }
  }

  return { ok: true };
}

/** Callable — إعجاب / تعليق / متابعة (videoId اختياري لنوع follow). */
exports.sendReelInteractionNotification = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'يجب تسجيل الدخول لإرسال الإشعار.',
      );
    }

    const {
      targetUserId,
      title,
      body,
      actorUid,
      actorName,
      actorAvatarUrl,
      type,
      videoId,
    } = data || {};

    const t = String(type || 'like');
    const vid = String(videoId || '').trim();

    if (!targetUserId || !actorUid || !body) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'بيانات الإشعار غير مكتملة.',
      );
    }

    if (actorUid !== context.auth.uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'معرّف المرسل غير مطابق للمستخدم الحالي.',
      );
    }

    if (targetUserId === actorUid) {
      return { skipped: true, reason: 'self' };
    }

    if (t !== 'follow' && t !== 'trending' && !vid) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'معرّف الفيديو مطلوب لهذا النوع من الإشعارات.',
      );
    }

    await deliverUserNotification({
      targetUserId,
      title,
      body,
      type: t,
      videoId: vid,
      actorUid,
      actorName,
      actorAvatarUrl,
    });

    return { ok: true };
  },
);

/**
 * عند تجاوز حدود مشاهدات مؤهّلة (كل 100 watch_count) نُشعر صاحب الريل.
 * يعتمد على حقل [watch_count] في مستند `reels/{reelId}`.
 */
exports.onReelWatchTrend = functions.firestore
  .document('reels/{reelId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    const reelId = context.params.reelId;

    const wa = Number(after.watch_count || 0);
    const wb = Number(before.watch_count || 0);
    const step = 100;

    const newTier = Math.floor(wa / step);
    const oldTier = Math.floor(wb / step);

    if (newTier < 1 || newTier <= oldTier) {
      return null;
    }

    const last = Number(after.watchTrendLastTier || 0);
    if (newTier <= last) {
      return null;
    }

    const ownerId = String(after.userId || '').trim();
    if (!ownerId) {
      return null;
    }

    const title = 'ترند الريلز 🚀';
    const body =
      newTier === 1
        ? 'فيديو الخاص بك بدأ في الانتشار! 🚀'
        : `فيديوك يحقق انتشاراً قوياً — أكثر من ${newTier * step} مشاهدة مؤهّلة 🔥`;

    try {
      await deliverUserNotification({
        targetUserId: ownerId,
        title,
        body,
        type: 'trending',
        videoId: reelId,
        actorUid: '',
        actorName: '',
        actorAvatarUrl: '',
      });

      await change.after.ref.set(
        { watchTrendLastTier: newTier },
        { merge: true },
      );
    } catch (e) {
      console.error('onReelWatchTrend error', e);
    }

    return null;
  });

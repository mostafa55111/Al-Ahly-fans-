import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// دردشة موحّدة للأصدقاء المتبادلين عبر `shared_chats` في Firestore (يعمل للتطبيقين).
///
/// [pairChatId] يُبنى من UID للطرفين **مرتّبين أبجدياً** ومفصولين بـ `__` (لا يظهر في UIDs).
class SharedFriendChatService {
  SharedFriendChatService._();

  static final FirebaseFirestore _fs = FirebaseFirestore.instance;

  static const String collection = 'shared_chats';

  /// معرّف محادثة ثابت بين مستخدمين.
  static String pairChatId(String uidA, String uidB) {
    final a = uidA.trim();
    final b = uidB.trim();
    if (a.isEmpty || b.isEmpty || a == b) {
      throw ArgumentError('أزواج UID غير صالحة للمحادثة');
    }
    final u = [a, b]..sort();
    return '${u[0]}__${u[1]}';
  }

  static DocumentReference<Map<String, dynamic>> chatRef(String chatId) =>
      _fs.collection(collection).doc(chatId);

  /// تأكيد وجود مستند المحادثة مع المشاركين (للقواعد والدوال السحابية).
  static Future<void> ensureChatRoom({
    required String myUid,
    required String peerUid,
  }) async {
    final id = pairChatId(myUid, peerUid);
    await chatRef(id).set(
      <String, dynamic>{
        'participantUids': [myUid, peerUid]..sort(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// هل المستخدم [viewerUid] صديق متبادل مع [peerUid]؟
  static Future<bool> isMutualFriend({
    required String viewerUid,
    required String peerUid,
  }) async {
    if (viewerUid.isEmpty || peerUid.isEmpty || viewerUid == peerUid) {
      return false;
    }
    try {
      final snap = await _fs
          .collection('social_graph')
          .doc(viewerUid)
          .collection('following')
          .doc(peerUid)
          .get();
      return snap.data()?['is_friend'] == true;
    } catch (e) {
      debugPrint('[Chat] isMutualFriend: $e');
      return false;
    }
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> mutualFriendEdgeStream({
    required String viewerUid,
    required String peerUid,
  }) {
    return _fs
        .collection('social_graph')
        .doc(viewerUid)
        .collection('following')
        .doc(peerUid)
        .snapshots();
  }

  /// تدفق رسائل مرتبة زمنياً (الأحدث في الأسفل داخل الواجهة).
  static Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(
    String chatId, {
    int limit = 80,
  }) {
    return chatRef(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  static Future<void> sendTextMessage({
    required String peerUid,
    required String text,
  }) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final ok = await isMutualFriend(viewerUid: me, peerUid: peerUid);
    if (!ok) {
      throw StateError('لا يمكن إرسال رسالة إلا للصديق المتبادل');
    }
    final id = pairChatId(me, peerUid);
    final chat = chatRef(id);
    final msg = chat.collection('messages').doc();
    final batch = _fs.batch();
    batch.set(
      chat,
      {
        'participantUids': [me, peerUid]..sort(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastPreview':
            trimmed.length > 80 ? '${trimmed.substring(0, 80)}…' : trimmed,
      },
      SetOptions(merge: true),
    );
    batch.set(msg, {
      'senderUid': me,
      'text': trimmed,
      'imageUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  static Future<void> sendImageMessage({
    required String peerUid,
    required String imageUrl,
    String caption = '',
  }) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null) return;
    final url = imageUrl.trim();
    if (url.isEmpty) return;
    final ok = await isMutualFriend(viewerUid: me, peerUid: peerUid);
    if (!ok) {
      throw StateError('لا يمكن إرسال رسالة إلا للصديق المتبادل');
    }
    final id = pairChatId(me, peerUid);
    final chat = chatRef(id);
    final msg = chat.collection('messages').doc();
    final batch = _fs.batch();
    batch.set(
      chat,
      {
        'participantUids': [me, peerUid]..sort(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastPreview': '📷 صورة',
      },
      SetOptions(merge: true),
    );
    batch.set(msg, {
      'senderUid': me,
      'text': caption.trim(),
      'imageUrl': url,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}

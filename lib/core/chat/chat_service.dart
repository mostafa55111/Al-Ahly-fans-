import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/chat/chat_compute.dart';
import 'package:gomhor_alahly_clean_new/core/chat/chat_message_vm.dart';
import 'package:gomhor_alahly_clean_new/core/services/shared_friend_chat_service.dart';

/// نواة محرّك الدردشة — تدفّق رسائل مع تعيين [compute] لتخفيف أعمال الخيط الرئيسي.
///
/// لا يُخزَّن هنا أي [StreamSubscription]. عند استخدام [watchSharedChatMessages]
/// مع [Stream.listen] يجب استدعاء [StreamSubscription.cancel] في [State.dispose]
/// (يُستحسن عبر Widget مخصّص كـ `_SharedChatMessagesList`).
///
/// التحديثات تُعالَج **عند وصول لقطة جديدة فقط** (سلوك كسول بالنسبة لمعالجة البيانات).
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  /// بث رسائل غرفة `shared_chats` بعد تحويلها إلى [ChatMessageVm].
  Stream<List<ChatMessageVm>> watchSharedChatMessages(
    String chatId, {
    int limit = 80,
  }) {
    return SharedFriendChatService.messagesStream(chatId, limit: limit)
        .asyncMap(_snapshotToViewModels);
  }

  static Future<List<ChatMessageVm>> _snapshotToViewModels(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    if (snap.docs.isEmpty) return const [];

    final payload = snap.docs.map((d) {
      final m = Map<String, dynamic>.from(d.data());
      m['_id'] = d.id;
      return m;
    }).toList(growable: false);

    if (kIsWeb) {
      return deserializeChatDocuments(payload);
    }
    return compute(deserializeChatDocuments, payload);
  }
}

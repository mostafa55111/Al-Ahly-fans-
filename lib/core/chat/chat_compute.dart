import 'package:gomhor_alahly_clean_new/core/chat/chat_message_vm.dart';

/// دالة **top-level** لاستدعائها عبر [compute] فقط — لا تضف اعتماديات على Flutter هنا.
///
/// ترتيب الإدخال: كما عاد من Firestore [orderBy createdAt descending] (الأحدث أولاً).
/// المخرجات: من الأقدم للأحدث لعمود [ListView] طبيعي.
List<ChatMessageVm> deserializeChatDocuments(List<Map<String, dynamic>> payload) {
  final out = <ChatMessageVm>[];
  for (var i = payload.length - 1; i >= 0; i--) {
    final m = payload[i];
    out.add(
      ChatMessageVm(
        id: (m['_id'] ?? '').toString(),
        senderUid: (m['senderUid'] ?? '').toString(),
        text: (m['text'] ?? '').toString(),
        imageUrl: m['imageUrl']?.toString(),
      ),
    );
  }
  return out;
}

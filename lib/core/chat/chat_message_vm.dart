/// نموذج عرض رسالة بعد المعالجة خارج الخيط الرئيسي (اختياري) — للدردشة الموحّدة.
class ChatMessageVm {
  const ChatMessageVm({
    required this.id,
    required this.senderUid,
    required this.text,
    this.imageUrl,
  });

  final String id;
  final String senderUid;
  final String text;
  final String? imageUrl;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/core/chat/chat_compute.dart';

void main() {
  // يغطي نفس منطق تحويل اللقطات في [ChatService._snapshotToViewModels] (ويب أو compute).
  group('deserializeChatDocuments (منطق ChatService / compute)', () {
    test('قائمة فارغة → []', () {
      expect(deserializeChatDocuments([]), isEmpty);
    });

    test('ترتيب العرض: من الأقدم للأحدث (عكس ترتيب Firestore desc)', () {
      final payload = [
        {'_id': '3', 'senderUid': 'a', 'text': 'newest'},
        {'_id': '2', 'senderUid': 'b', 'text': 'mid'},
        {'_id': '1', 'senderUid': 'c', 'text': 'oldest'},
      ];
      final out = deserializeChatDocuments(payload);
      expect(out.map((e) => e.id).toList(), ['1', '2', '3']);
      expect(out.first.text, 'oldest');
      expect(out.last.text, 'newest');
    });

    test('قيم ناقصة لا تُسقِط العنصر — حقول افتراضية كسلسلة فارغة', () {
      final payload = [
        {'_id': 'x'},
      ];
      final out = deserializeChatDocuments(payload);
      expect(out.single.id, 'x');
      expect(out.single.senderUid, '');
      expect(out.single.text, '');
      expect(out.single.imageUrl, isNull);
    });

    test('صورة اختيارية تُمرَّر كنص', () {
      final payload = [
        {'_id': '1', 'senderUid': 'u', 'text': 'hi', 'imageUrl': 'https://cdn/x.jpg'},
      ];
      expect(deserializeChatDocuments(payload).single.imageUrl, 'https://cdn/x.jpg');
    });
  });
}

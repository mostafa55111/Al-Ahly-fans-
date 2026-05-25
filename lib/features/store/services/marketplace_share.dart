import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// مشاركة رابط/نص ترويجي لصفحة تاجر داخل السوق.
Future<void> shareMerchantForPromotion({
  required String merchantName,
  required String merchantId,
  String slug = '',
}) async {
  final slugLine = slug.isNotEmpty ? 'الاسم المختصر للبحث: $slug\n' : '';
  final text = '''
🏪 $merchantName — سوق جمهور الأهلي

افتح التطبيق ← تبويب «المتجر» ← ابحث عن المتجر أو الصق معرّف الدعوة أدناه.

معرّف الدعوة (انسخه ومشاركته):
$merchantId
$slugLineشجّع أصدقاءك يفتحوا السوق ويدخلوا على متجرك من قائمة المتاجر أو البحث.
''';
  await Share.share(text.trim());
}

Future<void> copyMerchantInviteId(String merchantId) async {
  await Clipboard.setData(ClipboardData(text: merchantId));
}

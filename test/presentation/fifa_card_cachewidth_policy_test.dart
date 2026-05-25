import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// تثبيت سياسة الذاكرة: صور البطاقات الإدارية تُحمَّل بعرض كاش محدود.
void main() {
  test('FifaCardManagerTab يفرض cacheWidth: 250 لصور الشبكة', () {
    final path = '${Directory.current.path}/lib/features/admin/presentation/widgets/fifa_card_manager_tab.dart';
    final src = File(path).readAsStringSync();
    expect(src, contains('cacheWidth: 250'));
  });
}

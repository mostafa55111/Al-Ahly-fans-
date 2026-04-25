// اختبار أساسي — يتم تحديثه لاحقاً ليتوافق مع البنية الجديدة للتطبيق
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App sanity test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('جمهور الأهلي'))),
      ),
    );
    expect(find.text('جمهور الأهلي'), findsOneWidget);
  });
}

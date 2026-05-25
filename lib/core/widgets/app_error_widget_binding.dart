import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// يستبدل شاشة الخطأ الحمراء الافتراضية برسالة بسيطة — يشيّد «إطلاق النشاط» في اختبارات مثل Robo.
/// في وضع التطوير ما زال الخطأ يُطبَع في الكونسول.
void bindAppFriendlyErrorWidget() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
    return const _AppFriendlyErrorPlaceholder();
  };
}

class _AppFriendlyErrorPlaceholder extends StatelessWidget {
  const _AppFriendlyErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Color(0xFF0A0A0A),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'نادينا دائماً معك',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

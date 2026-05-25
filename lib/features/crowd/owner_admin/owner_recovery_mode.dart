import 'package:flutter/material.dart';

/// أسطح مقفلة عند فشل/انتهاء صلاحية المالك — التصويت العام غير متأثر.
class OwnerRecoveryMode {
  OwnerRecoveryMode._();

  static Widget lockedSurface(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المالك')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'هذه المنطقة للمالك فقط',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'سجّل الدخول بحساب المالك المصرّح أو أعد فتح التطبيق.\n'
                'تصويت الجمهور يعمل بشكل طبيعي.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showPublishInterrupted(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تعذّر النشر: $message'),
        action: SnackBarAction(
          label: 'حاول مجدداً',
          onPressed: () {},
        ),
      ),
    );
  }
}

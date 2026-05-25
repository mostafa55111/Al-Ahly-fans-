import 'package:flutter/material.dart';

import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';

/// تنبيهات المصادقة ورسائل التحقق (هاتف، OTP، أخطاء الخادم) بلون الهوية
/// (`colorScheme.primary`): أزرق للزمالك / أحمر للأهلي.
/// تصميم عائم بحواف دائرية وحد ذهبي خفيف.
void showBrandAuthErrorSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final scheme = Theme.of(context).colorScheme;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: scheme.primary,
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.luminousGold.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}

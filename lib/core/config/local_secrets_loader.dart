import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// تحميل `secrets.local.json` من جذر المشروع عند التشغيل على سطح المكتب (Windows/macOS/Linux).
/// على الهاتف استخدم: `flutter run --dart-define-from-file=secrets.local.json`
Future<Map<String, String>> loadLocalSecretsMap() async {
  final map = <String, String>{};
  if (kIsWeb) return map;
  try {
    if (Platform.isAndroid || Platform.isIOS) return map;
    final cwd = Directory.current.path;
    final file = File('$cwd${Platform.pathSeparator}secrets.local.json');
    if (!file.existsSync()) return map;
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is Map<String, dynamic>) {
      decoded.forEach((k, v) {
        if (v != null) map[k] = v.toString();
      });
    }
  } catch (e) {
    if (kDebugMode) debugPrint('secrets.local.json: $e');
  }
  return map;
}

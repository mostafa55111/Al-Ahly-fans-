import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// بصمة جهاز خفيفة — لا تتبع إعلاني.
class DeviceFingerprintHelper {
  DeviceFingerprintHelper(this._prefs);

  final SharedPreferences _prefs;
  static const _storageKey = 'crowd_device_fp_v1';

  String? _cached;

  Future<String> deviceKey() async {
    if (_cached != null) return _cached!;
    var id = _prefs.getString(_storageKey);
    if (id == null || id.isEmpty) {
      final seed =
          '${DateTime.now().microsecondsSinceEpoch}_${defaultTargetPlatform.name}';
      id = sha256.convert(utf8.encode(seed)).toString().substring(0, 24);
      await _prefs.setString(_storageKey, id);
    }
    _cached = id;
    return id;
  }
}

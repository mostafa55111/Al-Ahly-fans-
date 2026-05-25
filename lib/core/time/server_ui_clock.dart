import 'dart:async';

import 'package:flutter/foundation.dart';

/// نبضة UI واحدة للتطبيق — بدلاً من مؤقتات متعددة في كل widget.
class ServerUiClock extends ChangeNotifier {
  ServerUiClock._();

  static final ServerUiClock instance = ServerUiClock._();

  Timer? _timer;
  int _listeners = 0;

  void acquire() {
    _listeners++;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void release() {
    if (_listeners <= 0) return;
    _listeners--;
    if (_listeners == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

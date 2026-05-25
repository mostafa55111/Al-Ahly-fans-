/// يمنع فتح تيارات ثقيلة عند ضغط الذاكرة أو الخلفية.
class SocketPressureGuard {
  SocketPressureGuard._();

  static final SocketPressureGuard instance = SocketPressureGuard._();

  bool _backgrounded = false;
  bool _stadiumTabHidden = false;
  bool _runtimePressure = false;

  bool get shouldDeferHeavyStreams =>
      _backgrounded || _stadiumTabHidden || _runtimePressure;

  bool get isAppBackgrounded => _backgrounded;

  bool get runtimePressureHigh => _runtimePressure;

  void setAppBackgrounded(bool value) => _backgrounded = value;

  void setStadiumTabHidden(bool value) => _stadiumTabHidden = value;

  void setRuntimePressure({required bool high}) => _runtimePressure = high;

  void reset() {
    _backgrounded = false;
    _stadiumTabHidden = false;
    _runtimePressure = false;
  }
}

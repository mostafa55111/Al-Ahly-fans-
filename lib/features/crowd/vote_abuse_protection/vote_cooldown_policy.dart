/// تبريد قصير بعد صوت ناجح — لا يمنع إعادة الاتصال الشرعية.
class VoteCooldownPolicy {
  VoteCooldownPolicy({this.cooldownMs = 1500});

  final int cooldownMs;
  int? _lastConfirmedVoteMs;

  bool canCastNow(int serverNowMs) {
    final last = _lastConfirmedVoteMs;
    if (last == null) return true;
    return serverNowMs - last >= cooldownMs;
  }

  void markVoteConfirmed(int serverNowMs) {
    _lastConfirmedVoteMs = serverNowMs;
  }

  void reset() => _lastConfirmedVoteMs = null;
}

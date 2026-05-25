/// أولوية الكرت على الملعب لطبقة الأداء التكيفية.
enum CrowdCardRuntimeBand {
  /// المتصدر في التصويت.
  hero,

  /// اللاعب الذي صوّت له المستخدم الحالي.
  myPick,

  /// مرئي ضمن الفتحات ذات الأولوية العالية.
  standard,

  /// باقي اللاعبين — يُخفَّض الـ FX تحت الضغط.
  background,
}

CrowdCardRuntimeBand resolveCrowdCardRuntimeBand({
  required String playerId,
  required String? leadingPlayerId,
  required String? myVotedPlayerId,
  required int slotIndex,
  required int totalVotes,
}) {
  if (totalVotes > 0 && leadingPlayerId != null && leadingPlayerId == playerId) {
    return CrowdCardRuntimeBand.hero;
  }
  if (myVotedPlayerId != null && myVotedPlayerId.isNotEmpty && myVotedPlayerId == playerId) {
    return CrowdCardRuntimeBand.myPick;
  }
  if (slotIndex < 5) {
    return CrowdCardRuntimeBand.standard;
  }
  return CrowdCardRuntimeBand.background;
}

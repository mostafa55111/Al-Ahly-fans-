import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/models/match_vote_models.dart';

class CardIntegrityCheckResult {
  const CardIntegrityCheckResult({required this.ok, this.message});

  final bool ok;
  final String? message;
}

/// تحقق سلامة الكروت على الملعب قبل النشر.
class CardIntegrityValidator {
  const CardIntegrityValidator();

  CardIntegrityCheckResult validatePlayerCard(MatchPitchPlayer player) {
    final url = player.cardImageUrl.trim();
    final thumb = player.cardThumbnailUrl.trim();
    if (url.isEmpty && thumb.isEmpty) {
      return const CardIntegrityCheckResult(
        ok: false,
        message: 'لا صورة للكرت',
      );
    }
    final check = url.isNotEmpty ? url : thumb;
    if (_isAnimatedUnsupported(check)) {
      return const CardIntegrityCheckResult(
        ok: false,
        message: 'صيغة متحركة غير مدعومة',
      );
    }
    if (!_isHttpsOrEmpty(check)) {
      return const CardIntegrityCheckResult(
        ok: false,
        message: 'رابط غير آمن',
      );
    }
    return const CardIntegrityCheckResult(ok: true);
  }

  bool _isAnimatedUnsupported(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.gif') ||
        lower.contains('.gif?') ||
        lower.endsWith('.apng');
  }

  bool _isHttpsOrEmpty(String url) {
    if (url.isEmpty) return true;
    return url.startsWith('https://') || url.startsWith('http://');
  }
}

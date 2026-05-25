/// مسارات جوائز الإنتاج — معزولة لكل نادٍ.
///
/// ```
/// awards/{ahly|zamalek}/matches/{year}/{matchId}
/// awards/{ahly|zamalek}/monthly/{yyyy-MM}
/// awards/{ahly|zamalek}/season/{yyyy}
/// player_awards/{ahly|zamalek}/{playerId}
/// ```
class AwardsRtdbPaths {
  AwardsRtdbPaths._();

  static String _club(String clubTag) => clubTag.trim().toLowerCase();

  static String clubRoot(String clubTag) => 'awards/${_club(clubTag)}';

  static String matchesYear(String clubTag, int year) =>
      '${clubRoot(clubTag)}/matches/$year';

  static String matchAward(String clubTag, int year, String matchId) =>
      '${matchesYear(clubTag, year)}/$matchId';

  static String monthly(String clubTag, String yyyyMm) =>
      '${clubRoot(clubTag)}/monthly/$yyyyMm';

  static String season(String clubTag, String yyyy) =>
      '${clubRoot(clubTag)}/season/$yyyy';

  static String playerAwardsRoot(String clubTag) =>
      'player_awards/${_club(clubTag)}';

  static String playerAward(String clubTag, String playerId) =>
      '${playerAwardsRoot(clubTag)}/$playerId';
}

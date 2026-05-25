/// مسار خفيف لمكتبة الكروت — منفصل عن `match_votes` و`zamalek_squad`.
///
/// ```
/// cards/{club}/{cardId}/
///   imageUrl, thumbUrl, playerName, rarity, tags, createdAt
/// ```
class StadiumCardRegistryPaths {
  StadiumCardRegistryPaths._();

  static String root(String clubTag) => 'cards/${clubTag.trim().toLowerCase()}';

  static String card(String clubTag, String cardId) => '${root(clubTag)}/$cardId';
}

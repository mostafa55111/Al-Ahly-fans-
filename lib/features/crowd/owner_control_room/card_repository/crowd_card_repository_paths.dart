/// مسارات مستودع الكروت — معزولة لكل تطبيق.
///
/// ```
/// crowd_card_repository/{appId}/cards/{cardId}/
/// ```
class CrowdCardRepositoryPaths {
  CrowdCardRepositoryPaths._();

  static String root(String appId) =>
      'crowd_card_repository/${appId.trim().toLowerCase()}';

  static String cardsRoot(String appId) => '${root(appId)}/cards';

  static String card(String appId, String cardId) =>
      '${cardsRoot(appId)}/$cardId';
}

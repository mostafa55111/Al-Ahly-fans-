abstract final class OwnerMatchTemplatePaths {
  static String root(String club) => 'owner_match_templates/$club';

  static String template(String club, String templateId) =>
      '${root(club)}/$templateId';
}

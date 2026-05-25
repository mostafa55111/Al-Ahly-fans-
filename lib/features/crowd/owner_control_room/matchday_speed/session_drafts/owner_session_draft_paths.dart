abstract final class OwnerSessionDraftPaths {
  static String root(String club) => 'owner_session_drafts/$club';

  static String draft(String club, String draftId) => '${root(club)}/$draftId';
}

/// إعدادات OAuth المشتركة مع Firebase (مشروع gomhor-al-ahly).
///
/// [firebaseAuthWebClientId] من `google-services.json` (عميل Web، client_type: 3).
/// تمريره لـ [GoogleSignIn.serverClientId] مطلوب لدمج Google مع Firebase Auth.
class FirebaseOAuthConfig {
  FirebaseOAuthConfig._();

  static const String firebaseAuthWebClientId =
      '725028676186-537o4tmeomhro655q8e6tdm6gmiod17o.apps.googleusercontent.com';
}

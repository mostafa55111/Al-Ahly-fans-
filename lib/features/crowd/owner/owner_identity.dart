/// هوية المالك الوحيد — قائمة بريد من RTDB / Remote Config.
class OwnerIdentity {
  const OwnerIdentity({this.whitelistedEmails = const {}});

  final Set<String> whitelistedEmails;

  bool isOwnerEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    final normalized = email.trim().toLowerCase();
    return whitelistedEmails.contains(normalized);
  }

  OwnerIdentity mergeEmails(Iterable<String> emails) {
    final merged = {...whitelistedEmails};
    for (final e in emails) {
      final n = e.trim().toLowerCase();
      if (n.isNotEmpty) merged.add(n);
    }
    return OwnerIdentity(whitelistedEmails: merged);
  }
}

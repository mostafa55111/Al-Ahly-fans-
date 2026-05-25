import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner/owner_identity.dart';

void main() {
  test('owner email whitelist', () {
    const identity = OwnerIdentity(
      whitelistedEmails: {'owner@test.com'},
    );
    expect(identity.isOwnerEmail('owner@test.com'), isTrue);
    expect(identity.isOwnerEmail('OWNER@test.com'), isTrue);
    expect(identity.isOwnerEmail('fan@test.com'), isFalse);
  });

  test('mergeEmails adds normalized entries', () {
    const base = OwnerIdentity(whitelistedEmails: {'a@x.com'});
    final merged = base.mergeEmails(['B@y.com', '']);
    expect(merged.isOwnerEmail('b@y.com'), isTrue);
    expect(merged.isOwnerEmail('a@x.com'), isTrue);
  });
}

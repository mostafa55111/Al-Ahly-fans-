import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/services/user_initial_app_guard.dart';
import 'package:gomhor_alahly_clean_new/features/auth/domain/exceptions/fan_app_registry_exception.dart';

/// مستخدم وهمي — [User] كامل عبر [noSuchMethod] لتجاهل باقي الواجهة.
class FakeGuardUser implements User {
  FakeGuardUser({required this.uid, this.email});

  @override
  final String uid;

  @override
  final String? email;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('FakeGuardUser: ${invocation.memberName}');
  }
}

void main() {
  group('UserInitialAppGuard', () {
    late FakeFirebaseFirestore firestore;
    late UserInitialAppGuard guard;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      guard = UserInitialAppGuard(firestore);
    });

    test('سوبر أدمن: لا كتابة لـ Firestore وليس تسجيل خروج', () async {
      final user = FakeGuardUser(
        uid: 'admin_uid',
        email: FanAppIdentity.crossAppSuperAdminEmail,
      );

      var signOuts = 0;
      await guard.ensureMatchingOrSignOut(
        user: user,
        performSignOut: () async => signOuts++,
      );

      expect(signOuts, 0);
      final snap = await firestore.collection('users').doc('admin_uid').get();
      expect(snap.exists, isFalse);
    });

    test('مستخدم جديد: يضبط initial_app على تطبيق البناء الحالي', () async {
      final user = FakeGuardUser(uid: 'new_uid', email: 'fan@example.com');

      await guard.ensureMatchingOrSignOut(
        user: user,
        performSignOut: () async {},
      );

      final data = (await firestore.collection('users').doc('new_uid').get())
          .data();
      expect(data, isNotNull);
      expect(data![UserInitialAppGuard.firestoreField], FanAppIdentity.registryAppId);
    });

    test('initial_app مطابق: لا تعارض', () async {
      await firestore.collection('users').doc('u1').set({
        UserInitialAppGuard.firestoreField: FanAppIdentity.registryAppId,
      });
      final user = FakeGuardUser(uid: 'u1', email: 'fan@example.com');

      var signOuts = 0;
      await guard.ensureMatchingOrSignOut(
        user: user,
        performSignOut: () async => signOuts++,
      );
      expect(signOuts, 0);
    });

    test('تعارض initial_app: استدعاء تسجيل الخروج ثم FanAppRegistryException', () async {
      final conflicting =
          FanAppIdentity.registryAppId == 'ahly' ? 'zamalek' : 'ahly';
      await firestore.collection('users').doc('u2').set({
        UserInitialAppGuard.firestoreField: conflicting,
      });
      final user = FakeGuardUser(
        uid: 'u2',
        email: 'zamalekawy.fan@example.com',
      );

      var signOuts = 0;
      await expectLater(
        guard.ensureMatchingOrSignOut(
          user: user,
          performSignOut: () async => signOuts++,
        ),
        throwsA(isA<FanAppRegistryException>()),
      );
      expect(signOuts, 1);
    });
  });
}

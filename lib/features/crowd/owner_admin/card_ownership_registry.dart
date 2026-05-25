import 'package:firebase_auth/firebase_auth.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_entry.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/crowd_environment_resolver.dart';

/// بيانات ملكية الكرت عند الرفع.
class CardOwnershipRegistry {
  CardOwnershipRegistry({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  StadiumCardRegistryEntry stamp(StadiumCardRegistryEntry entry, String clubTag) {
    final env = CrowdEnvironmentResolver.isBootstrapped
        ? CrowdEnvironmentResolver.current.environment.name
        : 'development';
    return entry.copyWith(
      uploadedBy: _auth.currentUser?.email ?? '',
      clubScope: clubTag,
      sourceEnvironment: env,
      club: clubTag,
    );
  }
}

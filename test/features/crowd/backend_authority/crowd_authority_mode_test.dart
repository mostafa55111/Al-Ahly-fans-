import 'package:flutter_test/flutter_test.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_execution_mode.dart';

void main() {
  test('CrowdAuthorityMode parses remote and hybrid', () {
    expect(CrowdAuthorityModeX.fromWire('remote'), CrowdAuthorityMode.remote);
    expect(
      CrowdAuthorityModeX.fromWire('hybrid_shadow'),
      CrowdAuthorityMode.hybridShadow,
    );
    expect(CrowdAuthorityModeX.fromWire(null), CrowdAuthorityMode.local);
  });

  test('maps to execution mode', () {
    expect(
      CrowdAuthorityMode.remote.toExecutionMode(),
      AuthorityExecutionMode.remoteCloud,
    );
    expect(
      CrowdAuthorityMode.hybridShadow.toExecutionMode(),
      AuthorityExecutionMode.hybridShadow,
    );
  });
}

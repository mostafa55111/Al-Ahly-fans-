import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/cold_start_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/rehearsal_surface_gate.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/release_build_audit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/product_rehearsal/soft_launch_gate.dart';

/// تهيئة بروفة الإنتاج — Phase G (debug/staging).
class ProductRehearsalBootstrap {
  ProductRehearsalBootstrap._();

  static Future<void> runDressRehearsalChecks() async {
    if (!RehearsalSurfaceGate.allowDressRehearsal) return;

    final sw = Stopwatch()..start();
    ReleaseBuildAudit.instance.run();
    ColdStartAudit.instance.record('rehearsal_bootstrap', sw.elapsedMilliseconds);

    final gate = await SoftLaunchGate.instance.evaluateWithRehearsal(
      runSimulations: true,
    );

    debugPrint(
      '[ProductRehearsal] dress rehearsal decision=${gate.decision.name} '
      'blockers=${gate.blockers.length}',
    );
  }
}

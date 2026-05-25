import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/environment/crowd_environment_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/release/release_channel_resolver.dart';

/// غلاف التطبيق — بدون شريط ENV علوي للمستخدمين.
///
/// منطق البيئة والتشخيص يبقى عبر [CrowdEnvironmentResolver]؛ العرض العام مُزال.
class StagingEnvironmentBanner extends StatelessWidget {
  const StagingEnvironmentBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        const Positioned(
          right: 6,
          bottom: 6,
          child: _CrowdEnvDebugChip(),
        ),
      ],
    );
  }
}

/// شارة تشخيص صغيرة — debug فقط، لا تؤثر على SafeArea.
class _CrowdEnvDebugChip extends StatelessWidget {
  const _CrowdEnvDebugChip();

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    if (!CrowdEnvironmentResolver.isBootstrapped) {
      return const SizedBox.shrink();
    }
    final env = CrowdEnvironmentResolver.current;
    if (env.isProductionData) return const SizedBox.shrink();

    final channel = ReleaseChannelResolver.isBootstrapped
        ? ReleaseChannelResolver.current.wireName
        : '?';

    return IgnorePointer(
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            '${env.environment.name}/$channel',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

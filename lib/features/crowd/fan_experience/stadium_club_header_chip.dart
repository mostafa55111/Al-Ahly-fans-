import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_broadcast_layout.dart';

/// شارة النادي أعلى اليسار — ALAHLY / ZAMALEK (كود، ليس مدمجاً في صورة الملعب).
class StadiumClubHeaderChip extends StatelessWidget {
  const StadiumClubHeaderChip({super.key, this.identity});

  final CrowdAppIdentity? identity;

  @override
  Widget build(BuildContext context) {
    if (!StadiumBroadcastLayout.enabled) return const SizedBox.shrink();

    final id = identity ?? CrowdAppIdentity.current;
    final isAhly = FanAppIdentity.registryAppId == 'ahly';
    final label = isAhly ? 'ALAHLY' : 'ZAMALEK';
    final logo = isAhly
        ? 'assets/images/ahly_logo.png'
        : 'assets/images/zamalek_logo.png';

    return Positioned(
      top: MediaQuery.paddingOf(context).top + StadiumBroadcastLayout.headerTopPad,
      left: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.92),
                  Colors.white.withValues(alpha: 0.78),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: id.primaryColor.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isAhly ? Colors.black : id.primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 10),
                Image.asset(
                  logo,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.shield,
                    color: id.primaryColor,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

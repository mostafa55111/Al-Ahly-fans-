import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';

/// يظهر أعلى الشاشة عند انقطاع الشبكة أثناء الترحال.
class TravelConnectivityBanner extends StatelessWidget {
  const TravelConnectivityBanner({
    super.key,
    required this.child,
  });

  final Widget child;

  bool _isOffline(dynamic result) {
    if (result is List<ConnectivityResult>) {
      return result.isEmpty ||
          result.every((r) => r == ConnectivityResult.none);
    }
    if (result is ConnectivityResult) {
      return result == ConnectivityResult.none;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final offline = snapshot.hasData && _isOffline(snapshot.data);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 240),
              crossFadeState: offline
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Material(
                color: AppColors.warning.withValues(alpha: 0.92),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: AppColors.deepBlack, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'جاري محاولة إعادة الاتصال…',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.deepBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              secondChild: const SizedBox(width: double.infinity, height: 0),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

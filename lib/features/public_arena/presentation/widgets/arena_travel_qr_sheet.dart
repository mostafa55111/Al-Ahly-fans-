import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gomhor_alahly_clean_new/features/public_arena/domain/arena_trip_qr_payload.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/pages/travel_trip_chat_page.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/custom_button.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// مسح QR خاص بساحة الجمهور — يفتح [TripChatRoom] حسب مرحلة الرحلة (بداية / نهاية).
Future<void> showArenaTravelQrScanner(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return const _ArenaQrScannerSheet();
    },
  );
}

class _ArenaQrScannerSheet extends StatefulWidget {
  const _ArenaQrScannerSheet();

  @override
  State<_ArenaQrScannerSheet> createState() => _ArenaQrScannerSheetState();
}

class _ArenaQrScannerSheetState extends State<_ArenaQrScannerSheet> {
  final MobileScannerController _cam = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _cam.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture cap) {
    if (_handled) return;
    final raw = cap.barcodes.isNotEmpty ? cap.barcodes.first.rawValue : null;
    if (raw == null || raw.isEmpty) return;
    final payload = ArenaTripQrPayload.tryParse(raw);
    if (payload == null) return;

    _handled = true;
    if (!mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    Navigator.pop(context);

    final company =
        payload.companyName.isNotEmpty ? payload.companyName : 'رحلة جماعية';

    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => TripChatRoom(
          tripId: payload.tripId,
          tripCompanyName: company,
          readOnly: payload.isEnd,
          readOnlyBanner: payload.isEnd
              ? 'انتهت الرحلة.. نلتقي في المدرج القادم'
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0E0E0E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'مسح رمز الرحلة',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    CustomIconButton(
                      icon: Icons.close_rounded,
                      semanticsLabel: 'زر إغلاق نافذة الماسح',
                      color: Colors.white,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'امسح رمز «بداية» أو «نهاية» الرحلة الصادر من الإدارة. بداية الرحلة تفعّل الكتابة؛ نهاية الرحلة تعرض الشات للقراءة فقط.',
                  style: GoogleFonts.cairo(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _cam,
                        onDetect: _onDetect,
                      ),
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: primary.withValues(alpha: 0.7),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

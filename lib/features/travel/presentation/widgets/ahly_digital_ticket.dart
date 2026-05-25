import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/ticket_qr_payload.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/travel_booking.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/travel_schedule_helper.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AhlyDigitalTicket extends StatelessWidget {
  const AhlyDigitalTicket({
    super.key,
    required this.booking,
    required this.qrPayload,
  });

  final TravelBooking booking;
  final TicketQrPayload qrPayload;

  @override
  Widget build(BuildContext context) {
    final trip = booking.trip;
    final retAt = TravelScheduleHelper.returnDepartureAt(trip);
    final waitMin = TravelScheduleHelper.totalReturnWaitMinutes(trip);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.darkBlack, Color(0xFF151515)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(
          width: 2,
          color: AppColors.royalRed.withValues(alpha: 0.85),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalRed.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: Icon(
                Icons.sports_soccer,
                size: 160,
                color: AppColors.white.withValues(alpha: 0.04),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: AppColors.luminousGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'النادي الأهلي',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'تذكرة ترحال رقمية',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.luminousGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: qrPayload.toJsonString(),
                        version: QrVersions.auto,
                        size: 200,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.deepBlack,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.deepBlack,
                        ),
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoLine('المشجع', booking.fanName),
                  _infoLine('كود الحجز', booking.bookingCode),
                  _infoLine('الشركة', trip.companyName),
                  _infoLine(
                    'قبل المباراة',
                    'التجمع: ${trip.meetingPoint}\nالانطلاق: ${_fmt(trip.departureAt)}',
                  ),
                  _infoLine(
                    'بعد المباراة',
                    'انتظار $waitMin دقيقة بعد النهاية'
                        '${trip.hasCelebration ? ' (+احتفال بالتتويج)' : ''}\n'
                        'موعد العودة من نقطة التجمع: ${_fmt(retAt)}\n'
                        '${trip.returnMeetingPoint}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يعرض هذا الرمز على نقطة الصعود والعودة',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _infoLine(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.luminousGold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: GoogleFonts.cairo(
              fontSize: 13,
              height: 1.4,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

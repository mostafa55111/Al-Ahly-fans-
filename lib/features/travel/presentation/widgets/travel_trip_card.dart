import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/travel_trip_model.dart';

class TravelTripCard extends StatelessWidget {
  const TravelTripCard({
    super.key,
    required this.trip,
    this.onBook,
    this.onViewTicket,
    this.blockedByOtherActiveBooking = false,
  });

  final TravelTripModel trip;

  /// حجز جديد — يُعطى `null` عند تعطيل الزر (مثلاً حجز نشط برحلة أخرى).
  final VoidCallback? onBook;

  /// عند كون هذه الرحلة هي حجز المستخدم الحالي.
  final VoidCallback? onViewTicket;

  /// المستخدم لديه حجز نشط على رحلة أخرى.
  final bool blockedByOtherActiveBooking;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.mediumBlack,
            AppColors.darkBlack.withValues(alpha: 0.95),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border.all(color: AppColors.royalRed.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.companyName,
                      style: GoogleFonts.cairo(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  if (trip.hasCelebration)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.luminousGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'تتويج متوقع',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.luminousGold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _row(Icons.place_outlined, 'التجمع', trip.meetingPoint),
              _row(Icons.schedule, 'الانطلاق', _fmtTime(trip.departureAt)),
              _row(Icons.event_seat_outlined, 'المواصلات', trip.transportType),
              _row(Icons.location_searching, 'العودة من',
                  trip.returnMeetingPoint),
              _row(Icons.payments_outlined, 'السعر', '${trip.priceEgp} جنيه'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _primaryOnPressed(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalRed,
                    disabledBackgroundColor: AppColors.mediumGray,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _primaryLabel(),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  VoidCallback? _primaryOnPressed() {
    if (onViewTicket != null) return onViewTicket;
    if (trip.isFull) return null;
    if (blockedByOtherActiveBooking) return null;
    return onBook;
  }

  String _primaryLabel() {
    if (onViewTicket != null) return 'عرض التذكرة';
    if (trip.isFull) return 'مكتمل العدد';
    if (blockedByOtherActiveBooking) return 'لديك حجز نشط برحلة أخرى';
    return 'احجز الرحلة';
  }

  static String _fmtTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.luminousGold),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.lightGray,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.mediumGray,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

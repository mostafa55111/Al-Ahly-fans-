import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/ticket_qr_payload.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/cubit/travel_user_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/widgets/ahly_digital_ticket.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/widgets/boarding_countdown_banner.dart';

class TravelTicketPage extends StatelessWidget {
  const TravelTicketPage({
    super.key,
    required this.governorateCode,
  });

  final String governorateCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text(
          'تذكرتك',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<TravelUserCubit, TravelUserState>(
        builder: (context, state) {
          final booking = state.fanStatus.booking;
          if (booking == null) {
            return Center(
              child: Text(
                'لا يوجد حجز نشط.',
                style: GoogleFonts.cairo(color: AppColors.mediumGray),
              ),
            );
          }

          final payload = TicketQrPayload(
            bookingCode: booking.bookingCode,
            tripId: booking.tripId,
            fanUid: booking.fanUid,
            fanName: booking.fanName,
            governorateCode: governorateCode,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BoardingCountdownBanner(
                  departureAt: booking.trip.departureAt,
                  boardingConfirmed: state.fanStatus.boardingConfirmed,
                ),
                if (state.fanStatus.returnConfirmed)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تم تأكيد الوصول للعودة',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                AhlyDigitalTicket(booking: booking, qrPayload: payload),
              ],
            ),
          );
        },
      ),
    );
  }
}

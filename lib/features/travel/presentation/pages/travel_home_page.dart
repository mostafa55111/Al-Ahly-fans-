import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/governorate_model.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/cubit/travel_user_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/pages/travel_governorate_trips_page.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/pages/travel_trip_chat_page.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/widgets/boarding_countdown_banner.dart';
import 'package:gomhor_alahly_clean_new/features/travel/travel_demo_config.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/pages/travel_admin_page.dart';
import 'package:gomhor_alahly_clean_new/features/travel/data/travel_repository.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/custom_button.dart';

/// قائمة المحافظات مع [ListView.builder] للتنقل السريع.
class TravelHomePage extends StatelessWidget {
  const TravelHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Travel',
                          style: GoogleFonts.cairo(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          'Pick your governorate — booking codes start with its number',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomIconButton(
                    tooltip: 'Driver / admin panel',
                    icon: Icons.qr_code_scanner_rounded,
                    semanticsLabel: 'زر فتح لوحة السائق والأدمن',
                    color: AppColors.luminousGold,
                    size: 28,
                    onPressed: () {
                      final repo = context.read<TravelRepository>();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TravelAdminPage(
                            repository: repo,
                            tripId: kTravelDefaultAdminTripId,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            BlocBuilder<TravelUserCubit, TravelUserState>(
              builder: (context, st) {
                final b = st.fanStatus.booking;
                if (b == null) return const SizedBox.shrink();
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (st.fanStatus.returnConfirmed)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.6),
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
                      BoardingCountdownBanner(
                        departureAt: b.trip.departureAt,
                        boardingConfirmed: st.fanStatus.boardingConfirmed,
                      ),
                    ],
                  ),
                );
              },
            ),
            BlocBuilder<TravelUserCubit, TravelUserState>(
              builder: (context, st) {
                /// يطابق RTDB: meta.chatSessionActive + attendance/boarding/{uid}
                final fs = st.fanStatus;
                if (!fs.boardingConfirmed ||
                    !fs.chatSessionActive ||
                    fs.tripEnded) {
                  return const SizedBox.shrink();
                }
                final booking = fs.booking;
                if (booking == null) return const SizedBox.shrink();
                final company = booking.trip.companyName;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TravelTripChatPage(
                            tripId: booking.tripId,
                            tripCompanyName: company,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(
                      'دخول شات الرحلة',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalRed,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: context.read<TravelUserCubit>().setSearchQuery,
                style: GoogleFonts.cairo(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'ابحث عن المحافظة أو الكود (مثل 047)...',
                  hintStyle: GoogleFonts.cairo(color: AppColors.mediumGray),
                  prefixIcon: const Icon(Icons.search, color: AppColors.luminousGold),
                  filled: true,
                  fillColor: AppColors.mediumBlack,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<TravelUserCubit, TravelUserState>(
                builder: (context, state) {
                  final list = state.filteredGovernorates;
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final g = list[index];
                      return _GovernorateTile(
                        governorate: g,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => BlocProvider.value(
                                value: context.read<TravelUserCubit>(),
                                child: TravelGovernorateTripsPage(
                                  governorate: g,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GovernorateTile extends StatelessWidget {
  const _GovernorateTile({
    required this.governorate,
    required this.onTap,
  });

  final GovernorateModel governorate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.darkBlack,
              border: Border.all(
                color: AppColors.royalRed.withValues(alpha: 0.25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.royalRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      governorate.code3,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.luminousGold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      governorate.nameAr,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_left, color: AppColors.mediumGray),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

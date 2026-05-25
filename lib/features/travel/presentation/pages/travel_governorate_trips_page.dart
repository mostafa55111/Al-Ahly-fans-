import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/governorate_model.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/travel_trip_model.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/cubit/travel_user_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/pages/travel_ticket_page.dart';
import 'package:gomhor_alahly_clean_new/features/travel/services/travel_ai_assistant_service.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/widgets/travel_trip_card.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/custom_button.dart';

class TravelGovernorateTripsPage extends StatefulWidget {
  const TravelGovernorateTripsPage({
    super.key,
    required this.governorate,
  });

  final GovernorateModel governorate;

  @override
  State<TravelGovernorateTripsPage> createState() =>
      _TravelGovernorateTripsPageState();
}

class _TravelGovernorateTripsPageState
    extends State<TravelGovernorateTripsPage> {
  Future<List<TravelTripModel>>? _tripsFuture;
  bool _bookingInProgress = false;
  final TravelAiAssistantService _ai = TravelAiAssistantService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tripsFuture ??= context
        .read<TravelUserCubit>()
        .loadTripsForGovernorate(widget.governorate.id);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TravelUserCubit>();

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text(
          widget.governorate.nameAr,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        actions: [
          CustomIconButton(
            tooltip: 'مساعد Gemini',
            icon: Icons.auto_awesome_rounded,
            semanticsLabel: 'زر فتح مساعد الذكاء للرحلات',
            onPressed: () => _openAiAssistant(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<List<TravelTripModel>>(
            future: _tripsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.royalRed),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'تعذر تحميل الرحلات.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(color: AppColors.mediumGray),
                    ),
                  ),
                );
              }
              final trips = snapshot.data ?? [];
              if (trips.isEmpty) {
                return Center(
                  child: Text(
                    'لا توجد رحلات متاحة حالياً لهذه المحافظة.',
                    style: GoogleFonts.cairo(color: AppColors.mediumGray),
                  ),
                );
              }
              return BlocBuilder<TravelUserCubit, TravelUserState>(
                builder: (context, st) {
                  final booking = st.fanStatus.booking;
                  final liveBooking =
                      booking != null && !st.fanStatus.tripEnded;
                  final activeTripId = liveBooking ? booking.tripId : '';

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: trips.length,
                    itemBuilder: (context, i) {
                      final t = trips[i];
                      final isMyTrip = liveBooking && activeTripId == t.id;
                      final blockedOther = liveBooking && activeTripId != t.id;

                      return TravelTripCard(
                        trip: t,
                        blockedByOtherActiveBooking: blockedOther,
                        onViewTicket: isMyTrip
                            ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => BlocProvider.value(
                                      value: cubit,
                                      child: TravelTicketPage(
                                        governorateCode:
                                            widget.governorate.code3,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            : null,
                        onBook: () async {
                          setState(() => _bookingInProgress = true);
                          try {
                            await cubit.bookTrip(t);
                            if (!context.mounted) return;
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BlocProvider.value(
                                  value: cubit,
                                  child: TravelTicketPage(
                                    governorateCode: widget.governorate.code3,
                                  ),
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString(),
                                  style: GoogleFonts.cairo(),
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _bookingInProgress = false);
                            }
                          }
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          if (_bookingInProgress)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                          color: AppColors.royalRed),
                      const SizedBox(height: 18),
                      Text(
                        'جاري تأكيد الحجز…',
                        style: GoogleFonts.cairo(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openAiAssistant(BuildContext context) async {
    final trips = await _tripsFuture ?? const <TravelTripModel>[];
    if (!context.mounted) return;

    final questionController = TextEditingController();
    String answer = '';
    bool busy = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> ask() async {
              if (busy) return;
              setSheetState(() => busy = true);
              try {
                final result = await _ai.askTripAssistant(
                  governorateName: widget.governorate.nameAr,
                  trips: trips,
                  userQuestion: questionController.text,
                );
                if (!context.mounted) return;
                setSheetState(() => answer = result);
              } catch (_) {
                if (!context.mounted) return;
                setSheetState(
                  () =>
                      answer = 'حصل خطأ في الاتصال بـ Gemini. جرّب مرة تانية.',
                );
              } finally {
                if (context.mounted) {
                  setSheetState(() => busy = false);
                }
              }
            }

            Future<void> smokeCheck() async {
              if (busy) return;
              setSheetState(() => busy = true);
              try {
                final ok = await _ai.runConnectivityCheck();
                if (!context.mounted) return;
                setSheetState(
                  () => answer = ok
                      ? 'Gemini شغال ✅'
                      : 'Gemini غير متاح الآن. تأكد من GEMINI_API_KEY.',
                );
              } finally {
                if (context.mounted) {
                  setSheetState(() => busy = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Travel assistant (Gemini)',
                      style: GoogleFonts.cairo(
                        color: AppColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اسأل عن أنسب رحلة أو أفضل اختيار حسب البيانات الحالية.',
                      style: GoogleFonts.cairo(color: AppColors.mediumGray),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: questionController,
                      style: GoogleFonts.cairo(color: AppColors.white),
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'مثال: أنسب رحلة لعائلة وعدد مقاعدها كبير؟',
                        hintStyle:
                            GoogleFonts.cairo(color: AppColors.mediumGray),
                        filled: true,
                        fillColor: AppColors.mediumBlack,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (busy)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: LinearProgressIndicator(
                          color: AppColors.royalRed,
                          backgroundColor: AppColors.mediumBlack,
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: busy ? null : smokeCheck,
                            icon: const Icon(Icons.bolt_rounded),
                            label: Text(
                              'تشغيل Gemini',
                              style: GoogleFonts.cairo(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: busy ? null : ask,
                            icon: const Icon(Icons.send_rounded),
                            label: Text(
                              busy ? 'جاري الإرسال...' : 'اسأل الآن',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.royalRed,
                              foregroundColor: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (answer.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 260),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.mediumBlack,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                AppColors.luminousGold.withValues(alpha: 0.2),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            answer,
                            style: GoogleFonts.cairo(
                              color: AppColors.white,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(questionController.dispose);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';
import 'package:gomhor_alahly_clean_new/features/travel/data/travel_repository.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/attendee_record.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/cubit/travel_admin_cubit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// لوحة السائق/الأدمن: مسح QR + حضور + بوابة الشات + إغلاق الرحلة.
class TravelAdminPage extends StatelessWidget {
  const TravelAdminPage({
    super.key,
    required this.repository,
    required this.tripId,
  });

  final TravelRepository repository;
  final String tripId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TravelAdminCubit(
        repository: repository,
        tripId: tripId,
      ),
      child: const _TravelAdminBody(),
    );
  }
}

class _TravelAdminBody extends StatefulWidget {
  const _TravelAdminBody();

  @override
  State<_TravelAdminBody> createState() => _TravelAdminBodyState();
}

class _TravelAdminBodyState extends State<_TravelAdminBody> {
  final MobileScannerController _camera = MobileScannerController();

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text(
          'إدارة الرحلة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocConsumer<TravelAdminCubit, TravelAdminState>(
        listenWhen: (prev, curr) =>
            curr.lastMessage != null && curr.lastMessage != prev.lastMessage,
        listener: (context, state) {
          final msg = state.lastMessage;
          if (msg == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg, style: GoogleFonts.cairo()),
              backgroundColor:
                  state.lastMessageIsError ? AppColors.error : AppColors.success,
            ),
          );
        },
        builder: (context, state) {
          final snap = state.snapshot;
          if (snap == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.royalRed),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      snap.trip.companyName,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text('مسح الصعود',
                              style: GoogleFonts.cairo(fontSize: 13)),
                          selected: state.phase == AttendeeScanPhase.boarding,
                          onSelected: state.isBusy
                              ? null
                              : (_) => context
                                  .read<TravelAdminCubit>()
                                  .setPhase(AttendeeScanPhase.boarding),
                          selectedColor: AppColors.royalRed,
                          labelStyle: TextStyle(
                            color: state.phase == AttendeeScanPhase.boarding
                                ? AppColors.white
                                : AppColors.lightGray,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('مسح العودة',
                              style: GoogleFonts.cairo(fontSize: 13)),
                          selected: state.phase == AttendeeScanPhase.returnTrip,
                          onSelected: state.isBusy
                              ? null
                              : (_) => context
                                  .read<TravelAdminCubit>()
                                  .setPhase(AttendeeScanPhase.returnTrip),
                          selectedColor: AppColors.royalRed,
                          labelStyle: TextStyle(
                            color: state.phase == AttendeeScanPhase.returnTrip
                                ? AppColors.white
                                : AppColors.lightGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: snap.tripEnded || state.isBusy
                                ? null
                                : () => context
                                    .read<TravelAdminCubit>()
                                    .openTripChat(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mediumBlack,
                              foregroundColor: AppColors.luminousGold,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'فتح الشات (للمسحوبين)',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: snap.tripEnded || state.isBusy
                                ? null
                                : () => context
                                    .read<TravelAdminCubit>()
                                    .announceBusDeparture(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.royalRed,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'إعلان تحرك الحافلة',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 220,
                        child: MobileScanner(
                          controller: _camera,
                          onDetect: (capture) {
                            if (state.isBusy) return;
                            for (final b in capture.barcodes) {
                              final raw = b.rawValue;
                              if (raw != null && raw.isNotEmpty) {
                                context
                                    .read<TravelAdminCubit>()
                                    .submitQrRaw(raw);
                                break;
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _AttendanceBlock(snapshot: snap),
                    const SizedBox(height: 20),
                    _TripChatGate(snapshot: snap),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: snap.tripEnded || state.isBusy
                          ? null
                          : () =>
                              context.read<TravelAdminCubit>().closeTrip(),
                      icon: const Icon(Icons.flag_rounded,
                          color: AppColors.luminousGold),
                      label: Text(
                        snap.tripEnded ? 'الرحلة مغلقة' : 'إنهاء الرحلة',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.luminousGold,
                        side: const BorderSide(color: AppColors.luminousGold),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'لا يُسمح بالإغلاق إلا بعد اكتمال عدد الحاضرين أو انتهاء وقت الانتظار (${_fmt(snap.waitDeadlineAt)}).',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppColors.mediumGray,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.isBusy)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.royalRed,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'جاري المعالجة…',
                          style: GoogleFonts.cairo(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _fmt(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _AttendanceBlock extends StatelessWidget {
  const _AttendanceBlock({required this.snapshot});

  final TripAdminSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final present = snapshot.bookings.where((b) => b.attendedBoarding).toList();
    final absent = snapshot.bookings.where((b) => !b.attendedBoarding).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الحضور (${snapshot.boardedCount} / ${snapshot.expectedHeadcount})',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 10),
        _subHeading('من حضر للصعود', AppColors.success),
        ...present.map((e) => _personTile(e, true)),
        const SizedBox(height: 12),
        _subHeading('لم يُسجَّل حضورهم', AppColors.warning),
        ...absent.map((e) => _personTile(e, false)),
      ],
    );
  }

  Widget _subHeading(String t, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            t,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              color: c,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _personTile(AttendeeRecord a, bool present) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mediumBlack,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: present
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.mediumGray.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            present ? Icons.check_circle : Icons.person_off_outlined,
            color: present ? AppColors.success : AppColors.mediumGray,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.fanName,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  a.bookingCode,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          ),
          if (a.confirmedReturn)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'عودة ✓',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: AppColors.info,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TripChatGate extends StatelessWidget {
  const _TripChatGate({required this.snapshot});

  final TripAdminSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.darkBlack,
        border: Border.all(
          color: AppColors.luminousGold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                snapshot.tripEnded
                    ? Icons.lock_outline
                    : snapshot.chatSessionActive
                        ? Icons.chat_bubble_outline
                        : Icons.chat_bubble_outline,
                color: AppColors.luminousGold,
              ),
              const SizedBox(width: 8),
              Text(
                'الشات الجماعي للرحلة',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (snapshot.tripEnded)
            Text(
              'انتهت الرحلة — الشات مُغلق تلقائياً.',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.mediumGray,
                height: 1.4,
              ),
            )
          else if (!snapshot.chatSessionActive)
            Text(
              'اضغط «فتح الشات» لتفعيل الشات للمشجعين الذين سُجِّل صعودهم فقط.',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.mediumGray,
                height: 1.4,
              ),
            )
          else
            Text(
              'الشات مفعّل للمسجّلين بالصعود فقط. الإشعارات تُرسل عبر Cloud Function notifyTravelTrip.',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.success,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}

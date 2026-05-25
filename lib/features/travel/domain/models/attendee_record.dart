import 'package:equatable/equatable.dart';

enum AttendeeScanPhase { boarding, returnTrip }

/// سجل حضور لمشجع في رحلة (لقائمة الأدمن).
class AttendeeRecord extends Equatable {
  const AttendeeRecord({
    required this.uid,
    required this.fanName,
    required this.bookingCode,
    this.boardingScannedAt,
    this.returnScannedAt,
  });

  final String uid;
  final String fanName;
  final String bookingCode;
  final DateTime? boardingScannedAt;
  final DateTime? returnScannedAt;

  bool get attendedBoarding => boardingScannedAt != null;
  bool get confirmedReturn => returnScannedAt != null;

  AttendeeRecord copyWith({
    DateTime? boardingScannedAt,
    DateTime? returnScannedAt,
    bool clearBoarding = false,
    bool clearReturn = false,
  }) {
    return AttendeeRecord(
      uid: uid,
      fanName: fanName,
      bookingCode: bookingCode,
      boardingScannedAt:
          clearBoarding ? null : (boardingScannedAt ?? this.boardingScannedAt),
      returnScannedAt:
          clearReturn ? null : (returnScannedAt ?? this.returnScannedAt),
    );
  }

  @override
  List<Object?> get props =>
      [uid, fanName, bookingCode, boardingScannedAt, returnScannedAt];
}

import 'package:equatable/equatable.dart';

/// رحلة ترحال مرتبطة بمحافظة.
class TravelTripModel extends Equatable {
  const TravelTripModel({
    required this.id,
    required this.governorateId,
    required this.companyName,
    required this.meetingPoint,
    required this.departureAt,
    required this.priceEgp,
    required this.transportType,
    required this.returnMeetingPoint,
    required this.matchEndsAt,
    required this.capacity,
    required this.bookedCount,
    this.hasCelebration = false,
    this.waitDeadlineAt,
  });

  final String id;
  final String governorateId;
  final String companyName;
  final String meetingPoint;
  final DateTime departureAt;
  final int priceEgp;

  /// مثل: حافلة، ميني باص
  final String transportType;
  final String returnMeetingPoint;

  /// وقت انتهاء المباراة (لحساب موعد العودة = +90 دقيقة [+30 إن وجد تتويج])
  final DateTime matchEndsAt;
  final int capacity;
  final int bookedCount;

  /// عند `true` تُضاف 30 دقيقة إضافية لمواعيد العودة (فوق الـ 90 دقيقة بعد المباراة).
  final bool hasCelebration;

  /// انتهاء وقت انتظار الإدارة قبل إغلاق الرحلة يدوياً (اختياري في RTDB).
  final DateTime? waitDeadlineAt;

  bool get isFull => bookedCount >= capacity;

  Map<String, dynamic> toMap() => {
        'id': id,
        'governorateId': governorateId,
        'companyName': companyName,
        'meetingPoint': meetingPoint,
        'departureAt': departureAt.toIso8601String(),
        'priceEgp': priceEgp,
        'transportType': transportType,
        'returnMeetingPoint': returnMeetingPoint,
        'matchEndsAt': matchEndsAt.toIso8601String(),
        'capacity': capacity,
        'bookedCount': bookedCount,
        'hasCelebration': hasCelebration,
        if (waitDeadlineAt != null)
          'waitDeadlineAt': waitDeadlineAt!.toIso8601String(),
      };

  factory TravelTripModel.fromMap(Map<dynamic, dynamic> map) {
    return TravelTripModel(
      id: map['id'] as String? ?? '',
      governorateId: map['governorateId'] as String? ?? '',
      companyName: map['companyName'] as String? ?? '',
      meetingPoint: map['meetingPoint'] as String? ?? '',
      departureAt: DateTime.tryParse(map['departureAt'] as String? ?? '') ??
          DateTime.now(),
      priceEgp: (map['priceEgp'] as num?)?.toInt() ?? 0,
      transportType: map['transportType'] as String? ?? '',
      returnMeetingPoint: map['returnMeetingPoint'] as String? ?? '',
      matchEndsAt: DateTime.tryParse(map['matchEndsAt'] as String? ?? '') ??
          DateTime.now(),
      capacity: (map['capacity'] as num?)?.toInt() ?? 0,
      bookedCount: (map['bookedCount'] as num?)?.toInt() ?? 0,
      hasCelebration: map['hasCelebration'] == true || map['hasCelebration'] == 1,
      waitDeadlineAt: map['waitDeadlineAt'] != null
          ? DateTime.tryParse(map['waitDeadlineAt'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        governorateId,
        companyName,
        meetingPoint,
        departureAt,
        priceEgp,
        transportType,
        returnMeetingPoint,
        matchEndsAt,
        capacity,
        bookedCount,
        hasCelebration,
        waitDeadlineAt,
      ];
}

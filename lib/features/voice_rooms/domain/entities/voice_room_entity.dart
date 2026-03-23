import 'package:equatable/equatable.dart';

/// كيان غرفة الدردشة الصوتية (Voice Room Entity)
class VoiceRoomEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String hostId;
  final String hostName;
  final String hostImageUrl;
  final List<String> listenerIds;
  final List<String> speakerIds;
  final int maxListeners;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final String status; // 'scheduled', 'live', 'ended'
  final String category; // 'match-discussion', 'player-talk', 'general'
  final bool isRecorded;
  final int viewersCount;

  const VoiceRoomEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.hostId,
    required this.hostName,
    required this.hostImageUrl,
    required this.listenerIds,
    required this.speakerIds,
    required this.maxListeners,
    required this.createdAt,
    this.scheduledAt,
    required this.status,
    required this.category,
    required this.isRecorded,
    required this.viewersCount,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    hostId,
    hostName,
    hostImageUrl,
    listenerIds,
    speakerIds,
    maxListeners,
    createdAt,
    scheduledAt,
    status,
    category,
    isRecorded,
    viewersCount,
  ];
}

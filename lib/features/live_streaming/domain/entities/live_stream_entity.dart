import 'package:equatable/equatable.dart';

/// كيان البث المباشر (Live Stream Entity)
class LiveStreamEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String streamerId;
  final String streamerName;
  final String streamerImageUrl;
  final String streamUrl;
  final String thumbnailUrl;
  final int viewersCount;
  final int likesCount;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status; // 'scheduled', 'live', 'ended'
  final String category; // 'match', 'training', 'interview', 'analysis'
  final bool isVerified;
  final int duration; // بالدقائق
  final List<String> tags;
  final bool isRecorded;
  final String? recordingUrl;
  final bool allowComments;
  final bool allowGifts;
  final int giftAmount; // إجمالي الهدايا

  const LiveStreamEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.streamerId,
    required this.streamerName,
    required this.streamerImageUrl,
    required this.streamUrl,
    required this.thumbnailUrl,
    required this.viewersCount,
    required this.likesCount,
    required this.startedAt,
    this.endedAt,
    required this.status,
    required this.category,
    required this.isVerified,
    required this.duration,
    required this.tags,
    required this.isRecorded,
    this.recordingUrl,
    required this.allowComments,
    required this.allowGifts,
    required this.giftAmount,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    streamerId,
    streamerName,
    streamerImageUrl,
    streamUrl,
    thumbnailUrl,
    viewersCount,
    likesCount,
    startedAt,
    endedAt,
    status,
    category,
    isVerified,
    duration,
    tags,
    isRecorded,
    recordingUrl,
    allowComments,
    allowGifts,
    giftAmount,
  ];
}

/// فئة فئات البث
class StreamCategories {
  static const String match = 'match'; // مباراة
  static const String training = 'training'; // تدريب
  static const String interview = 'interview'; // مقابلة
  static const String analysis = 'analysis'; // تحليل
  static const String behindScenes = 'behind-scenes'; // كواليس
  static const String fanMeeting = 'fan-meeting'; // لقاء الجمهور

  static List<String> getAllCategories() => [
    match,
    training,
    interview,
    analysis,
    behindScenes,
    fanMeeting,
  ];
}

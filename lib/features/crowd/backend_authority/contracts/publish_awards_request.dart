class PublishAwardsRequest {
  const PublishAwardsRequest({
    required this.clubTag,
    required this.matchId,
    required this.year,
    required this.awardPayload,
  });

  final String clubTag;
  final String matchId;
  final int year;
  final Map<String, dynamic> awardPayload;

  Map<String, dynamic> toJson() => {
        'clubTag': clubTag,
        'matchId': matchId,
        'year': year,
        'awardPayload': awardPayload,
      };

  factory PublishAwardsRequest.fromJson(Map<String, dynamic> json) {
    final payload = json['awardPayload'];
    return PublishAwardsRequest(
      clubTag: json['clubTag']?.toString() ?? '',
      matchId: json['matchId']?.toString() ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      awardPayload: payload is Map<String, dynamic>
          ? Map<String, dynamic>.from(payload)
          : payload is Map
              ? Map<String, dynamic>.from(payload)
              : const {},
    );
  }
}

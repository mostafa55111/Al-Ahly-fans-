class FinalizeSessionResponse {
  const FinalizeSessionResponse({
    required this.success,
    this.alreadyFinalized = false,
    this.snapshotWritten = false,
    this.errorMessage,
  });

  final bool success;
  final bool alreadyFinalized;
  final bool snapshotWritten;
  final String? errorMessage;

  Map<String, dynamic> toJson() => {
        'success': success,
        'alreadyFinalized': alreadyFinalized,
        'snapshotWritten': snapshotWritten,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };

  factory FinalizeSessionResponse.fromJson(Map<String, dynamic> json) {
    return FinalizeSessionResponse(
      success: json['success'] == true,
      alreadyFinalized: json['alreadyFinalized'] == true,
      snapshotWritten: json['snapshotWritten'] == true,
      errorMessage: json['errorMessage']?.toString(),
    );
  }
}

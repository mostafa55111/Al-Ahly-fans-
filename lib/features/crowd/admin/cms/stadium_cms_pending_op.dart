import 'package:equatable/equatable.dart';

enum StadiumCmsPendingOpKind {
  cardRegistryUpsert,
}

/// عمل معلّق — يُعاد محاولته عند عودة الشبكة.
class StadiumCmsPendingOp extends Equatable {
  const StadiumCmsPendingOp({
    required this.id,
    required this.kind,
    required this.payload,
    this.attempts = 0,
    this.createdAt = 0,
    this.lastError = '',
  });

  final String id;
  final StadiumCmsPendingOpKind kind;
  final Map<String, dynamic> payload;
  final int attempts;
  final int createdAt;
  final String lastError;

  factory StadiumCmsPendingOp.fromMap(String id, Map<dynamic, dynamic> m) {
    final kindRaw = m['kind']?.toString() ?? '';
    final kind = kindRaw == 'cardRegistryUpsert'
        ? StadiumCmsPendingOpKind.cardRegistryUpsert
        : StadiumCmsPendingOpKind.cardRegistryUpsert;
    final payloadRaw = m['payload'];
    return StadiumCmsPendingOp(
      id: id,
      kind: kind,
      payload: payloadRaw is Map
          ? Map<String, dynamic>.from(
              payloadRaw.map((k, v) => MapEntry(k.toString(), v)),
            )
          : const {},
      attempts: (m['attempts'] as num?)?.toInt() ?? 0,
      createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
      lastError: m['lastError']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'kind': kind.name,
        'payload': payload,
        'attempts': attempts,
        'createdAt': createdAt,
        'lastError': lastError,
      };

  StadiumCmsPendingOp copyWith({
    int? attempts,
    String? lastError,
  }) {
    return StadiumCmsPendingOp(
      id: id,
      kind: kind,
      payload: payload,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  List<Object?> get props => [id, kind, payload, attempts, createdAt, lastError];
}

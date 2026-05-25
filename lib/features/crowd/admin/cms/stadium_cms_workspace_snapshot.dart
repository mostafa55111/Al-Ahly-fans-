import 'package:equatable/equatable.dart';

/// لقطة عمل الأدمن لاستئناف الجلسة بضغطة واحدة.
class StadiumCmsWorkspaceSnapshot extends Equatable {
  const StadiumCmsWorkspaceSnapshot({
    required this.sessionId,
    required this.title,
    required this.formation,
    required this.opponent,
    required this.sessionType,
    required this.fxLevel,
    required this.crowdProfile,
    required this.stadiumTheme,
    required this.overlaysProfile,
    required this.playerCount,
    required this.votingEnabled,
    required this.updatedAt,
    this.kitName = '',
  });

  final String sessionId;
  final String title;
  final String formation;
  final String opponent;
  final String sessionType;
  final String fxLevel;
  final String crowdProfile;
  final String stadiumTheme;
  final String overlaysProfile;
  final int playerCount;
  final bool votingEnabled;
  final int updatedAt;
  final String kitName;

  factory StadiumCmsWorkspaceSnapshot.fromMap(Map<dynamic, dynamic> m) {
    return StadiumCmsWorkspaceSnapshot(
      sessionId: m['sessionId']?.toString() ?? '',
      title: m['title']?.toString() ?? '',
      formation: m['formation']?.toString() ?? '4-3-3',
      opponent: m['opponent']?.toString() ?? '',
      sessionType: m['sessionType']?.toString() ?? 'league',
      fxLevel: m['fxLevel']?.toString() ?? 'warm',
      crowdProfile: m['crowdProfile']?.toString() ?? 'standard',
      stadiumTheme: m['stadiumTheme']?.toString() ?? 'default',
      overlaysProfile: m['overlaysProfile']?.toString() ?? 'default',
      playerCount: (m['playerCount'] as num?)?.toInt() ?? 0,
      votingEnabled: m['votingEnabled'] == true || m['votingEnabled'] == 1,
      updatedAt: (m['updatedAt'] as num?)?.toInt() ?? 0,
      kitName: m['kitName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toWriteMap() => {
        'sessionId': sessionId,
        'title': title,
        'formation': formation,
        'opponent': opponent,
        'sessionType': sessionType,
        'fxLevel': fxLevel,
        'crowdProfile': crowdProfile,
        'stadiumTheme': stadiumTheme,
        'overlaysProfile': overlaysProfile,
        'playerCount': playerCount,
        'votingEnabled': votingEnabled,
        'updatedAt': updatedAt,
        'kitName': kitName,
      };

  @override
  List<Object?> get props => [
        sessionId,
        title,
        formation,
        opponent,
        sessionType,
        fxLevel,
        crowdProfile,
        stadiumTheme,
        overlaysProfile,
        playerCount,
        votingEnabled,
        updatedAt,
        kitName,
      ];
}

import 'package:equatable/equatable.dart';

/// كيان المباراة
class MatchEntity extends Equatable {
  /// معرف المباراة
  final String id;
  
  /// اسم الفريق الأول
  final String homeTeam;
  
  /// اسم الفريق الثاني
  final String awayTeam;
  
  /// شعار الفريق الأول
  final String homeTeamLogo;
  
  /// شعار الفريق الثاني
  final String awayTeamLogo;
  
  /// أهداف الفريق الأول
  final int homeScore;
  
  /// أهداف الفريق الثاني
  final int awayScore;
  
  /// حالة المباراة
  final MatchStatus status;
  
  /// الوقت الحالي في المباراة
  final int currentMinute;
  
  /// وقت بدء المباراة
  final DateTime startTime;
  
  /// الملعب
  final String stadium;
  
  /// المدينة
  final String city;
  
  /// الحكم
  final String referee;
  
  /// البطولة
  final String tournament;
  
  /// الموسم
  final String season;
  
  /// الأحداث المهمة
  final List<MatchEvent> events;
  
  /// إحصائيات الفريق الأول
  final TeamStatistics homeTeamStats;
  
  /// إحصائيات الفريق الثاني
  final TeamStatistics awayTeamStats;
  
  /// تشكيل الفريق الأول
  final List<Player> homeTeamLineup;
  
  /// تشكيل الفريق الثاني
  final List<Player> awayTeamLineup;
  
  /// هل المباراة مباشرة
  final bool isLive;
  
  /// هل انتهت المباراة
  final bool isFinished;

  const MatchEntity({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeTeamLogo,
    required this.awayTeamLogo,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    required this.currentMinute,
    required this.startTime,
    required this.stadium,
    required this.city,
    required this.referee,
    required this.tournament,
    required this.season,
    required this.events,
    required this.homeTeamStats,
    required this.awayTeamStats,
    required this.homeTeamLineup,
    required this.awayTeamLineup,
    required this.isLive,
    required this.isFinished,
  });

  @override
  List<Object?> get props => [
    id,
    homeTeam,
    awayTeam,
    homeTeamLogo,
    awayTeamLogo,
    homeScore,
    awayScore,
    status,
    currentMinute,
    startTime,
    stadium,
    city,
    referee,
    tournament,
    season,
    events,
    homeTeamStats,
    awayTeamStats,
    homeTeamLineup,
    awayTeamLineup,
    isLive,
    isFinished,
  ];
}

/// حالات المباراة
enum MatchStatus {
  scheduled,  // مجدولة
  live,       // مباشرة
  halftime,   // نهاية الشوط الأول
  finished,   // انتهت
  postponed,  // مؤجلة
  cancelled,  // ملغاة
}

/// حدث في المباراة
class MatchEvent extends Equatable {
  /// نوع الحدث
  final EventType type;
  
  /// الدقيقة
  final int minute;
  
  /// اسم اللاعب
  final String playerName;
  
  /// رقم اللاعب
  final int playerNumber;
  
  /// الفريق
  final String team;
  
  /// الوصف
  final String description;
  
  /// الوقت
  final DateTime time;

  const MatchEvent({
    required this.type,
    required this.minute,
    required this.playerName,
    required this.playerNumber,
    required this.team,
    required this.description,
    required this.time,
  });

  @override
  List<Object?> get props => [
    type,
    minute,
    playerName,
    playerNumber,
    team,
    description,
    time,
  ];
}

/// أنواع الأحداث
enum EventType {
  goal,           // هدف
  ownGoal,        // هدف في المرمى
  yellowCard,     // بطاقة صفراء
  redCard,        // بطاقة حمراء
  substitution,   // تبديل
  injury,         // إصابة
  foul,           // خطأ
  offside,        // تسلل
  penaltyMissed,  // ركلة جزاء ضائعة
  penaltyGoal,    // ركلة جزاء هدف
}

/// إحصائيات الفريق
class TeamStatistics extends Equatable {
  /// الحيازة
  final double possession;
  
  /// التسديدات
  final int shots;
  
  /// التسديدات على المرمى
  final int shotsOnTarget;
  
  /// الزوايا
  final int corners;
  
  /// الأخطاء
  final int fouls;
  
  /// البطاقات الصفراء
  final int yellowCards;
  
  /// البطاقات الحمراء
  final int redCards;
  
  /// التمريرات
  final int passes;
  
  /// دقة التمريرات
  final double passAccuracy;
  
  /// الضربات الحرة
  final int freeKicks;

  const TeamStatistics({
    required this.possession,
    required this.shots,
    required this.shotsOnTarget,
    required this.corners,
    required this.fouls,
    required this.yellowCards,
    required this.redCards,
    required this.passes,
    required this.passAccuracy,
    required this.freeKicks,
  });

  @override
  List<Object?> get props => [
    possession,
    shots,
    shotsOnTarget,
    corners,
    fouls,
    yellowCards,
    redCards,
    passes,
    passAccuracy,
    freeKicks,
  ];
}

/// بيانات اللاعب
class Player extends Equatable {
  /// معرف اللاعب
  final String id;
  
  /// اسم اللاعب
  final String name;
  
  /// رقم اللاعب
  final int number;
  
  /// الموضع
  final String position;
  
  /// صورة اللاعب
  final String imageUrl;
  
  /// هل تم استبداله
  final bool isSubstituted;

  const Player({
    required this.id,
    required this.name,
    required this.number,
    required this.position,
    required this.imageUrl,
    required this.isSubstituted,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    number,
    position,
    imageUrl,
    isSubstituted,
  ];
}

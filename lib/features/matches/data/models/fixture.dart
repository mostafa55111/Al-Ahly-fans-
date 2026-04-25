import 'package:equatable/equatable.dart';

import 'package:gomhor_alahly_clean_new/features/matches/data/datasources/football_api_service.dart';

/// ═════════════════════════════════════════════════════════════════
/// موديلات TheSportsDB (حدث h2h)
/// ═════════════════════════════════════════════════════════════════
/// الـ JSON يأتي من `events` ككائنات مسطّحة (idEvent, strHomeTeam, …)
/// — لا يوجد تداخل `fixture` / `league` كما في api-sports.

/// حالة المباراة — مُستنتجة من [strStatus] في TheSportsDB
enum MatchPhase { upcoming, live, finished, postponed }

extension MatchPhaseX on MatchPhase {
  String get arabic {
    switch (this) {
      case MatchPhase.upcoming:
        return 'لم تبدأ';
      case MatchPhase.live:
        return 'مباشرة';
      case MatchPhase.finished:
        return 'انتهت';
      case MatchPhase.postponed:
        return 'مؤجّلة';
    }
  }

  /// توافق خلفي مع رموز api-sports القصيرة (لن يُستعمل مع البيانات الجديدة)
  static MatchPhase fromShort(String? short) {
    if (short == null) return MatchPhase.upcoming;
    switch (short.toUpperCase()) {
      case 'NS':
      case 'TBD':
        return MatchPhase.upcoming;
      case '1H':
      case '2H':
      case 'HT':
      case 'ET':
      case 'BT':
      case 'P':
      case 'LIVE':
      case 'INT':
        return MatchPhase.live;
      case 'FT':
      case 'AET':
      case 'PEN':
        return MatchPhase.finished;
      case 'PST':
      case 'CANC':
      case 'SUSP':
      case 'AWD':
      case 'WO':
        return MatchPhase.postponed;
      default:
        return MatchPhase.upcoming;
    }
  }

  /// تفسير [strStatus] من TheSportsDB (لغة إنجليزية)
  static MatchPhase fromTheSportsDbStatus(String? strStatus) {
    if (strStatus == null || strStatus.trim().isEmpty) {
      return MatchPhase.upcoming;
    }
    final s = strStatus.toLowerCase().trim();
    if (s == 'match finished' || s == 'ft') {
      return MatchPhase.finished;
    }
    if (s == 'not started' || s == 'scheduled' || s == 'time to be defined') {
      return MatchPhase.upcoming;
    }
    if (s.contains('postponed') || s == 'canceled' || s == 'cancelled') {
      return MatchPhase.postponed;
    }
    // أطوار اللعب والأشواط الإضافية
    if (s.contains('half') ||
        s.contains('break') ||
        s.contains('extra') ||
        s.contains('in progress') ||
        s == '1st' ||
        s == '2nd' ||
        (s.contains('penalty') && !s.contains('penalties finished'))) {
      return MatchPhase.live;
    }
    return MatchPhase.upcoming;
  }
}

class Venue extends Equatable {
  final int? id;
  final String name;
  final String city;
  final String? country;

  const Venue({
    this.id,
    required this.name,
    required this.city,
    this.country,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      name: (json['name'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      country: json['country']?.toString(),
    );
  }

  /// هل الاستاد في مصر؟ (لإظهار زر خرائط جوجل)
  bool get isInEgypt {
    final c = (country ?? '').toLowerCase();
    final cy = city.toLowerCase();
    return c.contains('egypt') ||
        c.contains('مصر') ||
        cy.contains('cairo') ||
        cy.contains('alex') ||
        cy.contains('giza') ||
        cy.contains('قاهرة') ||
        cy.contains('اسكندرية') ||
        cy.contains('جيزة');
  }

  String get googleMapsQuery {
    final q = Uri.encodeComponent('$name $city ${country ?? ''}'.trim());
    return 'https://www.google.com/maps/search/?api=1&query=$q';
  }

  @override
  List<Object?> get props => [id, name, city, country];
}

class FixtureTeam extends Equatable {
  final int id;
  final String name;
  final String? logo;
  final bool? winner;

  const FixtureTeam({
    required this.id,
    required this.name,
    this.logo,
    this.winner,
  });

  factory FixtureTeam.fromJson(Map<String, dynamic> json) {
    return FixtureTeam(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: (json['name'] ?? '').toString(),
      logo: json['logo']?.toString(),
      winner: json['winner'] is bool ? json['winner'] as bool : null,
    );
  }

  @override
  List<Object?> get props => [id, name, logo, winner];
}

class FixtureScore extends Equatable {
  final int? home;
  final int? away;

  const FixtureScore({this.home, this.away});

  /// من حقول intHomeScore / intAwayScore (قد تكون String أو int)
  factory FixtureScore.fromTheSportsDb(
    int? h,
    int? a,
  ) {
    return FixtureScore(home: h, away: a);
  }

  factory FixtureScore.fromGoals(Map<String, dynamic>? goals) {
    if (goals == null) return const FixtureScore();
    int? toI(dynamic v) =>
        v is int ? v : (v is String ? int.tryParse(v) : null);
    return FixtureScore(home: toI(goals['home']), away: toI(goals['away']));
  }

  bool get hasScore => home != null && away != null;
  String display(String sep) =>
      hasScore ? '$home $sep $away' : ' ${'-'} $sep ${'-'} ';

  @override
  List<Object?> get props => [home, away];
}

class Fixture extends Equatable {
  final int id;
  final DateTime date;
  final String? referee;
  final MatchPhase phase;
  final String statusShort;
  final int? elapsed;
  final Venue? venue;
  final String leagueName;
  final String? leagueLogo;
  final int? leagueId;
  final String? round;
  final FixtureTeam home;
  final FixtureTeam away;
  final FixtureScore goals;
  final String? eventThumb;
  final String? eventPoster;

  /// صيغة TheSportsDB مثل 2025-2026 — لطلب جدول الترتيب
  final String? seasonKey;

  /// مجموعة البطولة (مهم لدوري الأبطال/كأس العالم للأندية) — قد يكون فارغاً
  final String? groupName;

  const Fixture({
    required this.id,
    required this.date,
    required this.phase,
    required this.statusShort,
    required this.leagueName,
    required this.home,
    required this.away,
    required this.goals,
    this.referee,
    this.elapsed,
    this.venue,
    this.leagueLogo,
    this.leagueId,
    this.round,
    this.eventThumb,
    this.eventPoster,
    this.seasonKey,
    this.groupName,
  });

  /// idHomeTeam في TheSportsDB يساوي 138995
  bool get isAhlyHome => home.id == FootballApiService.alAhlyTeamId;

  FixtureTeam get opponent => isAhlyHome ? away : home;

  String get timeLabel {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String get dateLabel {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  static int? _intField(Map<String, dynamic> j, String key) {
    final v = j[key];
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v.trim());
    return int.tryParse(v.toString());
  }

  /// استجابة TheSportsDB لحقل واحد من `events`
  factory Fixture.fromJson(Map<String, dynamic> json) {
    final idEvent = int.tryParse('${json['idEvent'] ?? 0}') ?? 0;
    final st = (json['strStatus'] ?? '').toString();
    final phase = MatchPhaseX.fromTheSportsDbStatus(st);
    final sHome = _intField(json, 'intHomeScore');
    final sAway = _intField(json, 'intAwayScore');

    final vId = _parseId(json['idVenue']);
    final vName = (json['strVenue'] ?? '').toString();
    final vCity = (json['strCity'] ?? '').toString();
    final vCountry = (json['strCountry'] as String?);

    Venue? v;
    if (vName.isNotEmpty || vCity.isNotEmpty) {
      v = Venue(
        id: vId,
        name: vName,
        city: vCity,
        country: vCountry,
      );
    }

    return Fixture(
      id: idEvent,
      date: Fixture._rawParseDate(json),
      referee: json['strOfficial']?.toString().isNotEmpty == true
          ? json['strOfficial'].toString()
          : null,
      phase: phase,
      statusShort: st,
      elapsed: _maybeElapsed(phase, json),
      venue: v,
      leagueName: (json['strLeague'] ?? '').toString(),
      leagueLogo: json['strLeagueBadge']?.toString(),
      leagueId: int.tryParse('${json['idLeague'] ?? ''}'),
      round: json['intRound']?.toString(),
      home: FixtureTeam(
        id: int.tryParse('${json['idHomeTeam'] ?? 0}') ?? 0,
        name: (json['strHomeTeam'] ?? '').toString(),
        logo: json['strHomeTeamBadge']?.toString(),
        winner: _winnerFlag(sHome, sAway, true),
      ),
      away: FixtureTeam(
        id: int.tryParse('${json['idAwayTeam'] ?? 0}') ?? 0,
        name: (json['strAwayTeam'] ?? '').toString(),
        logo: json['strAwayTeamBadge']?.toString(),
        winner: _winnerFlag(sHome, sAway, false),
      ),
      goals: FixtureScore.fromTheSportsDb(sHome, sAway),
      eventThumb: _nonEmptyStr(json['strThumb']),
      eventPoster: _nonEmptyStr(json['strPoster']),
      seasonKey: _nonEmptyStr(json['strSeason']),
      groupName: _nonEmptyStr(json['strGroup']),
    );
  }

  static int? _parseId(dynamic v) => v == null
      ? null
      : (v is int
          ? v
          : int.tryParse(v.toString()));

  static String? _nonEmptyStr(dynamic o) {
    if (o == null) return null;
    final s = o.toString();
    return s.isEmpty ? null : s;
  }

  static bool? _winnerFlag(int? sH, int? sA, bool home) {
    if (sH == null || sA == null) return null;
    if (sH == sA) return null;
    if (home) return sH > sA;
    return sA > sH;
  }

  static int? _maybeElapsed(MatchPhase ph, Map<String, dynamic> json) {
    if (ph != MatchPhase.live) return null;
    // TheSportsDB لا يرد دائمًا بـ elapsed — نتجاهل أو نتوسع لاحقًا
    return null;
  }

  static DateTime _rawParseDate(Map<String, dynamic> e) {
    final ts = e['strTimestamp']?.toString();
    if (ts != null && ts.isNotEmpty) {
      final p = DateTime.tryParse(ts);
      if (p != null) return p.toLocal();
    }
    final d = (e['dateEvent'] ?? e['dateEventLocal'] ?? '').toString();
    final t = (e['strTime'] ?? e['strTimeLocal'] ?? '00:00:00').toString();
    if (d.isEmpty) return DateTime.now();
    final c = d.contains('T')
        ? d
        : '${d}T${t.isEmpty ? '00:00:00' : t}';
    return DateTime.tryParse(c)?.toLocal() ?? DateTime.now();
  }

  @override
  List<Object?> get props => [id, date, statusShort];
}

/// امتدادات للواجهة: تمييز مباراة محددة (مثل الأهلي × بيراميدز)
extension FixtureFocusX on Fixture {
  /// هل المباراة ضد بيراميدز (للترويسة المميّزة)
  bool get isOpponentPyramids {
    final n = opponent.name.toLowerCase();
    return n.contains('pyramid') || n.contains('بيراميد');
  }
}

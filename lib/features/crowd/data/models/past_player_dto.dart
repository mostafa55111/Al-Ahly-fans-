import 'package:equatable/equatable.dart';

/// لاعب من مسار [best_player] في Realtime Database.
///
/// **شكل العقدة في RTDB:**
/// ```
/// best_player/
///   player1/
///     name: "Mohamed El Shenawy"
///     cardUrl: "https://i.ibb.co/233N4k2f/IMG.png"
///     votes: 0
///   player12/
///     name: "Youssef Belamri"
///     cardUrl: "https://i.ibb.co/qMsWx84T/IMG.png"
///     votes: 0
/// ```
///
/// كل كارت **مصمَّم بالكامل** (الاسم/الرقم/المركز مدمج في الصورة) لذلك في الـ UI
/// نعرض الصورة كاملة بدلاً من Avatar دائري + اسم منفصل.
class PastPlayerDto extends Equatable {
  final String id;
  final String name;

  /// رابط كارت اللاعب المصمَّم (FIFA-style). يُقرأ من `cardUrl` بشكل أساسي
  /// مع رجوع آمن إلى `photoUrl` / `image` للتوافق مع أي بيانات قديمة.
  final String? cardUrl;

  final int? number;
  final String? position;
  final int? sort;

  /// عدد الأصوات التراكمي للاعب — يُحدَّث من تصويت نسر المباراة.
  final int votes;

  const PastPlayerDto({
    required this.id,
    required this.name,
    this.cardUrl,
    this.number,
    this.position,
    this.sort,
    this.votes = 0,
  });

  /// alias للتوافق مع الكود السابق الذي كان يستخدم `photoUrl`.
  String? get photoUrl => cardUrl;

  factory PastPlayerDto.fromMap(String id, Map<dynamic, dynamic> m) {
    final card = (m['cardUrl'] ?? m['photoUrl'] ?? m['image'])?.toString();
    final v = m['votes'];
    final votesInt = v is int
        ? v
        : (v is num ? v.toInt() : int.tryParse('${v ?? 0}') ?? 0);

    return PastPlayerDto(
      id: id,
      name: (m['name'] ?? m['arName'] ?? 'لاعب').toString(),
      cardUrl: (card != null && card.isNotEmpty) ? card : null,
      number: m['number'] is int
          ? m['number'] as int
          : int.tryParse('${m['number'] ?? ''}'),
      position: m['position']?.toString(),
      sort: m['sort'] is int
          ? m['sort'] as int
          : int.tryParse('${m['sort'] ?? 0}'),
      votes: votesInt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'cardUrl': cardUrl,
      if (number != null) 'number': number,
      if (position != null) 'position': position,
      if (sort != null) 'sort': sort,
      'votes': votes,
    };
  }

  @override
  List<Object?> get props => [id, name, cardUrl, number, position, votes];
}

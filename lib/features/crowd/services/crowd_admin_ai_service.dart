import 'package:firebase_database/firebase_database.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';

class CrowdAdminAiResponse {
  final String answer;
  final bool actionExecuted;

  const CrowdAdminAiResponse({
    required this.answer,
    this.actionExecuted = false,
  });
}

class CrowdAdminAiService {
  CrowdAdminAiService({
    FirebaseDatabase? database,
    String? apiKey,
  })  : _db = database ?? FirebaseDatabase.instance,
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey ?? AppConfig.geminiApiKey,
        );

  final FirebaseDatabase _db;
  final GenerativeModel _model;

  static const List<String> _badWords = [
    'سب',
    'شتيم',
    'قذر',
    'حمار',
    'غبي',
    'fuck',
    'shit',
    'عرص',
    'خول',
    'متناك',
  ];

  Future<CrowdAdminAiResponse> handlePrompt(String prompt) async {
    final text = prompt.trim();
    if (text.isEmpty) {
      return const CrowdAdminAiResponse(answer: 'اكتب طلبك الأول.');
    }

    final lower = text.toLowerCase();
    if (_matchesBadCommentsCommand(lower)) {
      final report = await _buildBadCommentsReport();
      return CrowdAdminAiResponse(answer: report);
    }
    if (_matchesTopScreensCommand(lower)) {
      final report = await _buildTopScreensReport();
      return CrowdAdminAiResponse(answer: report);
    }
    if (_matchesDeleteReportedVideoCommand(lower)) {
      final result = await _deleteMostReportedVideo();
      return CrowdAdminAiResponse(
        answer: result.$1,
        actionExecuted: result.$2,
      );
    }

    final context = await _buildFastContext();
    final ai = await _askGemini(prompt: text, context: context);
    return CrowdAdminAiResponse(answer: ai);
  }

  bool _matchesBadCommentsCommand(String text) {
    return text.contains('فلتر') &&
        text.contains('تعليق') &&
        (text.contains('خارجة') || text.contains('مسيئة'));
  }

  bool _matchesTopScreensCommand(String text) {
    return text.contains('تقرير') &&
        text.contains('شاش') &&
        (text.contains('زيارة') || text.contains('زياره'));
  }

  bool _matchesDeleteReportedVideoCommand(String text) {
    return text.contains('احذف') &&
        (text.contains('فيديو') || text.contains('ريل')) &&
        (text.contains('ريبورت') || text.contains('بلاغ') || text.contains('reports'));
  }

  Future<String> _buildBadCommentsReport() async {
    final snap = await _db
        .ref('reels')
        .orderByChild('timestamp')
        .limitToLast(150)
        .get();
    if (!snap.exists || snap.value is! Map) {
      return 'لا توجد ريلز حالياً للفحص.';
    }

    int scanned = 0;
    final flagged = <String>[];
    final reels = Map<dynamic, dynamic>.from(snap.value as Map);
    for (final entry in reels.entries) {
      final reelId = entry.key.toString();
      final reel = entry.value;
      if (reel is! Map) continue;
      final comments = reel['comments'];
      if (comments is! Map) continue;

      for (final c in comments.entries) {
        scanned++;
        final raw = c.value;
        if (raw is! Map) continue;
        final text = (raw['text'] ?? raw['comment'] ?? '').toString().toLowerCase();
        if (text.isEmpty) continue;
        if (_badWords.any(text.contains)) {
          flagged.add('ريل $reelId | تعليق ${c.key}: ${text.substring(0, text.length > 45 ? 45 : text.length)}');
          if (flagged.length >= 20) break;
        }
      }
      if (flagged.length >= 20) break;
    }

    if (flagged.isEmpty) {
      return 'تم فحص $scanned تعليق ولم يتم العثور على تعليقات خارجة.';
    }
    return 'تم فحص $scanned تعليق.\nتم رصد ${flagged.length} تعليق محتمل إساءة:\n- ${flagged.join('\n- ')}';
  }

  Future<String> _buildTopScreensReport() async {
    final directSnap = await _db.ref('app_analytics/screen_visits').get();
    if (directSnap.exists && directSnap.value is Map) {
      final map = Map<dynamic, dynamic>.from(directSnap.value as Map);
      final entries = map.entries
          .map((e) => (e.key.toString(), _asInt(e.value)))
          .toList()
        ..sort((a, b) => b.$2.compareTo(a.$2));
      final top = entries.take(5).toList();
      if (top.isEmpty) return 'لا توجد زيارات مسجلة حتى الآن.';
      return 'أكثر الشاشات زيارة:\n- ${top.map((e) => '${e.$1}: ${e.$2}').join('\n- ')}';
    }

    final usersSnap = await _db.ref('users').limitToFirst(250).get();
    if (!usersSnap.exists || usersSnap.value is! Map) {
      return 'لا يوجد data كافي لحساب تقرير الزيارات.';
    }
    final users = Map<dynamic, dynamic>.from(usersSnap.value as Map);
    int profileVisits = 0;
    for (final user in users.values) {
      if (user is! Map) continue;
      final visitors = user['visitors'];
      if (visitors is Map) {
        profileVisits += visitors.length;
      }
    }
    return 'لا يوجد مسار app_analytics/screen_visits حالياً.\nتقرير بديل (Profile visits): $profileVisits زيارة من آخر عينة مستخدمين.';
  }

  Future<(String, bool)> _deleteMostReportedVideo() async {
    final snap = await _db
        .ref('reels')
        .orderByChild('timestamp')
        .limitToLast(200)
        .get();
    if (!snap.exists || snap.value is! Map) {
      return ('لا توجد ريلز للحذف.', false);
    }
    String? targetId;
    int maxReports = 0;
    final reels = Map<dynamic, dynamic>.from(snap.value as Map);
    for (final entry in reels.entries) {
      final map = entry.value;
      if (map is! Map) continue;
      final reportCount = _asInt(map['reportCount']);
      final reportsMap = map['reports'];
      final byMap = reportsMap is Map ? reportsMap.length : 0;
      final total = reportCount > byMap ? reportCount : byMap;
      if (total > maxReports) {
        maxReports = total;
        targetId = entry.key.toString();
      }
    }
    if (targetId == null || maxReports < 3) {
      return ('لا يوجد فيديو عنده بلاغات كافية للحذف (الحد الحالي 3).', false);
    }
    await _db.ref('reels/$targetId').remove();
    return ('تم حذف الفيديو $targetId لأنه يحمل $maxReports بلاغات.', true);
  }

  Future<String> _buildFastContext() async {
    final session = await _db.ref('eagle_nesr/session_current').get();
    final players = await _db.ref('best_player').limitToFirst(60).get();
    final reels = await _db.ref('reels').orderByChild('timestamp').limitToLast(40).get();
    final sessionExists = session.exists;
    final playersCount = players.value is Map ? (players.value as Map).length : 0;
    final reelsCount = reels.value is Map ? (reels.value as Map).length : 0;
    return 'context: sessionExists=$sessionExists, playersCount=$playersCount, recentReelsCount=$reelsCount';
  }

  Future<String> _askGemini({
    required String prompt,
    required String context,
  }) async {
    try {
      final response = await _model.generateContent([
        Content.text(
          'أنت مساعد إداري لتطبيق جماهيري. '
          'قدّم إجابة عربية قصيرة وعملية. '
          'لو الطلب يتطلب حذف/تعديل بيانات، اطلب تأكيد صريح.\n'
          '$context',
        ),
        Content.text(prompt),
      ]);
      return response.text ?? 'لم أستطع توليد رد حالياً.';
    } catch (_) {
      return 'تعذر التواصل مع Gemini حالياً. تحقق من GEMINI_API_KEY.';
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? 0}') ?? 0;
  }
}

import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/core/config/local_secrets_loader.dart';
import 'package:gomhor_alahly_clean_new/core/services/finance_audit_log.dart';
import 'package:gomhor_alahly_clean_new/core/services/gemini/gemini_client.dart';
import 'package:gomhor_alahly_clean_new/features/travel/data/travel_rtdb_paths.dart';
import 'package:gomhor_alahly_clean_new/features/travel/services/travel_cloud_push_trigger.dart';
import 'package:gomhor_alahly_clean_new/features/travel/travel_demo_config.dart';

class CrowdAdminAiResponse {
  final String answer;
  final bool actionExecuted;
  final CrowdAdminAiAction? pendingAction;

  const CrowdAdminAiResponse({
    required this.answer,
    this.actionExecuted = false,
    this.pendingAction,
  });
}

enum CrowdAdminAiActionType {
  deleteMostReportedVideo,
}

class CrowdAdminAiAction {
  final CrowdAdminAiActionType type;
  final String label;

  const CrowdAdminAiAction({
    required this.type,
    required this.label,
  });
}

class CrowdAdminAiService {
  CrowdAdminAiService({
    FirebaseDatabase? database,
    String? apiKey,
  })  : _db = database ?? FirebaseDatabase.instance,
        _client = GeminiClient(
          apiKey: apiKey ?? AppConfig.geminiApiKey,
        );

  final FirebaseDatabase _db;
  GeminiClient _client;
  final List<String> _memory = <String>[];
  CrowdAdminAiAction? _pendingAction;

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
  static const Set<String> _knownPositions = {
    'gk',
    'lb',
    'cb',
    'rb',
    'cm',
    'lw',
    'rw',
    'st',
  };
  static const String _systemInstructions =
      'أنت الشريك التقني لمصطفى رياض ومدير تطبيق زملكاوي. '
      'اتكلم بلهجة زملكاوية مصرية: ذكية، عملية، مختصرة، واستباقية. '
      'دورك تحمي المنصة من المحتوى المسيء وتدعم التوسع حتى 100 ألف مستخدم بأداء ثابت. '
      'أنت فاهم هيكل Realtime Database بالكامل: '
      'reels (فيديوهات/تعليقات/بلاغات/تفاعل)، '
      'best_player (كروت اللاعبين والمراكز والتصويتات)، '
      'motm (تصويت أفضل لاعب في المباراة)، '
      'eagle_nesr (الجلسة الحالية والتجميعات الشهرية/الموسمية)، '
      'users (ملفات المستخدمين والزوار)، app_controls (تفعيل تبويبات التطبيق)، '
      'travel/trips (الترحال: meta/chatSessionActive، meta/closedAt، إشعارات FCM). '
      'لا تكتفي بالرد؛ حلل البيانات واقترح إجراءات عملية مسبقة. '
      'إذا رصدت خطر واضح (بلاغات عالية/تعليقات سامة/هبوط نشاط/بطء أداء) اذكره فوراً واقترح تنفيذ مباشر بصيغة: '
      '"يا مصطفى ... تحب أنفذ؟". '
      'أي حذف أو تعديل بيانات يتطلب تأكيد صريح قبل التنفيذ.';

  Future<CrowdAdminAiResponse> handlePrompt(String prompt) async {
    final text = prompt.trim();
    if (text.isEmpty) {
      return const CrowdAdminAiResponse(answer: 'اكتب طلبك الأول.');
    }

    _remember('user: $text');
    await _ensureGeminiConfigured();
    final lower = text.toLowerCase();

    if (_pendingAction != null && _isConfirmation(lower)) {
      final action = _pendingAction!;
      _pendingAction = null;
      final result = await _executePendingAction(action);
      _remember('assistant: ${result.$1}');
      return CrowdAdminAiResponse(
        answer: result.$1,
        actionExecuted: result.$2,
      );
    }

    if (_matchesProtectTodayCommand(lower)) {
      final report = await _buildProtectionReport();
      _remember('assistant: $report');
      return CrowdAdminAiResponse(answer: report);
    }
    if (_matchesAppStatusCommand(lower)) {
      final report = await _buildDailyAppStatusReport();
      _remember('assistant: $report');
      return CrowdAdminAiResponse(answer: report);
    }
    if (_matchesSentimentCommand(lower)) {
      final report = await _buildSentimentReport();
      _remember('assistant: $report');
      return CrowdAdminAiResponse(answer: report);
    }
    if (_matchesBadCommentsCommand(lower)) {
      final report = await _buildBadCommentsReport();
      _remember('assistant: $report');
      return CrowdAdminAiResponse(answer: report);
    }
    if (_matchesTopScreensCommand(lower)) {
      final report = await _buildTopScreensReport();
      _remember('assistant: $report');
      return CrowdAdminAiResponse(answer: report);
    }
    final platform = await _tryPlatformAdminCommands(text);
    if (platform != null) {
      return platform;
    }
    final requestedPosition = _extractRequestedPosition(lower);
    if (requestedPosition != null) {
      final report = await _buildCardsByPositionReport(requestedPosition);
      _remember('assistant: $report');
      return CrowdAdminAiResponse(answer: report);
    }
    if (_matchesDeleteReportedVideoCommand(lower)) {
      final a = const CrowdAdminAiAction(
        type: CrowdAdminAiActionType.deleteMostReportedVideo,
        label: 'حذف أكثر فيديو عليه بلاغات',
      );
      _pendingAction = a;
      final msg =
          'يا مصطفى، ده إجراء حذف مباشر ومحتاج تأكيد.\n'
          'اضغط "تأكيد التنفيذ" أو اكتب: تأكيد';
      _remember('assistant: $msg');
      return CrowdAdminAiResponse(
        answer: msg,
        pendingAction: a,
      );
    }

    final context = await _buildFastContext();
    final ai = await _askGemini(prompt: text, context: context);
    _remember('assistant: $ai');
    return CrowdAdminAiResponse(answer: ai);
  }

  bool _isConfirmation(String text) {
    return text.contains('تأكيد') ||
        text.contains('اكد') ||
        text.contains('أكد') ||
        text.contains('نفذ') ||
        text.contains('نفّذ') ||
        text.contains('confirm') ||
        text.trim() == 'ok';
  }

  Future<(String, bool)> _executePendingAction(CrowdAdminAiAction action) async {
    switch (action.type) {
      case CrowdAdminAiActionType.deleteMostReportedVideo:
        return _deleteMostReportedVideo();
    }
  }

  Future<String> runSmokeTest() async {
    final rows = <String>[];
    int passed = 0;
    int failed = 0;

    Future<void> runCase(String name, Future<bool> Function() action) async {
      try {
        final ok = await action();
        if (ok) {
          passed++;
          rows.add('✅ $name');
        } else {
          failed++;
          rows.add('❌ $name');
        }
      } catch (e) {
        failed++;
        rows.add('❌ $name (${e.toString()})');
      }
    }

    await runCase('best_player index query (position=st)', () async {
      final snap = await _db
          .ref('best_player')
          .orderByChild('position')
          .equalTo('st')
          .limitToFirst(1)
          .get();
      return snap.value == null || snap.exists;
    });

    await runCase('analytics path readable', () async {
      final snap = await _db.ref('app_analytics/screen_visits').limitToFirst(1).get();
      return snap.value == null || snap.exists;
    });

    await runCase('moderation report paths readable', () async {
      final c = await _db.ref('moderation/comment_report_counts').limitToFirst(1).get();
      final r = await _db.ref('moderation/reel_report_counts').limitToFirst(1).get();
      return (c.value == null || c.exists) && (r.value == null || r.exists);
    });

    await runCase('Gemini connectivity', () async {
      await _ensureGeminiConfigured();
      if (!_client.isConfigured) return false;
      final response = await _client.generateText(userPrompt: 'قل: OK');
      final text = (response ?? '').toLowerCase();
      return text.contains('ok');
    });

    return 'Smoke Test Result: $passed passed / $failed failed\n- ${rows.join('\n- ')}';
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

  bool _matchesSentimentCommand(String text) {
    return (text.contains('sentiment') ||
            text.contains('مشاعر') ||
            text.contains('نبرة') ||
            text.contains('مزاج')) &&
        text.contains('تعليق');
  }

  bool _matchesAppStatusCommand(String text) {
    return text.contains('حالة التطبيق') ||
        text.contains('حاله التطبيق') ||
        text.contains('app status') ||
        (text.contains('التطبيق') && text.contains('النهاردة'));
  }

  bool _matchesProtectTodayCommand(String text) {
    return text.contains('احميني النهاردة') ||
        text.contains('احميني') ||
        text.contains('protect today') ||
        (text.contains('حماية') && text.contains('النهاردة'));
  }

  bool _matchesDeleteReportedVideoCommand(String text) {
    return text.contains('احذف') &&
        (text.contains('فيديو') || text.contains('ريل')) &&
        (text.contains('ريبورت') || text.contains('بلاغ') || text.contains('reports'));
  }

  String? _extractRequestedPosition(String text) {
    if (!(text.contains('كارت') || text.contains('لاعب') || text.contains('مركز') || text.contains('position'))) {
      return null;
    }
    final regex = RegExp(r'\b(gk|lb|cb|rb|cm|cdm|cam|lw|rw|st|cf|ss|rm|lm|rwb|lwb|keeper|goalkeeper|striker|forward)\b');
    final match = regex.firstMatch(text);
    if (match == null) return null;
    return _normalizePosition(match.group(1));
  }

  Future<String> _buildBadCommentsReport() async {
    final indexed = await _buildBadCommentsReportFromIndex();
    if (indexed != null) return indexed;

    final snap = await _db
        .ref('all/reels')
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

  Future<String> _buildSentimentReport() async {
    final snap = await _db
        .ref('all/reels')
        .orderByChild('timestamp')
        .limitToLast(120)
        .get();
    if (!snap.exists || snap.value is! Map) {
      return 'يا مصطفى لسه مفيش بيانات كفاية لتحليل نبرة الجمهور.';
    }
    final reels = Map<dynamic, dynamic>.from(snap.value as Map);
    int scanned = 0;
    int negative = 0;
    int positive = 0;
    int neutral = 0;
    for (final reel in reels.values) {
      if (reel is! Map) continue;
      final comments = reel['comments'];
      if (comments is! Map) continue;
      for (final c in comments.values) {
        if (c is! Map) continue;
        final t = (c['text'] ?? c['comment'] ?? '').toString().toLowerCase().trim();
        if (t.isEmpty) continue;
        scanned++;
        if (_isNegativeComment(t)) {
          negative++;
        } else if (_isPositiveComment(t)) {
          positive++;
        } else {
          neutral++;
        }
      }
    }
    if (scanned == 0) return 'يا مصطفى مفيش تعليقات كفاية لتحليل المشاعر حالياً.';
    final negRate = ((negative * 100) / scanned).toStringAsFixed(1);
    final mood = negative > positive ? 'قلق' : 'متحمس';
    final suggestion = negative > (scanned * 0.35)
        ? 'يا مصطفى النبرة السلبية عالية، تحب أشغّل مراجعة مشددة للتعليقات وأرشّح فيديوهات للحذف؟'
        : 'يا مصطفى الوضع مطمئن، نقدر نزود محتوى تفاعلي عشان نرفع الولاء أكتر.';
    return 'تقرير نبرة الجمهور:\n'
        '- إجمالي تعليقات محللة: $scanned\n'
        '- إيجابي: $positive | محايد: $neutral | سلبي: $negative ($negRate%)\n'
        '- الحالة العامة: $mood\n'
        '- اقتراح: $suggestion';
  }

  Future<String?> _buildBadCommentsReportFromIndex() async {
    final snap = await _db
        .ref('moderation/comment_report_counts')
        .orderByValue()
        .limitToLast(20)
        .get();
    if (!snap.exists || snap.value is! Map) {
      return null;
    }
    final data = Map<dynamic, dynamic>.from(snap.value as Map);
    final entries = data.entries
        .map((e) => (e.key.toString(), _asInt(e.value)))
        .where((e) => e.$2 > 0)
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    if (entries.isEmpty) return 'لا توجد تعليقات مبلّغ عنها حالياً.';
    final top = entries.take(10).toList();
    return 'أعلى التعليقات المبلّغ عنها:\n- ${top.map((e) => '${e.$1}: ${e.$2} بلاغ').join('\n- ')}';
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

    final usersSnap = await _db.ref('users').limitToFirst(100).get();
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
    return 'لا يوجد مسار app_analytics/screen_visits حالياً.\nتقرير بديل سريع (Profile visits): $profileVisits زيارة من عينة 100 مستخدم.';
  }

  Future<String> _buildDailyAppStatusReport() async {
    final usersSnap = await _db.ref('users').limitToFirst(500).get();
    final reelsSnap = await _db
        .ref('all/reels')
        .orderByChild('timestamp')
        .limitToLast(200)
        .get();
    final visitsSnap = await _db.ref('app_analytics/screen_visits').get();
    final reportSnap = await _db.ref('moderation/reel_report_counts').get();
    final perfSnap = await _db.ref('app_analytics/performance').get();

    final usersCount = usersSnap.value is Map ? (usersSnap.value as Map).length : 0;
    final reelsCount = reelsSnap.value is Map ? (reelsSnap.value as Map).length : 0;
    final visitsCount = visitsSnap.value is Map
        ? (visitsSnap.value as Map).values.fold<int>(0, (a, b) => a + _asInt(b))
        : 0;
    final reportCount = reportSnap.value is Map
        ? (reportSnap.value as Map).values.fold<int>(0, (a, b) => a + _asInt(b))
        : 0;

    double avgLatencyMs = 0;
    int highDataSessions = 0;
    if (perfSnap.value is Map) {
      final m = Map<dynamic, dynamic>.from(perfSnap.value as Map);
      avgLatencyMs = (m['avgLatencyMs'] is num) ? (m['avgLatencyMs'] as num).toDouble() : 0;
      highDataSessions = _asInt(m['highDataSessions']);
    }

    final risks = <String>[];
    if (reportCount >= 10) risks.add('بلاغات المحتوى مرتفعة');
    if (avgLatencyMs > 450) risks.add('مؤشر لاج مرتفع (${avgLatencyMs.toStringAsFixed(0)}ms)');
    if (highDataSessions > 50) risks.add('استهلاك بيانات عالي عند شريحة من المستخدمين');
    if (risks.isEmpty) risks.add('لا توجد أعطال حرجة ظاهرة حالياً');

    final advice = (avgLatencyMs > 450 || highDataSessions > 50)
        ? 'يا مصطفى أقترح تفعيل ضغط أقوى للفيديو وتقليل preload للفيد القديم. تحب أطلعلك خطة تنفيذ؟'
        : 'يا مصطفى الأداء مستقر، نقدر نركز على تنمية التفاعل وزيادة المحتوى الآمن.';

    return 'تقرير حالة التطبيق النهاردة:\n'
        '- المستخدمون (عينة): $usersCount\n'
        '- الريلز النشطة (آخر عينة): $reelsCount\n'
        '- إجمالي الزيارات المرصودة: $visitsCount\n'
        '- إجمالي البلاغات: $reportCount\n'
        '- متوسط زمن الاستجابة: ${avgLatencyMs.toStringAsFixed(0)}ms\n'
        '- جلسات استهلاك بيانات عالي: $highDataSessions\n'
        '- المشاكل الحالية: ${risks.join('، ')}\n'
        '- التوصية: $advice';
  }

  Future<String> _buildProtectionReport() async {
    final status = await _buildDailyAppStatusReport();
    final sentiment = await _buildSentimentReport();
    final badComments = await _buildBadCommentsReport();

    final hasHighRisk = status.contains('بلاغات المحتوى مرتفعة') ||
        status.contains('مؤشر لاج مرتفع') ||
        sentiment.contains('النبرة السلبية عالية');

    final action = hasHighRisk
        ? 'يا مصطفى في إشارات خطر واضحة. تحب أبدأ بخطة حماية فورية: (1) مراجعة أعلى البلاغات، (2) ترشيح فيديوهات للحذف، (3) تخفيف preload للفيديوهات؟'
        : 'يا مصطفى الوضع آمن حالياً. تحب أفعّل مراقبة استباقية كل فترة بتقرير مختصر؟';

    return 'تقرير الحماية السريع (احميني النهاردة):\n'
        '--- حالة التطبيق ---\n$status\n\n'
        '--- نبرة الجمهور ---\n$sentiment\n\n'
        '--- ملخص التعليقات المسيئة ---\n$badComments\n\n'
        '--- الإجراء المقترح ---\n$action';
  }

  Future<(String, bool)> _deleteMostReportedVideo() async {
    final indexed = await _deleteMostReportedVideoFromIndex();
    if (indexed != null) return indexed;

    final snap = await _db
        .ref('all/reels')
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
    await _db.ref('all/reels/$targetId').remove();
    return ('تم حذف الفيديو $targetId لأنه يحمل $maxReports بلاغات.', true);
  }

  Future<(String, bool)?> _deleteMostReportedVideoFromIndex() async {
    final snap = await _db
        .ref('moderation/reel_report_counts')
        .orderByValue()
        .limitToLast(1)
        .get();
    if (!snap.exists || snap.value is! Map) {
      return null;
    }
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    if (map.isEmpty) return ('لا توجد فيديوهات مبلّغ عنها حالياً.', false);
    final first = map.entries.first;
    final reelId = first.key.toString();
    final count = _asInt(first.value);
    if (count < 3) {
      return ('لا يوجد فيديو عنده بلاغات كافية للحذف (الحد الحالي 3).', false);
    }
    await _db.ref('all/reels/$reelId').remove();
    await _db.ref('moderation/reel_report_counts/$reelId').remove();
    return ('تم حذف الفيديو $reelId لأنه يحمل $count بلاغات (من مؤشر البلاغات المباشر).', true);
  }

  Future<String> _buildCardsByPositionReport(String requestedPosition) async {
    final snap = await _db
        .ref('best_player')
        .orderByChild('position')
        .equalTo(requestedPosition)
        .limitToFirst(60)
        .get();

    final rows = <(String id, String name, String position)>[];
    if (snap.exists && snap.value is Map) {
      final map = Map<dynamic, dynamic>.from(snap.value as Map);
      for (final e in map.entries) {
        final value = e.value;
        if (value is! Map) continue;
        rows.add((
          e.key.toString(),
          (value['name'] ?? value['arName'] ?? 'لاعب').toString(),
          _normalizePosition(value['position']?.toString()) ?? '',
        ));
      }
    }

    if (rows.isEmpty) {
      final fallback = await _db.ref('best_player').limitToFirst(200).get();
      if (fallback.exists && fallback.value is Map) {
        final map = Map<dynamic, dynamic>.from(fallback.value as Map);
        for (final e in map.entries) {
          final value = e.value;
          if (value is! Map) continue;
          final normalized = _normalizePosition(value['position']?.toString());
          if (normalized == requestedPosition) {
            rows.add((
              e.key.toString(),
              (value['name'] ?? value['arName'] ?? 'لاعب').toString(),
              normalized!,
            ));
          }
        }
      }
    }

    if (rows.isEmpty) {
      return 'لا توجد كروت مطابقة للمركز ${requestedPosition.toUpperCase()} حالياً.';
    }

    return 'الكروت المطابقة لمركز ${requestedPosition.toUpperCase()} (${rows.length}):\n- ${rows.map((e) => '${e.$2} (${e.$1})').join('\n- ')}';
  }

  Future<String> _buildFastContext() async {
    final session = await _db.ref('eagle_nesr/session_current').get();
    final players = await _db.ref('best_player').limitToFirst(60).get();
    final reels = await _db.ref('all/reels').orderByChild('timestamp').limitToLast(40).get();
    final users = await _db.ref('users').limitToFirst(200).get();
    final motm = await _db.ref('motm').limitToFirst(50).get();
    final reports = await _db.ref('moderation/reel_report_counts').get();
    final sessionExists = session.exists;
    final playersCount = players.value is Map ? (players.value as Map).length : 0;
    final reelsCount = reels.value is Map ? (reels.value as Map).length : 0;
    final usersCount = users.value is Map ? (users.value as Map).length : 0;
    final motmSessions = motm.value is Map ? (motm.value as Map).length : 0;
    final reportsCount = reports.value is Map
        ? (reports.value as Map).values.fold<int>(0, (a, b) => a + _asInt(b))
        : 0;
    final memory = _memory.isEmpty ? 'none' : _memory.join(' || ');
    return 'project_context:\n'
        '- schema: reels, best_player, motm, eagle_nesr, users\n'
        '- sessionExists=$sessionExists\n'
        '- playersCount=$playersCount\n'
        '- recentReelsCount=$reelsCount\n'
        '- sampledUsersCount=$usersCount\n'
        '- motmSessions=$motmSessions\n'
        '- totalReportedReels=$reportsCount\n'
        '- conversation_memory=$memory';
  }

  Future<void> _ensureGeminiConfigured() async {
    if (_client.isConfigured) return;
    try {
      final m = await loadLocalSecretsMap();
      final k = m['GEMINI_API_KEY'];
      if (k != null && k.isNotEmpty) {
        _client = GeminiClient(apiKey: k);
      }
    } catch (_) {}
  }

  Future<CrowdAdminAiResponse?> _tryPlatformAdminCommands(String raw) async {
    final fee = _parsePlatformFeePercent(raw);
    if (fee != null) {
      try {
        await _db.ref('marketplace/settings/platformFeePercent').set(fee);
        FinanceAuditLog.record('marketplace_ai', {'platformFeePercent': fee});
        _remember('assistant: marketplace fee $fee');
        return CrowdAdminAiResponse(
          answer:
              'تم تعيين عمولة المنصة في marketplace/settings/platformFeePercent = $fee٪ (يُستوحى من واجهة المتجر لاحقاً).',
          actionExecuted: true,
        );
      } catch (e) {
        return CrowdAdminAiResponse(
          answer: 'تعذر حفظ العمولة: $e',
        );
      }
    }

    final ac = _parseAppControlToggle(raw);
    if (ac != null) {
      try {
        await _db.ref('app_controls').update(ac);
        FinanceAuditLog.record('app_controls_ai', {
          'updates': ac.map((k, v) => MapEntry(k, v.toString())),
        });
        _remember('assistant: app_controls $ac');
        final lines = ac.entries.map((e) => '• ${e.key} → ${e.value}').join('\n');
        return CrowdAdminAiResponse(
          answer: 'تم تحديث أقسام التطبيق:\n$lines',
          actionExecuted: true,
        );
      } catch (e) {
        return CrowdAdminAiResponse(answer: 'تعذر تحديث app_controls: $e');
      }
    }

    return _parseTravelAdminCommand(raw);
  }

  int? _parsePlatformFeePercent(String raw) {
    final t = raw.toLowerCase();
    if (!t.contains('عمولة')) return null;
    final m = RegExp(r'عمولة(?:\s*المنصة)?\s*(\d{1,2})\s*%?').firstMatch(t);
    if (m == null) return null;
    final v = int.tryParse(m.group(1)!);
    if (v == null || v < 0 || v > 60) return null;
    return v;
  }

  Map<String, Object>? _parseAppControlToggle(String raw) {
    final t = raw.toLowerCase();
    final hasEnable = RegExp(
            r'فعّل|فعل|شغّل|شغل|افتح|تشغيل|enable|تفعيل|شغّلى')
        .hasMatch(t);
    final hasDisable = RegExp(
            r'عطل|عطّل|أوقف|اوقف|وقف|تعطيل|disable|إيقاف|ايقاف|أوقفوا')
        .hasMatch(t);
    if (hasEnable == hasDisable) return null;

    String? key;
    if (t.contains('ترحال') || t.contains('رحلات')) {
      key = 'travelEnabled';
    } else if (t.contains('ريل')) {
      key = 'reelsEnabled';
    } else if (t.contains('متجر') || t.contains('سوق')) {
      key = 'storeEnabled';
    } else if (t.contains('جمهور') || t.contains('نسر')) {
      key = 'crowdEnabled';
    } else if (t.contains('حساب') || t.contains('بروفايل') || t.contains('profile')) {
      key = 'profileEnabled';
    }
    if (key == null) return null;
    return {key: hasEnable};
  }

  Future<CrowdAdminAiResponse?> _parseTravelAdminCommand(String raw) async {
    final t = raw.toLowerCase();
    final tripId = RegExp(r'trip_[a-z0-9_]+').firstMatch(t)?.group(0) ??
        kTravelDefaultAdminTripId;

    final openChat = t.contains('شات') &&
        (t.contains('فتح') ||
            t.contains('شغل') ||
            t.contains('شغّل') ||
            t.contains('تشغيل'));
    final busMove = (t.contains('حافلة') ||
            t.contains('حافله') ||
            t.contains('باص')) &&
        (t.contains('تحرك') ||
            t.contains('انطلق') ||
            t.contains('تحركت') ||
            t.contains('مغادرة') ||
            t.contains('انطلقت'));
    final closeTrip = t.contains('إغلاق الرحلة') ||
        t.contains('اغلاق الرحلة') ||
        t.contains('أغلق الرحلة') ||
        t.contains('اغلق الرحلة') ||
        (t.contains('اغلق') && t.contains('رحلة')) ||
        (t.contains('أغلق') && t.contains('رحلة'));

    try {
      if (openChat) {
        final tripRef = _db.ref(TravelRtdbPaths.trip(tripId));
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await tripRef.child('meta/chatSessionActive').set(true);
        await tripRef.child('meta/chatOpenedAt').set(nowMs);
        await triggerTravelTripPush(tripId: tripId, type: 'chat_open');
        FinanceAuditLog.record('travel_ai', {
          'action': 'open_chat',
          'tripId': tripId,
        });
        _remember('assistant: travel open_chat $tripId');
        return CrowdAdminAiResponse(
          answer:
              'تم فتح شات الرحلة $tripId وإرسال إشعار chat_open للمشتركين (topic).',
          actionExecuted: true,
        );
      }
      if (busMove) {
        final tripRef = _db.ref(TravelRtdbPaths.trip(tripId));
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        await tripRef.child('meta/lastBusDepartureAt').set(nowMs);
        await triggerTravelTripPush(tripId: tripId, type: 'bus_move');
        FinanceAuditLog.record('travel_ai', {
          'action': 'bus_move',
          'tripId': tripId,
        });
        _remember('assistant: travel bus_move $tripId');
        return CrowdAdminAiResponse(
          answer:
              'تم إعلان تحرك الحافلة لرحلة $tripId وإرسال إشعار bus_move.',
          actionExecuted: true,
        );
      }
      if (closeTrip) {
        final nowIso = DateTime.now().toIso8601String();
        await _db.ref(TravelRtdbPaths.tripMetaClosedAt(tripId)).set(nowIso);
        FinanceAuditLog.record('travel_ai', {
          'action': 'close_trip',
          'tripId': tripId,
        });
        _remember('assistant: travel close $tripId');
        return CrowdAdminAiResponse(
          answer:
              'تم إغلاق الرحلة $tripId (تم ضبط meta/closedAt). راجع لوحة الترحال للتحقق.',
          actionExecuted: true,
        );
      }
    } catch (e) {
      return CrowdAdminAiResponse(
        answer: 'تعذر تنفيذ أمر الترحال: $e',
      );
    }
    return null;
  }

  Future<String> _askGemini({
    required String prompt,
    required String context,
  }) async {
    try {
      await _ensureGeminiConfigured();
      if (!_client.isConfigured) {
        return 'تعذر التواصل مع Gemini حالياً. تحقق من GEMINI_API_KEY.';
      }
      final text = await _client.generateText(
        userPrompt: prompt,
        systemPrompt: '$_systemInstructions\n$context',
      );
      return text ?? 'لم أستطع توليد رد حالياً.';
    } catch (_) {
      return 'تعذر التواصل مع Gemini حالياً. تحقق من GEMINI_API_KEY.';
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? 0}') ?? 0;
  }

  String? _normalizePosition(String? raw) {
    final p = (raw ?? '').trim().toLowerCase();
    if (p.isEmpty) return null;
    if (p == 'goalkeeper' || p == 'keeper' || p == 'gk') return 'gk';
    if (p == 'left back' || p == 'lb' || p == 'lwb') return 'lb';
    if (p.startsWith('cb') || p.contains('center back') || p.contains('centre back') || p == 'defender') {
      return 'cb';
    }
    if (p == 'right back' || p == 'rb' || p == 'rwb') return 'rb';
    if (p.startsWith('cm') || p == 'midfielder' || p == 'cdm' || p == 'cam') return 'cm';
    if (p == 'left wing' || p == 'lw' || p == 'lm') return 'lw';
    if (p == 'right wing' || p == 'rw' || p == 'rm') return 'rw';
    if (p == 'st' || p == 'striker' || p == 'forward' || p == 'cf' || p == 'ss') return 'st';
    if (_knownPositions.contains(p)) return p;
    return _fuzzyPosition(p);
  }

  String? _fuzzyPosition(String p) {
    final aliases = <String, String>{
      'goal keeper': 'gk',
      'golkeeper': 'gk',
      'golkiper': 'gk',
      'righ wing': 'rw',
      'left winger': 'lw',
      'strker': 'st',
      'cenetr back': 'cb',
      'midfild': 'cm',
      'ليفت باك': 'lb',
      'رايت باك': 'rb',
      'جول كيبر': 'gk',
      'سترايكر': 'st',
    };
    if (aliases.containsKey(p)) return aliases[p];
    String? best;
    var bestDistance = 99;
    for (final pos in _knownPositions) {
      final d = _editDistance(p, pos);
      if (d < bestDistance) {
        bestDistance = d;
        best = pos;
      }
    }
    return bestDistance <= 2 ? best : null;
  }

  int _editDistance(String a, String b) {
    final dp = List.generate(a.length + 1, (_) => List<int>.filled(b.length + 1, 0));
    for (var i = 0; i <= a.length; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
    }
    return dp[a.length][b.length];
  }

  bool _isNegativeComment(String text) {
    if (_badWords.any(text.contains)) return true;
    const extra = ['مقرف', 'سيء', 'ضعيف', 'فاشل', 'trash', 'worst', 'bad'];
    return extra.any(text.contains);
  }

  bool _isPositiveComment(String text) {
    const good = ['جامد', 'عاش', 'برافو', 'عظمة', 'ممتاز', 'great', 'top', 'وحش'];
    return good.any(text.contains);
  }

  void _remember(String entry) {
    _memory.add(entry);
    if (_memory.length > 10) {
      _memory.removeAt(0);
    }
  }
}

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:gomhor_alahly_clean_new/main.dart' as app;

class AiAssistantService {
  static const String _systemPrompt = '''أنت مساعد ذكي متخصص في النادي الأهلي المصري. 
تجيب على جميع الأسئلة المتعلقة بـ:
- تاريخ النادي الأهلي وإنجازاته (41 بطولة محلية، 8 بطولات إفريقية)
- إحصائيات اللاعبين والفريق الحالي
- مواعيد المباريات والنتائج السابقة
- أسطورة النادي والمدربين الكبار
- معلومات عن الملعب والجماهير

كن ودياً وحماسياً في الإجابات، واستخدم كلمات تشجيعية. إذا لم تعرف الإجابة، قل "أنا لا أملك هذه المعلومة الآن، لكن يمكنك البحث عنها في الموقع الرسمي للنادي."
''';

  static late GenerativeModel _model;
  static bool _initialized = false;

  /// تهيئة خدمة الـ AI
  static void initialize([String? apiKey]) {
    if (!_initialized) {
      final key = apiKey ?? app.GEMINI_API_KEY;
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: key,
      );
      _initialized = true;
    }
  }

  /// تهيئة تلقائية باستخدام المفتاح من main.dart
  static void initializeAuto() {
    initialize(app.GEMINI_API_KEY);
  }

  /// جلب إجابة ذكية من Gemini
  static Future<String> getSmartAnswer(String userQuery) async {
    try {
      if (!_initialized) {
        return "عذراً، لم تتم تهيئة خدمة الـ AI. يرجى المحاولة لاحقاً.";
      }

      final content = [
        Content.text(_systemPrompt),
        Content.text(userQuery),
      ];

      final response = await _model.generateContent(content);
      
      return response.text ?? "عذراً، لم أستطع الإجابة على سؤالك.";
    } catch (e) {
      print('خطأ في AI Assistant: $e');
      return "حدث خطأ في الاتصال. يرجى المحاولة لاحقاً.";
    }
  }

  /// البحث عن لاعب معين وإرجاع معلومات عنه
  static Future<String> searchPlayer(String playerName) async {
    final query = "أخبرني عن لاعب النادي الأهلي $playerName. ما هي إحصائياته وإنجازاته؟";
    return await getSmartAnswer(query);
  }

  /// الحصول على معلومات عن مباراة قادمة
  static Future<String> getMatchInfo(String opponent) async {
    final query = "ما هي معلومات المباراة القادمة للأهلي ضد $opponent؟ متى موعدها وأين ستقام؟";
    return await getSmartAnswer(query);
  }

  /// الحصول على إحصائيات النادي
  static Future<String> getAhlyStats() async {
    const query = "أخبرني عن إحصائيات النادي الأهلي الشاملة (البطولات، الألقاب، أفضل اللاعبين)";
    return await getSmartAnswer(query);
  }

  /// الحصول على تنبيهات وأخبار مهمة
  static Future<String> getImportantNews() async {
    const query = "ما هي أهم الأخبار والتطورات الحالية في النادي الأهلي؟";
    return await getSmartAnswer(query);
  }

  /// تحليل أداء اللاعب
  static Future<String> analyzePlayerPerformance(String playerName) async {
    final query = "قم بتحليل أداء اللاعب $playerName في آخر 5 مباريات. ما هي نقاط القوة والضعف؟";
    return await getSmartAnswer(query);
  }
}

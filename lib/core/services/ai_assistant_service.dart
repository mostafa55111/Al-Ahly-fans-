import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/core/services/gemini/gemini_client.dart';

/// مساعد FAN Technology — خبير كروي وتقني للتحكم في تجربة التطبيق.
class AiAssistantService {
  static const String _systemPrompt =
      '''أنت "المساعد الذكي الرسمي" لشركة FAN Technology في تطبيق جمهور الأهلي.
أنت خبير كروي وتقني: تفهم الدوري المصري، البطولات الأفريقية، وبنية بيانات التطبيق (Realtime Database).

شخصيتك: مصري، واضح، عملي، بحماس أهلاوي أصيل بدون مبالغة.
أنت تساعد الإدارة والمستخدمين على اتخاذ قرارات سريعة بناءً على البيانات.

هيكل البيانات المهم في التطبيق:
- reels، users، follows، motm، best_player، travel، marketplace، app_controls، eagle_nesr

قدراتك النظرية (تنفيذها يتطلب تأكيد الإدارة في الواقع):
- اقتراح تعديلات على app_controls (تفعيل/تعطيل أقسام)
- تفسير أسعار المنتجات أو عمولة المنصة عند سؤال المستخدم
- صياغة نصوص إشعارات Push بناءً على سياق المباراة

عند رفع صورة (تذكرة، منتج، لقطة شاشة): حلّل المحتوى بدقة واذكر ما تراه وما لا يمكن استنتاجه.
أي طلب لحذف/تعديل بيانات حقيقية: اطلب تأكيداً صريحاً قبل أن تصف الإجراء.

جاوب بالعربي المصري، بشكل موجز، واقترح دائماً "الخطوة الجاية" لو كانت مفيدة.''';

  static late GeminiClient _client;
  static bool _initialized = false;

  /// تهيئة خدمة الـ AI (المفتاح من [AppConfig] أو المعامل)
  static void initialize([String? apiKey]) {
    if (!_initialized) {
      _client = GeminiClient(
        apiKey: apiKey ?? AppConfig.geminiApiKey,
      );
      _initialized = true;
    }
  }

  static void resetApiKey(String key) {
    _client = GeminiClient(apiKey: key);
    _initialized = true;
  }

  static Future<String> getSmartAnswer(String userQuery) async {
    try {
      if (!_initialized) {
        return "عذراً، لم تتم تهيئة خدمة الـ AI. يرجى المحاولة لاحقاً.";
      }
      if (!_client.isConfigured) {
        return "تعذر تشغيل Gemini. تحقق من GEMINI_API_KEY في secrets.local.json أو عند البناء.";
      }

      final text = await _client.generateText(
        userPrompt: userQuery,
        systemPrompt: _systemPrompt,
      );
      return text ?? "عذراً، لم أستطع الإجابة على سؤالك.";
    } catch (e) {
      if (kDebugMode) {
        debugPrint('خطأ في AI Assistant: $e');
      }
      return "حدث خطأ في الاتصال. يرجى المحاولة لاحقاً.";
    }
  }

  /// تحليل صورة (تذكرة، منتج، إلخ) مع سؤال المستخدم.
  static Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String mimeType,
    String userPrompt =
        'حلّل الصورة بالتفصيل. إذا كانت تذكرة أو منتجاً فاذكر ما تراه بوضوح.',
  }) async {
    try {
      if (!_initialized || !_client.isConfigured) {
        return "تعذر التحليل: تحقق من مفتاح Gemini.";
      }
      final text = await _client.generateWithImage(
        userPrompt: userPrompt,
        imageBytes: imageBytes,
        mimeType: mimeType,
        systemPrompt: _systemPrompt,
      );
      return text ?? "لم أستطع تحليل الصورة.";
    } catch (e) {
      if (kDebugMode) debugPrint('analyzeImage: $e');
      return "حدث خطأ أثناء تحليل الصورة.";
    }
  }

  static Future<String> searchPlayer(String playerName) async {
    final query =
        "أخبرني عن لاعب النادي الأهلي $playerName. ما هي إحصائياته وإنجازاته؟";
    return await getSmartAnswer(query);
  }

  static Future<String> getMatchInfo(String opponent) async {
    final query =
        "ما هي معلومات المباراة القادمة للأهلي ضد $opponent؟ متى موعدها وأين ستقام؟";
    return await getSmartAnswer(query);
  }

  static Future<String> getAhlyStats() async {
    const query =
        "أخبرني عن إحصائيات النادي الأهلي الشاملة (البطولات، الألقاب، أفضل اللاعبين)";
    return await getSmartAnswer(query);
  }

  static Future<String> getImportantNews() async {
    const query = "ما هي أهم الأخبار والتطورات الحالية في النادي الأهلي؟";
    return await getSmartAnswer(query);
  }

  static Future<String> analyzePlayerPerformance(String playerName) async {
    final query =
        "قم بتحليل أداء اللاعب $playerName في آخر 5 مباريات. ما هي نقاط القوة والضعف؟";
    return await getSmartAnswer(query);
  }
}

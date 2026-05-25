import 'package:gomhor_alahly_clean_new/core/services/gemini/gemini_client.dart';
import 'package:gomhor_alahly_clean_new/features/travel/domain/models/travel_trip_model.dart';

class TravelAiAssistantService {
  TravelAiAssistantService({GeminiClient? client})
      : _client = client ?? GeminiClient();

  final GeminiClient _client;

  bool get isConfigured => _client.isConfigured;

  Future<String> askTripAssistant({
    required String governorateName,
    required List<TravelTripModel> trips,
    required String userQuestion,
  }) async {
    if (!_client.isConfigured) {
      return 'تعذر تشغيل Gemini. تأكد من ضبط GEMINI_API_KEY.';
    }

    final q = userQuestion.trim();
    if (q.isEmpty) {
      return 'اكتب سؤالك الأول عن الرحلة وسأساعدك فورًا.';
    }

    final tripsSummary = trips
        .map(
          (t) =>
              '- شركة: ${t.companyName} | مواصلات: ${t.transportType} | السعر: ${t.priceEgp} ج | '
              'سعة: ${t.capacity} | متبقي: ${(t.capacity - t.bookedCount).clamp(0, t.capacity)} | '
              'ممتلئ: ${t.isFull ? "نعم" : "لا"} | التجمع: ${_fmt(t.departureAt)}',
        )
        .join('\n');

    final prompt = '''
المحافظة: $governorateName
الرحلات المتاحة:
$tripsSummary

سؤال المشجع:
$q
''';

    final answer = await _client.generateText(
      systemPrompt:
          'أنت مساعد ترحال لمشجعي الأهلي. رد بالمصري بشكل عملي وقصير. '
          'اعتمد فقط على بيانات الرحلات المتاحة في الرسالة. '
          'لو السؤال خارج البيانات، وضّح ده واقترح أفضل خيار متاح.',
      userPrompt: prompt,
    );

    return (answer ?? '').trim().isEmpty
        ? 'مش قادر أجاوب حاليًا، جرّب مرة تانية بعد لحظات.'
        : answer!.trim();
  }

  Future<bool> runConnectivityCheck() async {
    if (!_client.isConfigured) return false;
    final text = await _client.generateText(userPrompt: 'رد بكلمة: OK');
    return (text ?? '').toLowerCase().contains('ok');
  }

  String _fmt(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

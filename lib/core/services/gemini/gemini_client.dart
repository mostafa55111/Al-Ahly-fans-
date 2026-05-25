import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';

class GeminiClient {
  GeminiClient({
    String? apiKey,
    String? modelName,
    GenerationConfig? generationConfig,
  })  : _apiKey = (apiKey ?? AppConfig.geminiApiKey).trim(),
        _modelName = (modelName ?? AppConfig.geminiModelName).trim(),
        _generationConfig = generationConfig;

  final String _apiKey;
  final String _modelName;
  final GenerationConfig? _generationConfig;

  bool get isConfigured => _apiKey.isNotEmpty && _modelName.isNotEmpty;

  GenerativeModel _model({String? systemPrompt}) {
    return GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: _generationConfig,
      systemInstruction:
          systemPrompt != null && systemPrompt.trim().isNotEmpty
              ? Content.system(systemPrompt.trim())
              : null,
    );
  }

  Future<String?> generateText({
    required String userPrompt,
    String? systemPrompt,
    List<Content>? history,
  }) async {
    final model = _model(systemPrompt: systemPrompt);
    final content = <Content>[
      ...?history,
      Content('user', [TextPart(userPrompt)]),
    ];
    final res = await model.generateContent(content);
    return res.text;
  }

  /// تحليل صورة (تذكرة، منتج، لقطة شاشة) مع السؤال النصي.
  Future<String?> generateWithImage({
    required String userPrompt,
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String? systemPrompt,
  }) async {
    final model = _model(systemPrompt: systemPrompt);
    final res = await model.generateContent([
      Content('user', [
        TextPart(userPrompt),
        DataPart(mimeType, imageBytes),
      ]),
    ]);
    return res.text;
  }
}

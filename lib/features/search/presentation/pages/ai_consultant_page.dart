import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/core/services/ai_assistant_service.dart';
import 'package:gomhor_alahly_clean_new/core/services/fan_memory_cache_service.dart';
import 'package:gomhor_alahly_clean_new/core/time/time_service.dart';

class AIConsultantPage extends StatefulWidget {
  const AIConsultantPage({
    super.key,
    this.initialContextTag,
  });

  final String? initialContextTag;

  @override
  State<AIConsultantPage> createState() => _AIConsultantPageState();
}

class _AIConsultantPageState extends State<AIConsultantPage> {
  final _q = TextEditingController();
  String _provider = 'gemini';
  bool _loading = false;
  String _answer = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  String _systemPrompt() {
    final club = AppConfig.reelsFirestoreClubTag;
    final time = getIt<TimeService>().context;
    final uid = getIt<FirebaseAuth>().currentUser?.uid ?? '';
    final memory = getIt<FanMemoryCacheService>();
    final favs =
        uid.isEmpty ? <String>[] : memory.favoritePlayers(uid);
    final hints =
        uid.isEmpty ? <String>[] : memory.marketplaceKeywords(uid);
    final favLine =
        favs.isEmpty ? '' : 'اهتمامات المستخدم (لاعبون مفضلون): ${favs.join(', ')}.';
    final hintLine =
        hints.isEmpty ? '' : 'إشارات سلوكية (رياضيات بسيطة): ${hints.join(', ')}.';
    final contextLine = (widget.initialContextTag == null || widget.initialContextTag!.trim().isEmpty)
        ? ''
        : 'السياق الحالي للمستخدم داخل التطبيق: ${widget.initialContextTag}. ركّز إجابتك على هذا السياق أولاً.';
    return '''
أنت خبير كروي منتمي لنادي ${club == 'ahly' ? 'الأهلي' : 'الزمالك'}.
تكلم بالعربية المصرية المختصرة، وقدم 3 نقاط عملية دائمًا.
السياق الزمني الحالي في القاهرة: ${time.cairoNow}.
نمط الجلسة: ${time.moment.name}.
$favLine
$hintLine
$contextLine
إذا كان السؤال عن بيانات/أسعار/إشعارات فاعرض الحل كمخطط تنفيذ تقني.
''';
  }

  Future<void> _ask() async {
    final query = _q.text.trim();
    if (query.isEmpty || _loading) return;
    if (_provider == 'openai') {
      setState(() {
        _answer =
            'مسار OpenAI مُهيأ في الواجهة؛ بعد إضافة المفتاح والعميل سيتم التوجيه هنا بدل Gemini.';
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final finalPrompt = '${_systemPrompt()}\n\nسؤال المستخدم:\n$query';
      final response = await AiAssistantService.getSmartAnswer(finalPrompt);
      if (!mounted) return;
      setState(() => _answer = response);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Consultant')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('المزوّد:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _provider,
                  items: const [
                    DropdownMenuItem(value: 'gemini', child: Text('Gemini')),
                    DropdownMenuItem(value: 'openai', child: Text('OpenAI (ready)')),
                  ],
                  onChanged: _loading
                      ? null
                      : (v) {
                          if (v != null) setState(() => _provider = v);
                        },
                ),
              ],
            ),
            TextField(
              controller: _q,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'اسأل المحلل الكروي الذكي...',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _ask,
              child: Text(_loading ? 'جاري التحليل...' : 'إرسال'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(_answer.isEmpty ? 'النتيجة ستظهر هنا.' : _answer),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

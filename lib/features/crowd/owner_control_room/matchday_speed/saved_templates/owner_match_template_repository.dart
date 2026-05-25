import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_match_template.dart';

abstract class OwnerMatchTemplateRepository {
  Stream<List<OwnerMatchTemplate>> watchTemplates(String appId);

  Future<void> upsertTemplate({
    required String appId,
    required OwnerMatchTemplate template,
  });

  Future<void> markUsed(String appId, String templateId);

  Future<void> removeTemplate(String appId, String templateId);
}

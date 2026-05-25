import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_match_template.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_match_template_paths.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_match_template_repository.dart';

class OwnerMatchTemplateRepositoryRtdb implements OwnerMatchTemplateRepository {
  OwnerMatchTemplateRepositoryRtdb(this._db);

  final FirebaseDatabase _db;

  List<OwnerMatchTemplate> _parse(DataSnapshot snap, String appId) {
    if (!snap.exists || snap.value is! Map) return const [];
    final m = Map<dynamic, dynamic>.from(snap.value! as Map);
    final list = <OwnerMatchTemplate>[];
    m.forEach((k, v) {
      if (k.toString().isEmpty || v is! Map) return;
      final t = OwnerMatchTemplate.fromMap(
        k.toString(),
        Map<dynamic, dynamic>.from(v),
      );
      list.add(t.appId.isEmpty ? OwnerMatchTemplate(
        id: t.id,
        name: t.name,
        formation: t.formation,
        starters: t.starters,
        bench: t.bench,
        createdAt: t.createdAt,
        lastUsedAt: t.lastUsedAt,
        appId: appId,
      ) : t);
    });
    list.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return list;
  }

  @override
  Stream<List<OwnerMatchTemplate>> watchTemplates(String appId) {
    return _db.ref(OwnerMatchTemplatePaths.root(appId)).onValue.map((e) {
      return _parse(e.snapshot, appId);
    });
  }

  @override
  Future<void> upsertTemplate({
    required String appId,
    required OwnerMatchTemplate template,
  }) async {
    await _db
        .ref(OwnerMatchTemplatePaths.template(appId, template.id))
        .set(template.toWriteMap());
  }

  @override
  Future<void> markUsed(String appId, String templateId) async {
    await _db
        .ref('${OwnerMatchTemplatePaths.template(appId, templateId)}/lastUsedAt')
        .set(DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<void> removeTemplate(String appId, String templateId) async {
    await _db.ref(OwnerMatchTemplatePaths.template(appId, templateId)).remove();
  }
}

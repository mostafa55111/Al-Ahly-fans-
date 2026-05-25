import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_session_template.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/match_votes_admin_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_match_template.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_match_template_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/session_drafts/owner_session_draft.dart';

/// إطلاق سريع من قالب أو مسودة — بدون إعادة بناء يدوي.
class QuickLaunchService {
  QuickLaunchService({
    required OwnerMatchTemplateRepository templates,
  }) : _templates = templates;

  final OwnerMatchTemplateRepository _templates;

  Future<void> applyTemplate({
    required MatchVotesAdminCubit cubit,
    required OwnerMatchTemplate template,
    required String appId,
  }) async {
    final stadiumTemplate = StadiumSessionTemplate(
      id: template.id,
      name: template.name,
      formation: template.formation,
      lineupSlots: template.allSlots,
      updatedAt: template.lastUsedAt,
    );
    await cubit.applySessionTemplate(stadiumTemplate);
    await _templates.markUsed(appId, template.id);
  }

  Future<void> applyDraft({
    required MatchVotesAdminCubit cubit,
    required OwnerSessionDraft draft,
  }) async {
    final stadiumTemplate = StadiumSessionTemplate(
      id: draft.id,
      name: 'مسودة ${draft.id.substring(0, 6)}',
      formation: draft.formation,
      lineupSlots: [...draft.lineup, ...draft.bench],
      updatedAt: draft.updatedAt,
    );
    await cubit.applySessionTemplate(stadiumTemplate);
  }
}

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/vote_confirmation_sheet.dart';

/// تأكيد التصويت — يفوّض إلى bottom sheet سينمائي (نفس العقد العام).
Future<bool> showMatchVoteConfirmationDialog(
  BuildContext context, {
  required String playerName,
}) {
  return showMatchVoteConfirmationSheet(context, playerName: playerName);
}

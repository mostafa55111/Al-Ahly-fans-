import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/control_room_theme.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/models/owner_card_record.dart';

class OwnerCardTile extends StatelessWidget {
  const OwnerCardTile({
    super.key,
    required this.card,
    required this.theme,
    this.onDelete,
    this.onUsePitch,
    this.onUseBench,
  });

  final OwnerCardRecord card;
  final ControlRoomTheme theme;
  final VoidCallback? onDelete;
  final VoidCallback? onUsePitch;
  final VoidCallback? onUseBench;

  @override
  Widget build(BuildContext context) {
    final img = card.thumbnailUrl.isNotEmpty ? card.thumbnailUrl : card.imageUrl;
    return Container(
      width: 132,
      decoration: theme.panelDecoration(radius: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 62 / 86,
            child: img.isEmpty
                ? ColoredBox(
                    color: theme.surfaceElevated,
                    child: Icon(Icons.person, color: theme.secondaryText),
                  )
                : Image.network(img, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.primaryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${card.position}${card.playerNumber > 0 ? ' · ${card.playerNumber}' : ''}',
                  style: TextStyle(color: theme.secondaryText, fontSize: 10),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (onUsePitch != null)
                      _chip('أساسي', onUsePitch!),
                    if (onUseBench != null) ...[
                      const SizedBox(width: 4),
                      _chip('بديل', onUseBench!),
                    ],
                    const Spacer(),
                    if (onDelete != null)
                      InkWell(
                        onTap: onDelete,
                        child: Icon(Icons.delete_outline, size: 16, color: theme.secondaryText),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: theme.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: theme.identity.primaryColor,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

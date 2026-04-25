import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:gomhor_alahly_clean_new/features/matches/data/models/lineup.dart';

/// كارت لاعب لتصويت رجل المباراة.
/// ‣ بيعرض الصورة + الرقم + الاسم + المركز + شريط النسبة المئوية.
/// ‣ بيتلوّن لما المستخدم يصوّت له.
class MotmPlayerCard extends StatelessWidget {
  final LineupPlayer player;
  final int votes;
  final int totalVotes;
  final bool isMyVote;
  final bool isWinner;
  final bool enabled;
  final VoidCallback onTap;

  const MotmPlayerCard({
    super.key,
    required this.player,
    required this.votes,
    required this.totalVotes,
    required this.onTap,
    this.isMyVote = false,
    this.isWinner = false,
    this.enabled = true,
  });

  static const Color _ahlyRed = Color(0xFFE30613);
  static const Color _ahlyGold = Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    final pct = totalVotes > 0 ? (votes / totalVotes) : 0.0;
    final borderColor = isWinner
        ? _ahlyGold
        : isMyVote
            ? _ahlyRed
            : Colors.white12;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: isMyVote || isWinner ? 2 : 1),
            boxShadow: isWinner
                ? [
                    BoxShadow(
                      color: _ahlyGold.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_ahlyRed, Color(0xFF7A0000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: player.photoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: player.photoUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFF1F1F1F),
                                child: const Icon(Icons.person,
                                    color: Colors.white24, size: 40),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF1F1F1F),
                              child: const Icon(Icons.person,
                                  color: Colors.white24, size: 40),
                            ),
                    ),
                  ),
                  if (player.number != null)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _ahlyGold,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF0A0A0A), width: 2),
                        ),
                        child: Text(
                          '${player.number}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  if (isWinner)
                    Positioned(
                      top: -8,
                      left: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: _ahlyGold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events,
                            color: Colors.black, size: 14),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                player.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              if (player.position != null && player.position!.isNotEmpty)
                Text(
                  player.position!,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct.clamp(0, 1),
                  minHeight: 5,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isMyVote ? _ahlyRed : _ahlyGold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                totalVotes == 0
                    ? '0 صوت'
                    : '${(pct * 100).toStringAsFixed(0)}% • $votes صوت',
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

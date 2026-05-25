import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/premium_cards/premium_card_broadcast_tokens.dart';

/// استجابة لمس ≤160ms — بدون bounce.
class PremiumCardInteraction extends StatefulWidget {
  const PremiumCardInteraction({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.locked = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final bool locked;

  @override
  State<PremiumCardInteraction> createState() => _PremiumCardInteractionState();
}

class _PremiumCardInteractionState extends State<PremiumCardInteraction> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (!widget.enabled || widget.locked || widget.onTap == null) return;
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && !widget.locked && widget.onTap != null;
    final scale = _pressed ? PremiumCardBroadcastTokens.pressScale : 1.0;
    final opacity = _pressed ? PremiumCardBroadcastTokens.pressOpacity : 1.0;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: canTap ? widget.onTap : null,
        onTapDown: canTap ? (_) => _setPressed(true) : null,
        onTapUp: canTap ? (_) => _setPressed(false) : null,
        onTapCancel: canTap ? () => _setPressed(false) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: scale,
          duration: _pressed
              ? PremiumCardBroadcastTokens.pressDuration
              : PremiumCardBroadcastTokens.releaseDuration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: AnimatedOpacity(
            opacity: opacity,
            duration: PremiumCardBroadcastTokens.pressDuration,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

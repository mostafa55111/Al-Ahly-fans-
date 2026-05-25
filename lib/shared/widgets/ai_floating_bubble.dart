import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';

class AIFloatingBubble extends StatefulWidget {
  const AIFloatingBubble({
    super.key,
    required this.onTap,
    this.isPulsing = false,
  });

  final VoidCallback onTap;
  final bool isPulsing;

  @override
  State<AIFloatingBubble> createState() => _AIFloatingBubbleState();
}

class _AIFloatingBubbleState extends State<AIFloatingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
    lowerBound: 0.94,
    upperBound: 1.08,
  );

  @override
  void initState() {
    super.initState();
    if (widget.isPulsing) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant AIFloatingBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing == oldWidget.isPulsing) return;
    if (widget.isPulsing) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl
        ..stop()
        ..animateTo(1, duration: const Duration(milliseconds: 180));
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAhly = AppConfig.reelsFirestoreClubTag.toLowerCase() == 'ahly';
    final borderColor = isAhly ? const Color(0xFF7A0011) : const Color(0xFFD90429);
    final background = isAhly ? const Color(0xFFC8102E) : Colors.white;
    final iconColor = isAhly ? Colors.white : const Color(0xFFD90429);
    final shadow = isAhly
        ? const Color(0xFF8A0C1F).withValues(alpha: 0.45)
        : const Color(0xFFE63946).withValues(alpha: 0.35);

    return ScaleTransition(
      scale: _pulseCtrl,
      child: Semantics(
        button: true,
        label: 'مساعد الذكاء الاصطناعي الخاص بجمهور النادي',
        child: Tooltip(
          message: widget.isPulsing
              ? 'رسالة عاجلة من الإدارة — افتح المستشار'
              : 'المستشار الذكي',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: background,
                  border: Border.all(color: borderColor, width: 2.4),
                  boxShadow: [
                    BoxShadow(
                      color: shadow,
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 26,
                      color: iconColor,
                    ),
                    if (!isAhly)
                      Positioned(
                        bottom: 10,
                        child: Container(
                          width: 24,
                          height: 2,
                          color: const Color(0xFFD90429),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

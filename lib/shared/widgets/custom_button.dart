import 'package:flutter/material.dart';

/// Custom Button Widget
class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double padding;
  final bool isLoading;
  final IconData? icon;
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = Colors.red,
    this.textColor = Colors.white,
    this.borderRadius = 12,
    this.padding = 16,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    final child = widget.isOutlined
        ? OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: widget.backgroundColor, width: 2),
              padding: EdgeInsets.all(widget.padding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
            ),
            child: _buildButtonContent(),
          )
        : ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.backgroundColor,
              foregroundColor: widget.textColor,
              padding: EdgeInsets.all(widget.padding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              elevation: 4,
            ),
            child: _buildButtonContent(),
          );

    return Semantics(
      button: true,
      label: widget.label,
      child: Tooltip(message: widget.label, child: child),
    );
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(widget.textColor),
          strokeWidth: 2,
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon),
          const SizedBox(width: 8),
          Text(widget.label),
        ],
      );
    }

    return Text(widget.label);
  }
}

/// Custom Icon Button — تسمية عربية إلزامية لاختبارات الروبوت.
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double size;
  final String semanticsLabel;
  final String? tooltip;
  /// أيقونة مخصّصة (مثل Badge) بدل الـ [Icon] الافتراضي من [icon].
  final Widget? iconOverride;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticsLabel,
    this.color = Colors.red,
    this.size = 24,
    this.tooltip,
    this.iconOverride,
  });

  @override
  Widget build(BuildContext context) {
    final tip = tooltip ?? semanticsLabel;
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Tooltip(
        message: tip,
        child: IconButton(
          icon: iconOverride ?? Icon(icon),
          onPressed: onPressed,
          color: iconOverride == null ? color : null,
          iconSize: iconOverride == null ? size : null,
          tooltip: tip,
        ),
      ),
    );
  }
}

/// Custom Floating Action Button
class CustomFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final String semanticsLabel;
  final String? tooltip;
  final bool isExtended;
  final String? label;
  final TextStyle? labelStyle;
  final bool mini;

  const CustomFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticsLabel,
    this.backgroundColor = Colors.red,
    this.foregroundColor = Colors.white,
    this.tooltip,
    this.isExtended = false,
    this.label,
    this.labelStyle,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    final tip = tooltip ?? label ?? semanticsLabel;
    if (isExtended && label != null) {
      final fab = FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        icon: Icon(icon),
        label: Text(label!, style: labelStyle),
        tooltip: tip,
      );
      return Semantics(
        button: true,
        label: semanticsLabel,
        child: Tooltip(message: tip, child: fab),
      );
    }

    final fab = FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      tooltip: tip,
      mini: mini,
      child: Icon(icon),
    );
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Tooltip(message: tip, child: fab),
    );
  }
}

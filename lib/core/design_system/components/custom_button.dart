import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Custom Button Widget with consistent styling
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final TextStyle? textStyle;
  final Widget? icon;
  final bool isLoading;
  final bool isDisabled;
  final ButtonType type;
  final ButtonSize size;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.textStyle,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: (isDisabled || isLoading) ? null : onPressed,
      style: _getButtonStyle(),
      child: _buildButtonContent(),
    );
  }

  ButtonStyle _getButtonStyle() {
    switch (type) {
      case ButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          elevation: 4,
          shadowColor: AppColors.primaryWithOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
        );
      
      case ButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primary,
          elevation: 2,
          shadowColor: AppColors.surfaceWithOpacity(0.3),
          side: const BorderSide(color: AppColors.primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
        );
      
      case ButtonType.outlined:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          elevation: 0,
          side: const BorderSide(color: AppColors.primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
        );
      
      case ButtonType.text:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
          ),
          padding: _getPadding(),
        );
    }
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: _getLoadingSize(),
        width: _getLoadingSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == ButtonType.primary ? AppColors.textPrimary : AppColors.primary,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(
            text,
            style: _getTextStyle(),
          ),
        ],
      );
    }

    return Text(
      text,
      style: _getTextStyle(),
    );
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return textStyle ?? AppTextStyles.buttonSmall;
      case ButtonSize.medium:
        return textStyle ?? AppTextStyles.buttonMedium;
      case ButtonSize.large:
        return textStyle ?? AppTextStyles.buttonLarge;
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case ButtonSize.small:
        return 8;
      case ButtonSize.medium:
        return 12;
      case ButtonSize.large:
        return 16;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double _getLoadingSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }
}

enum ButtonType {
  primary,
  secondary,
  outlined,
  text,
}

enum ButtonSize {
  small,
  medium,
  large,
}

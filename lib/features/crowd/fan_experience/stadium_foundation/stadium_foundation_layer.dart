import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/fan_experience/stadium_foundation/stadium_foundation_tokens.dart';

/// طبقة الملعب الرسمية — صورة فقط، بدون كروت أو تصويت أو حركة.
class StadiumFoundationLayer extends StatelessWidget {
  const StadiumFoundationLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Image.asset(
        StadiumFoundationTokens.assetPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.medium,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => const ColoredBox(
          color: Color(0xFF0A0A0A),
        ),
      ),
    );
  }
}

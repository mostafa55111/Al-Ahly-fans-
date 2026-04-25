import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';

/// شاشة المتجر الرسمي للأهلي (placeholder — قيد التطوير)
class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('متجر الأهلي'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.luminousGold, AppColors.darkGold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.luminousGold.withValues(alpha: 0.35),
                    blurRadius: 22,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 72,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'متجر جمهور الأهلي',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'قمصان رسمية، إكسسوارات، وتذكارات النادي الأهلي 🔴⚪\nكل ما يخصّ نادي القرن في مكان واحد',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.6,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.royalRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: AppColors.royalRed.withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_bottom,
                      color: AppColors.royalRed, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'قيد التطوير',
                    style: TextStyle(
                      color: AppColors.royalRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

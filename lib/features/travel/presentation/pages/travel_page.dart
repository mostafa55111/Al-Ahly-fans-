import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/theme/app_theme.dart';

/// شاشة الترحال مع فريق الأهلي (مخطّط لها بنائياً — سيتم التطوير لاحقاً)
class TravelPage extends StatelessWidget {
  const TravelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('الترحال مع الأهلي'),
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
                  colors: [AppColors.royalRed, AppColors.darkRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalRed.withValues(alpha: 0.35),
                    blurRadius: 22,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.flight_takeoff_rounded,
                color: AppColors.luminousGold,
                size: 72,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'ترحال الجمهور',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'سافر مع نادي القرن حول العالم ❤️🤍\nقريباً ستجد هنا رحلات المشجعين ومباريات الفريق خارج مصر',
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
                color: AppColors.luminousGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: AppColors.luminousGold.withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.construction,
                      color: AppColors.luminousGold, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'قيد التطوير',
                    style: TextStyle(
                      color: AppColors.luminousGold,
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

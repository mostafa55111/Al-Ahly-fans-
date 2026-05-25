import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/branding/app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_design_system.dart';

/// عنوان موحّد لأقسام قاعة الشرف — نفس مقياس StadiumCmsDesign.
class HallOfFameSectionTitle extends StatelessWidget {
  const HallOfFameSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.featured = false,
  });

  final String title;
  final String? subtitle;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final id = CrowdAppIdentity.current;
    return Padding(
      padding: EdgeInsets.only(
        bottom: StadiumCmsDesign.spaceSm,
        top: featured ? StadiumCmsDesign.spaceMd : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: StadiumCmsDesign.title(id).copyWith(
              fontSize: featured ? 18 : StadiumCmsDesign.typeTitle,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: StadiumCmsDesign.caption),
          ],
        ],
      ),
    );
  }
}

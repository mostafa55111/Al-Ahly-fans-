import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_page.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/admin_surface_isolation.dart';

/// وحدة تحكم المباراة — للمالك فقط، مسار واحد للنشر.
class MatchControlConsolePage extends StatelessWidget {
  const MatchControlConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminSurfaceIsolation(
      child: StadiumCmsPage(),
    );
  }
}

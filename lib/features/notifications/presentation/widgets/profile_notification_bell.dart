import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/features/notifications/presentation/pages/notifications_page.dart';
import 'package:gomhor_alahly_clean_new/shared/widgets/custom_button.dart';

/// زر الإشعارات في أعلى البروفايل — أيقونة جرس موحّدة.
class ProfileNotificationBell extends StatelessWidget {
  const ProfileNotificationBell({
    super.key,
    required this.accentColor,
  });

  final Color accentColor;

  void _open(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsPage(accentColor: accentColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        final count =
            (snap.data?.data()?['notificationsUnreadCount'] as num?)?.toInt() ??
                0;
        final label = count > 99 ? '99+' : '$count';

        final semanticLabel = count > 0
            ? 'الإشعارات، $count غير مقروءة'
            : 'الإشعارات، لا يوجد جديد';

        return CustomIconButton(
          tooltip: 'الإشعارات',
          icon: Icons.notifications_active_outlined,
          semanticsLabel: semanticLabel,
          onPressed: () => _open(context),
          iconOverride: Badge(
            isLabelVisible: count > 0,
            backgroundColor: Colors.redAccent,
            label: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: accentColor,
              size: 26,
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

/// شاشة الإشعارات
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'المتابعة'),
            Tab(text: 'الإعجابات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllNotifications(),
          _buildFollowNotifications(),
          _buildLikeNotifications(),
        ],
      ),
    );
  }

  Widget _buildAllNotifications() {
    return ListView.builder(
      itemCount: 15,
      itemBuilder: (context, index) {
        return _buildNotificationItem(
          icon: Icons.person_add,
          title: 'متابع جديد',
          subtitle: 'أحمد محمد بدأ متابعتك',
          time: 'منذ ${index + 1} دقيقة',
          isRead: index < 5,
        );
      },
    );
  }

  Widget _buildFollowNotifications() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) {
        return _buildNotificationItem(
          icon: Icons.person_add,
          title: 'متابع جديد',
          subtitle: 'فاطمة علي بدأت متابعتك',
          time: 'منذ ${(index + 1) * 2} ساعة',
          isRead: true,
        );
      },
    );
  }

  Widget _buildLikeNotifications() {
    return ListView.builder(
      itemCount: 12,
      itemBuilder: (context, index) {
        return _buildNotificationItem(
          icon: Icons.favorite,
          title: 'إعجاب جديد',
          subtitle: 'أعجب محمود بمنشورك',
          time: 'منذ ${index + 1} يوم',
          isRead: true,
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required bool isRead,
  }) {
    return Container(
      color: isRead ? Colors.transparent : Colors.blue.withOpacity(0.1),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
        onTap: () {
          // الانتقال إلى التفاصيل
        },
      ),
    );
  }
}

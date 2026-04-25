import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/presentation/pages/crowd_screen.dart';
import 'package:gomhor_alahly_clean_new/features/profile/presentation/pages/profile_screen.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/cubit/reels_feed_cubit.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/pages/tiktok_reels_page.dart';
import 'package:gomhor_alahly_clean_new/features/store/presentation/pages/store_page.dart';
import 'package:gomhor_alahly_clean_new/features/travel/presentation/pages/travel_page.dart';

/// index التبويب المخصّص لشاشة الريلز
const int kReelsTabIndex = 2;

/// ══════════════════════════════════════════════════════════════════════
/// InheritedWidget يخبر الشاشات بالتبويب النشط حالياً
/// ══════════════════════════════════════════════════════════════════════
/// ‣ تستخدمه شاشة الريلز لإيقاف الفيديو لو المستخدم خرج منها لتبويب آخر
///   (الـ IndexedStack بيحتفظ بالشاشة لكن الصوت لازم يقف).
class AppTabScope extends InheritedWidget {
  final int currentIndex;

  const AppTabScope({
    required this.currentIndex,
    required super.child,
    super.key,
  });

  @override
  bool updateShouldNotify(AppTabScope old) =>
      old.currentIndex != currentIndex;

  static int of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppTabScope>();
    return scope?.currentIndex ?? 0;
  }
}

/// ══════════════════════════════════════════════════════════════════════
/// الهيكل الرئيسي للتطبيق — 5 تبويبات بستايل تيك توك
/// ══════════════════════════════════════════════════════════════════════
/// - شريط سفلي أسود صافي (Pitch Black)
/// - الأيقونة النشطة: أحمر فاتح (لكل التبويبات بلا استثناء — بما فيها الريلز)
/// - الأيقونات غير النشطة: أبيض عادي
class AppShell extends StatefulWidget {
  /// التبويب الافتراضي عند الدخول — الريلز هو الوسط
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = kReelsTabIndex});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  /// الشاشات الخمس
  List<Widget> _pages(Map<dynamic, dynamic> controls) => [
        _tabEnabled(controls, 'profileEnabled')
            ? const ProfileScreen()
            : const _FeatureDisabledView(label: 'حسابي'),
        _tabEnabled(controls, 'travelEnabled')
            ? const TravelPage()
            : const _FeatureDisabledView(label: 'الترحال'),
        _tabEnabled(controls, 'reelsEnabled')
            ? BlocProvider(
                create: (_) => ReelsFeedCubit(),
                child: const TikTokReelsPage(),
              )
            : const _FeatureDisabledView(label: 'الريلز'),
        _tabEnabled(controls, 'storeEnabled')
            ? const StorePage()
            : const _FeatureDisabledView(label: 'المتجر'),
        _tabEnabled(controls, 'crowdEnabled')
            ? const CrowdScreen()
            : const _FeatureDisabledView(label: 'الجمهور'),
      ];

  bool _tabEnabled(Map<dynamic, dynamic> controls, String key) {
    final value = controls[key];
    return value == null || value == true || value == 1;
  }

  /// بيانات عناصر شريط التنقل
  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'حسابي',
    ),
    _NavItem(
      icon: Icons.flight_takeoff_outlined,
      activeIcon: Icons.flight_takeoff,
      label: 'الترحال',
    ),
    _NavItem(
      icon: Icons.play_circle_outline,
      activeIcon: Icons.play_circle_filled_rounded,
      label: 'الريلز',
    ),
    _NavItem(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront,
      label: 'المتجر',
    ),
    _NavItem(
      icon: Icons.people_alt_outlined,
      activeIcon: Icons.people_alt,
      label: 'الجمهور',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('app_controls').onValue,
      builder: (context, snapshot) {
        final controls = snapshot.data?.snapshot.value is Map
            ? Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map)
            : <dynamic, dynamic>{};
        final pages = _pages(controls);
        return Scaffold(
          extendBody: false,
          backgroundColor: Colors.black,
          body: AppTabScope(
            currentIndex: _currentIndex,
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
          bottomNavigationBar: _buildBottomBar(controls),
        );
      },
    );
  }

  /// شريط التنقل — أسود صافي + نشط أحمر لكل الأزرار
  Widget _buildBottomBar(Map<dynamic, dynamic> controls) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Color(0xFF1F1F1F), width: 0.6),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final active = i == _currentIndex;
              return Expanded(
                child: InkResponse(
                  onTap: _tabEnabled(
                    controls,
                    switch (i) {
                      0 => 'profileEnabled',
                      1 => 'travelEnabled',
                      2 => 'reelsEnabled',
                      3 => 'storeEnabled',
                      _ => 'crowdEnabled',
                    },
                  )
                      ? () => setState(() => _currentIndex = i)
                      : null,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.white12,
                  child: _NavTile(item: item, active: active),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MARK: بطاقة عنصر واحد — نشط أحمر / غير نشط أبيض (زي تيك توك بالظبط)
// ═══════════════════════════════════════════════════════════════════════
class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool active;

  const _NavTile({required this.item, required this.active});

  static const Color _activeColor = Color(0xFFFF2E4D);

  @override
  Widget build(BuildContext context) {
    final color = active ? _activeColor : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              active ? item.activeIcon : item.icon,
              key: ValueKey(active),
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.1,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _FeatureDisabledView extends StatelessWidget {
  const _FeatureDisabledView({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Text(
        'تم إيقاف قسم $label مؤقتاً بواسطة الإدارة',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/owner_recovery_mode.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/owner_session_guard.dart';

/// حجب على مستوى المسار — لا يُبنى الـ CMS لغير المالك.
class AdminSurfaceIsolation extends StatefulWidget {
  const AdminSurfaceIsolation({
    super.key,
    required this.child,
    this.loading,
  });

  final Widget child;
  final Widget? loading;

  @override
  State<AdminSurfaceIsolation> createState() => _AdminSurfaceIsolationState();
}

class _AdminSurfaceIsolationState extends State<AdminSurfaceIsolation> {
  bool _checking = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    _gate();
    if (getIt.isRegistered<OwnerSessionGuard>()) {
      getIt<OwnerSessionGuard>().adminSurfaceAllowed.addListener(_onGuardChanged);
    }
  }

  @override
  void dispose() {
    if (getIt.isRegistered<OwnerSessionGuard>()) {
      getIt<OwnerSessionGuard>()
          .adminSurfaceAllowed
          .removeListener(_onGuardChanged);
    }
    super.dispose();
  }

  void _onGuardChanged() {
    if (!mounted) return;
    setState(() {
      _allowed = getIt<OwnerSessionGuard>().adminSurfaceAllowed.value;
      _checking = false;
    });
  }

  Future<void> _gate() async {
    if (!getIt.isRegistered<OwnerSessionGuard>()) {
      if (mounted) {
        setState(() {
          _allowed = false;
          _checking = false;
        });
      }
      return;
    }
    final ok = await getIt<OwnerSessionGuard>().assertOwnerAccess();
    if (!mounted) return;
    setState(() {
      _allowed = ok;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return widget.loading ??
          const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
    }
    if (!_allowed) {
      return OwnerRecoveryMode.lockedSurface(context);
    }
    return widget.child;
  }
}

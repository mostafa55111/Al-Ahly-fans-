import 'package:flutter/material.dart';
import 'package:gomhor_alahly_clean_new/core/di/service_locator_improved.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/control_room_shell/owner_control_room_shell.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_auth/owner_auth_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_auth/owner_login_surface.dart';

/// بوابة غرفة التحكم — تسجيل دخول، تحقق مالك، إعادة التحقق عند الاستئناف.
class OwnerControlRoomGate extends StatefulWidget {
  const OwnerControlRoomGate({super.key});

  @override
  State<OwnerControlRoomGate> createState() => _OwnerControlRoomGateState();
}

class _OwnerControlRoomGateState extends State<OwnerControlRoomGate>
    with WidgetsBindingObserver {
  bool _checking = true;
  bool _privileged = false;
  bool _silentExit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _evaluate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _evaluate(resume: true);
    }
  }

  Future<void> _evaluate({bool resume = false}) async {
    if (!getIt.isRegistered<OwnerAuthService>()) {
      if (mounted) {
        setState(() {
          _checking = false;
          _privileged = false;
          _silentExit = true;
        });
      }
      return;
    }
    final auth = getIt<OwnerAuthService>();
    final ok = resume ? await auth.revalidateOnResume() : await auth.hasPrivilegedSession();
    if (!mounted) return;
    if (!ok && resume) {
      setState(() {
        _checking = false;
        _privileged = false;
      });
      return;
    }
    setState(() {
      _checking = false;
      _privileged = ok;
      _silentExit = !ok && !resume;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_silentExit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const SizedBox.shrink();
    }
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_privileged) {
      return OwnerLoginSurface(onAuthenticated: () => _evaluate());
    }
    return const OwnerControlRoomShell();
  }
}

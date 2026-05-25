import 'package:flutter/material.dart';

import 'package:gomhor_alahly_clean_new/features/crowd/services/overlay_runtime_registry.dart';

/// يُسجّل [child] في [OverlayRuntimeRegistry] طوال حياته.
class CrowdRuntimeOverlayRegistrar extends StatefulWidget {
  const CrowdRuntimeOverlayRegistrar({
    super.key,
    required this.id,
    required this.kind,
    this.heavyAnimated = false,
    this.visible = true,
    required this.child,
  });

  final String id;
  final CrowdOverlayKind kind;
  final bool heavyAnimated;
  final bool visible;
  final Widget child;

  @override
  State<CrowdRuntimeOverlayRegistrar> createState() => _CrowdRuntimeOverlayRegistrarState();
}

class _CrowdRuntimeOverlayRegistrarState extends State<CrowdRuntimeOverlayRegistrar> {
  OverlayRuntimeTicket? _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = OverlayRuntimeRegistry.instance.register(
      id: widget.id,
      kind: widget.kind,
      visible: widget.visible,
      heavyAnimated: widget.heavyAnimated,
    );
  }

  @override
  void didUpdateWidget(covariant CrowdRuntimeOverlayRegistrar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible ||
        oldWidget.heavyAnimated != widget.heavyAnimated ||
        oldWidget.kind != widget.kind) {
      _ticket?.update(
        visible: widget.visible,
        heavyAnimated: widget.heavyAnimated,
        kind: widget.kind,
      );
    }
  }

  @override
  void dispose() {
    _ticket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// وضع تنفيذ السلطة — محلي، بعيد، أو ظل للمقارنة.
enum AuthorityExecutionMode {
  /// تنفيذ على العميل (fallback).
  local,

  /// سلطة Cloud Function / Callable (إنتاج).
  remoteCloud,

  /// يشغّل البعيد للمقارنة دون التأثير على الناتج.
  hybridShadow,

  /// @deprecated استخدم [remoteCloud]
  cloudFunction,

  /// @deprecated استخدم [remoteCloud]
  remoteBackend,
}

/// قيمة Remote Config: `crowd_authority_mode`
enum CrowdAuthorityMode {
  local,
  remote,
  hybridShadow,
}

extension CrowdAuthorityModeX on CrowdAuthorityMode {
  static CrowdAuthorityMode fromWire(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'remote':
      case 'remote_cloud':
      case 'remote_cloud_authority':
        return CrowdAuthorityMode.remote;
      case 'hybrid_shadow':
      case 'hybrid':
        return CrowdAuthorityMode.hybridShadow;
      default:
        return CrowdAuthorityMode.local;
    }
  }

  String get wireName {
    switch (this) {
      case CrowdAuthorityMode.local:
        return 'local';
      case CrowdAuthorityMode.remote:
        return 'remote';
      case CrowdAuthorityMode.hybridShadow:
        return 'hybrid_shadow';
    }
  }

  AuthorityExecutionMode toExecutionMode() {
    switch (this) {
      case CrowdAuthorityMode.local:
        return AuthorityExecutionMode.local;
      case CrowdAuthorityMode.remote:
        return AuthorityExecutionMode.remoteCloud;
      case CrowdAuthorityMode.hybridShadow:
        return AuthorityExecutionMode.hybridShadow;
    }
  }
}

extension AuthorityExecutionModeX on AuthorityExecutionMode {
  bool get isLocal =>
      this == AuthorityExecutionMode.local;

  bool get usesRemotePrimary =>
      this == AuthorityExecutionMode.remoteCloud ||
      this == AuthorityExecutionMode.cloudFunction ||
      this == AuthorityExecutionMode.remoteBackend;

  bool get isHybridShadow => this == AuthorityExecutionMode.hybridShadow;

  String get wireName {
    switch (this) {
      case AuthorityExecutionMode.local:
        return 'local_client_authority';
      case AuthorityExecutionMode.remoteCloud:
        return 'remote_cloud_authority';
      case AuthorityExecutionMode.hybridShadow:
        return 'hybrid_shadow_authority';
      case AuthorityExecutionMode.cloudFunction:
        return 'cloud_function_authority';
      case AuthorityExecutionMode.remoteBackend:
        return 'backend_worker_authority';
    }
  }
}

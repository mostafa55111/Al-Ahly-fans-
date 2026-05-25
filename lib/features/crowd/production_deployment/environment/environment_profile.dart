/// بيئات التشغيل — مشاريع Firebase منفصلة (يُضبط عبر build / RC).
enum DeploymentEnvironment {
  development,
  staging,
  production,
}

/// ملف تعريف بيئة واحدة (مسارات RTDB، تحليلات، Functions).
class EnvironmentProfile {
  const EnvironmentProfile({
    required this.environment,
    required this.firebaseProjectLabel,
    required this.rtdbNamespace,
    required this.analyticsNamespace,
    required this.remoteConfigNamespace,
    required this.functionsRegion,
    required this.allowsSandboxSessions,
    required this.isProductionData,
  });

  final DeploymentEnvironment environment;
  final String firebaseProjectLabel;
  final String rtdbNamespace;
  final String analyticsNamespace;
  final String remoteConfigNamespace;
  final String functionsRegion;
  final bool allowsSandboxSessions;
  final bool isProductionData;

  static EnvironmentProfile forEnv(
    DeploymentEnvironment env, {
    required String clubTag,
  }) {
    switch (env) {
      case DeploymentEnvironment.development:
        return EnvironmentProfile(
          environment: env,
          firebaseProjectLabel: 'dev-$clubTag',
          rtdbNamespace: 'dev',
          analyticsNamespace: 'crowd_dev_$clubTag',
          remoteConfigNamespace: 'crowd_dev',
          functionsRegion: 'us-central1',
          allowsSandboxSessions: true,
          isProductionData: false,
        );
      case DeploymentEnvironment.staging:
        return EnvironmentProfile(
          environment: env,
          firebaseProjectLabel: 'staging-$clubTag',
          rtdbNamespace: 'staging',
          analyticsNamespace: 'crowd_staging_$clubTag',
          remoteConfigNamespace: 'crowd_staging',
          functionsRegion: 'us-central1',
          allowsSandboxSessions: true,
          isProductionData: false,
        );
      case DeploymentEnvironment.production:
        return EnvironmentProfile(
          environment: env,
          firebaseProjectLabel: 'prod-$clubTag',
          rtdbNamespace: 'prod',
          analyticsNamespace: 'crowd_prod_$clubTag',
          remoteConfigNamespace: 'crowd_prod',
          functionsRegion: 'us-central1',
          allowsSandboxSessions: false,
          isProductionData: true,
        );
    }
  }

  String incidentPathPrefix(String clubTag) =>
      'production_incidents/$rtdbNamespace/$clubTag';

  Map<String, dynamic> toJson() => {
        'environment': environment.name,
        'firebaseProjectLabel': firebaseProjectLabel,
        'rtdbNamespace': rtdbNamespace,
        'analyticsNamespace': analyticsNamespace,
        'remoteConfigNamespace': remoteConfigNamespace,
        'functionsRegion': functionsRegion,
        'allowsSandboxSessions': allowsSandboxSessions,
        'isProductionData': isProductionData,
      };
}

/// نظام حقن الاعتماديات المحسّن
///
/// يستخدم هذا الملف نمط Service Locator لإدارة الاعتماديات
/// مما يسمح بفصل الكود وسهولة الاختبار
library;

import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gomhor_alahly_clean_new/core/network/api_client.dart';
import 'package:gomhor_alahly_clean_new/core/config/app_config.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/datasources/video_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/repositories/video_repository_impl.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/repositories/video_repository.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/bloc/reels_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/datasources/best_player_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/bloc/matches_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/core/services/fan_app_registry_service.dart';
import 'package:gomhor_alahly_clean_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gomhor_alahly_clean_new/features/auth/domain/repositories/auth_repository.dart';
import 'package:gomhor_alahly_clean_new/core/time/egypt_server_time_service.dart';
import 'package:gomhor_alahly_clean_new/core/time/time_service.dart';
import 'package:gomhor_alahly_clean_new/core/services/fan_memory_cache_service.dart';
import 'package:gomhor_alahly_clean_new/core/config/fan_app_identity.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/data/awards_repository_rtdb.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/domain/awards_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/awards/services/voting_session_lifecycle_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/authority_orchestrator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/crowd_authority_config_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/config/crowd_deployment_config_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident_logger.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/incidents/production_incident_store.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_deployment/rollback/safe_rollback_coordinator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/finalization_lease_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/finalize_retry_coordinator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/local_authority_gateway.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/backend_authority/remote_authority_gateway.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/failure_recovery/dead_session_recovery_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/production_runtime/production_finalize_pipeline.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner/owner_authority_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner/owner_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/card_soft_delete_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/emergency_session_freeze.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/owner_audit_log.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/owner_session_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_admin/secure_owner_resolver.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/read_pressure/visibility_subscription_guard.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_abuse_protection/device_fingerprint_helper.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_abuse_protection/vote_abuse_coordinator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/finalization_authority_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/sharded_vote_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/vote_scale/vote_aggregation_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/data/repositories/crowd_repository_impl.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/domain/repositories/crowd_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_registry_repository_rtdb.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/card_repository/crowd_card_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/card_repository/crowd_card_repository_rtdb.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/card_repository/owner_card_upload_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_auth/owner_auth_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/owner_auth/owner_secure_session.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/operational_shortcuts/operational_shortcuts.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/quick_launch/quick_launch_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/rapid_replacements/rapid_replacement_service.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_match_template_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_match_template_repository_rtdb.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/saved_templates/owner_template_writer.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/session_drafts/owner_session_draft_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/owner_control_room/matchday_speed/session_drafts/owner_session_draft_repository_rtdb.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_card_upload_coordinator.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/admin/cms/stadium_cms_repository_rtdb.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/data/match_votes_repository_rtdb.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/match_votes/domain/match_votes_repository.dart';
import 'package:gomhor_alahly_clean_new/features/crowd/services/celebration_seen_store.dart';
import 'package:gomhor_alahly_clean_new/features/notifications/data/reel_interaction_notification_service.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/services/ignored_reels_storage.dart';
import 'package:gomhor_alahly_clean_new/core/navigation/reels_deep_link_controller.dart';

/// الحصول على نسخة من Service Locator
final getIt = GetIt.instance;

/// إعداد حقن الاعتماديات
Future<void> setupServiceLocator() async {
  // ===== Core Services =====

  
  // ===== Firebase Services =====

  /// تسجيل Firebase Auth
  getIt.registerSingleton<FirebaseAuth>(
    FirebaseAuth.instance,
  );

  /// تسجيل Firebase Realtime Database
  getIt.registerSingleton<FirebaseDatabase>(
    FirebaseDatabase.instance,
  );

  /// Firestore — لسجلّ البريد الموحّد بين تطبيقي الأهلي والزمالك
  getIt.registerSingleton<FirebaseFirestore>(
    FirebaseFirestore.instance,
  );

  /// سجلّ التطبيق الرئيسي لكل إيميل (Firestore) — نسخة واحدة مشتركة
  getIt.registerSingleton<FanAppRegistryService>(
    FanAppRegistryService(getIt<FirebaseFirestore>()),
  );

  /// تسجيل Auth Repository (واجهة المصادقة)
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      firebaseAuth: getIt<FirebaseAuth>(),
      database: getIt<FirebaseDatabase>(),
      fanAppRegistry: getIt<FanAppRegistryService>(),
    ),
  );

  getIt.registerLazySingleton<ReelsDeepLinkController>(
    ReelsDeepLinkController.new,
  );

  getIt.registerLazySingleton<ReelInteractionNotificationService>(
    ReelInteractionNotificationService.new,
  );

  /// تسجيل Firebase Storage
  getIt.registerSingleton<FirebaseStorage>(
    FirebaseStorage.instance,
  );

  
  // ===== Network Services =====

  /// تسجيل Dio (HTTP Client)
  getIt.registerSingleton<Dio>(
    _createDioClient(),
  );

  /// تسجيل Cloudinary Service (يعتمد على Dio المُسجَّل بالأعلى)
  getIt.registerSingleton<CloudinaryService>(
    CloudinaryService(dio: getIt<Dio>()),
  );

  /// API Client Wrapper (موحّد)
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(
      dio: getIt<Dio>(),
      defaultHeaders: const <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  /// تسجيل Connectivity
  getIt.registerSingleton<Connectivity>(
    Connectivity(),
  );

  // ===== Local Storage Services =====

  /// تسجيل SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerLazySingleton<FanMemoryCacheService>(
    () => FanMemoryCacheService(getIt<SharedPreferences>()),
  );

  getIt.registerLazySingleton<IgnoredReelsStorage>(
    () => IgnoredReelsStorage(getIt<SharedPreferences>()),
  );

  /// وقت الخادم (Offset من Realtime DB) + عرض +3 اختياري
  getIt.registerLazySingleton<EgyptServerTimeService>(
    () => EgyptServerTimeService(),
  );
  getIt.registerLazySingleton<TimeService>(
    () => TimeService(serverTime: getIt<EgyptServerTimeService>()),
  );
  getIt.registerLazySingleton<CrowdRepository>(
    () => CrowdRepositoryImpl(getIt<FirebaseDatabase>(), getIt<FirebaseAuth>()),
  );
  getIt.registerLazySingleton<ShardedVoteRepository>(
    () => ShardedVoteRepository(getIt<FirebaseDatabase>()),
  );
  getIt.registerLazySingleton<VoteAggregationService>(
    () => VoteAggregationService(
      shardedVotes: getIt<ShardedVoteRepository>(),
    ),
  );
  getIt.registerLazySingleton<AwardsRepository>(
    () => AwardsRepositoryRtdb(getIt<FirebaseDatabase>()),
  );
  getIt.registerLazySingleton<VoteAbuseCoordinator>(
    () => VoteAbuseCoordinator(serverTime: getIt<EgyptServerTimeService>()),
  );
  getIt.registerLazySingleton<DeviceFingerprintHelper>(
    () => DeviceFingerprintHelper(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<MatchVotesRepository>(
    () => MatchVotesRepositoryRtdb(
      getIt<FirebaseDatabase>(),
      serverTime: getIt<EgyptServerTimeService>(),
      shardedVotes: getIt<ShardedVoteRepository>(),
      voteAbuse: getIt<VoteAbuseCoordinator>(),
    ),
  );
  getIt.registerLazySingleton<FinalizationAuthorityService>(
    () => FinalizationAuthorityService(
      votesRepository: getIt<MatchVotesRepository>(),
      awardsRepository: getIt<AwardsRepository>(),
      aggregator: getIt<VoteAggregationService>(),
      clubTag: FanAppIdentity.registryAppId,
    ),
  );
  getIt.registerLazySingleton<LocalAuthorityGateway>(
    () => LocalAuthorityGateway(
      authority: getIt<FinalizationAuthorityService>(),
      aggregator: getIt<VoteAggregationService>(),
    ),
  );
  getIt.registerLazySingleton<RemoteAuthorityGateway>(RemoteAuthorityGateway.new);
  getIt.registerLazySingleton<CrowdAuthorityConfigService>(
    CrowdAuthorityConfigService.new,
  );
  getIt.registerLazySingleton<CrowdDeploymentConfigService>(
    CrowdDeploymentConfigService.new,
  );
  getIt.registerLazySingleton<ProductionIncidentStore>(
    () => ProductionIncidentStore(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<ProductionIncidentLogger>(
    () => ProductionIncidentLogger(getIt<ProductionIncidentStore>()),
  );
  getIt.registerLazySingleton<SafeRollbackCoordinator>(
    SafeRollbackCoordinator.new,
  );
  getIt.registerLazySingleton<AuthorityOrchestrator>(
    () => AuthorityOrchestrator(
      localGateway: getIt<LocalAuthorityGateway>(),
      remoteGateway: getIt<RemoteAuthorityGateway>(),
    ),
  );
  getIt.registerLazySingleton<FinalizeRetryCoordinator>(
    FinalizeRetryCoordinator.new,
  );
  getIt.registerLazySingleton<FinalizationLeaseService>(
    () => FinalizationLeaseService(
      database: getIt<FirebaseDatabase>(),
      serverTime: getIt<EgyptServerTimeService>(),
    ),
  );
  getIt.registerLazySingleton<OwnerAuthorityService>(
    () => OwnerAuthorityService(
      database: getIt<FirebaseDatabase>(),
      auth: getIt<FirebaseAuth>(),
    ),
  );
  getIt.registerLazySingleton<SecureOwnerResolver>(
    () => SecureOwnerResolver(getIt<OwnerAuthorityService>()),
  );
  getIt.registerLazySingleton<OwnerAuditLog>(
    () => OwnerAuditLog(
      database: getIt<FirebaseDatabase>(),
      auth: getIt<FirebaseAuth>(),
      resolver: getIt<SecureOwnerResolver>(),
    ),
  );
  getIt.registerLazySingleton<OwnerSecureSession>(OwnerSecureSession.new);
  getIt.registerLazySingleton<OwnerSessionGuard>(
    () => OwnerSessionGuard(
      auth: getIt<FirebaseAuth>(),
      resolver: getIt<SecureOwnerResolver>(),
      audit: getIt<OwnerAuditLog>(),
      secureSession: getIt<OwnerSecureSession>(),
    ),
  );
  getIt.registerLazySingleton<OwnerAuthService>(
    () => OwnerAuthService(
      auth: getIt<FirebaseAuth>(),
      resolver: getIt<SecureOwnerResolver>(),
      secureSession: getIt<OwnerSecureSession>(),
    ),
  );
  getIt.registerLazySingleton<OwnerGuard>(
    () => OwnerGuard(getIt<OwnerAuthorityService>()),
  );
  getIt.registerLazySingleton<EmergencySessionFreeze>(
    () => EmergencySessionFreeze(
      votes: getIt<MatchVotesRepository>(),
      audit: getIt<OwnerAuditLog>(),
    ),
  );
  getIt.registerLazySingleton<CardSoftDeleteService>(
    () => CardSoftDeleteService(
      registry: getIt<StadiumCardRegistryRepository>(),
      audit: getIt<OwnerAuditLog>(),
    ),
  );
  getIt.registerLazySingleton<VisibilitySubscriptionGuard>(
    VisibilitySubscriptionGuard.new,
  );
  getIt.registerLazySingleton<ProductionFinalizePipeline>(
    () => ProductionFinalizePipeline(
      orchestrator: getIt<AuthorityOrchestrator>(),
      votes: getIt<MatchVotesRepository>(),
      awards: getIt<AwardsRepository>(),
      serverTime: getIt<EgyptServerTimeService>(),
      lease: getIt<FinalizationLeaseService>(),
      retry: getIt<FinalizeRetryCoordinator>(),
      prefs: getIt<SharedPreferences>(),
      clubTag: FanAppIdentity.registryAppId,
      leaseOwnerId: 'lifecycle:${FanAppIdentity.registryAppId}',
    ),
  );
  getIt.registerLazySingleton<DeadSessionRecoveryService>(
    () => DeadSessionRecoveryService(
      finalizePipeline: getIt<ProductionFinalizePipeline>(),
      serverTime: getIt<EgyptServerTimeService>(),
    ),
  );
  getIt.registerLazySingleton<VotingSessionLifecycleService>(
    () => VotingSessionLifecycleService(
      serverTime: getIt<EgyptServerTimeService>(),
      awardsRepository: getIt<AwardsRepository>(),
      finalizePipeline: getIt<ProductionFinalizePipeline>(),
      deadSessionRecovery: getIt<DeadSessionRecoveryService>(),
      clubTag: FanAppIdentity.registryAppId,
    ),
  );
  getIt.registerLazySingleton<StadiumCardRegistryRepository>(
    () => StadiumCardRegistryRepositoryRtdb(getIt<FirebaseDatabase>()),
  );
  getIt.registerLazySingleton<StadiumCmsRepository>(
    () => StadiumCmsRepositoryRtdb(getIt<FirebaseDatabase>()),
  );
  getIt.registerLazySingleton<StadiumCardUploadCoordinator>(
    () => StadiumCardUploadCoordinator(
      cloudinary: getIt<CloudinaryService>(),
      registry: getIt<StadiumCardRegistryRepository>(),
      cms: getIt<StadiumCmsRepository>(),
      connectivity: getIt<Connectivity>(),
    ),
  );
  getIt.registerLazySingleton<CrowdCardRepository>(
    () => CrowdCardRepositoryRtdb(getIt<FirebaseDatabase>()),
  );
  getIt.registerLazySingleton<OwnerCardUploadService>(
    () => OwnerCardUploadService(
      cloudinary: getIt<CloudinaryService>(),
      repository: getIt<CrowdCardRepository>(),
    ),
  );
  getIt.registerLazySingleton<OwnerMatchTemplateRepository>(
    () => OwnerMatchTemplateRepositoryRtdb(getIt<FirebaseDatabase>()),
  );
  getIt.registerLazySingleton<OwnerSessionDraftRepository>(
    () => OwnerSessionDraftRepositoryRtdb(getIt<FirebaseDatabase>()),
  );
  getIt.registerLazySingleton<OwnerTemplateWriter>(
    () => OwnerTemplateWriter(repository: getIt<OwnerMatchTemplateRepository>()),
  );
  getIt.registerLazySingleton<QuickLaunchService>(
    () => QuickLaunchService(templates: getIt<OwnerMatchTemplateRepository>()),
  );
  getIt.registerLazySingleton<RapidReplacementService>(
    RapidReplacementService.new,
  );
  getIt.registerLazySingleton<OperationalShortcuts>(
    () => OperationalShortcuts(
      quickLaunch: getIt<QuickLaunchService>(),
      drafts: getIt<OwnerSessionDraftRepository>(),
    ),
  );
  getIt.registerLazySingleton<CelebrationSeenStore>(
    () => CelebrationSeenStore(getIt<SharedPreferences>()),
  );

  // ===== Repository Services =====

  /// تسجيل Reels Feature
  getIt.registerLazySingleton<VideoRemoteDataSource>(
    () => VideoRemoteDataSource(),
  );
  getIt.registerLazySingleton<VideoRepository>(
    () => VideoRepositoryImpl(
      remoteDataSource: getIt<VideoRemoteDataSource>(),
      cloudinaryService: getIt<CloudinaryService>(),
    ),
  );

  /// تسجيل Matches Feature
  getIt.registerLazySingleton<BestPlayerRemoteDataSource>(
    () => BestPlayerRemoteDataSource(),
  );
  // ===== BLoC Services =====

  /// تسجيل BLoCs
  getIt.registerFactory<ReelsBloc>(
    () => ReelsBloc(videoRepository: getIt<VideoRepository>()),
  );
  getIt.registerFactory<MatchesBloc>(
    () => MatchesBloc(dataSource: getIt<BestPlayerRemoteDataSource>()),
  );
}

/// إنشاء عميل Dio محسّن
Dio _createDioClient() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: AppConfig.connectTimeoutDuration,
      receiveTimeout: AppConfig.receiveTimeoutDuration,
      responseType: ResponseType.json,
      contentType: 'application/json',
    ),
  );

  // إضافة Interceptors
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // يمكن إضافة Headers هنا
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // معالجة الاستجابة الناجحة
        return handler.next(response);
      },
      onError: (error, handler) {
        // معالجة الأخطاء
        return handler.next(error);
      },
    ),
  );

  return dio;
}

/// إعادة تعيين Service Locator (للاختبارات)
void resetServiceLocator() {
  getIt.reset();
}

/// التحقق من تسجيل خدمة معينة
bool isServiceRegistered<T extends Object>() {
  return getIt.isRegistered<T>();
}

/// الحصول على خدمة معينة
T getService<T extends Object>() {
  return getIt<T>();
}

/// تسجيل خدمة جديدة
void registerService<T extends Object>(T instance) {
  getIt.registerSingleton<T>(instance);
}

/// تسجيل Factory (لإنشاء نسخة جديدة في كل مرة)
void registerFactory<T extends Object>(
  T Function() factory,
) {
  getIt.registerFactory<T>(factory);
}

/// تسجيل Lazy Singleton (يتم إنشاؤه عند الاستخدام الأول)
void registerLazySingleton<T extends Object>(
  T Function() factory,
) {
  getIt.registerLazySingleton<T>(factory);
}

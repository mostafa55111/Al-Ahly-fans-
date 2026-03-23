import 'package:firebase_database/firebase_database.dart';
import 'package:gomhor_alahly_clean_new/core/services/firebase_service.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/datasources/video_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/repositories/video_repository_impl.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/usecases/get_reels.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/usecases/add_like.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/bloc/reels_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/marketplace/data/datasources/product_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/marketplace/data/repositories/product_repository_impl.dart';
import 'package:gomhor_alahly_clean_new/features/bus_booking/data/datasources/trip_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/bus_booking/data/repositories/trip_repository_impl.dart';
import 'package:gomhor_alahly_clean_new/features/voting_match_center/data/datasources/match_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/voting_match_center/data/repositories/match_repository_impl.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  factory ServiceLocator() {
    return _instance;
  }

  ServiceLocator._internal();

  late FirebaseDatabase _firebaseDatabase;

  Future<void> init() async {
    // Initialize Firebase
    await FirebaseService.initializeFirebase();
    _firebaseDatabase = FirebaseService.database;

    // Register Firebase Database
    _registerFirebaseDatabase();

    // Register Reels Feature
    _registerReelsFeature();

    // Register Marketplace Feature
    _registerMarketplaceFeature();

    // Register Bus Booking Feature
    _registerBusBookingFeature();

    // Register Voting & Match Center Feature
    _registerVotingMatchCenterFeature();
  }

  void _registerFirebaseDatabase() {
    // Firebase Database is already initialized in FirebaseService
  }

  void _registerReelsFeature() {
    // Data Sources
    final videoRemoteDataSource = VideoRemoteDataSourceImpl(_firebaseDatabase);

    // Repositories
    final videoRepository = VideoRepositoryImpl(remoteDataSource: videoRemoteDataSource);

    // Use Cases
    final getReels = GetReels(videoRepository);
    final addLike = AddLike(videoRepository);

    // BLoCs
    final reelsBloc = ReelsBloc(videoRepository: videoRepository);

    // Store instances (you can use GetIt or similar for better dependency injection)
    // For now, we'll use a simple approach
  }

  void _registerMarketplaceFeature() {
    // Data Sources
    final productRemoteDataSource = ProductRemoteDataSourceImpl(_firebaseDatabase);

    // Repositories
    final productRepository = ProductRepositoryImpl(remoteDataSource: productRemoteDataSource);

    // Store instances
  }

  void _registerBusBookingFeature() {
    // Data Sources
    final tripRemoteDataSource = TripRemoteDataSourceImpl(_firebaseDatabase);

    // Repositories
    final tripRepository = TripRepositoryImpl(remoteDataSource: tripRemoteDataSource);

    // Store instances
  }

  void _registerVotingMatchCenterFeature() {
    // Data Sources
    final matchRemoteDataSource = MatchRemoteDataSourceImpl(_firebaseDatabase);

    // Repositories
    final matchRepository = MatchRepositoryImpl(remoteDataSource: matchRemoteDataSource);

    // Store instances
  }

  // Getter methods to retrieve instances
  FirebaseDatabase get firebaseDatabase => _firebaseDatabase;
}

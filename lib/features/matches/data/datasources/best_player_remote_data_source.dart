import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

/// Model for Best Player data
class BestPlayerModel {
  final String id;
  final String name;
  final String position;
  final String imageUrl;
  final int goals;
  final int assists;
  final String team;

  const BestPlayerModel({
    required this.id,
    required this.name,
    required this.position,
    required this.imageUrl,
    required this.goals,
    required this.assists,
    required this.team,
  });

  factory BestPlayerModel.fromMap(Map<String, dynamic> map, String id) {
    debugPrint('🔥 PLAYER MODEL: Parsing player data for id: $id');
    debugPrint('🔥 PLAYER MODEL: Raw map data: $map');
    
    return BestPlayerModel(
      id: id,
      name: map['name'] ?? 'Unknown Player',
      position: map['position'] ?? 'Player',
      imageUrl: map['cardUrl'] ?? map['imageUrl'] ?? '',
      goals: _parseCount(map['goals']?.toString() ?? '0'),
      assists: _parseCount(map['assists']?.toString() ?? '0'),
      team: map['team'] ?? 'الأهلي',
    );
  }

  static int _parseCount(String value) {
    try {
      return int.parse(value);
    } catch (e) {
      return 0;
    }
  }
}

/// Remote data source for best players from Realtime Database
class BestPlayerRemoteDataSource {
  final FirebaseDatabase _database;
  final String _bestPlayerPath = 'best_player';

  BestPlayerRemoteDataSource() : _database = FirebaseDatabase.instance {
    debugPrint('🔥 BestPlayerRemoteDataSource initialized');
    debugPrint('🔥 Realtime Database URL: ${_database.databaseURL}');
  }

  /// Fetch best players from Realtime Database
  Future<List<BestPlayerModel>> fetchBestPlayers() async {
    try {
      debugPrint('🔥 REALTIME DB: Fetching best players');
      debugPrint('🔥 REALTIME DB: Database URL: ${_database.databaseURL}');
      
      DatabaseReference bestPlayerRef = _database.ref(_bestPlayerPath);
      final DataSnapshot snapshot = await bestPlayerRef.get();
      
      debugPrint('🔥 REALTIME DB: Retrieved best players data - exists: ${snapshot.exists}');
      debugPrint('🔥 REALTIME DB: Data type: ${snapshot.value.runtimeType}');
      debugPrint('🔥 REALTIME DB: Raw data: ${snapshot.value}');
      
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> playersData = snapshot.value as Map;
        final List<BestPlayerModel> players = [];
        
        debugPrint('🔥 REALTIME DB: Processing ${playersData.length} player entries');
        
        playersData.forEach((key, value) {
          debugPrint('🔥 REALTIME DB: Processing player key: $key, value type: ${value.runtimeType}');
          debugPrint('🔥 REALTIME DB: Raw player data: $value');
          
          if (value is Map) {
            // Convert Map<Object?, Object?> to Map<String, dynamic>
            final Map<String, dynamic> playerData = {};
            value.forEach((k, v) {
              if (k != null) {
                playerData[k.toString()] = v?.toString() ?? '';
              }
            });
            debugPrint('🔥 REALTIME DB: Converted player data: $playerData');
            players.add(BestPlayerModel.fromMap(playerData, key.toString()));
          } else {
            debugPrint('❌ REALTIME DB: Invalid data format for player $key');
          }
        });
        
        debugPrint('🔥 REALTIME DB: Parsed ${players.length} best players');
        return players;
      } else {
        debugPrint('🔥 REALTIME DB: No best players found');
        return [];
      }
    } catch (e) {
      debugPrint('🔥 REALTIME DB ERROR: Failed to fetch best players: $e');
      throw Exception('Failed to fetch best players: $e');
    }
  }
}

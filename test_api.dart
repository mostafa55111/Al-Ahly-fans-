import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

void main() async {
  debugPrint('🔍 Testing TheSportDB API Connection...');
  
  const String apiUrl = 'https://www.thesportsdb.com/api/v1/json/3';
  const String teamId = '133912'; // Al Ahly team ID in TheSportDB
  
  final headers = {
    'Accept': 'application/json',
  };
  
  try {
    debugPrint('📡 Sending request to TheSportDB API...');
    final response = await http.get(
      Uri.parse('$apiUrl/eventsnext.php?id=$teamId'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));
    
    debugPrint('📊 Response Status: ${response.statusCode}');
    debugPrint('📦 Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['events'] != null) {
        debugPrint('✅ TheSportDB API Connection Successful!');
        debugPrint('📋 Found ${data['events'].length} upcoming matches');
        
        for (var match in data['events']) {
          debugPrint('⚽ ${match['strHomeTeam']} vs ${match['strAwayTeam']} - ${match['dateEvent']}');
        }
      } else {
        debugPrint('⚠️  API Response format unexpected');
      }
    } else {
      debugPrint('❌ API Error: ${response.statusCode}');
      debugPrint('💡 Error details: ${response.body}');
    }
  } catch (e) {
    debugPrint('❌ Exception occurred: $e');
  }
}
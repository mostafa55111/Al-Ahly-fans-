import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('🔍 Testing TheSportDB API Connection...');
  
  const String apiUrl = 'https://www.thesportsdb.com/api/v1/json/3';
  const String teamId = '133912'; // Al Ahly team ID in TheSportDB
  
  final headers = {
    'Accept': 'application/json',
  };
  
  try {
    print('📡 Sending request to TheSportDB API...');
    final response = await http.get(
      Uri.parse('$apiUrl/eventsnext.php?id=$teamId'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));
    
    print('📊 Response Status: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['events'] != null) {
        print('✅ TheSportDB API Connection Successful!');
        print('📋 Found ${data['events'].length} upcoming matches');
        
        // Display match details
        for (var match in data['events']) {
          print('⚽ ${match['strHomeTeam']} vs ${match['strAwayTeam']} - ${match['dateEvent']}');
        }
      } else {
        print('⚠️  API Response format unexpected');
      }
    } else {
      print('❌ API Error: ${response.statusCode}');
      print('💡 Error details: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception occurred: $e');
  }
}
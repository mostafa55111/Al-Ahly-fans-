import 'dart:convert';
import 'package:http/http.dart' as http;

class SportsApiService {
  Future<http.Response> get(String url) async {
    return await http.get(Uri.parse(url));
  }

  Future<List<dynamic>> getNextMatches() async {
    return [];
  }

  Future<List<dynamic>> getLastMatches() async {
    return [];
  }

  String getMatchStatusDisplay(String status) {
    return status;
  }
}

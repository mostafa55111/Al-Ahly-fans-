import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TestReelsScreen extends StatefulWidget {
  @override
  _TestReelsScreenState createState() => _TestReelsScreenState();
}

class _TestReelsScreenState extends State<TestReelsScreen> {
  List<String> videos = [];

  @override
  void initState() {
    super.initState();
    debugFirebaseConnection();
    fetchReels();
  }

  Future<void> debugFirebaseConnection() async {
    try {
      final db = FirebaseDatabase.instance;
      final ref = db.ref('reels');

      print("STEP 2 - DB REF: $ref");
      print("STEP 2 - DB INSTANCE: $db");

      final snapshot = await ref.get();

      print("STEP 3 - EXISTS: ${snapshot.exists}");
      print("STEP 3 - RAW DATA: ${snapshot.value}");
      print("STEP 3 - SNAPSHOT TYPE: ${snapshot.value.runtimeType}");
    } catch (e) {
      print("STEP 3 - FIREBASE ERROR: $e");
      print("STEP 3 - ERROR TYPE: ${e.runtimeType}");
    }

    // STEP 4: Verify database URL
    final expectedUrl = 'https://gomhor-al-ahly-default-rtdb.firebaseio.com/';
    final actualUrl = FirebaseDatabase.instance.databaseURL;
    print("STEP 4 - EXPECTED URL: $expectedUrl");
    print("STEP 4 - ACTUAL URL: $actualUrl");
    print("STEP 4 - URL MATCHES: ${actualUrl == expectedUrl}");
  }

  Future<void> fetchReels() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('reels').get();

      print("RAW DATA: ${snapshot.value}");
      print("SNAPSHOT EXISTS: ${snapshot.exists}");
      print("SNAPSHOT TYPE: ${snapshot.value.runtimeType}");

      if (snapshot.exists) {
        final data = snapshot.value as Map?;
        if (data != null) {
          print("DATA ENTRIES COUNT: ${data.entries.length}");
          final list = data.entries.map((e) {
            print("ENTRY KEY: ${e.key}, VALUE TYPE: ${e.value.runtimeType}");
            print("ENTRY VALUE: ${e.value}");
            return e.value['videoUrl'] as String;
          }).toList();

          setState(() {
            videos = list;
          });
        }
      } else {
        print("SNAPSHOT DOES NOT EXIST - No reels data found");
      }
    } catch (e) {
      print("FETCH ERROR: $e");
      print("FETCH ERROR TYPE: ${e.runtimeType}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: videos.isEmpty
          ? Center(child: Text("No videos", style: TextStyle(color: Colors.white)))
          : PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: videos.length,
              itemBuilder: (_, i) {
                return Center(
                  child: Text(
                    videos[i],
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
    );
  }
}

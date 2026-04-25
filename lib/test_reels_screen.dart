import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TestReelsScreen extends StatefulWidget {
  const TestReelsScreen({super.key});

  @override
  TestReelsScreenState createState() => TestReelsScreenState();
}

class TestReelsScreenState extends State<TestReelsScreen> {
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

      debugPrint("STEP 2 - DB REF: $ref");
      debugPrint("STEP 2 - DB INSTANCE: $db");

      final snapshot = await ref.get();

      debugPrint("STEP 3 - EXISTS: ${snapshot.exists}");
      debugPrint("STEP 3 - RAW DATA: ${snapshot.value}");
      debugPrint("STEP 3 - SNAPSHOT TYPE: ${snapshot.value.runtimeType}");
    } catch (e) {
      debugPrint("STEP 3 - FIREBASE ERROR: $e");
      debugPrint("STEP 3 - ERROR TYPE: ${e.runtimeType}");
    }

    // STEP 4: Verify database URL
    const expectedUrl = 'https://gomhor-al-ahly-default-rtdb.firebaseio.com/';
    final actualUrl = FirebaseDatabase.instance.databaseURL;
    debugPrint("STEP 4 - EXPECTED URL: $expectedUrl");
    debugPrint("STEP 4 - ACTUAL URL: $actualUrl");
    debugPrint("STEP 4 - URL MATCHES: ${actualUrl == expectedUrl}");
  }

  Future<void> fetchReels() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('reels').get();

      debugPrint("RAW DATA: ${snapshot.value}");
      debugPrint("SNAPSHOT EXISTS: ${snapshot.exists}");
      debugPrint("SNAPSHOT TYPE: ${snapshot.value.runtimeType}");

      if (snapshot.exists) {
        final data = snapshot.value as Map?;
        if (data != null) {
          debugPrint("DATA ENTRIES COUNT: ${data.entries.length}");
          final list = data.entries.map((e) {
            debugPrint("ENTRY KEY: ${e.key}, VALUE TYPE: ${e.value.runtimeType}");
            debugPrint("ENTRY VALUE: ${e.value}");
            return e.value['videoUrl'] as String;
          }).toList();

          setState(() {
            videos = list;
          });
        }
      } else {
        debugPrint("SNAPSHOT DOES NOT EXIST - No reels data found");
      }
    } catch (e) {
      debugPrint("FETCH ERROR: $e");
      debugPrint("FETCH ERROR TYPE: ${e.runtimeType}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: videos.isEmpty
          ? const Center(child: Text("No videos", style: TextStyle(color: Colors.white)))
          : PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: videos.length,
              itemBuilder: (_, i) {
                return Center(
                  child: Text(
                    videos[i],
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
    );
  }
}

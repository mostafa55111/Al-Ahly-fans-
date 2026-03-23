import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

class PredictWinScreen extends StatefulWidget {
  final Map<String, dynamic> matchData;
  const PredictWinScreen({super.key, required this.matchData});

  @override
  State<PredictWinScreen> createState() => _PredictWinScreenState();
}

class _PredictWinScreenState extends State<PredictWinScreen> {
  String? _selectedPrediction; // win, draw, loss
  bool _isPredicted = false;
  final int _points = 0;

  @override
  void initState() {
    super.initState();
    _checkUserPrediction();
  }

  void _checkUserPrediction() async {
    const userId = "current_user_id"; // يتم الحصول عليه من Firebase Auth
    final predictionRef = FirebaseDatabase.instance.ref("predictions/${widget.matchData['id']}/$userId");
    final snapshot = await predictionRef.get();
    
    if (snapshot.exists) {
      setState(() {
        _selectedPrediction = snapshot.value as String?;
        _isPredicted = true;
      });
    }
  }

  void _submitPrediction() async {
    if (_selectedPrediction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("اختر توقعك أولاً")),
      );
      return;
    }

    const userId = "current_user_id";
    final matchId = widget.matchData['id'];
    
    // حفظ التوقع في Firebase
    await FirebaseDatabase.instance
        .ref("predictions/$matchId/$userId")
        .set(_selectedPrediction);

    // إضافة نقاط للمستخدم
    await FirebaseDatabase.instance
        .ref("users/$userId/prediction_points")
        .set(_points + 10);

    setState(() => _isPredicted = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تم حفظ توقعك! +10 نقاط 🎉")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeTeam = widget.matchData['strHomeTeam'] ?? 'فريق';
    final awayTeam = widget.matchData['strAwayTeam'] ?? 'فريق';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "ملك التوقعات 👑",
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset('assets/images/gold_pattern.png', repeat: ImageRepeat.repeat),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                FadeInDown(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.withAlpha(25), Colors.red.withAlpha(25)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amber.withAlpha(76)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "توقع نتيجة المباراة",
                          style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.sports_soccer, color: Colors.amber, size: 40),
                                const SizedBox(height: 8),
                                Text(homeTeam, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              ],
                            ),
                            const Text("VS", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            Column(
                              children: [
                                const Icon(Icons.sports_soccer, color: Colors.amber, size: 40),
                                const SizedBox(height: 8),
                                Text(awayTeam, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: const Text(
                    "اختر توقعك:",
                    style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 15),
                _buildPredictionOption("فوز الأهلي 🏆", "win", Colors.green),
                const SizedBox(height: 10),
                _buildPredictionOption("تعادل ⚖️", "draw", Colors.blue),
                const SizedBox(height: 10),
                _buildPredictionOption("خسارة الأهلي ❌", "loss", Colors.red),
                const SizedBox(height: 30),
                if (!_isPredicted)
                  FadeInUp(
                    child: GestureDetector(
                      onTap: _submitPrediction,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red, Colors.red.withAlpha(178)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.red.withAlpha(128), blurRadius: 15, spreadRadius: 2),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "تأكيد التوقع (+10 نقاط)",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withAlpha(128)),
                    ),
                    child: const Center(
                      child: Text(
                        "✓ تم حفظ توقعك",
                        style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                _buildLeaderboard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionOption(String title, String value, Color color) {
    final isSelected = _selectedPrediction == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPrediction = value),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(76) : Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withAlpha(25),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? color : Colors.white.withAlpha(76)),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.amber.withAlpha(51)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🏆 أفضل المتوقعين",
              style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildLeaderboardItem("أحمد محمد", 850, 1),
            _buildLeaderboardItem("فاطمة علي", 720, 2),
            _buildLeaderboardItem("محمود حسن", 650, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(String name, int points, int rank) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: rank == 1 ? Colors.amber : rank == 2 ? Colors.grey[400] : Colors.orange.withAlpha(128),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "$rank",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            "$points نقطة",
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

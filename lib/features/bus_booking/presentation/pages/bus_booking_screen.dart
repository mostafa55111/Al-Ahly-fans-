import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class BusBookingScreen extends StatefulWidget {
  const BusBookingScreen({super.key});

  @override
  State<BusBookingScreen> createState() => _BusBookingScreenState();
}

class _BusBookingScreenState extends State<BusBookingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ترحال الجماهير',
          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // زخرفة ذهبية في الخلفية
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset('assets/images/gold_pattern.png', repeat: ImageRepeat.repeat),
            ),
          ),
          ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: 4, // عينة من الرحلات
            itemBuilder: (context, index) {
              return FadeInLeft(
                delay: Duration(milliseconds: index * 150),
                child: _buildTripCard(index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(int index) {
    final trips = [
      {'origin': 'القاهرة', 'destination': 'الإسكندرية', 'price': '150', 'time': '08:00 AM', 'date': '2026-03-10'},
      {'origin': 'القاهرة', 'destination': 'الإسماعيلية', 'price': '120', 'time': '09:30 AM', 'date': '2026-03-12'},
      {'origin': 'القاهرة', 'destination': 'بورسعيد', 'price': '180', 'time': '07:00 AM', 'date': '2026-03-15'},
      {'origin': 'القاهرة', 'destination': 'السويس', 'price': '100', 'time': '10:00 AM', 'date': '2026-03-18'},
    ];

    final trip = trips[index % trips.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_bus, color: Colors.red, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${trip['origin']} ➔ ${trip['destination']}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.amber, size: 14),
                    const SizedBox(width: 5),
                    Text(trip['date']!, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                    const SizedBox(width: 15),
                    const Icon(Icons.access_time, color: Colors.amber, size: 14),
                    const SizedBox(width: 5),
                    Text(trip['time']!, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${trip['price']} ج.م",
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 5),
              const Text("حجز", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

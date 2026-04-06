import 'package:flutter/material.dart';

class BusBookingScreen extends StatelessWidget {
  const BusBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Booking'),
      ),
      body: const Center(
        child: Text('Bus Booking Screen'),
      ),
    );
  }
}

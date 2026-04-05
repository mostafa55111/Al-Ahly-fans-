import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PerformanceMonitor extends StatefulWidget {
  final Widget child;

  const PerformanceMonitor({
    super.key,
    required this.child,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> with WidgetsBindingObserver {
  int _frameCount = 0;
  DateTime _lastTime = DateTime.now();
  double _fps = 0.0;
  double _minFps = 60.0;
  double _maxFps = 0.0;
  List<double> _fpsHistory = [];
  bool _showOverlay = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startMonitoring() {
    // Use a timer to calculate FPS
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      
      final now = DateTime.now();
      final elapsed = now.difference(_lastTime).inMilliseconds;
      
      if (elapsed > 0) {
        final currentFps = (_frameCount * 1000) / elapsed;
        _fps = currentFps;
        
        _fpsHistory.add(currentFps);
        if (_fpsHistory.length > 100) {
          _fpsHistory.removeAt(0);
        }
        
        _minFps = _minFps > currentFps ? currentFps : _minFps;
        _maxFps = _maxFps < currentFps ? currentFps : _maxFps;
        
        _frameCount = 0;
        _lastTime = now;
        
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void didUpdateWidget(PerformanceMonitor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset counters when widget updates
    _frameCount = 0;
    _lastTime = DateTime.now();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _frameCount = 0;
    }
  }

  void _onFrame(Duration timestamp) {
    _frameCount++;
  }

  double get _averageFps {
    if (_fpsHistory.isEmpty) return 0.0;
    final sum = _fpsHistory.reduce((a, b) => a + b);
    return sum / _fpsHistory.length;
  }

  String _getFpsColor() {
    if (_fps >= 55) return '🟢'; // Green
    if (_fps >= 30) return '🟡'; // Yellow  
    return '🔴'; // Red
  }

  @override
  Widget build(BuildContext context) {
    // Register frame callback
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
    
    return Stack(
      children: [
        widget.child,
        
        // Performance overlay
        if (_showOverlay)
          Positioned(
            top: 50,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_getFpsColor()} FPS: ${_fps.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Avg: ${_averageFps.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Min: ${_minFps.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Max: ${_maxFps.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jank: ${(_fps < 30 ? 'YES' : 'NO')}',
                    style: TextStyle(
                      color: _fps < 30 ? Colors.red : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Toggle button
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showOverlay = !_showOverlay;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showOverlay ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _showOverlay ? Icons.speed : Icons.speed_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

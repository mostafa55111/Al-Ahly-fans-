#!/usr/bin/env dart

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Script to analyze VideoPlayerController lifecycle logs
/// Usage: dart analyze_controller_logs.dart <log_file_path>

void main(List<String> args) {
  if (args.isEmpty) {
    debugPrint('Usage: dart analyze_controller_logs.dart <log_file_path>');
    exit(1);
  }

  final logFile = File(args[0]);
  if (!logFile.existsSync()) {
    debugPrint('Error: Log file not found: ${args[0]}');
    exit(1);
  }

  final logs = logFile.readAsLinesSync();
  final analysis = analyzeLogs(logs);
  
  debugPrint('\nVideoPlayerController Lifecycle Analysis\n');
  debugPrint('=' * 50);
  
  debugPrint('\nSummary:');
  debugPrint('- Total logs processed: ${logs.length}');
  debugPrint('- Controller creations: ${analysis.creations}');
  debugPrint('- Controller disposals: ${analysis.disposals}');
  debugPrint('- Index changes: ${analysis.indexChanges}');
  debugPrint('- Peak controller count: ${analysis.peakControllerCount}');
  debugPrint('- Final controller count: ${analysis.finalControllerCount}');
  
  debugPrint('\nHealth Check:');
  debugPrint('- Max controllers exceeded: ${analysis.maxControllersExceeded ? 'YES' : 'NO'}');
  debugPrint('- Disposal failures: ${analysis.disposalFailures}');
  debugPrint('- Memory leaks detected: ${analysis.memoryLeaksDetected ? 'YES' : 'NO'}');
  debugPrint('- Performance issues: ${analysis.performanceIssues}');
  
  if (analysis.issues.isNotEmpty) {
    debugPrint('\nIssues Found:');
    for (final issue in analysis.issues) {
      debugPrint('  - $issue');
    }
  }
  
  if (analysis.warnings.isNotEmpty) {
    debugPrint('\nWarnings:');
    for (final warning in analysis.warnings) {
      debugPrint('  - $warning');
    }
  }
  
  debugPrint('\nController Timeline:');
  for (final event in analysis.timeline.take(20)) {
    debugPrint('  ${event.time.padRight(12)} ${event.type.padRight(20)} ${event.description}');
  }
  if (analysis.timeline.length > 20) {
    debugPrint('  ... and ${analysis.timeline.length - 20} more events');
  }
  
  debugPrint('\nRecommendation:');
  debugPrint(analysis.recommendation);
}

class LogAnalysis {
  int creations = 0;
  int disposals = 0;
  int indexChanges = 0;
  int peakControllerCount = 0;
  int finalControllerCount = 0;
  bool maxControllersExceeded = false;
  int disposalFailures = 0;
  bool memoryLeaksDetected = false;
  int performanceIssues = 0;
  List<String> issues = [];
  List<String> warnings = [];
  List<ControllerEvent> timeline = [];
  String recommendation = '';
}

class ControllerEvent {
  final String time;
  final String type;
  final String description;
  
  ControllerEvent(this.time, this.type, this.description);
}

LogAnalysis analyzeLogs(List<String> logs) {
  final analysis = LogAnalysis();
  final activeControllers = <int>{};
  int currentControllerCount = 0;
  
  for (int i = 0; i < logs.length; i++) {
    final log = logs[i];
    final timestamp = extractTimestamp(log);
    
    // Track controller creations
    if (log.contains('🎥 CONTROLLER CREATED:')) {
      analysis.creations++;
      currentControllerCount++;
      activeControllers.add(extractIndex(log));
      
      if (currentControllerCount > analysis.peakControllerCount) {
        analysis.peakControllerCount = currentControllerCount;
      }
      
      if (currentControllerCount > 2) {
        analysis.maxControllersExceeded = true;
        analysis.issues.add('Controller count exceeded limit: $currentControllerCount > 2 at line ${i + 1}');
      }
      
      analysis.timeline.add(ControllerEvent(timestamp, 'CREATED', log));
    }
    
    // Track controller disposals
    if (log.contains('🎥 CONTROLLER DISPOSED:')) {
      analysis.disposals++;
      currentControllerCount--;
      activeControllers.remove(extractIndex(log));
      
      analysis.timeline.add(ControllerEvent(timestamp, 'DISPOSED', log));
    }
    
    // Track index changes
    if (log.contains('🎥 INDEX CHANGED:')) {
      analysis.indexChanges++;
      analysis.timeline.add(ControllerEvent(timestamp, 'INDEX_CHANGE', log));
    }
    
    // Track disposal failures
    if (log.contains('🎥 ERROR: Failed to dispose controller')) {
      analysis.disposalFailures++;
      analysis.issues.add('Controller disposal failure at line ${i + 1}');
    }
    
    // Track performance issues
    if (log.contains('🎥 TIMEOUT:') || log.contains('🎬 ERROR:')) {
      analysis.performanceIssues++;
      analysis.warnings.add('Performance issue at line ${i + 1}');
    }
    
    // Track cleanup operations
    if (log.contains('🎥 CONTROLLER COUNT:')) {
      final count = extractControllerCount(log);
      analysis.finalControllerCount = count;
      analysis.timeline.add(ControllerEvent(timestamp, 'COUNT', log));
    }
  }
  
  // Check for memory leaks
  if (analysis.creations != analysis.disposals) {
    analysis.memoryLeaksDetected = true;
    analysis.issues.add('Memory leak detected: ${analysis.creations} created vs ${analysis.disposals} disposed');
  }
  
  // Generate recommendation
  if (analysis.issues.isEmpty) {
    analysis.recommendation = '✅ Controller lifecycle is working correctly!';
  } else {
    analysis.recommendation = '❌ Issues found that need to be addressed.';
  }
  
  return analysis;
}

String extractTimestamp(String log) {
  // Extract timestamp from log line (format may vary)
  final match = RegExp(r'\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d{3}').firstMatch(log);
  return match?.group(0) ?? 'Unknown';
}

int extractIndex(String log) {
  // Extract index from log line
  final match = RegExp(r'Index (\d+)').firstMatch(log);
  return match != null ? int.parse(match.group(1)!) : -1;
}

int extractControllerCount(String log) {
  // Extract controller count from log line
  final match = RegExp(r'(\d+)/2').firstMatch(log);
  return match != null ? int.parse(match.group(1)!) : 0;
}

class DeviceCompatibilityReport {
  const DeviceCompatibilityReport({
    required this.profileName,
    required this.stadiumOpenMs,
    required this.avgFrameMs,
    required this.reconnectMs,
    required this.memoryGrowthMb,
    required this.imagePressureScore,
    required this.batteryDrainScore,
    required this.passed,
  });

  final String profileName;
  final int stadiumOpenMs;
  final double avgFrameMs;
  final int reconnectMs;
  final double memoryGrowthMb;
  final double imagePressureScore;
  final double batteryDrainScore;
  final bool passed;

  Map<String, dynamic> toJson() => {
        'profileName': profileName,
        'stadiumOpenMs': stadiumOpenMs,
        'avgFrameMs': avgFrameMs,
        'reconnectMs': reconnectMs,
        'memoryGrowthMb': memoryGrowthMb,
        'imagePressureScore': imagePressureScore,
        'batteryDrainScore': batteryDrainScore,
        'passed': passed,
      };
}

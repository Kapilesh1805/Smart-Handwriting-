class PressureUtils {
  /// Compute average pressure percentage from pressure points
  /// Converts from 0.0-1.0 range to 0-100% range
  static double? computeAveragePressure(List<Map<String, dynamic>> pressurePoints) {
    if (pressurePoints.isEmpty) return null;

    try {
      final pressures = pressurePoints.map((p) => (p['pressure'] ?? 0).toDouble()).toList();
      final avg = (pressures.reduce((a, b) => a + b) / pressures.length) * 100;
      return avg;
    } catch (e) {
      // Error handled by caller
      return null;
    }
  }
}
import 'package:intl/intl.dart';

/// Formatting utilities for hardware metrics, network throughput, and timestamps.
class MetricFormatters {
  MetricFormatters._();

  /// Formats byte quantities into human-readable B, KB, MB, GB, TB strings.
  static String formatBytes(num? bytes) {
    if (bytes == null || bytes < 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(d >= 100 || i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  /// Formats network transfer rate in B/s, KB/s, MB/s.
  static String formatRate(num? bytesPerSec) {
    if (bytesPerSec == null || bytesPerSec < 0) return '0 B/s';
    return '${formatBytes(bytesPerSec)}/s';
  }

  /// Formats UNIX timestamp in seconds to local time string (HH:mm:ss or yyyy-MM-dd HH:mm).
  static String formatTimestamp(int? unixSeconds) {
    if (unixSeconds == null || unixSeconds <= 0) return 'Never';
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds <= 0) {
      return 'Just now';
    } else if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return DateFormat('HH:mm:ss').format(dt);
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  /// Formats temperature with Celsius unit.
  static String formatTemp(num? celsius) {
    if (celsius == null) return '-- °C';
    return '${celsius.toStringAsFixed(1)}°C';
  }

  /// Formats percentage with 1 decimal.
  static String formatPercent(num? percent) {
    if (percent == null) return '0.0%';
    return '${percent.toStringAsFixed(1)}%';
  }
}

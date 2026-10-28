import 'package:ancymon_mobile/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetricFormatters Tests', () {
    test('formatBytes formats numbers accurately into B, KB, MB, GB, TB', () {
      expect(MetricFormatters.formatBytes(null), equals('0 B'));
      expect(MetricFormatters.formatBytes(-50), equals('0 B'));
      expect(MetricFormatters.formatBytes(500), equals('500 B'));
      expect(MetricFormatters.formatBytes(1024), equals('1.0 KB'));
      expect(MetricFormatters.formatBytes(1048576), equals('1.0 MB'));
      expect(MetricFormatters.formatBytes(1073741824), equals('1.0 GB'));
    });

    test('formatRate formats rate strings', () {
      expect(MetricFormatters.formatRate(null), equals('0 B/s'));
      expect(MetricFormatters.formatRate(1048576), equals('1.0 MB/s'));
    });

    test('formatTimestamp handles clock drift and negative diffs gracefully', () {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Null or invalid timestamps
      expect(MetricFormatters.formatTimestamp(null), equals('Never'));
      expect(MetricFormatters.formatTimestamp(0), equals('Never'));
      expect(MetricFormatters.formatTimestamp(-100), equals('Never'));

      // Future timestamps (negative diff due to host/server clock drift, e.g. +3 seconds ahead)
      expect(MetricFormatters.formatTimestamp(nowSec + 3), equals('Just now'));
      expect(MetricFormatters.formatTimestamp(nowSec + 1), equals('Just now'));

      // Right now (0s diff)
      expect(MetricFormatters.formatTimestamp(nowSec), equals('Just now'));

      // Past timestamps within 60s
      expect(MetricFormatters.formatTimestamp(nowSec - 5), equals('5s ago'));
      expect(MetricFormatters.formatTimestamp(nowSec - 45), equals('45s ago'));

      // Past timestamps within 60m
      expect(MetricFormatters.formatTimestamp(nowSec - 120), equals('2m ago'));
      expect(MetricFormatters.formatTimestamp(nowSec - 1800), equals('30m ago'));
    });

    test('formatTemp formats temperature strings', () {
      expect(MetricFormatters.formatTemp(null), equals('-- °C'));
      expect(MetricFormatters.formatTemp(48.56), equals('48.6°C'));
    });

    test('formatPercent formats percentage strings', () {
      expect(MetricFormatters.formatPercent(null), equals('0.0%'));
      expect(MetricFormatters.formatPercent(42.37), equals('42.4%'));
    });
  });
}

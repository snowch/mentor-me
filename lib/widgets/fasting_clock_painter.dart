// lib/widgets/fasting_clock_painter.dart
// Custom painter for fasting clock visualization
// Shows eating window (green) and fasting window (red/orange) with clock hands

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/fasting_entry.dart';

class FastingClockPainter extends CustomPainter {
  final FastingGoal goal;
  final DateTime currentTime;
  final bool isFasting;

  FastingClockPainter({
    required this.goal,
    required this.currentTime,
    required this.isFasting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw clock face background
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw zones if eating window is configured
    if (goal.eatingWindowStart != null && goal.eatingWindowEnd != null) {
      _drawZones(canvas, center, radius);
    }

    // Draw hour markers
    _drawHourMarkers(canvas, center, radius);

    // Draw clock hands
    _drawClockHands(canvas, center, radius);

    // Draw center dot
    final centerDotPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, centerDotPaint);
  }

  void _drawZones(Canvas canvas, Offset center, double radius) {
    final start = goal.eatingWindowStart!;
    final end = goal.eatingWindowEnd!;

    // Convert times to angles (12 o'clock = -90 degrees)
    final startAngle = _timeToAngle(start);
    final endAngle = _timeToAngle(end);

    // Calculate sweep angles
    double eatingSweep;
    double fastingSweep;
    double fastingStart;

    if (endAngle > startAngle) {
      // Normal case: eating window doesn't cross midnight
      eatingSweep = endAngle - startAngle;
      fastingSweep = 360 - eatingSweep;
      fastingStart = endAngle;
    } else {
      // Eating window crosses midnight
      eatingSweep = (360 - startAngle) + endAngle;
      fastingSweep = 360 - eatingSweep;
      fastingStart = endAngle;
    }

    // Draw fasting zone (red/orange)
    final fastingPaint = Paint()
      ..color = Colors.red.shade100.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      _degreesToRadians(fastingStart - 90),
      _degreesToRadians(fastingSweep),
      true,
      fastingPaint,
    );

    // Draw eating zone (green)
    final eatingPaint = Paint()
      ..color = Colors.green.shade100.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      _degreesToRadians(startAngle - 90),
      _degreesToRadians(eatingSweep),
      true,
      eatingPaint,
    );

    // Draw border arcs for clarity
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Eating zone border
    borderPaint.color = Colors.green.shade400;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      _degreesToRadians(startAngle - 90),
      _degreesToRadians(eatingSweep),
      true,
      borderPaint,
    );

    // Fasting zone border
    borderPaint.color = Colors.red.shade400;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      _degreesToRadians(fastingStart - 90),
      _degreesToRadians(fastingSweep),
      true,
      borderPaint,
    );
  }

  void _drawHourMarkers(Canvas canvas, Offset center, double radius) {
    final markerPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final isMainHour = i % 3 == 0; // 12, 3, 6, 9
      final markerLength = isMainHour ? 15.0 : 10.0;
      final markerWidth = isMainHour ? 3.0 : 2.0;

      markerPaint.strokeWidth = markerWidth;

      final startX = center.dx + (radius - markerLength - 10) * math.cos(angle);
      final startY = center.dy + (radius - markerLength - 10) * math.sin(angle);
      final endX = center.dx + (radius - 10) * math.cos(angle);
      final endY = center.dy + (radius - 10) * math.sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        markerPaint,
      );
    }
  }

  void _drawClockHands(Canvas canvas, Offset center, double radius) {
    final hour = currentTime.hour % 12;
    final minute = currentTime.minute;

    // Hour hand
    final hourAngle = ((hour + minute / 60) * 30 - 90) * math.pi / 180;
    final hourPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final hourLength = radius * 0.4;
    canvas.drawLine(
      center,
      Offset(
        center.dx + hourLength * math.cos(hourAngle),
        center.dy + hourLength * math.sin(hourAngle),
      ),
      hourPaint,
    );

    // Minute hand
    final minuteAngle = (minute * 6 - 90) * math.pi / 180;
    final minutePaint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final minuteLength = radius * 0.55;
    canvas.drawLine(
      center,
      Offset(
        center.dx + minuteLength * math.cos(minuteAngle),
        center.dy + minuteLength * math.sin(minuteAngle),
      ),
      minutePaint,
    );
  }

  double _timeToAngle(TimeOfDay time) {
    // Convert time to angle (0-360 degrees, with 0 at 12 o'clock)
    final totalMinutes = time.hour * 60 + time.minute;
    return (totalMinutes / (24 * 60)) * 360;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  @override
  bool shouldRepaint(FastingClockPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime ||
        oldDelegate.goal != goal ||
        oldDelegate.isFasting != isFasting;
  }
}

import 'dart:math' as math;
import 'package:forui/forui.dart';
import 'package:flutter/material.dart';

class ChartData {
  final String label;
  final double value;
  final Color color;
  final double maxValue;

  ChartData({
    required this.label,
    required this.value,
    required this.color,
    required this.maxValue,
  });
}

class Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const Legend({
    super.key,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 12,
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class RadialChart extends CustomPainter {
  final List<ChartData> data;
  final double accuracyPercent;
  final dynamic theme;

  RadialChart({
    required this.data,
    required this.accuracyPercent,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2 - 20;
    final strokeWidth = 20.0;

    // Draw background circle for accuracy
    final backgroundPaint = Paint()
      ..color = data[0].color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, baseRadius, backgroundPaint);

    // Draw progress arc for accuracy
    final progress = (data[0].value / data[0].maxValue).clamp(0.0, 1.0);
    final sweepAngle = progress * 2 * math.pi;

    final progressPaint = Paint()
      ..color = data[0].color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: baseRadius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );

    // Draw center content - "Memorized" text and accuracy percentage
    final accuracyText = '${accuracyPercent.toStringAsFixed(1)}%';
    final labelText = 'Memorized';

    // Draw accuracy percentage
    final percentTextPainter = TextPainter(
      text: TextSpan(
        text: accuracyText,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: theme.colors.foreground,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    percentTextPainter.layout();

    // Draw "Memorized" label
    final labelTextPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(fontSize: 14, color: theme.colors.mutedForeground),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    labelTextPainter.layout();

    // Position texts in center
    final totalTextHeight =
        percentTextPainter.height + labelTextPainter.height + 4;
    final startY = center.dy - totalTextHeight / 2;

    percentTextPainter.paint(
      canvas,
      Offset(center.dx - percentTextPainter.width / 2, startY),
    );

    labelTextPainter.paint(
      canvas,
      Offset(
        center.dx - labelTextPainter.width / 2,
        startY + percentTextPainter.height + 4,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';

enum TimePeriod {
  weeks4(28, 'Last 4 weeks'),
  weeks12(84, 'Last 12 weeks'),
  months3(90, 'Last 3 months'),
  months6(180, 'Last 6 months');
  // year1(365, 'Last year');

  const TimePeriod(this.days, this.displayName);
  final int days;
  final String displayName;
}

class LayoutParams {
  final double labelWidth;
  final double monthLabelHeight;
  final double cellSize;
  final double cellPadding;
  final double totalCellSize;
  final double startX;
  final double startY;
  final int totalWeeks;

  LayoutParams({
    required this.labelWidth,
    required this.monthLabelHeight,
    required this.cellSize,
    required this.cellPadding,
    required this.totalCellSize,
    required this.startX,
    required this.startY,
    required this.totalWeeks,
  });
}

class Day {
  final DateTime date;
  final int count;
  final int intensity;

  Day({required this.date, required this.count, required this.intensity});
}

class Heatmap extends CustomPainter {
  final List<Day> data;
  final dynamic theme;
  final TimePeriod timePeriod;
  final double cellSize;

  Heatmap({
    required this.data,
    required this.theme,
    required this.timePeriod,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Calculate layout parameters based on time period
    final layoutParams = _calculateLayoutParams(size, cellSize);

    // Draw month labels for longer periods
    if (timePeriod.days > 84) {
      _drawMonthLabels(canvas, size, layoutParams);
    }

    // Draw day labels
    _drawDayLabels(canvas, layoutParams);

    // Draw heatmap cells
    _drawHeatmapCells(canvas, layoutParams);
  }

  LayoutParams _calculateLayoutParams(Size size, double cellSize) {
    final labelWidth = 30.0;
    final monthLabelHeight = timePeriod.days > 84 ? 20.0 : 0.0;
    final availableWidth = size.width - labelWidth;
    const cellPadding = 2.0;
    final totalCellSize = cellSize + cellPadding;
    final totalWeeks = (data.length / 7).ceil();
    final totalWidth = totalWeeks * totalCellSize - cellPadding;
    final startX = labelWidth + (availableWidth - totalWidth) / 2;
    final startY = monthLabelHeight;

    return LayoutParams(
      labelWidth: labelWidth,
      monthLabelHeight: monthLabelHeight,
      cellSize: cellSize,
      cellPadding: cellPadding,
      totalCellSize: totalCellSize,
      startX: startX,
      startY: startY,
      totalWeeks: totalWeeks,
    );
  }

  void _drawMonthLabels(Canvas canvas, Size size, LayoutParams params) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Group weeks by month
    final monthPositions = <String, double>{};
    for (int i = 0; i < data.length; i += 7) {
      final weekDate = data[i].date;
      final monthKey = '${weekDate.year}-${weekDate.month}';
      final weekIndex = i ~/ 7;

      if (!monthPositions.containsKey(monthKey)) {
        monthPositions[monthKey] =
            params.startX + weekIndex * params.totalCellSize;
      }
    }

    // Draw month labels
    monthPositions.forEach((monthKey, x) {
      final parts = monthKey.split('-');
      final month = int.parse(parts[1]);
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      textPainter.text = TextSpan(
        text: monthNames[month - 1],
        style: TextStyle(fontSize: 10, color: theme.colors.mutedForeground),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, 0));
    });
  }

  void _drawDayLabels(Canvas canvas, LayoutParams params) {
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int day = 0; day < 7; day++) {
      textPainter.text = TextSpan(
        text: dayLabels[day],
        style: TextStyle(
          fontSize: (params.cellSize * 0.6).clamp(8.0, 12.0),
          color: theme.colors.mutedForeground,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          params.startX - 20,
          params.startY +
              day * params.totalCellSize +
              (params.cellSize - textPainter.height) / 2,
        ),
      );
    }
  }

  void _drawHeatmapCells(Canvas canvas, LayoutParams params) {
    for (int i = 0; i < data.length; i++) {
      final dayData = data[i];
      final weekIndex = i ~/ 7;
      final dayIndex = i % 7;

      final x = params.startX + weekIndex * params.totalCellSize;
      final y = params.startY + dayIndex * params.totalCellSize;

      final rect = Rect.fromLTWH(x, y, params.cellSize, params.cellSize);
      final paint = Paint()
        ..color = _getIntensityColor(dayData.intensity)
        ..style = PaintingStyle.fill;

      final cornerRadius = (params.cellSize * 0.15).clamp(1.0, 3.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)),
        paint,
      );
    }
  }

  Color _getIntensityColor(int intensity) {
    switch (intensity) {
      case 0:
        return theme.colors.border;
      case 1:
        return Colors.green.shade200;
      case 2:
        return Colors.green.shade400;
      case 3:
        return Colors.green.shade600;
      case 4:
        return Colors.green.shade800;
      default:
        return theme.colors.border;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

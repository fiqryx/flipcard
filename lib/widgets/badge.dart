import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class TBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double radius;
  final TextStyle? style;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const TBadge({
    super.key,
    required this.label,
    this.style,
    this.margin,
    this.padding,
    this.radius = 10,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      margin: margin,
      padding: padding ?? EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colors.primary,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        label,
        style:
            style ??
            theme.typography.xs.copyWith(
              fontSize: 10,
              color: foregroundColor ?? theme.colors.primaryForeground,
            ),
      ),
    );
  }
}

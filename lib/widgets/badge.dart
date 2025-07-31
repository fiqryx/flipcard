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
  final int? maxLines;
  final TextOverflow overflow;

  const TBadge({
    super.key,
    required this.label,
    this.style,
    this.margin,
    this.padding,
    this.radius = 10,
    this.backgroundColor,
    this.foregroundColor,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
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
      constraints: BoxConstraints(minWidth: 20),
      child: Text(
        label,
        maxLines: maxLines,
        overflow: overflow,
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

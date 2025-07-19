import 'package:forui/forui.dart';
import 'package:flutter/material.dart';

class ButtonGroup extends StatelessWidget {
  final List<ButtonGroupItem> children;
  final EdgeInsetsGeometry? margin;
  final double spacing;
  final double borderRadius;

  const ButtonGroup({
    super.key,
    required this.children,
    this.margin,
    this.spacing = 2,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Container(
      margin: margin ?? const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: colors.mutedForeground.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        spacing: spacing,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class ButtonGroupItem extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final bool isActive;
  final VoidCallback? onPressed;
  final double? iconSize;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double itemBorderRadius;

  const ButtonGroupItem({
    super.key,
    this.icon,
    this.text,
    required this.isActive,
    this.onPressed,
    this.width,
    this.height,
    this.iconSize = 20,
    this.padding = EdgeInsets.zero,
    this.margin = const EdgeInsets.all(2),
    this.itemBorderRadius = 6,
  }) : assert(icon != null || text != null, 'Must provide either icon or text');

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return AnimatedContainer(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isActive ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(itemBorderRadius),
      ),
      child: _buildChild(context),
    );
  }

  Widget _buildChild(BuildContext context) {
    final colors = context.theme.colors;
    final textStyle = context.theme.typography.sm.copyWith(
      color: isActive ? colors.primaryForeground : colors.foreground,
    );

    if (icon != null && text != null) {
      return TextButton.icon(
        icon: Icon(icon, size: iconSize),
        label: Text(text!, style: textStyle),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(itemBorderRadius),
          ),
        ),
      );
    } else if (icon != null) {
      return IconButton(
        icon: Icon(
          icon,
          size: iconSize,
          color: isActive ? colors.primaryForeground : colors.foreground,
        ),
        onPressed: onPressed,
        padding: padding ?? EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      );
    } else {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(itemBorderRadius),
          ),
        ),
        child: Text(text!, style: textStyle),
      );
    }
  }
}

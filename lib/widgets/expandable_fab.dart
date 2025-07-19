import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class ExpandedFab extends StatefulWidget {
  static final FloatingActionButtonLocation location = ExpandableFab.location;

  final List<Widget> children;
  final double distance;
  final Duration? duration;
  final Icon openIcon;
  final Icon closeIcon;
  final ShapeBorder? shape;
  final ExpandableFabSize size;
  final ExpandableFabType type;
  final ExpandableFabOverlayStyle? overlay;
  final ExpandableFabAnimation childrenAnimation;

  const ExpandedFab({
    super.key,
    required this.children,
    this.shape,
    this.distance = 70,
    this.duration,
    this.openIcon = const Icon(FIcons.menu, size: 20),
    this.closeIcon = const Icon(FIcons.x, size: 20),
    this.size = ExpandableFabSize.small,
    this.type = ExpandableFabType.up,
    this.overlay,
    this.childrenAnimation = ExpandableFabAnimation.rotate,
  });

  @override
  State<ExpandedFab> createState() => ExpandedFabState();
}

class ExpandedFabState extends State<ExpandedFab> {
  final GlobalKey<ExpandableFabState> _expandableFabKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return ExpandableFab(
      key: _expandableFabKey,
      type: widget.type,
      distance: widget.distance,
      childrenAnimation: widget.childrenAnimation,
      openButtonBuilder: DefaultFloatingActionButtonBuilder(
        fabSize: widget.size,
        shape: widget.shape,
        child: widget.openIcon,
      ),
      closeButtonBuilder: DefaultFloatingActionButtonBuilder(
        fabSize: widget.size,
        shape: widget.shape,
        child: widget.closeIcon,
      ),
      overlayStyle:
          widget.overlay ??
          ExpandableFabOverlayStyle(
            blur: 1.5,
            color: colors.background.withValues(alpha: 0.5),
          ),
      children: widget.children,
    );
  }

  void toggle() => _expandableFabKey.currentState?.toggle();
  void open() => _expandableFabKey.currentState?.activate();
  void close() => _expandableFabKey.currentState?.close();
}

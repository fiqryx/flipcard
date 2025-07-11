import 'package:flutter/material.dart';
import 'package:forui/widgets/toast.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

class BackpressExit extends StatefulWidget {
  final Widget child;
  const BackpressExit({super.key, required this.child});

  @override
  State<BackpressExit> createState() => _BackpressExitState();
}

class _BackpressExitState extends State<BackpressExit> {
  DateTime? lastBackPressTime;

  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(
      _interceptor,
      name: "exit_interceptor",
      context: context,
    );
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(_interceptor);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  bool _interceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (stopDefaultButtonEvent) return false;

    // If a dialog (or any other route) is open, don't run the interceptor.
    if (info.ifRouteChanged(context)) return false;

    final now = DateTime.now();
    if (lastBackPressTime == null ||
        now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
      setState(() => lastBackPressTime = now);

      if (mounted) {
        showFToast(
          context: context,
          duration: Duration(seconds: 2),
          title: Text("Press back again to exit"),
          alignment: FToastAlignment.bottomCenter,
        );
      }

      return true;
    }

    return false;
  }
}

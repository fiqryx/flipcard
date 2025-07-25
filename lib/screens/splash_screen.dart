import 'package:flipcard/constants/storage.dart';
import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flipcard/helpers/logger.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:flipcard/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

class SplashScreen extends StatefulWidget {
  final Duration duration;

  const SplashScreen({super.key, this.duration = const Duration(seconds: 3)});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late UserStore _userStore;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    BackButtonInterceptor.add(_interceptor, name: "exit", context: context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userStore = Provider.of<UserStore>(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    BackButtonInterceptor.remove(_interceptor);
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _controller.forward();

      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        final session = data.session;

        if (event == AuthChangeEvent.signedIn && session != null) {
          await _userStore.getData();
        } else if (event == AuthChangeEvent.signedOut) {
          _userStore.reset();
          await storage.delete(key: 'logged');
        }
      });

      if (UserService.isAuthenticated) {
        await _userStore.getData();
        await storage.write(key: 'logged', value: 'true');
      }

      await _controller.forward();

      final setupDone = await storage.read(key: 'setup_permission');
      if (mounted) {
        final name = setupDone == "true"
            ? (_userStore.isLogged ? '/main' : '/login')
            : '/permission';
        Navigator.of(context).pushNamedAndRemoveUntil(name, (route) => false);
      }
    } catch (e) {
      Logger.log(e.toString(), name: "SplashScreen");
      setState(_userStore.reset);
      if (mounted) {
        showFToast(
          context: context,
          title: Text(e.toString().replaceAll('Exception: ', '')),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  bool _interceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.colors.background,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset('assets/images/logo.png', width: 160, height: 160),
        ),
      ),
    );
  }
}

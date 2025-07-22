import 'dart:developer' as dev;
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flipcard/services/background_service.dart';
import 'package:flipcard/services/user_service.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

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
          BackgroundService.stopService();
        }
      });

      if (UserService.isAuthenticated) {
        await _userStore.getData();
      }

      await _controller.forward();

      final setupDone = await _storage.read(key: 'setup_permission');
      if (mounted) {
        final name = setupDone == "true"
            ? (_userStore.isLogged ? '/main' : '/login')
            : '/permission';
        Navigator.of(context).pushNamedAndRemoveUntil(name, (route) => false);
      }
    } catch (e) {
      dev.log(e.toString(), name: "initialize");
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

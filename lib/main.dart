import 'package:flipcard/screens/permission_screen.dart';
import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';

import 'package:flipcard/helpers/speech.dart';
import 'package:flipcard/constants/config.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:flipcard/screens/deck_screen.dart';
import 'package:flipcard/screens/quiz_screen.dart';
import 'package:flipcard/screens/login_screen.dart';
import 'package:flipcard/screens/splash_screen.dart';
import 'package:flipcard/widgets/backpress_exit.dart';
import 'package:flipcard/screens/profile_screen.dart';
import 'package:flipcard/screens/register_screen.dart';
import 'package:flipcard/helpers/local_notification.dart';
import 'package:flipcard/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await FullScreen.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  await LocalNotification.initialize();
  await BackgroundService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Speech()),
        ChangeNotifierProvider(create: (_) => UserStore()),
      ],
      child: const Application(),
    ),
  );
}

final routes = <String, WidgetBuilder>{
  "/splash": (ctx) => SplashScreen(duration: Duration(seconds: 5)),
  "/login": (ctx) => BackpressExit(child: LoginScreen()),
  "/permission": (ctx) => BackpressExit(child: PermissionScreen()),
  "/register": (ctx) => RegisterScreen(),
  "/main": (ctx) => Main(),
};

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return MaterialApp(
      routes: routes,
      initialRoute: "/splash",
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: FLocalizations.localizationsDelegates,
      theme: FThemes.zinc.light.toApproximateMaterialTheme(),
      darkTheme: FThemes.zinc.dark.toApproximateMaterialTheme(),
      builder: (context, child) => FTheme(
        data: isDark ? FThemes.zinc.dark : FThemes.zinc.light,
        child: FToaster(child: child!),
      ),
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final userStore = Provider.of<UserStore>(context);

    return Scaffold(
      bottomNavigationBar: FBottomNavigationBar(
        index: _current,
        onChange: (idx) => setState(() => _current = idx),
        style: (style) => style.copyWith(padding: EdgeInsets.only(top: 6)),
        children: [
          FBottomNavigationBarItem(
            style: (p0) => p0.copyWith(padding: EdgeInsets.zero),
            icon: Icon(FIcons.layers),
            label: Text('Deck'),
          ),
          FBottomNavigationBarItem(
            style: (p0) => p0.copyWith(padding: EdgeInsets.zero),
            icon: Icon(FIcons.circlePlay),
            label: Text('Quiz'),
          ),
          FBottomNavigationBarItem(
            style: (p0) => p0.copyWith(padding: EdgeInsets.zero),
            icon: ClipOval(
              child: FAvatar(
                size: 28,
                fallback: Icon(Icons.person),
                image: NetworkImage(userStore.user?.imageUrl ?? ''),
                style: (style) => style.copyWith(
                  backgroundColor: colors.muted,
                  foregroundColor: colors.primaryForeground,
                ),
              ),
            ),
            label: Text('Me'),
          ),
        ],
      ),
      body: BackpressExit(
        child: IndexedStack(
          index: _current,
          children: [DeckScreen(), QuizScreen(), ProfileScreen()],
        ),
      ),
    );
  }
}

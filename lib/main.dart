import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';

import 'package:flipcard/helpers/speech.dart';
import 'package:flipcard/screens/home_screen.dart';
import 'package:flipcard/screens/menu_screen.dart';
import 'package:flipcard/screens/quiz_screen.dart';
import 'package:flipcard/screens/login_screen.dart';
import 'package:flipcard/screens/splash_screen.dart';
import 'package:flipcard/screens/profile_screen.dart';
import 'package:flipcard/screens/register_screen.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:flipcard/widgets/backpress_exit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final speech = Speech();

  await dotenv.load(fileName: ".env");
  await FullScreen.ensureInitialized();

  await Supabase.initialize(
    url: dotenv.get("SUPABASE_URL"),
    anonKey: dotenv.get("SUPABASE_ANON_KEY"),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => speech),
        ChangeNotifierProvider(create: (_) => UserStore()),
      ],
      child: const Application(),
    ),
  );
}

final routes = <String, WidgetBuilder>{
  "/splash": (ctx) => SplashScreen(duration: Duration(seconds: 5)),
  "/login": (ctx) => LoginScreen(),
  "/register": (ctx) => RegisterScreen(),
  "/main": (ctx) => Main(),
};

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final theme = isDark ? FThemes.zinc.dark : FThemes.zinc.light;

    return MaterialApp(
      routes: routes,
      initialRoute: "/splash",
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: FLocalizations.localizationsDelegates,
      theme: FThemes.zinc.light.toApproximateMaterialTheme(),
      darkTheme: FThemes.zinc.dark.toApproximateMaterialTheme(),
      builder: (context, child) => FTheme(
        data: theme,
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
    return Scaffold(
      bottomNavigationBar: FBottomNavigationBar(
        index: _current,
        onChange: (idx) => setState(() => _current = idx),
        children: [
          FBottomNavigationBarItem(
            icon: Icon(FIcons.house),
            label: Text('Home'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(FIcons.menu),
            label: Text('Menu'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(FIcons.circlePlay),
            label: Text('Quiz'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(FIcons.user),
            label: Text('Profile'),
          ),
        ],
      ),
      body: BackpressExit(
        child: IndexedStack(
          index: _current,
          children: [HomeScreen(), MenuScreen(), QuizScreen(), ProfileScreen()],
        ),
      ),
    );
  }
}

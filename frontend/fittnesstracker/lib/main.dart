import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/plans_screen.dart';
import 'screens/add_exercise_screen.dart';
import 'screens/plan_detail_screen.dart';
import 'screens/workout_session_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = normalizeThemeIndex(prefs.getInt('theme_index') ?? 0);
  runApp(MainApp(initialThemeIndex: savedTheme));
}

class MainApp extends StatefulWidget {
  final int initialThemeIndex;

  const MainApp({super.key, required this.initialThemeIndex});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  static const _themePreferenceKey = 'theme_index';

  late int _themeIndex;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _themeIndex = normalizeThemeIndex(widget.initialThemeIndex);
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              MainShell(onThemeChanged: _setThemeIndex),
        ),
        GoRoute(
          path: '/plan-detail',
          builder: (context, state) {
            final planId = state.extra as int?;
            return PlanDetailScreen(planId: planId ?? 0);
          },
        ),
        GoRoute(
          path: '/workout-session',
          builder: (context, state) {
            final plan = state.extra as Map<String, dynamic>;
            return WorkoutSessionScreen(plan: plan);
          },
        ),
      ],
    );
  }

  Future<void> _setThemeIndex(int newIndex) async {
    final normalized = normalizeThemeIndex(newIndex);
    if (normalized != _themeIndex) {
      setState(() => _themeIndex = normalized);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePreferenceKey, normalized);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      theme: buildAppTheme(_themeIndex),
    );
  }
}

class MainShell extends StatefulWidget {
  final ValueChanged<int> onThemeChanged;

  const MainShell({super.key, required this.onThemeChanged});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const AddExerciseScreen(),
      const PlansScreen(),
      SettingsScreen(onThemeChanged: widget.onThemeChanged),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Übung',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Pläne',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Einstellungen',
          ),
        ],
      ),
    );
  }
}

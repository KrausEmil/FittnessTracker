import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/plans_screen.dart';
import 'screens/add_exercise_screen.dart';
import 'screens/plan_detail_screen.dart';
import 'screens/workout_session_screen.dart';
import 'screens/settings_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = normalizeThemeIndex(prefs.getInt('theme_index') ?? 0);
  final savedRestDuration = prefs.getInt('rest_duration') ?? 60;

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(
        initialThemeIndex: savedTheme,
        initialRestDuration: savedRestDuration,
      ),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const MainShell()),
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

  @override
  Widget build(BuildContext context) {
    final themeIndex = context.select<AppState, int>(
      (state) => state.themeIndex,
    );
    return MaterialApp.router(
      routerConfig: _router,
      theme: buildAppTheme(themeIndex),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

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
      const SettingsScreen(),
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

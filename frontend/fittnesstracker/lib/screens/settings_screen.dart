import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme_options.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _restDuration = 60;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _restDuration = context.read<AppState>().restDuration.toDouble();
    _initialized = true;
  }

  String _fmtSeconds(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    if (m > 0 && sec > 0) return '${m}m ${sec}s';
    if (m > 0) return '${m}m';
    return '${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final themeIndex = appState.themeIndex;

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined),
                      const SizedBox(width: 8),
                      const Text(
                        'Pausenzeit zwischen Sätzen',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _fmtSeconds(_restDuration.toInt()),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Slider(
                    value: _restDuration,
                    min: 10,
                    max: 300,
                    divisions: 58,
                    label: _fmtSeconds(_restDuration.toInt()),
                    onChanged: (v) {
                      final snapped = (v / 5).round() * 5;
                      setState(() => _restDuration = snapped.toDouble());
                    },
                    onChangeEnd: (v) async {
                      final snapped = (v / 5).round() * 5;
                      await appState.setRestDuration(snapped);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '10s',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '5m',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.palette_outlined),
                      const SizedBox(width: 8),
                      const Text(
                        'App-Theme',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<int>(
                    groupValue: themeIndex,
                    onChanged: (value) async {
                      if (value == null) return;
                      await appState.setThemeIndex(value);
                    },
                    child: Column(
                      children: List.generate(appThemeOptions.length, (index) {
                        final option = appThemeOptions[index];
                        return RadioListTile<int>(
                          value: index,
                          title: Text(option.label),
                          secondary: CircleAvatar(
                            radius: 10,
                            backgroundColor: option.seedColor,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

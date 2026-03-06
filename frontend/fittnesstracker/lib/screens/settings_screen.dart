import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _restDuration = 60;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _restDuration = (prefs.getInt('rest_duration') ?? 60).toDouble();
    });
  }

  Future<void> _save(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rest_duration', value.toInt());
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
                      _save(snapped.toDouble());
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
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PlanDetailScreen extends StatefulWidget {
  final int planId;
  const PlanDetailScreen({super.key, required this.planId});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  Map<String, dynamic>? _plan;
  List<Map<String, dynamic>> _allExercises = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final plan = await ApiService.getPlanById(widget.planId);
      final exercises = await ApiService.getExercises();
      setState(() {
        _plan = plan;
        _allExercises = exercises;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  Future<void> _addExerciseToPlan() async {
    final planExerciseIds = ((_plan?['exercises'] as List?) ?? [])
        .map((e) => e['exercise_id'] as int)
        .toSet();

    final available = _allExercises
        .where((e) => !planExerciseIds.contains(e['id']))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine weiteren Übungen verfügbar.')),
      );
      return;
    }

    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '10');
    int? selectedExId;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Übung hinzufügen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Übung',
                      border: OutlineInputBorder(),
                    ),
                    items: available
                        .map(
                          (e) => DropdownMenuItem<int>(
                            value: e['id'] as int,
                            child: Text(e['name'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedExId = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: setsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Sätze',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: repsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Wdh',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: selectedExId == null
                      ? null
                      : () => Navigator.pop(ctx, {
                          'exercise_id': selectedExId,
                          'sets': int.tryParse(setsCtrl.text) ?? 3,
                          'repetitions': int.tryParse(repsCtrl.text) ?? 10,
                        }),
                  child: const Text('Hinzufügen'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      await ApiService.addExerciseToPlan(
        widget.planId,
        result['exercise_id'],
        result['sets'],
        result['repetitions'],
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  Future<void> _removeExercise(int peId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Übung entfernen'),
        content: Text('"$name" aus dem Plan entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Entfernen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.removePlanExercise(widget.planId, peId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ((_plan?['exercises'] as List?) ?? [])
        .cast<Map<String, dynamic>>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_plan?['name'] ?? 'Plan-Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Übung hinzufügen',
            onPressed: _addExerciseToPlan,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : exercises.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text('Noch keine Übungen im Plan.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _addExerciseToPlan,
                    icon: const Icon(Icons.add),
                    label: const Text('Übung hinzufügen'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: exercises.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final ex = exercises[i];
                  final weight = (ex['weight'] as num?)?.toDouble() ?? 0;
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.fitness_center,
                        color: Colors.blue,
                      ),
                      title: Text(ex['name'] ?? ''),
                      subtitle: Text(
                        '${ex['sets']} Sätze x ${ex['repetitions']} Wdh'
                        '${weight > 0 ? '  •  ${weight.toStringAsFixed(1)} kg' : ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeExercise(
                          ex['plan_exercise_id'] as int,
                          ex['name'] as String,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

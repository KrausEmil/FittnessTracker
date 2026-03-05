import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getPlans();
      setState(() {
        _plans = data;
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

  Future<void> _addPlan() async {
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neuer Trainingsplan'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'z.B. Push Pull',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    try {
      await ApiService.createPlan(name);
      await _loadPlans();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  Future<void> _deletePlan(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Plan löschen'),
        content: Text('"$name" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.deletePlan(id);
      await _loadPlans();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainingspläne'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Neuer Plan',
            onPressed: _addPlan,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Noch keine Pläne vorhanden.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _addPlan,
                    icon: const Icon(Icons.add),
                    label: const Text('Plan erstellen'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPlans,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: _plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final plan = _plans[i];
                  final exercises = (plan['exercises'] as List?) ?? [];
                  final exerciseCount = exercises.length;

                  String subtitle;
                  if (exerciseCount == 0) {
                    subtitle = 'Keine Übungen';
                  } else {
                    final names = exercises
                        .map((e) => e['name'] as String? ?? '')
                        .take(3)
                        .join(', ');
                    subtitle = exerciseCount <= 3
                        ? names
                        : '$names  (+${exerciseCount - 3})';
                  }

                  return Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(
                        Icons.fitness_center,
                        color: Colors.blue,
                      ),
                      title: Text(
                        plan['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(subtitle),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$exerciseCount',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.blue),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _deletePlan(plan['id'] as int, plan['name']),
                          ),
                        ],
                      ),
                      onTap: () {
                        context.push('/plan-detail', extra: plan['id'] as int);
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}

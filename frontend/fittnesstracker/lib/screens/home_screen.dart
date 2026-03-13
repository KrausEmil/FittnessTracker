import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final plans = await ApiService.getPlans();
      List<Map<String, dynamic>> history = [];
      try {
        history = await ApiService.getHistory();
      } catch (_) {}
      setState(() {
        _plans = plans;
        _history = history;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Guten Morgen';
    if (hour < 18) return 'Guten Tag';
    return 'Guten Abend';
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = _parseDate(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Heute';
    if (diff.inDays == 1) return 'Gestern';
    return 'vor ${diff.inDays} Tagen';
  }

  DateTime? _parseDate(dynamic rawDate) {
    if (rawDate == null) return null;
    final parsed = DateTime.tryParse(rawDate.toString());
    return parsed?.toLocal();
  }

  DateTime? _historyDate(Map<String, dynamic> item) {
    return _parseDate(item['performed_at'] ?? item['created_at']);
  }

  int _streakDays() {
    final doneDays = <String>{};
    for (final item in _history) {
      final date = _historyDate(item);
      if (date == null) continue;
      final key = '${date.year}-${date.month}-${date.day}';
      doneDays.add(key);
    }

    int streak = 0;
    var check = DateTime.now();
    while (true) {
      final key = '${check.year}-${check.month}-${check.day}';
      if (!doneDays.contains(key)) break;
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> _quickStart() async {
    if (_plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erstelle zuerst einen Trainingsplan!')),
      );
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan auswählen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._plans.map(
              (plan) => ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(plan['name'] ?? ''),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () => Navigator.pop(ctx, plan),
              ),
            ),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;

    try {
      final detail = await ApiService.getPlanById(selected['id']);
      if (mounted) context.push('/workout-session', extra: detail);
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Text(
                          'Home / Dashboard',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Aktualisieren',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.primaryContainer,
                            Color.lerp(
                                  colors.primaryContainer,
                                  colors.surface,
                                  0.3,
                                ) ??
                                colors.primaryContainer,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dein Workout für heute',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _PillInfo(
                                icon: Icons.local_fire_department_outlined,
                                text: '${_streakDays()} Tage Streak',
                              ),
                              const SizedBox(width: 8),
                              _PillInfo(
                                icon: Icons.fitness_center_outlined,
                                text: '${_plans.length} Pläne bereit',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _quickStart,
                        icon: const Icon(Icons.play_circle_fill_rounded),
                        label: const Text(
                          'Quick Start Workout',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _StatCard(
                      title: 'Gesamt Pläne',
                      value: '${_plans.length}',
                      icon: Icons.list_alt_outlined,
                    ),
                    const SizedBox(height: 28),

                    Text(
                      'Letzte Aktivität',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_history.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Noch keine Aktivitäten.\nStarte dein erstes Workout!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._history
                          .take(5)
                          .map(
                            (h) => _ActivityTile(
                              name: h['plan_name'] ?? 'Workout',
                              subtitle: _timeAgo(
                                h['performed_at'] ?? h['created_at'],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PillInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PillInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String name;
  final String subtitle;

  const _ActivityTile({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: colors.primary, width: 4)),
      ),
      child: ListTile(
        leading: Icon(Icons.check_circle_outline, color: colors.primary),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final Map<String, dynamic> plan;

  const WorkoutSessionScreen({super.key, required this.plan});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late List<Map<String, dynamic>> _exercises;
  int _currentExIndex = 0;
  int _currentSet = 1;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _elapsedTimer;
  String _elapsedStr = '00:00';

  int _restDuration = 60;
  int _restRemaining = 0;
  Timer? _restTimer;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _exercises = List<Map<String, dynamic>>.from(
      (widget.plan['exercises'] as List?) ?? [],
    );
    _loadRestDuration();
    _stopwatch.start();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedStr = _fmtDuration(_stopwatch.elapsed);
      });
    });
  }

  Future<void> _loadRestDuration() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _restDuration = prefs.getInt('rest_duration') ?? 60;
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  String _fmtDuration(Duration d) {
    final m = (d.inMinutes).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtSeconds(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startRest() {
    setState(() {
      _isResting = true;
      _restRemaining = _restDuration;
    });
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restRemaining <= 1) {
        _restTimer?.cancel();
        setState(() {
          _isResting = false;
          _restRemaining = 0;
        });
      } else {
        setState(() => _restRemaining--);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restRemaining = 0;
    });
  }

  void _completeSet() {
    final ex = _exercises[_currentExIndex];
    final totalSets = (ex['sets'] as num?)?.toInt() ?? 3;

    if (_currentSet < totalSets) {
      setState(() => _currentSet++);
      _startRest();
    } else if (_currentExIndex < _exercises.length - 1) {
      setState(() {
        _currentExIndex++;
        _currentSet = 1;
      });
      _startRest();
    } else {
      _finishWorkout();
    }
  }

  Future<void> _finishWorkout() async {
    _stopwatch.stop();
    _elapsedTimer?.cancel();
    _restTimer?.cancel();

    final planId = widget.plan['id'] as int?;
    if (planId != null) {
      try {
        await ApiService.createHistory(planId);
      } catch (_) {}
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Workout abgeschlossen!'),
        content: Text(
          'Gesamtzeit: $_elapsedStr\n'
          '${_exercises.length} Übungen absolviert',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (context.mounted) context.pop();
            },
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmQuit() async {
    final quit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Workout abbrechen?'),
        content: const Text('Dein Fortschritt geht verloren.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Weiter'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (quit == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final planName = widget.plan['name'] as String? ?? 'Workout';

    if (_exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(planName)),
        body: const Center(child: Text('Keine Übungen im Plan.')),
      );
    }

    final ex = _exercises[_currentExIndex];
    final totalSets = (ex['sets'] as num?)?.toInt() ?? 3;
    final reps = (ex['repetitions'] as num?)?.toInt() ?? 10;
    final weight = (ex['weight'] as num?)?.toDouble() ?? 0;

    String nextInfo;
    if (_currentSet < totalSets) {
      nextInfo = '${ex['name']} – Satz ${_currentSet + 1}';
    } else if (_currentExIndex < _exercises.length - 1) {
      nextInfo = '${_exercises[_currentExIndex + 1]['name']} – Satz 1';
    } else {
      nextInfo = 'Letzter Satz!';
    }

    final isLastSet =
        _currentSet >= totalSets && _currentExIndex >= _exercises.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _confirmQuit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(planName),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmQuit,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ── Total elapsed time ──
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _elapsedStr,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Circular rest timer ──
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(220, 220),
                      painter: _CircularTimerPainter(
                        progress: _isResting && _restDuration > 0
                            ? _restRemaining / _restDuration
                            : 0,
                        activeColor: Colors.red,
                        bgColor: Colors.grey.shade300,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isResting)
                          const Text(
                            'Pause',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        Text(
                          _isResting ? _fmtSeconds(_restRemaining) : '00:00',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: _isResting
                                ? Colors.red
                                : Colors.grey.shade400,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        if (_isResting)
                          TextButton(
                            onPressed: _skipRest,
                            child: const Text('Überspringen'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Exercise name ──
              Text(
                ex['name'] ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Satz $_currentSet / $totalSets',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // ── Weight & Reps display ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (weight > 0) ...[
                    Text(
                      '${weight.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                  Text(
                    '$reps Wdh',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ── Progress dots ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_exercises.length, (i) {
                    Color dotColor;
                    if (i < _currentExIndex) {
                      dotColor = Colors.green;
                    } else if (i == _currentExIndex) {
                      dotColor = Colors.red;
                    } else {
                      dotColor = Colors.grey.shade300;
                    }
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),

              // ── Next set info ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Text(
                      'Nächster Satz: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      nextInfo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _isResting ? Colors.grey : Colors.red,
                    ),
                    onPressed: _isResting ? null : _completeSet,
                    child: Text(
                      isLastSet ? 'Workout abschließen' : 'Satz abschließen',
                      style: const TextStyle(fontSize: 18),
                    ),
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

class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color bgColor;

  _CircularTimerPainter({
    required this.progress,
    required this.activeColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularTimerPainter old) =>
      old.progress != progress;
}

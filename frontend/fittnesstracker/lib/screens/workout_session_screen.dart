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
  int _currentExerciseIndex = 0;
  int _currentSet = 1;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _elapsedTimer;
  String _elapsedTime = '00:00';

  int _restDuration = 60;
  int _restTimeLeft = 0;
  Timer? _restTimer;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _exercises = List<Map<String, dynamic>>.from(
      (widget.plan['exercises'] as List?) ?? [],
    );
    _loadRestDuration();
    _startElapsedTimer();
  }

  void _startElapsedTimer() {
    _stopwatch.start();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedTime = _formatDuration(_stopwatch.elapsed);
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

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatSeconds(int totalSeconds) {
    String minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    String seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startRestTimer() {
    setState(() {
      _isResting = true;
      _restTimeLeft = _restDuration;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restTimeLeft <= 1) {
        _restTimer?.cancel();
        setState(() {
          _isResting = false;
          _restTimeLeft = 0;
        });
      } else {
        setState(() {
          _restTimeLeft--;
        });
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restTimeLeft = 0;
    });
  }

  void _completeSet() {
    Map<String, dynamic> exercise = _exercises[_currentExerciseIndex];
    int totalSets = (exercise['sets'] as num?)?.toInt() ?? 3;

    bool hasMoreSets = _currentSet < totalSets;
    bool hasMoreExercises = _currentExerciseIndex < _exercises.length - 1;

    if (hasMoreSets) {
      setState(() => _currentSet++);
      _startRestTimer();
    } else if (hasMoreExercises) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
      });
      _startRestTimer();
    } else {
      _finishWorkout();
    }
  }

  Future<void> _finishWorkout() async {
    _stopwatch.stop();
    _elapsedTimer?.cancel();
    _restTimer?.cancel();

    int? planId = widget.plan['id'] as int?;
    if (planId != null) {
      try {
        await ApiService.createHistory(planId);
      } catch (_) {}
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Workout abgeschlossen!'),
          ],
        ),
        content: Text(
          'Gesamtzeit: $_elapsedTime\n'
          '${_exercises.length} Übungen absolviert',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (context.mounted) context.pop();
            },
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmQuit() async {
    bool? shouldQuit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Workout abbrechen?'),
        content: const Text('Dein Fortschritt geht verloren.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Weiter'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldQuit == true && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    String planName = widget.plan['name'] as String? ?? 'Workout';

    if (_exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(planName)),
        body: const Center(child: Text('Keine Übungen im Plan.')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _confirmQuit();
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(planName),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmQuit,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildElapsedTime(),
              const SizedBox(height: 20),
              _buildRestTimer(),
              const SizedBox(height: 24),
              _buildExerciseInfo(),
              const Spacer(),
              _buildProgressDots(),
              const SizedBox(height: 12),
              _buildNextSetInfo(),
              const SizedBox(height: 16),
              _buildCompleteButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElapsedTime() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            _elapsedTime,
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimer() {
    double timerProgress = (_isResting && _restDuration > 0)
        ? _restTimeLeft / _restDuration
        : 0;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _CircularTimerPainter(
              progress: timerProgress,
              activeColor: Colors.redAccent,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isResting)
                Text(
                  'Pause',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              Text(
                _isResting ? _formatSeconds(_restTimeLeft) : '00:00',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: _isResting ? Colors.redAccent : Colors.grey.shade300,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (_isResting)
                TextButton.icon(
                  onPressed: _skipRest,
                  icon: const Icon(Icons.skip_next, size: 18),
                  label: const Text('Überspringen'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseInfo() {
    Map<String, dynamic> exercise = _exercises[_currentExerciseIndex];
    int totalSets = (exercise['sets'] as num?)?.toInt() ?? 3;
    int reps = (exercise['repetitions'] as num?)?.toInt() ?? 10;
    double weight = (exercise['weight'] as num?)?.toDouble() ?? 0;

    return Column(
      children: [
        Text(
          exercise['name'] ?? '',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Satz $_currentSet / $totalSets',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (weight > 0) ...[
              _buildInfoChip(
                Icons.fitness_center,
                '${weight.toStringAsFixed(1)} kg',
              ),
              const SizedBox(width: 12),
            ],
            _buildInfoChip(Icons.repeat, '$reps Wdh'),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDots() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_exercises.length, (index) {
          Color dotColor;
          if (index < _currentExerciseIndex) {
            dotColor = Colors.green;
          } else if (index == _currentExerciseIndex) {
            dotColor = Colors.redAccent;
          } else {
            dotColor = Colors.grey.shade300;
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          );
        }),
      ),
    );
  }

  Widget _buildNextSetInfo() {
    Map<String, dynamic> exercise = _exercises[_currentExerciseIndex];
    int totalSets = (exercise['sets'] as num?)?.toInt() ?? 3;

    String nextText;
    if (_currentSet < totalSets) {
      nextText = '${exercise['name']} – Satz ${_currentSet + 1}';
    } else if (_currentExerciseIndex < _exercises.length - 1) {
      nextText = '${_exercises[_currentExerciseIndex + 1]['name']} – Satz 1';
    } else {
      nextText = 'Letzter Satz!';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Icon(Icons.navigate_next, size: 20, color: Colors.grey.shade600),
          const Text(
            'Nächster Satz: ',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Flexible(
            child: Text(
              nextText,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    Map<String, dynamic> exercise = _exercises[_currentExerciseIndex];
    int totalSets = (exercise['sets'] as num?)?.toInt() ?? 3;
    bool isLastSet =
        _currentSet >= totalSets &&
        _currentExerciseIndex >= _exercises.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _isResting ? Colors.grey : Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _isResting ? null : _completeSet,
          child: Text(
            isLastSet ? 'Workout abschließen' : 'Satz abschließen',
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color backgroundColor;

  _CircularTimerPainter({
    required this.progress,
    required this.activeColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = size.width / 2 - 10;

    Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress > 0) {
      Paint foregroundPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      double startAngle = -pi / 2;
      double sweepAngle = 2 * pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        foregroundPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularTimerPainter oldPainter) {
    return oldPainter.progress != progress;
  }
}

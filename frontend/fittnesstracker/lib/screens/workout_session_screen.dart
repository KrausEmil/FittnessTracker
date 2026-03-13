import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../services/api_service.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final Map<String, dynamic> plan;

  const WorkoutSessionScreen({super.key, required this.plan});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen>
    with TickerProviderStateMixin {
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

  late AnimationController _confettiController;
  List<_ConfettiParticle> _confettiParticles = [];
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _exercises = List<Map<String, dynamic>>.from(
      (widget.plan['exercises'] as List?) ?? [],
    );
    _startElapsedTimer();
    _initAnimations();
  }

  void _initAnimations() {
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _generateConfetti();
  }

  void _generateConfetti() {
    final random = Random();
    _confettiParticles = List.generate(60, (_) => _ConfettiParticle(random));
  }

  void _startElapsedTimer() {
    _stopwatch.start();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedTime = _formatDuration(_stopwatch.elapsed);
      });
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    _stopwatch.stop();
    _confettiController.dispose();
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
    final configuredRestDuration = context.read<AppState>().restDuration;

    setState(() {
      _restDuration = configuredRestDuration;
      _isResting = true;
      _restTimeLeft = configuredRestDuration;
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

  void _startConfetti() {
    _generateConfetti();
    setState(() => _showConfetti = true);
    _confettiController.reset();
    _confettiController.forward().then((_) {
      if (mounted) setState(() => _showConfetti = false);
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

    _startConfetti();
    await Future.delayed(const Duration(milliseconds: 500));
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
            Expanded(child: Text('Workout abgeschlossen!')),
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
        body: Stack(
          children: [
            SafeArea(
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
            if (_showConfetti) _buildConfettiOverlay(),
          ],
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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            exercise['name'] ?? '',
            key: ValueKey('exercise_$_currentExerciseIndex'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
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

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: index == _currentExerciseIndex ? 14 : 12,
            height: index == _currentExerciseIndex ? 14 : 12,
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

  Widget _buildConfettiOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _confettiController,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(
                particles: _confettiParticles,
                progress: _confettiController.value,
              ),
            );
          },
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

class _ConfettiParticle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;
  final double wobbleAmount;
  final double wobbleSpeed;

  static const _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.amber,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.cyan,
  ];

  _ConfettiParticle(Random random)
    : x = random.nextDouble(),
      startY = -random.nextDouble() * 0.3,
      speed = 0.5 + random.nextDouble() * 0.5,
      size = 6 + random.nextDouble() * 8,
      color = _colors[random.nextInt(_colors.length)],
      rotation = random.nextDouble() * 2 * pi,
      rotationSpeed = (random.nextDouble() - 0.5) * 4,
      wobbleAmount = 0.02 + random.nextDouble() * 0.04,
      wobbleSpeed = 2 + random.nextDouble() * 3;
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = p.startY + progress * p.speed * 1.5;
      if (y > 1.2) continue;

      final x = p.x + sin(progress * p.wobbleSpeed * 2 * pi) * p.wobbleAmount;
      final opacity = progress > 0.7 ? (1.0 - (progress - 0.7) / 0.3) : 1.0;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(p.rotation + progress * p.rotationSpeed);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

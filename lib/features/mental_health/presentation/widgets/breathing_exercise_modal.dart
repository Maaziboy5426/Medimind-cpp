import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class BreathingExerciseModal extends StatefulWidget {
  const BreathingExerciseModal({super.key});

  @override
  State<BreathingExerciseModal> createState() => _BreathingExerciseModalState();
}

class _BreathingExerciseModalState extends State<BreathingExerciseModal>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  static const _phaseInSec = 4.0;
  static const _phaseHoldSec = 2.0;
  static const _phaseOutSec = 4.0;
  static const _totalSec = _phaseInSec + _phaseHoldSec + _phaseOutSec;

  String _phaseLabel = 'Breathe in';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000), // 10 sec cycle
    )..addListener(_updatePhase);
    _controller.repeat();
  }

  void _updatePhase() {
    final t = _controller.value * _totalSec;
    String label;
    if (t < _phaseInSec) label = 'Breathe in';
    else if (t < _phaseInSec + _phaseHoldSec) label = 'Hold';
    else label = 'Breathe out';
    if (_phaseLabel != label) setState(() => _phaseLabel = label);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Breathing exercise',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow the circle: breathe in, hold, breathe out.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.surfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 200,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(200, 200),
                    painter: _BreathingCirclePainter(
                      phase: _controller.value,
                      phaseIn: _phaseInSec,
                      phaseHold: _phaseHoldSec,
                      phaseOut: _phaseOutSec,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _phaseLabel,
                key: ValueKey(_phaseLabel),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.cyanAccent,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: AppTheme.cyanAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingCirclePainter extends CustomPainter {
  _BreathingCirclePainter({
    required this.phase,
    required this.phaseIn,
    required this.phaseHold,
    required this.phaseOut,
  });

  final double phase;
  final double phaseIn;
  final double phaseHold;
  final double phaseOut;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final total = phaseIn + phaseHold + phaseOut;
    final progress = (phase * total) % total;
    double radiusScale;
    if (progress < phaseIn) {
      radiusScale = 0.4 + 0.6 * (progress / phaseIn);
    } else if (progress < phaseIn + phaseHold) {
      radiusScale = 1.0;
    } else {
      final outProgress = (progress - phaseIn - phaseHold) / phaseOut;
      radiusScale = 1.0 - 0.6 * outProgress;
    }
    final radius = (size.shortestSide / 2) * radiusScale;
    final fillPaint = Paint()
      ..color = AppTheme.cyanAccent.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);
    final strokePaint = Paint()
      ..color = AppTheme.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _BreathingCirclePainter old) =>
      old.phase != phase;
}

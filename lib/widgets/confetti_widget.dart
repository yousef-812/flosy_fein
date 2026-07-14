import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiWidget extends StatefulWidget {
  final bool show;
  final VoidCallback? onFinished;

  const ConfettiWidget({
    super.key,
    required this.show,
    this.onFinished,
  });

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _controller.addListener(() {
      setState(() {
        for (var p in _particles) {
          p.update();
        }
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.onFinished != null) {
          widget.onFinished!();
        }
      }
    });

    if (widget.show) {
      _startConfetti();
    }
  }

  @override
  void didUpdateWidget(ConfettiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _startConfetti();
    }
  }

  void _startConfetti() {
    _particles.clear();
    for (int i = 0; i < 100; i++) {
      _particles.add(ConfettiParticle(
        x: _random.nextDouble() * 400,
        y: -_random.nextDouble() * 200,
        color: Colors.primaries[_random.nextInt(Colors.primaries.length)],
        size: _random.nextDouble() * 8 + 4,
        speedX: (_random.nextDouble() - 0.5) * 4,
        speedY: _random.nextDouble() * 4 + 4,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
      ));
    }
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: ConfettiPainter(_particles),
      ),
    );
  }
}

class ConfettiParticle {
  double x;
  double y;
  Color color;
  double size;
  double speedX;
  double speedY;
  double rotation = 0;
  double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.rotationSpeed,
  });

  void update() {
    x += speedX;
    y += speedY;
    rotation += rotationSpeed;
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      paint.color = p.color;
      canvas.save();
      canvas.translate(p.x % size.width, p.y);
      canvas.rotate(p.rotation);
      // Draw rectangular confetti piece
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 1.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

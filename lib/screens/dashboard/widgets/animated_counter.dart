import 'package:flutter/material.dart';

class AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle style;
  final String suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutQuint,
      builder: (context, val, child) {
        return Text(
          '${val.toStringAsFixed(2)} $suffix',
          style: style,
        );
      },
    );
  }
}

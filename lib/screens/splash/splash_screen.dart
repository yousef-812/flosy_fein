import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/language_provider.dart';
import '../../main.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<FallingCoin> _coins = [];
  final Random _random = Random();
  double _logoScale = 0.0;
  double _textOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Initialize coins at random positions falling down
    for (int i = 0; i < 30; i++) {
      _coins.add(FallingCoin(
        x: _random.nextDouble() * 400,
        y: -_random.nextDouble() * 300,
        speedY: _random.nextDouble() * 3 + 2,
        rotation: _random.nextDouble() * pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
        size: _random.nextDouble() * 10 + 10,
      ));
    }

    _controller.addListener(() {
      setState(() {
        for (var coin in _coins) {
          coin.update();
        }
        // Animate logo scale and text opacity towards the end
        if (_controller.value > 0.4) {
          _logoScale = ((_controller.value - 0.4) / 0.4).clamp(0.0, 1.2);
          if (_logoScale > 1.0) _logoScale = 2.0 - _logoScale; // overshoot bounce
        }
        if (_controller.value > 0.7) {
          _textOpacity = ((_controller.value - 0.7) / 0.3).clamp(0.0, 1.0);
        }
      });
    });

    _controller.forward().then((_) => _navigateToNext());
  }

  void _navigateToNext() {
    if (!mounted) return;
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => onboarding.isOnboarded ? const MainHomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFBF4DF),
      body: Stack(
        children: [
          // Coins layer
          CustomPaint(
            size: Size.infinite,
            painter: SplashCoinPainter(_coins),
          ),
          
          // Center logo & Name
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: _logoScale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E88E5), width: 3),
                    ),
                    alignment: Alignment.center,
                    child: const Text('💰', style: TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedOpacity(
                  opacity: _textOpacity,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    languageProvider.translate('app_name'),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: _textOpacity,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    languageProvider.translate('tagline'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FallingCoin {
  double x;
  double y;
  double speedY;
  double rotation;
  double rotationSpeed;
  double size;

  FallingCoin({
    required this.x,
    required this.y,
    required this.speedY,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
  });

  void update() {
    y += speedY;
    rotation += rotationSpeed;
  }
}

class SplashCoinPainter extends CustomPainter {
  final List<FallingCoin> coins;

  SplashCoinPainter(this.coins);

  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFDAA520)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var coin in coins) {
      // Loop wrapping for coordinates
      final coinX = coin.x % size.width;
      if (coin.y > size.height) continue; // Off screen bottom

      canvas.save();
      canvas.translate(coinX, coin.y);
      canvas.rotate(coin.rotation);
      
      // Draw 3D gold coin shape (ellipse)
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: coin.size, height: coin.size * 0.6),
        goldPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: coin.size, height: coin.size * 0.6),
        borderPaint,
      );

      // Inner details
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: coin.size * 0.6, height: coin.size * 0.6 * 0.6),
        borderPaint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

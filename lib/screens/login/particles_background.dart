// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';

// --- رنگ‌های سبز ---
class LoginColors {
  static const primaryGreen = Color(0xFF2E7D66);
  static const lightGreen = Color(0xFF4CAF50);
  static const darkGreen = Color(0xFF1B5E20);
  static const softGreen = Color(0xFF66BB6A);
  static const backgroundGreen = Color(0xFF0D4F3C);
}

class ParticlesBackground extends StatelessWidget {
  final bool isExpanded;
  final Color primaryColor;
  final Random random;
  
  const ParticlesBackground({
    super.key,
    required this.isExpanded,
    required this.primaryColor,
    required this.random,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LoginColors.backgroundGreen,
            LoginColors.darkGreen.withOpacity(0.8),
            LoginColors.primaryGreen.withOpacity(0.6),
            LoginColors.softGreen.withOpacity(0.4),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: ParticlesPainter(
          isExpanded: isExpanded,
          primaryColor: primaryColor,
          random: random,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class ParticlesPainter extends CustomPainter {
  final bool isExpanded;
  final Color primaryColor;
  final Random random;
  final List<Particle> particles;

  ParticlesPainter({
    required this.isExpanded, 
    required this.primaryColor, 
    required this.random
  }) : particles = List.generate(80, (_) => Particle(random));

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final position = particle.getPosition(size, isExpanded);
      final radius = particle.radius * (isExpanded ? 1.5 : 1.0);
      
      // گرادیت سبز پررنگ برای پارتیکل‌ها
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            LoginColors.lightGreen.withOpacity(0.8),
            LoginColors.primaryGreen.withOpacity(0.4),
            LoginColors.softGreen.withOpacity(0.1),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: position, radius: radius));
      
      canvas.drawCircle(position, radius, paint);
      
      // افکت درخشان اضافی
      final glowPaint = Paint()
        ..color = LoginColors.lightGreen.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawCircle(position, radius * 0.6, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  final double initialX, initialY, radius, speed, rotationSpeed;
  final double phaseX, phaseY;
  
  Particle(Random random)
      : initialX = random.nextDouble(),
        initialY = random.nextDouble(),
        radius = random.nextDouble() * 6 + 2, // پارتیکل‌های بزرگ‌تر
        speed = random.nextDouble() * 3 + 1,
        rotationSpeed = random.nextDouble() * 2 + 0.5,
        phaseX = random.nextDouble() * 2 * pi,
        phaseY = random.nextDouble() * 2 * pi;

  Offset getPosition(Size size, bool isExpanded) {
    final time = DateTime.now().millisecondsSinceEpoch / 1000;
    
    final amplitudeX = isExpanded ? 40.0 : 25.0;
    final amplitudeY = isExpanded ? 35.0 : 20.0;
    
    final dx = (initialX * size.width) + 
               (sin(time * speed + phaseX) * amplitudeX) +
               (cos(time * rotationSpeed) * 15);
               
    final dy = (initialY * size.height) + 
               (cos(time * speed + phaseY) * amplitudeY) +
               (sin(time * rotationSpeed * 0.7) * 10);
    
    return Offset(dx, dy);
  }
}
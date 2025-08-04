// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/avatar_manager.dart';

class ProfileAvatar extends StatelessWidget {
  final AvatarManager avatarManager;
  final Map<String, dynamic> profile;
  final VoidCallback onAvatarChanged;

  const ProfileAvatar({
    super.key,
    required this.avatarManager,
    required this.profile,
    required this.onAvatarChanged,
  });

  void _showAvatarInfo(BuildContext context) {
    final patternName = PatternType.values
        .firstWhere((p) => p.name == avatarManager.currentSettings.pattern)
        .persianName;

    final primarySymbol = AvatarSymbol.values
        .firstWhere((s) => s.name == avatarManager.currentSettings.symbol);

    final secondarySymbol = avatarManager.currentSettings.secondarySymbol != null
        ? AvatarSymbol.values.firstWhere(
            (s) => s.name == avatarManager.currentSettings.secondarySymbol)
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اطلاعات آواتار'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('نماد اصلی: '),
                Text(
                  primarySymbol.symbol,
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
            if (secondarySymbol != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('نماد ثانویه: '),
                  Text(
                    secondarySymbol.symbol,
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text('الگو: $patternName'),
            const SizedBox(height: 8),
            Text('شماره پالت رنگ: ${avatarManager.currentSettings.colorIndex + 1}'),
            const SizedBox(height: 8),
            Text('انیمیشن: ${avatarManager.currentSettings.animate ? "فعال" : "غیرفعال"}'),
            const SizedBox(height: 16),
            const Text(
              'این آواتار بر اساس نام کاربری شما تولید شده است.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('باشه'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final username = profile['username'] ?? '';
              await avatarManager.generateAvatarFromUsername(username);
              onAvatarChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('آواتار بازسازی شد!'),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('بازسازی'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showAvatarInfo(context),
          child: Hero(
            tag: 'avatar',
            child: GeometricAvatar(
              username: profile['username'] ?? '',
              size: 120,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ضربه بزنید برای اطلاعات آواتار',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// آواتار هندسی پیشرفته
class GeometricAvatar extends StatelessWidget {
  final String username;
  final double size;

  const GeometricAvatar({
    super.key,
    required this.username,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final hash = username.hashCode.abs();
    final patternType = hash % GeometricPattern.values.length;
    final colorScheme = _getColorScheme(hash);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: GeometricPatternPainter(
            pattern: GeometricPattern.values[patternType],
            colors: colorScheme,
            seed: hash,
          ),
        ),
      ),
    );
  }

  List<Color> _getColorScheme(int hash) {
    final schemes = [
      [Color(0xFF8BC34A), Color(0xFF4CAF50), Color(0xFF2E7D32)], // سبز
      [Color(0xFFFFA726), Color(0xFFFF9800), Color(0xFFEF6C00)], // نارنجی
      [Color(0xFF5C6BC0), Color(0xFF3F51B5), Color(0xFF283593)], // آبی
      [Color(0xFFEF5350), Color(0xFFF44336), Color(0xFFC62828)], // قرمز
      [Color(0xFF7E57C2), Color(0xFF673AB7), Color(0xFF4527A0)], // بنفش
      [Color(0xFF26A69A), Color(0xFF009688), Color(0xFF00695C)], // فیروزه‌ای
      [Color(0xFFEC407A), Color(0xFFE91E63), Color(0xFFAD1457)], // صورتی
      [Color(0xFF8D6E63), Color(0xFF6D4C41), Color(0xFF4E342E)], // قهوه‌ای
      [Color(0xFF546E7A), Color(0xFF455A64), Color(0xFF263238)], // خاکستری
      [Color(0xFFFFCA28), Color(0xFFFFC107), Color(0xFFF57C00)], // زرد
    ];
    
    return schemes[hash % schemes.length];
  }
}

enum GeometricPattern {
  star,
  hexagon,
  cross,
  diamond,
  triangle,
  zigzag,
  checkerboard,
  flower,
  spiral,
  mandala,
}

class GeometricPatternPainter extends CustomPainter {
  final GeometricPattern pattern;
  final List<Color> colors;
  final int seed;

  GeometricPatternPainter({
    required this.pattern,
    required this.colors,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // پس‌زمینه سفید
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    
    switch (pattern) {
      case GeometricPattern.star:
        _drawStarPattern(canvas, center, radius);
        break;
      case GeometricPattern.hexagon:
        _drawHexagonPattern(canvas, center, radius);
        break;
      case GeometricPattern.cross:
        _drawCrossPattern(canvas, center, radius);
        break;
      case GeometricPattern.diamond:
        _drawDiamondPattern(canvas, center, radius);
        break;
      case GeometricPattern.triangle:
        _drawTrianglePattern(canvas, center, radius);
        break;
      case GeometricPattern.zigzag:
        _drawZigzagPattern(canvas, size);
        break;
      case GeometricPattern.checkerboard:
        _drawCheckerboardPattern(canvas, size);
        break;
      case GeometricPattern.flower:
        _drawFlowerPattern(canvas, center, radius);
        break;
      case GeometricPattern.spiral:
        _drawSpiralPattern(canvas, center, radius);
        break;
      case GeometricPattern.mandala:
        _drawMandalaPattern(canvas, center, radius);
        break;
    }
  }

  void _drawStarPattern(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final outerRadius = radius * 0.8;
    final innerRadius = radius * 0.4;
    final points = 8;
    
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final offset = i * 0.1;
      
      for (int j = 0; j < points * 2; j++) {
        final angle = (j * math.pi / points) + (i * math.pi / 6);
        final r = j.isEven ? outerRadius * (1 - offset) : innerRadius * (1 - offset);
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      path.close();
      paint.color = colors[i % colors.length].withOpacity(0.8);
      canvas.drawPath(path, paint);
    }
  }

  void _drawHexagonPattern(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    for (int ring = 0; ring < 4; ring++) {
      final hexRadius = radius * (1 - ring * 0.25);
      final path = Path();
      
      for (int i = 0; i < 6; i++) {
        final angle = (i * math.pi / 3) + (ring * math.pi / 12);
        final x = center.dx + hexRadius * math.cos(angle);
        final y = center.dy + hexRadius * math.sin(angle);
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      path.close();
      paint.color = colors[(ring + seed) % colors.length].withOpacity(0.7);
      canvas.drawPath(path, paint);
    }
  }

  void _drawCrossPattern(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final crossSize = radius * 0.3;
    final spacing = radius * 0.4;
    
    for (int i = -2; i <= 2; i++) {
      for (int j = -2; j <= 2; j++) {
        final x = center.dx + i * spacing;
        final y = center.dy + j * spacing;
        
        if ((x - center.dx).abs() < radius && (y - center.dy).abs() < radius) {
          final colorIndex = ((i + 2) + (j + 2)) % colors.length;
          paint.color = colors[colorIndex];
          
          // رسم صلیب
          canvas.drawRect(
            Rect.fromCenter(center: Offset(x, y), width: crossSize * 2, height: crossSize * 0.6),
            paint,
          );
          canvas.drawRect(
            Rect.fromCenter(center: Offset(x, y), width: crossSize * 0.6, height: crossSize * 2),
            paint,
          );
        }
      }
    }
  }

  void _drawDiamondPattern(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final diamondSize = radius * 0.25;
    
    for (int ring = 0; ring < 4; ring++) {
      final ringRadius = radius * (ring + 1) * 0.25;
      final count = 6 + ring * 2;
      
      for (int i = 0; i < count; i++) {
        final angle = (i * 2 * math.pi / count) + (ring * math.pi / 8);
        final x = center.dx + ringRadius * math.cos(angle);
        final y = center.dy + ringRadius * math.sin(angle);
        
        final path = Path()
          ..moveTo(x, y - diamondSize)
          ..lineTo(x + diamondSize * 0.7, y)
          ..lineTo(x, y + diamondSize)
          ..lineTo(x - diamondSize * 0.7, y)
          ..close();
        
        paint.color = colors[(i + ring) % colors.length];
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawTrianglePattern(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final triangleSize = radius * 0.3;
    final rows = 5;
    
    for (int row = 0; row < rows; row++) {
      final y = center.dy - radius * 0.6 + row * triangleSize * 1.5;
      final trianglesInRow = row + 1;
      
      for (int col = 0; col < trianglesInRow; col++) {
        final x = center.dx - (trianglesInRow - 1) * triangleSize * 0.5 + col * triangleSize;
        
        if ((x - center.dx).abs() < radius * 0.8) {
          final path = Path()
            ..moveTo(x, y - triangleSize * 0.6)
            ..lineTo(x + triangleSize * 0.5, y + triangleSize * 0.3)
            ..lineTo(x - triangleSize * 0.5, y + triangleSize * 0.3)
            ..close();
          
          paint.color = colors[(row + col) % colors.length];
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  void _drawZigzagPattern(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final zigzagHeight = size.height / 8;
    final zigzagWidth = size.width / 6;
    
    for (int row = 0; row < 8; row++) {
      final path = Path();
      final y = row * zigzagHeight;
      
      path.moveTo(0, y);
      
      for (int i = 0; i <= 6; i++) {
        final x = i * zigzagWidth;
        final yOffset = (i % 2 == 0) ? 0 : zigzagHeight * 0.5;
        path.lineTo(x, y + yOffset);
      }
      
      path.lineTo(size.width, y + zigzagHeight);
      path.lineTo(0, y + zigzagHeight);
      path.close();
      
      paint.color = colors[row % colors.length];
      canvas.drawPath(path, paint);
    }
  }

  void _drawCheckerboardPattern(Canvas canvas, Size size) {
    final paint = Paint();
    final squareSize = size.width / 8;
    
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final x = col * squareSize;
        final y = row * squareSize;
        
        // فقط مربع‌هایی که داخل دایره هستند را رسم کن
        final dx = x + squareSize / 2 - size.width / 2;
        final dy = y + squareSize / 2 - size.height / 2;
        final distance = math.sqrt(dx * dx + dy * dy);
        
        if (distance < size.width / 2) {
          final colorIndex = ((row + col) % 2 == 0) ? 0 : 1;
          paint.color = colors[colorIndex % colors.length];
          canvas.drawRect(
            Rect.fromLTWH(x, y, squareSize, squareSize),
            paint,
          );
        }
      }
    }
  }

  void _drawFlowerPattern(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // رسم گلبرگ‌ها
    final petalCount = 8;
    final petalRadius = radius * 0.4;
    
    for (int i = 0; i < petalCount; i++) {
      final angle = i * 2 * math.pi / petalCount;
      final petalCenter = Offset(
        center.dx + radius * 0.5 * math.cos(angle),
        center.dy + radius * 0.5 * math.sin(angle),
      );
      
      paint.color = colors[i % colors.length];
      canvas.drawCircle(petalCenter, petalRadius, paint);
    }
    
    // رسم مرکز گل
    paint.color = colors.last;
    canvas.drawCircle(center, radius * 0.3, paint);
  }

  void _drawSpiralPattern(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.05;

    final totalTurns = 4;
    final pointsPerTurn = 50;
    final totalPoints = totalTurns * pointsPerTurn;
    
    for (int layer = 0; layer < 3; layer++) {
      final path = Path();
      final layerOffset = layer * 0.3;
      
      for (int i = 0; i < totalPoints; i++) {
        final progress = i / totalPoints;
        final angle = progress * totalTurns * 2 * math.pi;
        final r = radius * progress * (0.8 - layerOffset);
        
        final x = center.dx + r * math.cos(angle + layer * math.pi / 3);
        final y = center.dy + r * math.sin(angle + layer * math.pi / 3);
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      paint.color = colors[layer % colors.length];
      canvas.drawPath(path, paint);
    }
  }

  void _drawMandalaPattern(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // رسم حلقه‌های متحدالمرکز با الگوهای مختلف
    for (int ring = 0; ring < 4; ring++) {
      final ringRadius = radius * (1 - ring * 0.2);
      final elements = 8 + ring * 4;
      
      for (int i = 0; i < elements; i++) {
        final angle = i * 2 * math.pi / elements;
        
        if (ring % 2 == 0) {
          // رسم دایره‌های کوچک
          final circleCenter = Offset(
            center.dx + ringRadius * math.cos(angle),
            center.dy + ringRadius * math.sin(angle),
          );
          paint.color = colors[(i + ring) % colors.length];
          canvas.drawCircle(circleCenter, radius * 0.08, paint);
        } else {
          // رسم لوزی‌ها
          final x = center.dx + ringRadius * math.cos(angle);
          final y = center.dy + ringRadius * math.sin(angle);
          
          final path = Path()
            ..moveTo(x, y - radius * 0.1)
            ..lineTo(x + radius * 0.05, y)
            ..lineTo(x, y + radius * 0.1)
            ..lineTo(x - radius * 0.05, y)
            ..close();
          
          // چرخش لوزی
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(angle);
          canvas.translate(-x, -y);
          
          paint.color = colors[(i + ring) % colors.length];
          canvas.drawPath(path, paint);
          
          canvas.restore();
        }
      }
    }
    
    // رسم مرکز
    paint.color = colors[seed % colors.length];
    canvas.drawCircle(center, radius * 0.15, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
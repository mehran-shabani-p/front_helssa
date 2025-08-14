import 'dart:math';
import 'package:flutter/material.dart';

class ParticlesBackground extends StatefulWidget {
  const ParticlesBackground({super.key});
  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final _Model _model;

  @override
  void initState() {
    super.initState();
    _ctl =
        AnimationController(vsync: this, duration: const Duration(seconds: 18))
          ..addListener(() => _model.tick())
          ..repeat();
    _model = _Model(onNeedsPaint: () => setState(() {}));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
          painter: _Painter(_model), child: const SizedBox.expand()),
    );
  }
}

class _Model {
  final VoidCallback onNeedsPaint;
  final rnd = Random();
  List<_Particle> ps = [];
  Size size = Size.zero;

  _Model({required this.onNeedsPaint});

  void ensure(Size s) {
    if (s == size && ps.isNotEmpty) return;
    size = s;
    ps = [];
    final count = (s.shortestSide / 18).clamp(24, 64).toInt();
    for (int i = 0; i < count; i++) {
      ps.add(_Particle(
        pos: Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height),
        vel: Offset(
            (rnd.nextDouble() - .5) * .25, (rnd.nextDouble() - .5) * .25),
        r: rnd.nextDouble() * 1.6 + .6,
        a: rnd.nextDouble() * 0.25 + 0.05,
      ));
    }
  }

  void tick() {
    if (size == Size.zero) return;
    for (final p in ps) {
      p.pos += p.vel;
      if (p.pos.dx < -p.r) p.pos = Offset(size.width + p.r, p.pos.dy);
      if (p.pos.dx > size.width + p.r) p.pos = Offset(-p.r, p.pos.dy);
      if (p.pos.dy < -p.r) p.pos = Offset(p.pos.dx, size.height + p.r);
      if (p.pos.dy > size.height + p.r) p.pos = Offset(p.pos.dx, -p.r);
    }
    onNeedsPaint();
  }
}

class _Particle {
  Offset pos;
  Offset vel;
  double r;
  double a;
  _Particle(
      {required this.pos, required this.vel, required this.r, required this.a});
}

class _Painter extends CustomPainter {
  final _Model m;
  _Painter(this.m);

  @override
  void paint(Canvas c, Size s) {
    m.ensure(s);
    if (m.ps.isEmpty) return;

    final dot = Paint()..color = Colors.white.withValues(alpha: .12);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..strokeWidth = .6;

    const maxDist2 = 110 * 110;
    for (int i = 0; i < m.ps.length; i++) {
      final pi = m.ps[i];
      for (int j = i + 1; j < m.ps.length; j++) {
        final pj = m.ps[j];
        final dx = pi.pos.dx - pj.pos.dx, dy = pi.pos.dy - pj.pos.dy;
        final d2 = dx * dx + dy * dy;
        if (d2 < maxDist2) {
          final t = 1 - (d2 / maxDist2);
          line.color = Colors.white.withValues(alpha: .05 + .10 * t);
          c.drawLine(pi.pos, pj.pos, line);
        }
      }
    }
    for (final p in m.ps) {
      dot.color = Colors.white.withValues(alpha: p.a);
      c.drawCircle(p.pos, p.r, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _Painter oldDelegate) => true;
}

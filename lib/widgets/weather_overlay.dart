import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/audio_haptic_helper.dart';
import '../core/effects_settings.dart';

/// Full-screen, touch-through effects layer (snow, rain, lightning, teddies...).
/// Put it on top of any screen inside a Stack. [subtle] softens the lightning
/// flash, which is used while playing the game.
class WeatherOverlay extends StatefulWidget {
  final bool subtle;
  const WeatherOverlay({super.key, this.subtle = false});

  @override
  State<WeatherOverlay> createState() => _WeatherOverlayState();
}

class _WeatherOverlayState extends State<WeatherOverlay>
    with SingleTickerProviderStateMixin {
  final _rng = Random();
  late final Ticker _ticker;
  final _WeatherState _weather = _WeatherState();
  Duration _last = Duration.zero;
  bool _prevLightning = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    final s = EffectsSettings.instance;
    if (!s.anyOn && _weather.idle) return; // nothing to draw, save battery
    if (!mounted) return;
    if (s.lightning && !_prevLightning) _weather.triggerStrikeSoon();
    _prevLightning = s.lightning;
    _weather.update(
      dt,
      MediaQuery.sizeOf(context),
      _rng,
      snow: s.snow,
      rain: s.rain,
      lightning: s.lightning,
      arrows: s.arrows,
      sparks: s.sparks,
      meteors: s.meteors,
      teddy: s.teddy,
      hearts: s.hearts,
      party: s.party,
      confetti: s.confetti,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _weather.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _WeatherPainter(_weather)),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _FlashPainter(_weather, widget.subtle ? 0.35 : 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The ON/OFF buttons for every effect. Shared by About and the in-game sheet.
class EffectsPanel extends StatelessWidget {
  const EffectsPanel({super.key});

  Widget _btn(String key, String label, IconData icon, Color color,
      {String? emoji}) {
    final s = EffectsSettings.instance;
    return Expanded(
      child: _EffectButton(
        label: label,
        emoji: emoji,
        icon: icon,
        color: color,
        active: s.get(key),
        onTap: () {
          AudioHapticHelper.playClick();
          s.toggle(key);
        },
      ),
    );
  }

  Widget _row(List<Widget> kids) {
    final out = <Widget>[];
    for (int i = 0; i < kids.length; i++) {
      if (i > 0) out.add(const SizedBox(width: 10));
      out.add(kids[i]);
    }
    return Row(children: out);
  }

  @override
  Widget build(BuildContext context) {
    final s = EffectsSettings.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row([
            _btn('snow', 'SNOW', Icons.ac_unit_rounded, const Color(0xFF9BE7FF)),
            _btn('rain', 'RAIN', Icons.water_drop_rounded, const Color(0xFF4DA3FF)),
            _btn('lightning', 'LIGHTNING', Icons.bolt_rounded, const Color(0xFFFFE259)),
          ]),
          const SizedBox(height: 10),
          _row([
            _btn('arrows', 'ARROWS', Icons.north_east_rounded, const Color(0xFF00E5FF)),
            _btn('sparks', 'SPARKS', Icons.auto_awesome_rounded, const Color(0xFFFFC83D)),
            _btn('meteors', 'METEORS', Icons.nightlight_round, const Color(0xFFFF7A59)),
          ]),
          const SizedBox(height: 10),
          _row([
            _btn('teddy', 'TEDDY', Icons.pets_rounded, const Color(0xFFFFB085), emoji: '🧸'),
            _btn('hearts', 'HEARTS', Icons.favorite_rounded, const Color(0xFFFF6B9D), emoji: '💖'),
            _btn('party', 'PARTY', Icons.celebration_rounded, const Color(0xFFB5F36B), emoji: '🎉'),
          ]),
          const SizedBox(height: 10),
          _row([
            _btn('confetti', 'CONFETTI', Icons.confirmation_number_rounded, const Color(0xFFFF8AE2), emoji: '🎊'),
            Expanded(
              child: _EffectButton(
                label: 'ALL ON',
                icon: Icons.thunderstorm_rounded,
                color: const Color(0xFFB388FF),
                active: s.allOn,
                onTap: () {
                  AudioHapticHelper.playClick();
                  s.setAll(true);
                },
              ),
            ),
            Expanded(
              child: _EffectButton(
                label: 'ALL OFF',
                icon: Icons.wb_sunny_rounded,
                color: const Color(0xFFFFB74D),
                active: !s.anyOn,
                onTap: () {
                  AudioHapticHelper.playClick();
                  s.setAll(false);
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _EffectButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? emoji;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _EffectButton({
    required this.label,
    this.emoji,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.22)
              : const Color(0xFF0E1A3D).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color : const Color(0xFF3A4A7A),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: active ? color.withValues(alpha: 0.45) : Colors.transparent,
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          children: [
            emoji != null
                ? Opacity(
                    opacity: active ? 1 : 0.5,
                    child: Text(emoji!, style: const TextStyle(fontSize: 22)),
                  )
                : Icon(icon,
                    color: active ? color : const Color(0xFF6C7BA8), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF8D9CC8),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              active ? 'ON' : 'OFF',
              style: TextStyle(
                color: active ? color : const Color(0xFF5A6890),
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================== WEATHER

class _Flake {
  double x, y, r, speed, phase, drift;
  _Flake(this.x, this.y, this.r, this.speed, this.phase, this.drift);
}

class _Drop {
  double x, y, len, speed;
  _Drop(this.x, this.y, this.len, this.speed);
}

class _FloatArrow {
  double x, y, size, speed, phase;
  _FloatArrow(this.x, this.y, this.size, this.speed, this.phase);
}

class _Spark {
  double x, y, r, speed, phase, twinkle;
  _Spark(this.x, this.y, this.r, this.speed, this.phase, this.twinkle);
}

class _Meteor {
  double x, y, vx, vy, life;
  _Meteor(this.x, this.y, this.vx, this.vy, this.life);
}

class _EmojiP {
  double x, y, size, speed, phase, rot = 0;
  String e;
  _EmojiP(this.e, this.x, this.y, this.size, this.speed, this.phase);
}

class _Confetti {
  double x, y, w, h, speed, phase;
  Color c;
  _Confetti(this.x, this.y, this.w, this.h, this.speed, this.phase, this.c);
}

class _Bolt {
  final List<Offset> main;
  final List<List<Offset>> branches;
  double life; // 1 -> 0
  _Bolt(this.main, this.branches, this.life);
}

/// Holds all particle state and acts as the repaint [Listenable].
class _WeatherState extends ChangeNotifier {
  static const int flakeCount = 90;
  static const int dropCount = 130;

  final List<_Flake> flakes = [];
  final List<_Drop> drops = [];
  final List<_Bolt> bolts = [];
  final List<_FloatArrow> arrows = [];
  final List<_Spark> sparks = [];
  final List<_Meteor> meteors = [];
  double arrowAlpha = 0, sparkAlpha = 0, meteorAlpha = 0;
  double _nextMeteor = 1.0;
  final List<_EmojiP> teddies = [];
  final List<_EmojiP> heartsList = [];
  final List<_EmojiP> partyList = [];
  final List<_Confetti> confettiList = [];
  double teddyAlpha = 0, heartAlpha = 0, partyAlpha = 0, confettiAlpha = 0;

  double snowAlpha = 1, rainAlpha = 0;
  double flash = 0; // 0..1 screen flash intensity
  double _nextStrike = 1.5;
  double _clock = 0;
  bool _seeded = false;

  void seed(Random rng) {
    _seeded = false;
  }

  void _ensureSeeded(Size s, Random rng) {
    if (_seeded || s.isEmpty) return;
    _seeded = true;
    for (int i = 0; i < flakeCount; i++) {
      flakes.add(_Flake(
        rng.nextDouble() * s.width,
        rng.nextDouble() * s.height,
        1.2 + rng.nextDouble() * 3.2,
        25 + rng.nextDouble() * 55,
        rng.nextDouble() * pi * 2,
        10 + rng.nextDouble() * 22,
      ));
    }
    const heartEmojis = ['💖', '💗', '💙', '💛', '💜'];
    const partyEmojis = ['🎉', '⭐', '🔥', '🌈', '🎈', '✨', '🏆', '👑', '🎮', '🚀'];
    const confettiColors = [
      Color(0xFFFF4D6D),
      Color(0xFFFFD166),
      Color(0xFF06D6A0),
      Color(0xFF4DA3FF),
      Color(0xFFB388FF),
      Color(0xFFFF8AE2),
    ];
    for (int i = 0; i < 16; i++) {
      teddies.add(_EmojiP('🧸', rng.nextDouble() * s.width,
          rng.nextDouble() * s.height, 26 + rng.nextDouble() * 22,
          28 + rng.nextDouble() * 42, rng.nextDouble() * pi * 2));
    }
    for (int i = 0; i < 18; i++) {
      heartsList.add(_EmojiP(heartEmojis[rng.nextInt(heartEmojis.length)],
          rng.nextDouble() * s.width, rng.nextDouble() * s.height,
          18 + rng.nextDouble() * 18, 30 + rng.nextDouble() * 45,
          rng.nextDouble() * pi * 2));
    }
    for (int i = 0; i < 22; i++) {
      partyList.add(_EmojiP(partyEmojis[rng.nextInt(partyEmojis.length)],
          rng.nextDouble() * s.width, rng.nextDouble() * s.height,
          20 + rng.nextDouble() * 20, 35 + rng.nextDouble() * 55,
          rng.nextDouble() * pi * 2));
    }
    for (int i = 0; i < 70; i++) {
      confettiList.add(_Confetti(
          rng.nextDouble() * s.width, rng.nextDouble() * s.height,
          5 + rng.nextDouble() * 6, 8 + rng.nextDouble() * 8,
          60 + rng.nextDouble() * 120, rng.nextDouble() * pi * 2,
          confettiColors[rng.nextInt(confettiColors.length)]));
    }
    for (int i = 0; i < 14; i++) {
      arrows.add(_FloatArrow(
        rng.nextDouble() * s.width,
        rng.nextDouble() * s.height,
        10 + rng.nextDouble() * 16,
        18 + rng.nextDouble() * 38,
        rng.nextDouble() * pi * 2,
      ));
    }
    for (int i = 0; i < 50; i++) {
      sparks.add(_Spark(
        rng.nextDouble() * s.width,
        rng.nextDouble() * s.height,
        1 + rng.nextDouble() * 2.2,
        8 + rng.nextDouble() * 22,
        rng.nextDouble() * pi * 2,
        1.5 + rng.nextDouble() * 3,
      ));
    }
    for (int i = 0; i < dropCount; i++) {
      drops.add(_Drop(
        rng.nextDouble() * s.width,
        rng.nextDouble() * s.height,
        14 + rng.nextDouble() * 22,
        520 + rng.nextDouble() * 380,
      ));
    }
  }

  void triggerStrikeSoon() => _nextStrike = 0.25;

  bool get idle =>
      snowAlpha < 0.01 &&
      rainAlpha < 0.01 &&
      arrowAlpha < 0.01 &&
      sparkAlpha < 0.01 &&
      meteorAlpha < 0.01 &&
      teddyAlpha < 0.01 &&
      heartAlpha < 0.01 &&
      partyAlpha < 0.01 &&
      confettiAlpha < 0.01 &&
      bolts.isEmpty &&
      meteors.isEmpty &&
      flash <= 0.01;

  void update(
    double dt,
    Size s,
    Random rng, {
    required bool snow,
    required bool rain,
    required bool lightning,
    required bool arrows,
    required bool sparks,
    required bool meteors,
    required bool teddy,
    required bool hearts,
    required bool party,
    required bool confetti,
  }) {
    _ensureSeeded(s, rng);
    _clock += dt;

    // fade layers in/out smoothly
    snowAlpha += ((snow ? 1 : 0) - snowAlpha) * min(1, dt * 4);
    rainAlpha += ((rain ? 1 : 0) - rainAlpha) * min(1, dt * 4);

    arrowAlpha += ((arrows ? 1 : 0) - arrowAlpha) * min(1, dt * 4);
    sparkAlpha += ((sparks ? 1 : 0) - sparkAlpha) * min(1, dt * 4);
    meteorAlpha += ((meteors ? 1 : 0) - meteorAlpha) * min(1, dt * 4);

    teddyAlpha += ((teddy ? 1 : 0) - teddyAlpha) * min(1, dt * 4);
    heartAlpha += ((hearts ? 1 : 0) - heartAlpha) * min(1, dt * 4);
    partyAlpha += ((party ? 1 : 0) - partyAlpha) * min(1, dt * 4);
    confettiAlpha += ((confetti ? 1 : 0) - confettiAlpha) * min(1, dt * 4);

    if (teddyAlpha > 0.01) {
      for (final t in teddies) {
        t.y += t.speed * dt; // teddies fall
        t.x += sin(_clock * 0.8 + t.phase) * 16 * dt;
        t.rot = sin(_clock * 1.3 + t.phase) * 0.5;
        if (t.y > s.height + 40) {
          t.y = -40;
          t.x = rng.nextDouble() * s.width;
        }
      }
    }
    if (heartAlpha > 0.01) {
      for (final h in heartsList) {
        h.y -= h.speed * dt; // hearts float up
        h.x += sin(_clock + h.phase) * 14 * dt;
        h.rot = sin(_clock * 1.6 + h.phase) * 0.35;
        if (h.y < -40) {
          h.y = s.height + 40;
          h.x = rng.nextDouble() * s.width;
        }
      }
    }
    if (partyAlpha > 0.01) {
      for (final p in partyList) {
        p.y += p.speed * dt;
        p.x += sin(_clock * 0.9 + p.phase) * 18 * dt;
        p.rot += dt * (0.6 + (p.phase % 1.5));
        if (p.y > s.height + 40) {
          p.y = -40;
          p.x = rng.nextDouble() * s.width;
        }
      }
    }
    if (confettiAlpha > 0.01) {
      for (final c in confettiList) {
        c.y += c.speed * dt;
        c.x += sin(_clock * 1.4 + c.phase) * 24 * dt;
        if (c.y > s.height + 20) {
          c.y = -20;
          c.x = rng.nextDouble() * s.width;
        }
      }
    }

    if (arrowAlpha > 0.01) {
      for (final a in this.arrows) {
        a.y -= a.speed * dt;
        a.x += sin(_clock * 0.7 + a.phase) * 10 * dt;
        if (a.y < -30) {
          a.y = s.height + 30;
          a.x = rng.nextDouble() * s.width;
        }
      }
    }
    if (sparkAlpha > 0.01) {
      for (final sp in this.sparks) {
        sp.y -= sp.speed * dt;
        sp.x += sin(_clock + sp.phase) * 8 * dt;
        if (sp.y < -6) {
          sp.y = s.height + 6;
          sp.x = rng.nextDouble() * s.width;
        }
      }
    }
    if (meteors) {
      _nextMeteor -= dt;
      if (_nextMeteor <= 0) {
        _nextMeteor = 0.8 + rng.nextDouble() * 2.2;
        this.meteors.add(_Meteor(
          s.width * (0.3 + rng.nextDouble() * 0.9),
          -10,
          -(260 + rng.nextDouble() * 200),
          300 + rng.nextDouble() * 220,
          1,
        ));
      }
    }
    for (final m in this.meteors) {
      m.x += m.vx * dt;
      m.y += m.vy * dt;
      m.life -= dt * 0.7;
    }
    this.meteors.removeWhere((m) => m.life <= 0 || m.y > s.height + 40);

    if (snowAlpha > 0.01) {
      for (final f in flakes) {
        f.y += f.speed * dt;
        f.x += sin(_clock * 0.9 + f.phase) * f.drift * dt;
        if (f.y > s.height + 6) {
          f.y = -6;
          f.x = rng.nextDouble() * s.width;
        }
        if (f.x < -6) f.x = s.width + 6;
        if (f.x > s.width + 6) f.x = -6;
      }
    }

    if (rainAlpha > 0.01) {
      for (final d in drops) {
        d.y += d.speed * dt;
        d.x -= d.speed * 0.18 * dt; // slanted fall
        if (d.y > s.height + d.len || d.x < -20) {
          d.y = -d.len;
          d.x = rng.nextDouble() * (s.width + 80);
        }
      }
    }

    // lightning
    if (lightning) {
      _nextStrike -= dt;
      if (_nextStrike <= 0) {
        _strike(s, rng);
        _nextStrike = 1.8 + rng.nextDouble() * 4.2;
      }
    }
    for (final b in bolts) {
      b.life -= dt * 2.6;
    }
    bolts.removeWhere((b) => b.life <= 0);
    flash = max(0, flash - dt * 3.2);

    notifyListeners();
  }

  void _strike(Size s, Random rng) {
    final startX = s.width * (0.15 + rng.nextDouble() * 0.7);
    final endY = s.height * (0.45 + rng.nextDouble() * 0.4);
    final main = <Offset>[Offset(startX, 0)];
    var x = startX, y = 0.0;
    final branches = <List<Offset>>[];
    while (y < endY) {
      y += 24 + rng.nextDouble() * 38;
      x += (rng.nextDouble() - 0.5) * 70;
      main.add(Offset(x, y));
      if (rng.nextDouble() < 0.28) {
        final br = <Offset>[Offset(x, y)];
        var bx = x, by = y;
        final dir = rng.nextBool() ? 1 : -1;
        for (int i = 0; i < 3 + rng.nextInt(3); i++) {
          bx += dir * (14 + rng.nextDouble() * 26);
          by += 14 + rng.nextDouble() * 26;
          br.add(Offset(bx, by));
        }
        branches.add(br);
      }
    }
    bolts.add(_Bolt(main, branches, 1));
    flash = 0.75 + rng.nextDouble() * 0.25;
  }
}

class _WeatherPainter extends CustomPainter {
  final _WeatherState w;
  static final Map<String, TextPainter> _cache = {};
  _WeatherPainter(this.w) : super(repaint: w);

  @override
  void paint(Canvas canvas, Size size) {
    // ---- confetti
    if (w.confettiAlpha > 0.01) {
      final p = Paint();
      for (final c in w.confettiList) {
        final flip = (sin(w._clock * 3 + c.phase)).abs();
        p.color = c.c.withValues(alpha: 0.9 * w.confettiAlpha);
        canvas.save();
        canvas.translate(c.x, c.y);
        canvas.rotate(w._clock * 1.2 + c.phase);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: c.w, height: max(1.5, c.h * flip)),
          p,
        );
        canvas.restore();
      }
    }

    // ---- emoji layers
    void emojiLayer(List<_EmojiP> list, double alpha) {
      if (alpha <= 0.01) return;
      for (final e in list) {
        final tp = _cache.putIfAbsent(
          e.e,
          () => TextPainter(
            text: TextSpan(text: e.e, style: const TextStyle(fontSize: 32)),
            textDirection: TextDirection.ltr,
          )..layout(),
        );
        canvas.save();
        canvas.translate(e.x, e.y);
        canvas.rotate(e.rot);
        canvas.scale(e.size / 32 * alpha);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }

    emojiLayer(w.partyList, w.partyAlpha);
    emojiLayer(w.teddies, w.teddyAlpha);
    emojiLayer(w.heartsList, w.heartAlpha);

    // ---- floating glowing arrows (game theme)
    if (w.arrowAlpha > 0.01) {
      final fill = Paint();
      final glow = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      for (final a in w.arrows) {
        final c = const Color(0xFF00E5FF).withValues(alpha: 0.35 * w.arrowAlpha);
        fill.color = c;
        glow.color = c.withValues(alpha: 0.25 * w.arrowAlpha);
        final path = Path()
          ..moveTo(a.x, a.y - a.size)
          ..lineTo(a.x + a.size * 0.6, a.y)
          ..lineTo(a.x + a.size * 0.2, a.y)
          ..lineTo(a.x + a.size * 0.2, a.y + a.size * 0.9)
          ..lineTo(a.x - a.size * 0.2, a.y + a.size * 0.9)
          ..lineTo(a.x - a.size * 0.2, a.y)
          ..lineTo(a.x - a.size * 0.6, a.y)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
      }
    }

    // ---- golden sparks
    if (w.sparkAlpha > 0.01) {
      final p = Paint();
      final g = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      for (final sp in w.sparks) {
        final tw = 0.5 + 0.5 * sin(w._clock * sp.twinkle + sp.phase);
        p.color = const Color(0xFFFFE08A).withValues(alpha: tw * w.sparkAlpha);
        g.color = const Color(0xFFFFA400).withValues(alpha: 0.5 * tw * w.sparkAlpha);
        canvas.drawCircle(Offset(sp.x, sp.y), sp.r * 2.4, g);
        canvas.drawCircle(Offset(sp.x, sp.y), sp.r, p);
      }
    }

    // ---- meteors
    if (w.meteorAlpha > 0.01) {
      for (final m in w.meteors) {
        final tail = Offset(m.x - m.vx * 0.18, m.y - m.vy * 0.18);
        final head = Offset(m.x, m.y);
        final shader = LinearGradient(
          colors: [
            const Color(0x00FF7A59),
            const Color(0xFFFFD6A5).withValues(alpha: m.life.clamp(0.0, 1.0)),
          ],
        ).createShader(Rect.fromPoints(tail, head));
        canvas.drawLine(
          tail,
          head,
          Paint()
            ..shader = shader
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(head, 2.6,
            Paint()..color = Colors.white.withValues(alpha: m.life.clamp(0.0, 1.0)));
      }
    }

    // ---- rain
    if (w.rainAlpha > 0.01) {
      final p = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.4
        ..color = const Color(0xFF9CC8FF).withValues(alpha: 0.5 * w.rainAlpha);
      for (final d in w.drops) {
        canvas.drawLine(
          Offset(d.x, d.y),
          Offset(d.x + d.len * 0.18, d.y - d.len),
          p,
        );
      }
    }

    // ---- snow
    if (w.snowAlpha > 0.01) {
      final glow = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      final core = Paint();
      for (final f in w.flakes) {
        final a = (0.55 + (f.r / 4.4) * 0.45) * w.snowAlpha;
        glow.color = Colors.white.withValues(alpha: a * 0.45);
        core.color = Colors.white.withValues(alpha: a);
        canvas.drawCircle(Offset(f.x, f.y), f.r * 1.6, glow);
        canvas.drawCircle(Offset(f.x, f.y), f.r, core);
      }
    }

    // ---- lightning bolts
    for (final b in w.bolts) {
      final a = b.life.clamp(0.0, 1.0);
      final flicker = (sin(b.life * 40) > -0.3) ? 1.0 : 0.45;
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 9
        ..color = const Color(0xFF7FB2FF).withValues(alpha: 0.55 * a * flicker)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      final corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.6
        ..color = Colors.white.withValues(alpha: a * flicker);

      Path toPath(List<Offset> pts) {
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final o in pts.skip(1)) {
          path.lineTo(o.dx, o.dy);
        }
        return path;
      }

      final mainPath = toPath(b.main);
      canvas.drawPath(mainPath, glowPaint);
      canvas.drawPath(mainPath, corePaint);
      for (final br in b.branches) {
        final bp = toPath(br);
        canvas.drawPath(bp, glowPaint..strokeWidth = 5);
        canvas.drawPath(bp, corePaint..strokeWidth = 1.4);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter old) => false;
}

/// Full-screen white/blue flash when lightning strikes.
class _FlashPainter extends CustomPainter {
  final _WeatherState w;
  final double scale;
  _FlashPainter(this.w, this.scale) : super(repaint: w);

  @override
  void paint(Canvas canvas, Size size) {
    if (w.flash <= 0.01) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = const Color(0xFFBFD8FF).withValues(alpha: 0.28 * w.flash * scale),
    );
  }

  @override
  bool shouldRepaint(covariant _FlashPainter old) => false;
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../core/audio_haptic_helper.dart';
import '../../core/constants.dart';
import '../../core/effects_settings.dart';
import '../../widgets/weather_overlay.dart';

/// About screen for Mathra Arrow Escape: 3D tilting badge + effects layer.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with SingleTickerProviderStateMixin {
  static const String developerName = AppConstants.developerName;
  static const String developerNameSi = 'දෙනුවන් ආකාශ්';
  static const String version = 'v1.0.12';

  late final Ticker _ticker;
  final ValueNotifier<int> _badgeTick = ValueNotifier<int>(0);

  // 3D drag rotation
  double _dragX = 0;
  double _dragY = 0;
  bool _dragging = false;
  double _time = 0;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _time += dt;
    if (!_dragging) {
      _dragX *= pow(0.04, dt).toDouble();
      _dragY *= pow(0.04, dt).toDouble();
    }
    _badgeTick.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _badgeTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ListenableBuilder(
            listenable: EffectsSettings.instance,
            builder: (context, _) {
              final stormy = EffectsSettings.instance.stormy;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: stormy
                        ? const [Color(0xFF05070F), Color(0xFF0B1226), Color(0xFF020409)]
                        : const [Color(0xFF0A1330), Color(0xFF0E1E4A), Color(0xFF040814)],
                  ),
                ),
              );
            },
          ),
          const WeatherOverlay(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(onBack: () => Navigator.pop(context)),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _build3DBadge(),
                        const SizedBox(height: 18),
                        _buildTitle(),
                        const SizedBox(height: 16),
                        _buildAboutCard(),
                        const SizedBox(height: 16),
                        _buildDeveloperCard(),
                        const SizedBox(height: 16),
                        _buildLinksCard(),
                        const SizedBox(height: 20),
                        const Text(
                          'EFFECTS',
                          style: TextStyle(
                            color: Color(0xFF9FB2E8),
                            fontSize: 13,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'These also play while you are in a game',
                          style: TextStyle(
                            color: Color(0xFF6C7BA8),
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const EffectsPanel(),
                        const SizedBox(height: 14),
                        Text(
                          '${AppConstants.appName}  $version',
                          style: const TextStyle(
                            color: Color(0xFF6C7BA8),
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
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

  // ---------------------------------------------------------------- 3D badge

  Widget _build3DBadge() {
    final size = MediaQuery.sizeOf(context).width * 0.68;
    return GestureDetector(
      onPanStart: (_) => _dragging = true,
      onPanUpdate: (d) {
        _dragX = (_dragX + d.delta.dx * 0.012).clamp(-0.9, 0.9);
        _dragY = (_dragY - d.delta.dy * 0.012).clamp(-0.6, 0.6);
      },
      onPanEnd: (_) => _dragging = false,
      onPanCancel: () => _dragging = false,
      child: ValueListenableBuilder<int>(
        valueListenable: _badgeTick,
        builder: (context, _, child) {
          final swayY = sin(_time * 0.9) * 0.28;
          final swayX = cos(_time * 0.7) * 0.10;
          final bob = sin(_time * 1.6) * 8;
          final matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(swayY + _dragX)
            ..rotateX(swayX + _dragY);
          final shadowScale = 1 - (bob / 60);

          return SizedBox(
            width: size,
            height: size + 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // ground glow / shadow
                Positioned(
                  bottom: 0,
                  child: Transform.scale(
                    scaleX: shadowScale,
                    child: Container(
                      width: size * 0.6,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2A7BFF).withValues(alpha: 0.55),
                            blurRadius: 30,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12 + bob,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: matrix,
                    child: child,
                  ),
                ),
              ],
            ),
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A7BFF).withValues(alpha: 0.6),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/mathra_badge.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 700.ms).scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
          duration: 800.ms,
        );
  }

  // ------------------------------------------------------------------- title

  Widget _buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [Color(0xFFFFE259), Color(0xFFFFA400)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(rect),
          child: const Text(
            'MATHRA',
            style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
              height: 1,
              shadows: [Shadow(color: Color(0xAAFFA400), blurRadius: 18)],
            ),
          ),
        ),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [Color(0xFF7DF9FF), Color(0xFF2A7BFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(rect),
          child: const Text(
            'ARROW ESCAPE',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
              height: 1.1,
              shadows: [Shadow(color: Color(0xAA2A7BFF), blurRadius: 18)],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 250.ms, duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  // ------------------------------------------------------------- about cards

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A3D).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF3D8BFF).withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A7BFF).withValues(alpha: 0.25),
            blurRadius: 22,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAboutCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.info_rounded, color: Color(0xFFFFC83D), size: 20),
              SizedBox(width: 8),
              Text(
                'ABOUT THE GAME',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Mathra Arrow Escape is a slick, satisfying arrow puzzle. Every '
            'arrow points a direction, and your job is to slide each one off '
            'the board without crashing into another. Think a few moves '
            'ahead, clear the path, and escape!\n\n'
            'Race through hand-crafted style levels, take on boss and god '
            'stages, chill in Zen mode, beat the clock in Time Attack, or '
            'challenge your friends on the exact same puzzle in Multiplayer.\n\n'
            'Slide. Solve. Escape.',
            style: TextStyle(
              color: Color(0xFFC9D6F5),
              fontSize: 15,
              height: 1.45,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'whatsapp':
        return Icons.chat_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'youtube':
        return Icons.play_circle_fill_rounded;
      case 'tiktok':
        return Icons.music_note_rounded;
      case 'telegram':
        return Icons.send_rounded;
      case 'github':
        return Icons.code_rounded;
      case 'email':
        return Icons.email_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  Widget _buildLinksCard() {
    return _glassCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final l in AppConstants.aboutLinks)
            GestureDetector(
              onTap: () async {
                AudioHapticHelper.playClick();
                try {
                  await launchUrl(Uri.parse(l[2]),
                      mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1A3D),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF3D8BFF).withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconFor(l[1]),
                        color: const Color(0xFFFFC83D), size: 20),
                    const SizedBox(width: 8),
                    Text(l[0],
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 650.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildDeveloperCard() {
    return _glassCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFFE259), Color(0xFFFFA400)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.code_rounded, color: Color(0xFF14204A), size: 30),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEVELOPED BY',
                  style: TextStyle(
                    color: Color(0xFF7F92C9),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  developerName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                // BebasNeue has no Sinhala glyphs, so use the system font here.
                Text(
                  developerNameSi,
                  style: TextStyle(
                    fontFamily: null,
                    color: Color(0xFFFFC83D),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 550.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

}

// ======================================================================= UI

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioHapticHelper.playClick();
              onBack();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0E1A3D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF3D8BFF).withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'ABOUT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}


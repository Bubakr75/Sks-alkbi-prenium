import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'firebase_options.dart';
import 'screens/choix_scenario_screen.dart';
import 'screens/test_mode_screen.dart';
import 'join_room_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKS Alibi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
        textTheme: GoogleFonts.spaceGroteskTextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  PageRoute _route(Widget page) => PageRouteBuilder(
    pageBuilder: (ctx, a1, a2) => page,
    transitionsBuilder: (ctx, anim, a2, child) => FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 300),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      body: Stack(
        children: [
          Positioned(top: -100, left: -80, child: _GlowCircle(color: const Color(0xFF6C63FF), size: 350)),
          Positioned(bottom: -80, right: -60, child: _GlowCircle(color: const Color(0xFF00C9A7), size: 280)),
          Positioned(top: 300, right: -40, child: _GlowCircle(color: const Color(0xFFFF6B6B), size: 200)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6C63FF), Color(0xFF3A3580)],
                      ),
                      boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.5), blurRadius: 50, spreadRadius: 5)],
                    ),
                    child: const Center(child: Text('🎭', style: TextStyle(fontSize: 58))),
                  )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 400.ms),
                  const SizedBox(height: 28),
                  Text(
                    'SKS : Alibi',
                    style: GoogleFonts.spaceGrotesk(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5),
                  )
                  .animate()
                  .slideY(begin: 0.3, duration: 500.ms, delay: 200.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Le jeu du bluff et de l\'enquête',
                    style: GoogleFonts.spaceGrotesk(fontSize: 15, color: Colors.white38, fontWeight: FontWeight.w400),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 400.ms),
                  const Spacer(flex: 2),
                  _PremiumButton(
                    label: 'Créer un salon',
                    emoji: '🏠',
                    gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3A3580)]),
                    glowColor: const Color(0xFF6C63FF),
                    onTap: () => Navigator.push(context, _route(const ChoixScenarioScreen())),
                  )
                  .animate()
                  .slideY(begin: 0.4, duration: 500.ms, delay: 500.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 400.ms, delay: 500.ms),
                  const SizedBox(height: 14),
                  _GlassButton(
                    label: 'Rejoindre un salon',
                    emoji: '🔑',
                    onTap: () => Navigator.push(context, _route(const JoinRoomScreen())),
                  )
                  .animate()
                  .slideY(begin: 0.4, duration: 500.ms, delay: 600.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 400.ms, delay: 600.ms),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => Navigator.push(context, _route(const TestModeSetupScreen())),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🤖', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text('Mode Test (solo + IA)', style: GoogleFonts.spaceGrotesk(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          const Text('⚠️', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 700.ms),
                  const Spacer(),
                  Text('v2.0 — Beta', style: GoogleFonts.spaceGrotesk(color: Colors.white12, fontSize: 11))
                  .animate().fadeIn(duration: 400.ms, delay: 900.ms),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumButton extends StatefulWidget {
  final String label;
  final String emoji;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback onTap;
  const _PremiumButton({required this.label, required this.emoji, required this.gradient, required this.glowColor, required this.onTap});
  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) => setState(() => _pressed = true),
      onTapUp: (d) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: widget.glowColor.withValues(alpha: _pressed ? 0.2 : 0.45), blurRadius: _pressed ? 10 : 25, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Text(widget.label, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatefulWidget {
  final String label;
  final String emoji;
  final VoidCallback onTap;
  const _GlassButton({required this.label, required this.emoji, required this.onTap});
  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) => setState(() => _pressed = true),
      onTapUp: (d) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _pressed ? 0.05 : 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Text(widget.label, style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 17, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.0)]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../create_room_screen.dart';

class ChoixScenarioScreen extends StatefulWidget {
  const ChoixScenarioScreen({super.key});

  @override
  State<ChoixScenarioScreen> createState() => _ChoixScenarioScreenState();
}

class _ChoixScenarioScreenState extends State<ChoixScenarioScreen> {
  String? _themeChoisi;

  final List<Map<String, dynamic>> _themes = [
    {
      'id': 'trahison',
      'titre': 'Trahison',
      'emoji': '🗡️',
      'tag': 'TRAHISON',
      'description': 'Quelqu\'un dans le groupe a trahi la confiance de tous. Mensonges, faux-semblants et coups bas au programme.',
      'couleur': const Color(0xFFFF4757),
      'gradient': [const Color(0xFF8B0000), const Color(0xFF1A0000)],
    },
    {
      'id': 'vol',
      'titre': 'Vol',
      'emoji': '💰',
      'tag': 'VOL',
      'description': 'Quelque chose de précieux a disparu. L\'un d\'entre vous l\'a pris. Mais lequel ?',
      'couleur': const Color(0xFFFFB300),
      'gradient': [const Color(0xFF5C3D00), const Color(0xFF1A1000)],
    },
    {
      'id': 'tromperie',
      'titre': 'Tromperie',
      'emoji': '🎭',
      'tag': 'TROMPERIE',
      'description': 'Les apparences sont trompeuses. Quelqu\'un joue un double jeu depuis le début.',
      'couleur': const Color(0xFFAB47BC),
      'gradient': [const Color(0xFF3A0050), const Color(0xFF0D001A)],
    },
    {
      'id': 'aleatoire',
      'titre': 'Surprise',
      'emoji': '🎲',
      'tag': 'ALÉATOIRE',
      'description': 'L\'IA choisit le thème selon vos profils psychologiques. Résultat imprévisible.',
      'couleur': const Color(0xFF00C9A7),
      'gradient': [const Color(0xFF003D35), const Color(0xFF001A15)],
    },
  ];

  void _naviguerVersCreation() {
    if (_themeChoisi == null) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, a1, a2) => CreateRoomScreen(scenarioId: _themeChoisi!),
        transitionsBuilder: (ctx, anim, a2, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      body: Stack(
        children: [
          // Cercles lumineux
          if (_themeChoisi != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              top: -50, left: -50,
              child: _buildGlow(
                _themes.firstWhere((t) => t['id'] == _themeChoisi)['couleur'] as Color,
                300,
              ),
            ),
          Positioned(bottom: -100, right: -80,
            child: _buildGlow(const Color(0xFF6C63FF), 250)),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text('SKS : ALIBI',
                              style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text('Choisis', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w500))
                        .animate().fadeIn(duration: 400.ms),
                      Text('ton univers', style: GoogleFonts.spaceGrotesk(fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1))
                        .animate().slideY(begin: 0.2, duration: 400.ms, delay: 100.ms).fadeIn(duration: 400.ms, delay: 100.ms),
                      const SizedBox(height: 8),
                      Text(
                        'L\'IA génère une histoire unique\nadaptée à vos profils psychologiques',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 13, height: 1.5),
                      ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── LISTE THÈMES ──────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _themes.length,
                    itemBuilder: (context, index) {
                      final theme = _themes[index];
                      final isSelected = _themeChoisi == theme['id'];
                      final couleur = theme['couleur'] as Color;
                      final gradient = theme['gradient'] as List<Color>;

                      return GestureDetector(
                        onTap: () => setState(() => _themeChoisi = theme['id']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: gradient,
                                  )
                                : null,
                            color: isSelected ? null : const Color(0xFF111124),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected ? couleur.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.07),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: couleur.withValues(alpha: 0.3), blurRadius: 25, spreadRadius: 1, offset: const Offset(0, 6))]
                                : [],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                // Emoji container
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                    color: isSelected ? couleur.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected ? couleur.withValues(alpha: 0.4) : Colors.white12,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(theme['emoji'] as String,
                                      style: TextStyle(fontSize: isSelected ? 32 : 28)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            theme['titre'] as String,
                                            style: GoogleFonts.spaceGrotesk(
                                              color: isSelected ? couleur : Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: couleur.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: couleur.withValues(alpha: 0.4)),
                                              ),
                                              child: Text('CHOISI',
                                                style: GoogleFonts.spaceGrotesk(color: couleur, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        theme['description'] as String,
                                        style: GoogleFonts.spaceGrotesk(
                                          color: isSelected ? Colors.white60 : Colors.white38,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? couleur : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? couleur : Colors.white24,
                                      width: 2,
                                    ),
                                    boxShadow: isSelected
                                        ? [BoxShadow(color: couleur.withValues(alpha: 0.5), blurRadius: 10)]
                                        : [],
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate(delay: (index * 80).ms)
                        .slideX(begin: 0.2, duration: 400.ms, curve: Curves.easeOut)
                        .fadeIn(duration: 400.ms);
                    },
                  ),
                ),

                // ── BOUTON CRÉER ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: AnimatedOpacity(
                    opacity: _themeChoisi != null ? 1.0 : 0.35,
                    duration: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: _naviguerVersCreation,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: _themeChoisi != null
                              ? LinearGradient(colors: [
                                  (_themes.firstWhere((t) => t['id'] == _themeChoisi, orElse: () => _themes[0])['couleur'] as Color),
                                  (_themes.firstWhere((t) => t['id'] == _themeChoisi, orElse: () => _themes[0])['couleur'] as Color).withValues(alpha: 0.6),
                                ])
                              : const LinearGradient(colors: [Color(0xFF2A2A3E), Color(0xFF1A1A2E)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: _themeChoisi != null
                              ? [BoxShadow(
                                  color: (_themes.firstWhere((t) => t['id'] == _themeChoisi, orElse: () => _themes[0])['couleur'] as Color).withValues(alpha: 0.4),
                                  blurRadius: 25, offset: const Offset(0, 8))]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Créer le salon',
                              style: GoogleFonts.spaceGrotesk(
                                color: _themeChoisi != null ? Colors.white : Colors.white38,
                                fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded,
                              color: _themeChoisi != null ? Colors.white : Colors.white24, size: 22),
                          ],
                        ),
                      ),
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

  Widget _buildGlow(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.0)]),
      ),
    );
  }
}

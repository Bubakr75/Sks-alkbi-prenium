import 'package:flutter/material.dart';
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
      'description': 'Quelqu\'un dans le groupe a trahi la confiance de tous. Mais qui ?',
      'couleur': Colors.red,
    },
    {
      'id': 'vol',
      'titre': 'Vol',
      'emoji': '💰',
      'description': 'Quelque chose de précieux a disparu. L\'un d\'entre vous l\'a pris.',
      'couleur': Colors.amber,
    },
    {
      'id': 'tromperie',
      'titre': 'Tromperie',
      'emoji': '🎭',
      'description': 'Les apparences sont trompeuses. Quelqu\'un joue un double jeu.',
      'couleur': Colors.purple,
    },
    {
      'id': 'aleatoire',
      'titre': 'Aléatoire',
      'emoji': '🎲',
      'description': 'Laisse l\'IA choisir le thème qui correspond le mieux à vos profils.',
      'couleur': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // HEADER
              const Text(
                'SKS : ALIBI',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  letterSpacing: 6,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Choisis\nun thème',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'L\'IA créera une histoire unique\nadaptée aux profils de vos joueurs',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // THEMES
              Expanded(
                child: ListView.builder(
                  itemCount: _themes.length,
                  itemBuilder: (context, index) {
                    final theme = _themes[index];
                    final isSelected = _themeChoisi == theme['id'];
                    final couleur = theme['couleur'] as Color;

                    return GestureDetector(
                      onTap: () => setState(() => _themeChoisi = theme['id']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? couleur.withValues(alpha: 0.15)
                              : const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? couleur : Colors.white12,
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: couleur.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: couleur.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: couleur.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  theme['emoji'] as String,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    theme['titre'] as String,
                                    style: TextStyle(
                                      color: isSelected ? couleur : Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    theme['description'] as String,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? couleur : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? couleur : Colors.white38,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // BOUTON CONTINUER
              AnimatedOpacity(
                opacity: _themeChoisi != null ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _themeChoisi == null
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateRoomScreen(
                                  scenarioId: _themeChoisi!,
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.green.withValues(alpha: 0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: _themeChoisi != null ? 8 : 0,
                      shadowColor: Colors.green.withValues(alpha: 0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Créer le salon',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_forward, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

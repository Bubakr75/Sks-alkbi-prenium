import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'scoring_screen.dart';

const List<Map<String, String>> kQuestions = [
  {'trait': 'calme',           'texte': 'Qui garde son sang-froid même quand tout brûle autour de lui ?',         'emoji': '🧊'},
  {'trait': 'nerveux',         'texte': 'Qui ressent les choses plus intensément que les autres ?',               'emoji': '⚡'},
  {'trait': 'patient',         'texte': 'Qui peut attendre des heures sans perdre patience ?',                    'emoji': '⏳'},
  {'trait': 'zen',             'texte': 'Qui reste détendu en toutes circonstances ?',                            'emoji': '🧘'},
  {'trait': 'flemmard',        'texte': 'Qui trouve toujours le chemin le plus court vers le résultat ?',         'emoji': '😴'},
  {'trait': 'procrastinateur', 'texte': 'Qui fait tout à la dernière minute — et réussit quand même ?',           'emoji': '🕐'},
  {'trait': 'retardataire',    'texte': 'Qui arrive toujours après tout le monde mais remarque ce que les autres ont manqué ?', 'emoji': '🚶'},
  {'trait': 'negociateur',     'texte': 'Qui trouve les mots justes pour que tout le monde soit d\'accord ?',     'emoji': '🤝'},
  {'trait': 'manipulateur',    'texte': 'Qui influence les autres si naturellement qu\'ils ne s\'en rendent pas compte ?', 'emoji': '🎭'},
  {'trait': 'voyeur',          'texte': 'Qui n\'hésite pas à enfreindre les règles si cela fait avancer les choses ?', 'emoji': '👁️'},
  {'trait': 'tete_en_lair',    'texte': 'Qui oublie les détails mais ne perd jamais de vue l\'essentiel ?',       'emoji': '☁️'},
  {'trait': 'mentor',          'texte': 'Qui reste complètement naturel quelles que soient les circonstances ?',  'emoji': '🦉'},
  {'trait': 'egoiste',         'texte': 'Qui pense à se protéger avant de penser au groupe ?',                   'emoji': '🛡️'},
  {'trait': 'lache',           'texte': 'Qui préfère éviter les tensions quand la situation s\'envenime ?',       'emoji': '🐢'},
  {'trait': 'loyal',           'texte': 'Qui reste fidèle même quand il est plus facile de partir ?',             'emoji': '❤️'},
  {'trait': 'cupidon',         'texte': 'Qui est le plus motivé par ce qu\'il y a à gagner ?',                   'emoji': '💘'},
  {'trait': 'heros',           'texte': 'Qui protège les autres avant de se protéger soi-même ?',                'emoji': '🦸'},
];

class QuestionnaireScreen extends StatefulWidget {
  final String code;
  final String playerName;
  final int manche;

  const QuestionnaireScreen({
    super.key,
    required this.code,
    required this.playerName,
    required this.manche,
  });

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen>
    with TickerProviderStateMixin {
  int _currentQuestion = 0;
  final Map<String, String?> _reponses = {};
  bool _isSubmitting = false;
  bool _waitingOthers = false;
  bool _navigated = false;

  List<DocumentSnapshot> _autresJoueurs = [];
  String _myUid = '';
  bool _loadingPlayers = true;

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200), reverseDuration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _chargerJoueurs();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _chargerJoueurs() async {
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final snap = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.code)
        .collection('players')
        .get();
    setState(() {
      _autresJoueurs = snap.docs.where((d) => d.id != _myUid).toList();
      _loadingPlayers = false;
    });
    _fadeController.forward();
  }

  List<Map<String, String>> get _questions10 {
    final all = List<Map<String, String>>.from(kQuestions)..shuffle();
    return all.take(10).toList();
  }

  late final List<Map<String, String>> _questionsChoisies = _questions10;

  void _selectionnerJoueur(String uid) {
    setState(() {
      _reponses[_questionsChoisies[_currentQuestion]['trait']!] = uid;
    });
  }

  void _questionSuivante() {
    if (_currentQuestion < 9) {
      _fadeController.reset();
      setState(() => _currentQuestion++);
      _fadeController.forward();
    } else {
      _soumettreReponses();
    }
  }

  void _questionPrecedente() {
    if (_currentQuestion > 0) {
      _fadeController.reset();
      setState(() => _currentQuestion--);
      _fadeController.forward();
    }
  }

  Future<void> _soumettreReponses() async {
    setState(() => _isSubmitting = true);
    try {
      final mancheKey = 'manche_${widget.manche}';
      final batch = FirebaseFirestore.instance.batch();
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.code);

      _reponses.forEach((trait, targetUid) {
        if (targetUid != null) {
          batch.update(roomRef, {
            'questionnaire.$mancheKey.$_myUid.$trait': targetUid,
          });
        }
      });

      await batch.commit();
      await roomRef.update({'questionnaireReady.$mancheKey.$_myUid': true});

      setState(() { _isSubmitting = false; _waitingOthers = true; });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  // ─── COULEURS PAR TRAIT ───────────────────────────────────────────────────
  Color _traitColor(String trait) {
    const map = {
      'calme': Color(0xFF00BCD4), 'nerveux': Color(0xFFFF5722),
      'patient': Color(0xFF8BC34A), 'zen': Color(0xFF4CAF50),
      'flemmard': Color(0xFF9E9E9E), 'procrastinateur': Color(0xFFFF9800),
      'retardataire': Color(0xFFFFEB3B), 'negociateur': Color(0xFF2196F3),
      'manipulateur': Color(0xFF9C27B0), 'voyeur': Color(0xFF607D8B),
      'tete_en_lair': Color(0xFF03A9F4), 'mentor': Color(0xFFFFD700),
      'egoiste': Color(0xFFF44336), 'lache': Color(0xFF795548),
      'loyal': Color(0xFFE91E63), 'cupidon': Color(0xFFFF4081),
      'heros': Color(0xFFFF6F00),
    };
    return map[trait] ?? Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPlayers) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D1A),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }
    if (_waitingOthers) return _buildWaitingScreen();

    final question = _questionsChoisies[_currentQuestion];
    final traitActuel = question['trait']!;
    final reponseActuelle = _reponses[traitActuel];
    final traitColor = _traitColor(traitActuel);
    final progress = (_currentQuestion + 1) / 10;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // ── HEADER ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentQuestion + 1} / 10',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [traitColor.withValues(alpha: 0.3), traitColor.withValues(alpha: 0.1)]),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: traitColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'MANCHE ${widget.manche}',
                            style: TextStyle(color: traitColor, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Barre de progression animée
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          widthFactor: progress,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [traitColor, traitColor.withValues(alpha: 0.6)]),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [BoxShadow(color: traitColor.withValues(alpha: 0.5), blurRadius: 8)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── CARTE QUESTION ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        traitColor.withValues(alpha: 0.15),
                        const Color(0xFF1A1A2E),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: traitColor.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: traitColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        question['emoji'] ?? '❓',
                        style: const TextStyle(fontSize: 52),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        question['texte']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // ── LABEL ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward_rounded, color: traitColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Désigne le joueur qui correspond le mieux',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // ── LISTE JOUEURS ─────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _autresJoueurs.length,
                  itemBuilder: (context, index) {
                    final p = _autresJoueurs[index];
                    final data = p.data() as Map<String, dynamic>;
                    final uid = p.id;
                    final name = data['name'] as String? ?? '???';
                    final isSelected = reponseActuelle == uid;
                    final initiale = name[0].toUpperCase();

                    return GestureDetector(
                      onTap: () => _selectionnerJoueur(uid),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [traitColor.withValues(alpha: 0.25), traitColor.withValues(alpha: 0.05)])
                              : null,
                          color: isSelected ? null : const Color(0xFF1E1E30),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? traitColor : Colors.white12,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: traitColor.withValues(alpha: 0.3), blurRadius: 12)]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [traitColor, traitColor.withValues(alpha: 0.6)]
                                      : [Colors.white24, Colors.white10],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  initiale,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 17,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: isSelected
                                  ? Icon(Icons.check_circle_rounded, color: traitColor, size: 28, key: const ValueKey('check'))
                                  : Icon(Icons.radio_button_unchecked, color: Colors.white24, size: 26, key: const ValueKey('empty')),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── BOUTONS NAVIGATION ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    if (_currentQuestion > 0) ...[
                      GestureDetector(
                        onTap: _questionPrecedente,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: GestureDetector(
                        onTap: (reponseActuelle == null || _isSubmitting) ? null : _questionSuivante,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: reponseActuelle != null
                                ? LinearGradient(colors: [traitColor, traitColor.withValues(alpha: 0.7)])
                                : null,
                            color: reponseActuelle == null ? Colors.white12 : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: reponseActuelle != null
                                ? [BoxShadow(color: traitColor.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))]
                                : [],
                          ),
                          child: Center(
                            child: _isSubmitting
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text(
                                    _currentQuestion < 9 ? 'Suivant →' : '✅ Envoyer mes réponses',
                                    style: TextStyle(
                                      color: reponseActuelle != null ? Colors.white : Colors.white38,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
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
        ),
      ),
    );
  }

  // ── ÉCRAN ATTENTE ──────────────────────────────────────────────────────────
  Widget _buildWaitingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('rooms').doc(widget.code).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
            final data = snap.data!.data() as Map<String, dynamic>?;
            final mancheKey = 'manche_${widget.manche}';
            final ready = (data?['questionnaireReady']?[mancheKey] ?? {}) as Map<String, dynamic>;
            final totalJoueurs = _autresJoueurs.length + 1;
            final readyCount = ready.length;

            if (readyCount >= totalJoueurs && !_navigated) {
              _navigated = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScoringScreen(
                        code: widget.code,
                        playerName: widget.playerName,
                        manche: widget.manche,
                      ),
                    ),
                  );
                }
              });
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF1B5E20)]),
                          boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 30)],
                        ),
                        child: const Center(child: Text('✅', style: TextStyle(fontSize: 48))),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Réponses enregistrées !',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'En attente des autres joueurs...',
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Barre de progression joueurs
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Joueurs prêts', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              Text(
                                '$readyCount / $totalJoueurs',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: readyCount / totalJoueurs,
                              backgroundColor: Colors.white12,
                              color: Colors.green,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

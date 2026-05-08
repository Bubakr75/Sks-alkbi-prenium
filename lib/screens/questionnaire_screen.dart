import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'scoring_screen.dart';

const List<Map<String, String>> kQuestions = [
  {'trait': 'manipulateur', 'texte': 'Qui serait capable de te mentir en te regardant droit dans les yeux sans ciller ?',           'emoji': '🎭'},
  {'trait': 'lache',        'texte': 'Qui disparaîtrait en silence plutôt que d\'affronter une situation difficile ?',               'emoji': '🐢'},
  {'trait': 'egoiste',      'texte': 'Qui penserait à sauver sa peau en premier si tout s\'effondrait ?',                            'emoji': '🛡️'},
  {'trait': 'nerveux',      'texte': 'Qui craquerait en premier sous la pression si on le poussait à bout ?',                        'emoji': '⚡'},
  {'trait': 'voyeur',       'texte': 'Qui irait fouiller là où il ne devrait pas pour obtenir ce qu\'il veut ?',                     'emoji': '👁️'},
  {'trait': 'negociateur',  'texte': 'Qui trouverait un arrangement même dans la situation la plus désespérée ?',                    'emoji': '🤝'},
  {'trait': 'calme',        'texte': 'Qui resterait de marbre même si on l\'accusait à tort devant tout le monde ?',                 'emoji': '🧊'},
  {'trait': 'heros',        'texte': 'Qui prendrait un coup pour protéger quelqu\'un d\'autre, même un inconnu ?',                   'emoji': '🦸'},
  {'trait': 'loyal',        'texte': 'Qui serait incapable de trahir quelqu\'un même si ça lui coûtait cher ?',                     'emoji': '❤️'},
  {'trait': 'mentor',       'texte': 'Qui saurait exactement quoi dire pour que tout le monde le suive sans poser de questions ?',   'emoji': '🦉'},
  {'trait': 'flemmard',     'texte': 'Qui trouverait un moyen de faire faire le travail aux autres tout en prenant le mérite ?',     'emoji': '😴'},
  {'trait': 'tete_en_lair', 'texte': 'Qui oublierait un détail crucial au pire moment possible ?',                                  'emoji': '☁️'},
  {'trait': 'cupidon',      'texte': 'Qui serait prêt à tout pour obtenir ce qu\'il convoite, même à en perdre ses valeurs ?',      'emoji': '💘'},
  {'trait': 'procrastinateur','texte':'Qui attendrait la dernière seconde pour agir, quitte à tout faire foirer ?',                  'emoji': '🕐'},
  {'trait': 'retardataire', 'texte': 'Qui arriverait après la bataille mais prétendrait avoir tout vu ?',                           'emoji': '🚶'},
  {'trait': 'patient',      'texte': 'Qui serait capable d\'attendre des mois pour se venger au bon moment ?',                      'emoji': '⏳'},
  {'trait': 'zen',          'texte': 'Qui sourirait calmement même en sachant que tout part en vrille autour de lui ?',              'emoji': '🧘'},
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
  final Map<String, String> _reponses = {};
  bool _isSubmitting = false;
  bool _waitingOthers = false;
  bool _navigated = false;
  bool _isTransitioning = false;

  List<DocumentSnapshot> _autresJoueurs = [];
  String _myUid = '';
  bool _loadingPlayers = true;

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _slideAnim = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _chargerJoueurs();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
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
    _slideController.forward();
  }

  List<Map<String, String>> get _questions10 {
    final all = List<Map<String, String>>.from(kQuestions)..shuffle();
    return all.take(10).toList();
  }

  late final List<Map<String, String>> _questionsChoisies = _questions10;

  // ── AUTO-AVANCE dès la sélection ─────────────────────────────────────────
  Future<void> _selectionnerEtAvancer(String uid) async {
    if (_isTransitioning) return;
    final trait = _questionsChoisies[_currentQuestion]['trait']!;

    setState(() {
      _reponses[trait] = uid;
      _isTransitioning = true;
    });

    // Petit délai visuel pour voir la sélection
    await Future.delayed(const Duration(milliseconds: 450));

    if (_currentQuestion < 9) {
      // Animation de transition
      await _fadeController.reverse();
      setState(() {
        _currentQuestion++;
        _isTransitioning = false;
      });
      _slideController.reset();
      _fadeController.reset();
      _slideController.forward();
      _fadeController.forward();
    } else {
      setState(() => _isTransitioning = false);
      _soumettreReponses();
    }
  }

  void _questionPrecedente() {
    if (_currentQuestion > 0 && !_isTransitioning) {
      _fadeController.reverse().then((_) {
        setState(() => _currentQuestion--);
        _fadeController.forward();
        _slideController.reset();
        _slideController.forward();
      });
    }
  }

  Future<void> _soumettreReponses() async {
    setState(() => _isSubmitting = true);
    try {
      final mancheKey = 'manche_${widget.manche}';
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.code);

      // Un seul update groupé pour la cohérence
      final Map<String, dynamic> updates = {};
      _reponses.forEach((trait, targetUid) {
        updates['questionnaire.$mancheKey.$_myUid.$trait'] = targetUid;
      });
      updates['questionnaireReady.$mancheKey.$_myUid'] = true;

      await roomRef.update(updates);

      setState(() { _isSubmitting = false; _waitingOthers = true; });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red.shade800),
        );
      }
    }
  }

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
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentQuestion > 0)
                        GestureDetector(
                          onTap: _questionPrecedente,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white54, size: 20),
                          ),
                        )
                      else
                        const SizedBox(width: 36),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentQuestion + 1} / 10',
                          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: traitColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: traitColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'M${widget.manche}',
                          style: TextStyle(color: traitColor, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Barre de progression par points
                  Row(
                    children: List.generate(10, (i) => Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _currentQuestion ? traitColor : Colors.white10,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: i == _currentQuestion
                              ? [BoxShadow(color: traitColor.withValues(alpha: 0.6), blurRadius: 6)]
                              : [],
                        ),
                      ),
                    )),
                  ),
                ],
              ),
            ),

            // ── CARTE QUESTION ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [traitColor.withValues(alpha: 0.18), const Color(0xFF12122A)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: traitColor.withValues(alpha: 0.5), width: 1.5),
                      boxShadow: [BoxShadow(color: traitColor.withValues(alpha: 0.25), blurRadius: 25, spreadRadius: 2)],
                    ),
                    child: Column(
                      children: [
                        Text(question['emoji'] ?? '❓', style: const TextStyle(fontSize: 54)),
                        const SizedBox(height: 18),
                        Text(
                          question['texte']!,
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700, height: 1.55),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── INSTRUCTION ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: traitColor.withValues(alpha: 0.7), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Touche un joueur — la sélection est immédiate',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),

            // ── LISTE JOUEURS ────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _autresJoueurs.length,
                itemBuilder: (context, index) {
                  final p = _autresJoueurs[index];
                  final data = Map<String, dynamic>.from(p.data() as Map? ?? {});
                  final uid = p.id;
                  final name = data['name'] as String? ?? '???';
                  final isSelected = reponseActuelle == uid;
                  final isDisabled = _isTransitioning && !isSelected;

                  return GestureDetector(
                    onTap: isDisabled ? null : () => _selectionnerEtAvancer(uid),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(colors: [traitColor.withValues(alpha: 0.3), traitColor.withValues(alpha: 0.08)])
                            : null,
                        color: isSelected ? null : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? traitColor : Colors.white12,
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: traitColor.withValues(alpha: 0.4), blurRadius: 16)]
                            : [],
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isSelected
                                    ? [traitColor, traitColor.withValues(alpha: 0.6)]
                                    : [Colors.white24, Colors.white10],
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: traitColor.withValues(alpha: 0.5), blurRadius: 12)]
                                  : [],
                            ),
                            child: Center(
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 26)
                                  : Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 18,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                                if (isSelected)
                                  Text('Sélectionné ✓', style: TextStyle(color: traitColor, fontSize: 12)),
                              ],
                            ),
                          ),
                          if (_isTransitioning && isSelected)
                            SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: traitColor),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── INDICATEUR SOUMISSION ─────────────────────────────────────────
            if (_isSubmitting)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
                    const SizedBox(width: 12),
                    const Text('Envoi des réponses...', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              )
            else
              const SizedBox(height: 16),
          ],
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
            final data = Map<String, dynamic>.from(snap.data!.data() as Map? ?? {});
            final mancheKey = 'manche_${widget.manche}';
            final ready = Map<String, dynamic>.from((data['questionnaireReady']?[mancheKey] ?? {}) as Map? ?? {});
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
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF1B5E20)]),
                          boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 30)],
                        ),
                        child: const Center(child: Text('✅', style: TextStyle(fontSize: 48))),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('Réponses enregistrées !', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('En attente des autres joueurs...', style: TextStyle(color: Colors.white54, fontSize: 15)),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Joueurs prêts', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              Text('$readyCount / $totalJoueurs', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: totalJoueurs > 0 ? readyCount / totalJoueurs : 0,
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




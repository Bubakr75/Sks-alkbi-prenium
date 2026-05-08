import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'scoring_screen.dart';

const List<Map<String, String>> kQuestions = [
  {'trait': 'calme',           'texte': 'Qui garde son sang-froid même quand tout brûle autour de lui ?'},
  {'trait': 'nerveux',         'texte': 'Qui ressent les choses plus intensément que les autres ?'},
  {'trait': 'patient',         'texte': 'Qui peut attendre des heures sans perdre patience ?'},
  {'trait': 'zen',             'texte': 'Qui reste détendu en toutes circonstances ?'},
  {'trait': 'flemmard',        'texte': 'Qui trouve toujours le chemin le plus court vers le résultat ?'},
  {'trait': 'procrastinateur', 'texte': 'Qui fait tout à la dernière minute — et réussit quand même ?'},
  {'trait': 'retardataire',    'texte': 'Qui arrive toujours après tout le monde, mais remarque ce que les autres ont manqué ?'},
  {'trait': 'negociateur',     'texte': 'Qui trouve les mots justes pour que tout le monde soit d\'accord ?'},
  {'trait': 'manipulateur',    'texte': 'Qui parvient à influencer les autres si naturellement qu\'ils ne s\'en rendent même pas compte ?'},
  {'trait': 'voyeur',          'texte': 'Qui n\'hésite pas à enfreindre les règles si cela permet de faire avancer les choses ?'},
  {'trait': 'tete_en_lair',    'texte': 'Qui oublie les détails mais ne perd jamais de vue l\'essentiel ?'},
  {'trait': 'mentor',          'texte': 'Qui reste complètement naturel quelles que soient les circonstances ?'},
  {'trait': 'egoiste',         'texte': 'Qui pense à se protéger avant de penser au groupe ?'},
  {'trait': 'lache',           'texte': 'Qui préfère éviter les tensions quand la situation s\'envenime ?'},
  {'trait': 'loyal',           'texte': 'Qui reste fidèle même quand il est plus facile de partir ?'},
  {'trait': 'cupidon',         'texte': 'Qui est le plus motivé par ce qu\'il y a à gagner ?'},
  {'trait': 'heros',           'texte': 'Qui protège les autres avant de se protéger soi-même ?'},
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

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentQuestion = 0;
  final Map<String, String?> _reponses = {};
  bool _isSubmitting = false;
  bool _waitingOthers = false;
  bool _navigated = false;

  List<DocumentSnapshot> _autrесJoueurs = [];
  String _myUid = '';
  bool _loadingPlayers = true;

  @override
  void initState() {
    super.initState();
    _chargerJoueurs();
  }

  Future<void> _chargerJoueurs() async {
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final snap = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.code)
        .collection('players')
        .get();
    setState(() {
      _autrесJoueurs = snap.docs.where((d) => d.id != _myUid).toList();
      _loadingPlayers = false;
    });
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
      setState(() => _currentQuestion++);
    } else {
      _soumettreReponses();
    }
  }

  void _questionPrecedente() {
    if (_currentQuestion > 0) {
      setState(() => _currentQuestion--);
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

      await roomRef.update({
        'questionnaireReady.$mancheKey.$_myUid': true,
      });

      setState(() {
        _isSubmitting = false;
        _waitingOthers = true;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPlayers) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (_waitingOthers) {
      return _buildWaitingScreen();
    }

    final question = _questionsChoisies[_currentQuestion];
    final traitActuel = question['trait']!;
    final reponseActuelle = _reponses[traitActuel];

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestion + 1} / 10',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  Text(
                    'Manche ${widget.manche}',
                    style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentQuestion + 1) / 10,
                  backgroundColor: Colors.white12,
                  color: Colors.green,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
                ),
                child: Text(
                  question['texte']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Désigne un joueur :',
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _autrесJoueurs.length,
                  itemBuilder: (context, index) {
                    final p = _autrесJoueurs[index];
                    final data = p.data() as Map<String, dynamic>;
                    final uid = p.id;
                    final name = data['name'] as String? ?? '???';
                    final isSelected = reponseActuelle == uid;

                    return GestureDetector(
                      onTap: () => _selectionnerJoueur(uid),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green.withOpacity(0.25)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? Colors.green : Colors.white24,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isSelected ? Colors.green : Colors.white24,
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              name,
                              style: TextStyle(
                                color: isSelected ? Colors.green : Colors.white,
                                fontSize: 18,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Colors.green, size: 28),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_currentQuestion > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _questionPrecedente,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('← Précédent'),
                      ),
                    ),
                  if (_currentQuestion > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (reponseActuelle == null || _isSubmitting)
                          ? null
                          : _questionSuivante,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _currentQuestion < 9 ? 'Suivant →' : '✅ Terminer',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.code)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final data = snap.data!.data() as Map<String, dynamic>?;
            final mancheKey = 'manche_${widget.manche}';
            final ready = (data?['questionnaireReady']?[mancheKey] ?? {}) as Map<String, dynamic>;
            final totalJoueurs = _autrесJoueurs.length + 1;
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
                    const Text('✅', style: TextStyle(fontSize: 70)),
                    const SizedBox(height: 24),
                    const Text(
                      'Tes réponses sont enregistrées !',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'En attente des autres joueurs...\n$readyCount / $totalJoueurs ont répondu',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(color: Colors.green),
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

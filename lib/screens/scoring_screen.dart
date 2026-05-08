import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ia_generation_screen.dart';

class ScoringScreen extends StatefulWidget {
  final String code;
  final String playerName;
  final int manche;

  const ScoringScreen({
    super.key,
    required this.code,
    required this.playerName,
    required this.manche,
  });

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _navigated = false;
  Map<String, Map<String, double>> _profilsJoueurs = {};
  Map<String, String> _nomsJoueurs = {};
  String _myUid = '';

  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _headerAnim;

  static const Map<String, String> _traitEmojis = {
    'calme': '🧊', 'nerveux': '⚡', 'patient': '⏳', 'zen': '🧘',
    'flemmard': '😴', 'procrastinateur': '🕐', 'retardataire': '🚶',
    'negociateur': '🤝', 'manipulateur': '🎭', 'voyeur': '👁️',
    'tete_en_lair': '☁️', 'mentor': '🦉', 'egoiste': '🛡️',
    'lache': '🐢', 'loyal': '❤️', 'cupidon': '💘', 'heros': '🦸',
  };

  static const Map<String, Color> _traitColors = {
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

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _listController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _headerAnim = CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _calculerScores();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _calculerScores() async {
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.code);
    final roomSnap = await roomRef.get();
    final roomData = roomSnap.data() ?? {};

    final playersSnap = await roomRef.collection('players').get();
    final joueurs = playersSnap.docs;
    final totalJoueurs = joueurs.length;

    final Map<String, String> noms = {};
    for (final j in joueurs) {
      noms[j.id] = (j.data()['name'] as String?) ?? '???';
    }

    final questionnaire = Map<String, dynamic>.from(roomData['questionnaire'] as Map? ?? {});
    final Map<String, Map<String, int>> compteurs = {for (final j in joueurs) j.id: {}};

    for (int m = 1; m <= widget.manche; m++) {
      final mancheData = Map<String, dynamic>.from(questionnaire['manche_$m'] as Map? ?? {});
      mancheData.forEach((voterUid, reponses) {
        Map<String, dynamic>.from(reponses as Map? ?? {}).forEach((trait, targetUid) {
          if (compteurs.containsKey(targetUid as String)) {
            compteurs[targetUid]![trait] = (compteurs[targetUid]![trait] ?? 0) + 1;
          }
        });
      });
    }

    final int maxVotesPossibles = (totalJoueurs - 1) * widget.manche;
    final Map<String, Map<String, double>> profils = {};
    for (final j in joueurs) {
      final Map<String, double> traitPct = {};
      compteurs[j.id]!.forEach((trait, voteCount) {
        traitPct[trait] = maxVotesPossibles > 0 ? (voteCount / maxVotesPossibles) * 100 : 0.0;
      });
      profils[j.id] = traitPct;
    }

    final batch = FirebaseFirestore.instance.batch();
    profils.forEach((uid, traits) {
      batch.update(roomRef, {'profils.manche_${widget.manche}.$uid': traits});
    });
    await batch.commit();

    setState(() {
      _profilsJoueurs = profils;
      _nomsJoueurs = noms;
      _isLoading = false;
    });
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () => _listController.forward());
  }

  List<MapEntry<String, double>> _getTopTraits(String uid) {
    final traits = _profilsJoueurs[uid] ?? {};
    return (traits.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5).toList();
  }

  List<MapEntry<String, double>> _getBottomTraits(String uid) {
    final traits = _profilsJoueurs[uid] ?? {};
    final sorted = traits.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    if (widget.manche == 2) return sorted.take(2).toList();
    if (widget.manche >= 3) return sorted.take(4).toList();
    return [];
  }

  Color _couleurTrait(String trait, double pct) {
    return _traitColors[trait] ?? (pct >= 60 ? Colors.redAccent : pct >= 35 ? Colors.amber : Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFF7B2FBE), Color(0xFF3A1078)]),
                  boxShadow: [BoxShadow(color: const Color(0xFF7B2FBE).withValues(alpha: 0.4), blurRadius: 30)],
                ),
                child: const Center(child: Text('🧠', style: TextStyle(fontSize: 38))),
              ),
              const SizedBox(height: 28),
              const Text('Analyse des profils...', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Calcul des traits psychologiques', style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Color(0xFF7B2FBE)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────────
            FadeTransition(
              opacity: _headerAnim,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF7B2FBE), Color(0xFF3A1078)]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text('🧠', style: TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ANALYSE PSYCHOLOGIQUE', style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2)),
                            Text('Profils — Manche ${widget.manche}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B2FBE).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            '${_nomsJoueurs.length} joueurs',
                            style: const TextStyle(color: Color(0xFFCE93D8), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          const Color(0xFF7B2FBE).withValues(alpha: 0.5),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── LISTE JOUEURS ────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _nomsJoueurs.length,
                itemBuilder: (context, index) {
                  final uid = _nomsJoueurs.keys.elementAt(index);
                  final nom = _nomsJoueurs[uid]!;
                  final topTraits = _getTopTraits(uid);
                  final bottomTraits = _getBottomTraits(uid);
                  final isMe = uid == _myUid;

                  return AnimatedBuilder(
                    animation: _listController,
                    builder: (context, child) {
                      final delay = index * 0.15;
                      final anim = Curves.easeOut.transform(
                        (((_listController.value - delay) / (1 - delay)).clamp(0.0, 1.0)),
                      );
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - anim)),
                        child: Opacity(opacity: anim, child: child),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: isMe
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1A2744), Color(0xFF0D0D1A)],
                              )
                            : null,
                        color: isMe ? null : const Color(0xFF141428),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isMe ? const Color(0xFF7B2FBE).withValues(alpha: 0.6) : Colors.white12,
                          width: isMe ? 1.5 : 1,
                        ),
                        boxShadow: isMe
                            ? [BoxShadow(color: const Color(0xFF7B2FBE).withValues(alpha: 0.2), blurRadius: 20)]
                            : [],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nom joueur
                            Row(
                              children: [
                                Container(
                                  width: 46, height: 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: isMe
                                          ? [const Color(0xFF7B2FBE), const Color(0xFF3A1078)]
                                          : [Colors.white24, Colors.white10],
                                    ),
                                    boxShadow: isMe
                                        ? [BoxShadow(color: const Color(0xFF7B2FBE).withValues(alpha: 0.4), blurRadius: 12)]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      nom[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isMe ? '$nom (toi)' : nom,
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${topTraits.length} traits identifiés',
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                  ],
                                ),
                                if (isMe) ...[
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7B2FBE).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF7B2FBE).withValues(alpha: 0.4)),
                                    ),
                                    child: const Text('TOI', style: TextStyle(color: Color(0xFFCE93D8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                  ),
                                ],
                              ],
                            ),

                            if (topTraits.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Text('Aucun trait désigné', style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)),
                              )
                            else ...[
                              const SizedBox(height: 18),
                              const Text('TRAITS DOMINANTS', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              ...topTraits.asMap().entries.map((entry) {
                                final i = entry.key;
                                final e = entry.value;
                                final color = _couleurTrait(e.key, e.value);
                                final emoji = _traitEmojis[e.key] ?? '•';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      // Rang
                                      Container(
                                        width: 22, height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: i == 0 ? color.withValues(alpha: 0.3) : Colors.white10,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${i + 1}',
                                            style: TextStyle(
                                              color: i == 0 ? color : Colors.white38,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(emoji, style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          e.key.replaceAll('_', ' '),
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Container(
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Colors.white10,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            FractionallySizedBox(
                                              widthFactor: e.value / 100,
                                              child: Container(
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.5)]),
                                                  borderRadius: BorderRadius.circular(4),
                                                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${e.value.toStringAsFixed(0)}%',
                                        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],

                            // Traits faibles (visible uniquement pour soi)
                            if (bottomTraits.isNotEmpty && isMe) ...[
                              const SizedBox(height: 14),
                              Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    Colors.transparent,
                                    Colors.white24,
                                    Colors.transparent,
                                  ]),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Icon(Icons.lock_outline, color: Colors.white38, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.manche >= 3 ? 'TES 4 TRAITS LES PLUS BAS' : 'TES 2 TRAITS LES PLUS BAS',
                                    style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('(toi seul)', style: TextStyle(color: Colors.white24, fontSize: 10)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: bottomTraits.map((e) {
                                  final emoji = _traitEmojis[e.key] ?? '•';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Text(
                                      '$emoji ${e.key.replaceAll("_", " ")} · ${e.value.toStringAsFixed(0)}%',
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── BOUTON BAS ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF0D0D1A).withValues(alpha: 0), const Color(0xFF0D0D1A)],
                ),
              ),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('rooms').doc(widget.code).snapshots(),
                builder: (context, snap) {
                  final data = Map<String, dynamic>.from(snap.data?.data() as Map? ?? {});
                  final isHost = data['hostUid'] == _myUid;

                  if (!isHost) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)),
                          SizedBox(width: 12),
                          Text("En attente que l'hôte lance l'IA...", style: TextStyle(color: Colors.white54, fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  return GestureDetector(
                    onTap: _navigated ? null : () {
                      setState(() => _navigated = true);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IaGenerationScreen(
                            code: widget.code,
                            playerName: widget.playerName,
                            manche: widget.manche,
                            profils: _profilsJoueurs,
                            noms: _nomsJoueurs,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B2FBE), Color(0xFF3A1078)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF7B2FBE).withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🤖', style: TextStyle(fontSize: 22)),
                          SizedBox(width: 12),
                          Text(
                            "Générer l'histoire avec l'IA",
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


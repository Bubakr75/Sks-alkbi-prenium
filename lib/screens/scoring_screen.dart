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

class _ScoringScreenState extends State<ScoringScreen> {
  bool _isLoading = true;
  bool _navigated = false;
  Map<String, Map<String, double>> _profilsJoueurs = {};
  Map<String, String> _nomsJoueurs = {};
  String _myUid = '';

  @override
  void initState() {
    super.initState();
    _calculerScores();
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
      final d = j.data();
      noms[j.id] = d['name'] as String? ?? '???';
    }

    // Cumul questionnaires toutes manches jusqu'a maintenant
    final questionnaire = (roomData['questionnaire'] ?? {}) as Map<String, dynamic>;
    final Map<String, Map<String, int>> compteurs = {};
    for (final j in joueurs) {
      compteurs[j.id] = {};
    }

    for (int m = 1; m <= widget.manche; m++) {
      final mancheKey = 'manche_$m';
      final mancheData = (questionnaire[mancheKey] ?? {}) as Map<String, dynamic>;
      mancheData.forEach((voterUid, reponses) {
        final reponsesMap = reponses as Map<String, dynamic>;
        reponsesMap.forEach((trait, targetUid) {
          if (compteurs.containsKey(targetUid as String)) {
            compteurs[targetUid]![trait] = (compteurs[targetUid]![trait] ?? 0) + 1;
          }
        });
      });
    }

    // Convertir en pourcentages
    final Map<String, Map<String, double>> profils = {};
    final int maxVotesPossibles = (totalJoueurs - 1) * widget.manche;

    for (final j in joueurs) {
      final Map<String, double> traitPct = {};
      compteurs[j.id]!.forEach((trait, count) {
        traitPct[trait] = maxVotesPossibles > 0
            ? (count / maxVotesPossibles) * 100
            : 0.0;
      });
      profils[j.id] = traitPct;
    }

    // Sauvegarder les profils dans Firestore
    final mancheKey = 'manche_${widget.manche}';
    final batch = FirebaseFirestore.instance.batch();
    profils.forEach((uid, traits) {
      batch.update(roomRef, {
        'profils.$mancheKey.$uid': traits,
      });
    });
    await batch.commit();

    setState(() {
      _profilsJoueurs = profils;
      _nomsJoueurs = noms;
      _isLoading = false;
    });
  }

  List<MapEntry<String, double>> _getTopTraits(String uid) {
    final traits = _profilsJoueurs[uid] ?? {};
    final sorted = traits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  List<MapEntry<String, double>> _getBottomTraits(String uid) {
    final traits = _profilsJoueurs[uid] ?? {};
    final sorted = traits.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (widget.manche == 2) return sorted.take(2).toList();
    if (widget.manche >= 3) return sorted.take(4).toList();
    return [];
  }

  Color _couleurTrait(double pct) {
    if (pct >= 60) return Colors.redAccent;
    if (pct >= 35) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 24),
              Text(
                'Calcul des profils en cours...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'Profils — Manche ${widget.manche}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _nomsJoueurs.length,
              itemBuilder: (context, index) {
                final uid = _nomsJoueurs.keys.elementAt(index);
                final nom = _nomsJoueurs[uid]!;
                final topTraits = _getTopTraits(uid);
                final bottomTraits = _getBottomTraits(uid);
                final isMe = uid == _myUid;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.green.withOpacity(0.1)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMe ? Colors.green : Colors.white24,
                      width: isMe ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isMe ? Colors.green : Colors.white24,
                              child: Text(
                                nom[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isMe ? '$nom (toi)' : nom,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (topTraits.isEmpty)
                          const Text(
                            'Aucun trait désigné pour ce joueur.',
                            style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                          )
                        else ...[
                          const Text(
                            'TRAITS DOMINANTS',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...topTraits.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    e.key.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(
                                      color: _couleurTrait(e.value),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: e.value / 100,
                                      backgroundColor: Colors.white12,
                                      color: _couleurTrait(e.value),
                                      minHeight: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${e.value.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: _couleurTrait(e.value),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                        if (bottomTraits.isNotEmpty && isMe) ...[
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 8),
                          Text(
                            widget.manche == 2
                                ? 'TES 2 TRAITS LES PLUS BAS (visible uniquement par toi)'
                                : 'TES 4 TRAITS LES PLUS BAS (visible uniquement par toi)',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: bottomTraits.map((e) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                '${e.key.replaceAll("_", " ")} ${e.value.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.code)
                  .snapshots(),
              builder: (context, snap) {
                final data = snap.data?.data() as Map<String, dynamic>?;
                final isHost = data?['hostUid'] == _myUid;

                if (!isHost) {
                  return const Text(
                    'En attente que l\'hôte lance la génération de l\'histoire...',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _navigated ? null : () {
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '🤖 Générer l\'histoire avec l\'IA',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FinaleScreen extends StatefulWidget {
  final String code;
  const FinaleScreen({super.key, required this.code});

  @override
  State<FinaleScreen> createState() => _FinaleScreenState();
}

class _FinaleScreenState extends State<FinaleScreen> {
  bool _revealed = false;

  int _calculerPointsJoueur({
    required String uid,
    required List<dynamic> coupablesParManche,
    required Map<String, dynamic> votesParManche,
    required Map<String, dynamic> votesPredictifs,
    required Map<String, dynamic> defisResultats,
    required int totalManches,
  }) {
    int total = 0;

    // Points votes finaux
    for (int i = 0; i < coupablesParManche.length; i++) {
      final mancheKey = 'manche_${i + 1}';
      final votesM = (votesParManche[mancheKey] ?? {}) as Map<String, dynamic>;
      final coupableUid = coupablesParManche[i];
      if (votesM[uid] == coupableUid) total += 3;
    }

    // Points vote prédictif (+2 si correct)
    for (int i = 0; i < coupablesParManche.length; i++) {
      final mancheKey = 'manche_${i + 1}';
      final predM = (votesPredictifs[mancheKey] ?? {}) as Map<String, dynamic>;
      final coupableUid = coupablesParManche[i];
      if (predM[uid] == coupableUid) total += 2;
    }

    // Points défis secrets
    for (int i = 1; i <= totalManches; i++) {
      final mancheKey = 'manche_$i';
      final defisM = (defisResultats[mancheKey] ?? {}) as Map<String, dynamic>;
      if (defisM.containsKey(uid)) {
        final resultat = defisM[uid] as Map<String, dynamic>;
        total += (resultat['points'] as int? ?? 0);
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a1f),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.code)
              .snapshots(),
          builder: (context, roomSnap) {
            if (!roomSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final roomData = roomSnap.data!.data() as Map<String, dynamic>?;
            if (roomData == null) {
              return const Center(
                child: Text('Salon introuvable', style: TextStyle(color: Colors.white)),
              );
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.code)
                  .collection('players')
                  .snapshots(),
              builder: (context, joueursSnap) {
                if (!joueursSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final joueurs = joueursSnap.data!.docs;
                final votesParManche = (roomData['votesParManche'] ?? {}) as Map<String, dynamic>;
                final votesPredictifs = (roomData['votesPredictifs'] ?? {}) as Map<String, dynamic>;
                final defisResultats = (roomData['defisResultats'] ?? {}) as Map<String, dynamic>;
                final coupablesParManche = (roomData['coupablesParManche'] ?? []) as List<dynamic>;
                final totalManches = roomData['totalManches'] as int? ?? 3;
                final myUid = FirebaseAuth.instance.currentUser?.uid;

                final nomsParUid = <String, String>{};
                for (var j in joueurs) {
                  final d = j.data() as Map<String, dynamic>;
                  nomsParUid[j.id] = d['name'] as String? ?? 'Joueur';
                }

                // Calcul scores
                final scores = <String, int>{};
                for (var j in joueurs) {
                  scores[j.id] = _calculerPointsJoueur(
                    uid: j.id,
                    coupablesParManche: coupablesParManche,
                    votesParManche: votesParManche,
                    votesPredictifs: votesPredictifs,
                    defisResultats: defisResultats,
                    totalManches: totalManches,
                  );
                }

                // Bonus +5 au leader
                final maxScore = scores.values.isEmpty
                    ? 0
                    : scores.values.reduce((a, b) => a > b ? a : b);
                final scoresFinaux = Map<String, int>.from(scores);
                if (maxScore > 0) {
                  scoresFinaux.forEach((uid, score) {
                    if (score == maxScore) scoresFinaux[uid] = score + 5;
                  });
                }

                final classement = joueurs.toList()
                  ..sort((a, b) =>
                      (scoresFinaux[b.id] ?? 0).compareTo(scoresFinaux[a.id] ?? 0));

                final champion = classement.isNotEmpty ? classement.first : null;
                final championNom = nomsParUid[champion?.id] ?? 'Personne';

                // Détail points par joueur
                Map<String, Map<String, int>> detailPoints = {};
                for (var j in joueurs) {
                  int ptVotes = 0, ptPredictif = 0, ptDefis = 0;
                  for (int i = 0; i < coupablesParManche.length; i++) {
                    final mk = 'manche_${i + 1}';
                    final vm = (votesParManche[mk] ?? {}) as Map<String, dynamic>;
                    if (vm[j.id] == coupablesParManche[i]) ptVotes += 3;
                    final pm = (votesPredictifs[mk] ?? {}) as Map<String, dynamic>;
                    if (pm[j.id] == coupablesParManche[i]) ptPredictif += 2;
                  }
                  for (int i = 1; i <= totalManches; i++) {
                    final mk = 'manche_$i';
                    final dm = (defisResultats[mk] ?? {}) as Map<String, dynamic>;
                    if (dm.containsKey(j.id)) {
                      ptDefis += (dm[j.id]['points'] as int? ?? 0);
                    }
                  }
                  detailPoints[j.id] = {
                    'votes': ptVotes,
                    'predictif': ptPredictif,
                    'defis': ptDefis,
                  };
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // HEADER
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFF6B00)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            Text('🏆', style: TextStyle(fontSize: 60)),
                            SizedBox(height: 8),
                            Text(
                              'GRANDE FINALE',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Révélation des coupables & scores finaux',
                              style: TextStyle(color: Colors.black87, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // BOUTON RÉVÉLER
                      if (!_revealed)
                        ElevatedButton(
                          onPressed: () { SoundService().onFinale(); setState(() => _revealed = true); },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 16),
                          ),
                          child: const Text(
                            '🔓 RÉVÉLER LES COUPABLES',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),

                      if (_revealed) ...[
                        // COUPABLES PAR MANCHE
                        const Text(
                          'LES COUPABLES',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(coupablesParManche.length, (i) {
                          final coupableUid = coupablesParManche[i] as String;
                          final nomCoupable = nomsParUid[coupableUid] ?? 'Inconnu';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.redAccent, width: 2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text('${i + 1}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Manche ${i + 1}',
                                          style: const TextStyle(
                                              color: Colors.white70, fontSize: 12)),
                                      Text('🔪 $nomCoupable',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 30),

                        // CLASSEMENT FINAL
                        const Text(
                          'CLASSEMENT FINAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...classement.asMap().entries.map((entry) {
                          final pos = entry.key;
                          final j = entry.value;
                          final nom = nomsParUid[j.id] ?? 'Joueur';
                          final scoreBase = scores[j.id] ?? 0;
                          final scoreFinal = scoresFinaux[j.id] ?? 0;
                          final bonus = scoreFinal - scoreBase;
                          final isMe = j.id == myUid;
                          final isChamp = pos == 0;
                          final detail = detailPoints[j.id] ?? {};
                          final medaille = pos == 0 ? '🥇' : pos == 1 ? '🥈' : pos == 2 ? '🥉' : '  ';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: isChamp
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)])
                                  : null,
                              color: isChamp
                                  ? null
                                  : isMe
                                      ? Colors.blueAccent.withValues(alpha: 0.2)
                                      : Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isChamp
                                    ? Colors.amber
                                    : isMe
                                        ? Colors.blueAccent
                                        : Colors.white24,
                                width: isChamp ? 3 : isMe ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(medaille,
                                        style: const TextStyle(fontSize: 28)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        isMe ? '$nom (TOI)' : nom,
                                        style: TextStyle(
                                          color: isChamp ? Colors.black : Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isChamp ? Colors.black : Colors.amber,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$scoreFinal pts',
                                        style: TextStyle(
                                          color: isChamp ? Colors.amber : Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // DÉTAIL DES POINTS
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _pointDetail('🎯 Votes', '${detail['votes'] ?? 0}', isChamp),
                                    _pointDetail('🔮 Pronostic', '+${detail['predictif'] ?? 0}', isChamp),
                                    _pointDetail('⚡ Défis', '${(detail['defis'] ?? 0) >= 0 ? '+' : ''}${detail['defis'] ?? 0}', isChamp),
                                    if (bonus > 0)
                                      _pointDetail('👑 Bonus', '+$bonus', isChamp),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 30),

                        // CHAMPION
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.amber, width: 2),
                          ),
                          child: Column(
                            children: [
                              const Text('👑', style: TextStyle(fontSize: 50)),
                              const Text(
                                'CHAMPION',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                championNom.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // RETOUR ACCUEIL
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              '🏠 RETOUR ACCUEIL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _pointDetail(String label, String valeur, bool isChamp) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isChamp ? Colors.black54 : Colors.white54,
            fontSize: 11,
          ),
        ),
        Text(
          valeur,
          style: TextStyle(
            color: isChamp ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}



import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a1f),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('rooms').doc(widget.code).snapshots(),
          builder: (context, roomSnap) {
            if (!roomSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final roomData = roomSnap.data!.data() as Map<String, dynamic>?;
            if (roomData == null) {
              return const Center(child: Text('Salon introuvable', style: TextStyle(color: Colors.white)));
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
                final coupablesParManche = (roomData['coupablesParManche'] ?? []) as List<dynamic>;
                final totalManches = roomData['totalManches'] ?? 3;

                // Calcul des scores totaux
                final scores = <String, int>{};
                final votesCorrectsParManche = <String, List<bool>>{};

                for (var j in joueurs) {
                  scores[j.id] = 0;
                  votesCorrectsParManche[j.id] = List.filled(totalManches, false);
                }

                for (int i = 0; i < coupablesParManche.length; i++) {
                  final mancheKey = 'manche_${i + 1}';
                  final votesM = (votesParManche[mancheKey] ?? {}) as Map<String, dynamic>;
                  final coupableUid = coupablesParManche[i];
                  votesM.forEach((voterUid, votedUid) {
                    if (votedUid == coupableUid) {
                      scores[voterUid] = (scores[voterUid] ?? 0) + 1;
                      if (i < totalManches) {
                        votesCorrectsParManche[voterUid]?[i] = true;
                      }
                    }
                  });
                }

                // Bonus finale: +5 pts au joueur ayant le plus de votes corrects
                final maxScore = scores.values.isEmpty ? 0 : scores.values.reduce((a, b) => a > b ? a : b);
                final scoresFinaux = Map<String, int>.from(scores);
                if (maxScore > 0) {
                  scoresFinaux.forEach((uid, score) {
                    if (score == maxScore) {
                      scoresFinaux[uid] = score + 5;
                    }
                  });
                }

                final classement = joueurs.toList()
                  ..sort((a, b) => (scoresFinaux[b.id] ?? 0).compareTo(scoresFinaux[a.id] ?? 0));

                final champion = classement.isNotEmpty ? classement.first : null;
                final championData = champion?.data() as Map<String, dynamic>?;
                final championNom = championData?['name'] ?? 'Personne';

                final myUid = FirebaseAuth.instance.currentUser?.uid;
                final nomsParUid = <String, String>{};
                for (var j in joueurs) {
                  final d = j.data() as Map<String, dynamic>;
                  nomsParUid[j.id] = d['name'] ?? 'Joueur';
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFF6B00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
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
                              'Revelation des coupables',
                              style: TextStyle(color: Colors.black87, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (!_revealed)
                        ElevatedButton(
                          onPressed: () => setState(() => _revealed = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                          ),
                          child: const Text(
                            '🔓 REVELER LES COUPABLES',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (_revealed) ...[
                        const Text(
                          'LES COUPABLES DES 3 MANCHES',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(coupablesParManche.length, (i) {
                          final coupableUid = coupablesParManche[i];
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
                                          fontSize: 16,
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
                                      Text(
                                        '🔪 $nomCoupable',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 30),
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
                          final jData = j.data() as Map<String, dynamic>;
                          final nom = jData['name'] ?? 'Joueur';
                          final scoreBase = scores[j.id] ?? 0;
                          final scoreFinal = scoresFinaux[j.id] ?? 0;
                          final bonus = scoreFinal - scoreBase;
                          final isMe = j.id == myUid;
                          final isChamp = pos == 0;
                          final medaille = pos == 0
                              ? '🥇'
                              : pos == 1
                                  ? '🥈'
                                  : pos == 2
                                      ? '🥉'
                                      : '  ';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: isChamp
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)])
                                  : null,
                              color: isChamp
                                  ? null
                                  : (isMe
                                      ? Colors.blueAccent.withValues(alpha: 0.3)
                                      : Colors.white10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isChamp
                                    ? Colors.amber
                                    : (isMe ? Colors.blueAccent : Colors.white24),
                                width: isChamp ? 3 : (isMe ? 2 : 1),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Text(medaille, style: const TextStyle(fontSize: 28)),
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
                                if (bonus > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '🎁 Bonus finale : +$bonus pts',
                                      style: TextStyle(
                                        color: isChamp ? Colors.black87 : Colors.amberAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(totalManches, (i) {
                                      final correct =
                                          votesCorrectsParManche[j.id]?[i] ?? false;
                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: correct
                                              ? Colors.green
                                              : Colors.red.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'M${i + 1} ${correct ? "✓" : "✗"}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 30),
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
                                championNom.toString().toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
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
}


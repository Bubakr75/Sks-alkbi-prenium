import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../game_screen.dart';
import '../services/scenario_service.dart';
import 'finale_screen.dart';

class ClassementMancheScreen extends StatefulWidget {
  final String code;
  final int mancheTerminee;
  final int totalManches;

  const ClassementMancheScreen({
    super.key,
    required this.code,
    required this.mancheTerminee,
    required this.totalManches,
  });

  @override
  State<ClassementMancheScreen> createState() => _ClassementMancheScreenState();
}

class _ClassementMancheScreenState extends State<ClassementMancheScreen> {
  bool _isLoading = false;

  Future<void> _passerMancheSuivante() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final roomDoc = FirebaseFirestore.instance.collection('rooms').doc(widget.code);
    final roomSnap = await roomDoc.get();
    final data = roomSnap.data();
    if (data == null) return;
    final hostUid = data['hostUid'];
    if (uid != hostUid) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seul l hote peut lancer la manche suivante')),
      );
      return;
    }

    final prochaineManche = widget.mancheTerminee + 1;

    if (prochaineManche > widget.totalManches) {
      // Aller a la finale
      await roomDoc.update({
        'status': 'finale',
        'manche': prochaineManche,
      });
    } else {
      // Lancer la manche suivante avec rotation des roles
      try {
        final scenarioId = data['scenarioId'] ?? 'penalty_manque';
        final service = ScenarioService();
        final scenario = await service.chargerScenario(scenarioId);
        if (scenario == null) throw Exception('Scenario introuvable');

        // Recuperer les joueurs
        final joueursSnap = await roomDoc.collection('players').get();
        final joueurs = joueursSnap.docs.map((doc) {
          final d = doc.data();
          return JoueurInfo(
            id: d['uid'] as String? ?? doc.id,
            prenom: d['name'] as String? ?? 'Joueur',
          );
        }).toList();

        // Redistribuer les cartes (melange aleatoire => roles tournent)
        final cartesParJoueur = service.distribuerCartes(
          scenario: scenario,
          joueurs: joueurs,
        );

        // Sauvegarder les nouvelles cartes
        for (final joueur in joueurs) {
          final carte = cartesParJoueur[joueur.id]!;
          await roomDoc.collection('players').doc(joueur.id).update({
            'carte': carte.toMap(),
            'roleKey': carte.role,
          });
        }

        // Demarrer la manche suivante
        await roomDoc.update({
          'status': 'playing',
          'manche': prochaineManche,
          'gameStartedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur redistribution : $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
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

            final mancheActuelle = roomData['manche'] ?? widget.mancheTerminee;
            final status = roomData['status'] ?? 'classement';
            final uid = FirebaseAuth.instance.currentUser?.uid;
            final isHost = uid == roomData['hostUid'];

            // Si l hote a lance la manche suivante, on redirige tout le monde
            if (status == 'playing' && mancheActuelle > widget.mancheTerminee) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameScreen(code: widget.code, playerName: ''),
                  ),
                );
              });
            }
            if (status == 'finale') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FinaleScreen(code: widget.code),
                  ),
                );
              });
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
                // Calcul des votes corrects de chaque joueur sur les manches deja jouees
                final votesParManche = (roomData['votesParManche'] ?? {}) as Map<String, dynamic>;
                final coupablesParManche = (roomData['coupablesParManche'] ?? []) as List<dynamic>;

                final scores = <String, int>{};
                for (var j in joueurs) {
                  scores[j.id] = 0;
                }

                for (int i = 0; i < coupablesParManche.length; i++) {
                  final mancheKey = 'manche_${i + 1}';
                  final votesM = (votesParManche[mancheKey] ?? {}) as Map<String, dynamic>;
                  final coupableUid = coupablesParManche[i];
                  votesM.forEach((voterUid, votedUid) {
                    if (votedUid == coupableUid) {
                      scores[voterUid] = (scores[voterUid] ?? 0) + 1;
                    }
                  });
                }

                final classement = joueurs.toList()
                  ..sort((a, b) => (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0));

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'MANCHE ${widget.mancheTerminee} / ${widget.totalManches}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'TERMINEE',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber, width: 2),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.lock, color: Colors.amber, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'COUPABLES NON REVELES',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Les identites des coupables seront devoilees a la FINALE.\nGarde tes soupcons pour toi !',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'CLASSEMENT PARTIEL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...classement.asMap().entries.map((entry) {
                        final pos = entry.key;
                        final j = entry.value;
                        final jData = j.data() as Map<String, dynamic>;
                        final nom = jData['name'] ?? 'Joueur';
                        final score = scores[j.id] ?? 0;
                        final isMe = j.id == uid;
                        final medaille = pos == 0 ? '🥇' : pos == 1 ? '🥈' : pos == 2 ? '🥉' : '  ';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blueAccent.withOpacity(0.3) : Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isMe ? Colors.blueAccent : Colors.white24,
                              width: isMe ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(medaille, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isMe ? '$nom (TOI)' : nom,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$score pt${score > 1 ? "s" : ""}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 30),
                      if (isHost)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _passerMancheSuivante,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.mancheTerminee >= widget.totalManches
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : Text(
                                    widget.mancheTerminee >= widget.totalManches
                                        ? '🏆 LANCER LA FINALE'
                                        : '▶️ MANCHE ${widget.mancheTerminee + 1}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'En attente que l hote lance la suite...',
                            style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                          ),
                        ),
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




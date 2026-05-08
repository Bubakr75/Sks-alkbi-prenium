import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'questionnaire_screen.dart';
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
  bool _navigated = false;
  String _myUid = '';

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<void> _lancerMancheSuivante() async {
    setState(() => _isLoading = true);

    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.code);
    final roomSnap = await roomRef.get();
    final data = roomSnap.data();
    if (data == null) return;

    final hostUid = data['hostUid'];
    if (_myUid != hostUid) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seul l\'hote peut lancer la manche suivante')),
        );
      }
      return;
    }

    final prochaineManche = widget.mancheTerminee + 1;

    if (prochaineManche > widget.totalManches) {
      await roomRef.update({'status': 'finale', 'manche': prochaineManche});
    } else {
      // Nettoyer les voteRequests de la manche précédente
      final voteReqSnap = await roomRef.collection('voteRequests').get();
      for (final doc in voteReqSnap.docs) {
        await doc.reference.delete();
      }

      // Lancer le questionnaire de la manche suivante
      await roomRef.update({
        'status': 'questionnaire',
        'manche': prochaineManche,
        'gameStartedAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
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
            final roomData = Map<String, dynamic>.from(roomSnap.data!.data() as Map? ?? {});

            final mancheActuelle = roomData['manche'] as int? ?? widget.mancheTerminee;
            final status = roomData['status'] as String? ?? 'classement';
            final isHost = _myUid == roomData['hostUid'];

            // Redirection automatique pour tous les joueurs
            if (status == 'questionnaire' && mancheActuelle > widget.mancheTerminee && !_navigated) {
              _navigated = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  final playerName = '';
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuestionnaireScreen(
                        code: widget.code,
                        playerName: playerName,
                        manche: mancheActuelle,
                      ),
                    ),
                  );
                }
              });
            }

            if (status == 'finale' && !_navigated) {
              _navigated = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FinaleScreen(code: widget.code),
                    ),
                  );
                }
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
                final votesParManche = Map<String, dynamic>.from((roomData['votesParManche'] ?? {}) as Map? ?? {});
                final coupablesParManche = (roomData['coupablesParManche'] ?? []) as List<dynamic>;

                final scores = <String, int>{};
                for (var j in joueurs) {
                  scores[j.id] = 0;
                }

                for (int i = 0; i < coupablesParManche.length; i++) {
                  final mancheKey = 'manche_${i + 1}';
                  final votesM = Map<String, dynamic>.from((votesParManche[mancheKey] ?? {}) as Map? ?? {});
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
                              'TERMINÉE ✓',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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
                              'COUPABLES NON RÉVÉLÉS',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Les identités seront dévoilées à la FINALE.\nGarde tes soupçons pour toi !',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'CLASSEMENT PARTIEL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '(votes corrects uniquement)',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ...classement.asMap().entries.map((entry) {
                        final pos = entry.key;
                        final j = entry.value;
                        final jData = Map<String, dynamic>.from(j.data() as Map? ?? {});
                        final nom = jData['name'] as String? ?? 'Joueur';
                        final score = scores[j.id] ?? 0;
                        final isMe = j.id == _myUid;
                        final medaille = pos == 0 ? '🥇' : pos == 1 ? '🥈' : pos == 2 ? '🥉' : '  ';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isMe ? Colors.green : Colors.white24,
                              width: isMe ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(medaille, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isMe ? '$nom (toi)' : nom,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.amber),
                                ),
                                child: Text(
                                  '$score ✓',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                      if (isHost)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _lancerMancheSuivante,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    widget.mancheTerminee >= widget.totalManches
                                        ? '🏆 Voir la Finale !'
                                        : '🚀 Lancer la Manche ${widget.mancheTerminee + 1}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        )
                      else
                        const Text(
                          'En attente que l\'hôte lance la manche suivante...',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 20),
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





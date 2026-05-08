import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'carte_ia_screen.dart';

class VotePredictifScreen extends StatefulWidget {
  final String code;
  final String playerName;

  const VotePredictifScreen({
    super.key,
    required this.code,
    required this.playerName,
  });

  @override
  State<VotePredictifScreen> createState() => _VotePredictifScreenState();
}

class _VotePredictifScreenState extends State<VotePredictifScreen> {
  String? _selectedUid;
  bool _hasVoted = false;
  bool _isSubmitting = false;
  bool _navigated = false;
  String _myUid = '';

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<void> _submitVotePredictif() async {
    if (_selectedUid == null) return;
    setState(() => _isSubmitting = true);

    try {
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.code);
      final roomSnap = await roomRef.get();
      final manche = roomSnap.data()?['manche'] as int? ?? 1;

      await roomRef.update({
        'votesPredictifs.manche_$manche.$_myUid': _selectedUid,
      });

      setState(() {
        _hasVoted = true;
        _isSubmitting = false;
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('rooms')
              .doc(widget.code)
              .collection('players')
              .snapshots(),
          builder: (context, playersSnap) {
            if (!playersSnap.hasData) {
              return const Center(child: CircularProgressIndicator(color: Colors.green));
            }

            final players = playersSnap.data!.docs;
            final totalPlayers = players.length;

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.code)
                  .snapshots(),
              builder: (context, roomSnap) {
                if (!roomSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final roomData = roomSnap.data!.data() as Map<String, dynamic>?;
                final manche = roomData?['manche'] as int? ?? 1;
                final votesPredictifs = (roomData?['votesPredictifs'] ?? {}) as Map<String, dynamic>;
                final votesM = (votesPredictifs['manche_$manche'] ?? {}) as Map<String, dynamic>;
                final votesCount = votesM.length;

                // Compter les votes par joueur pour affichage public
                final Map<String, int> compteurVotes = {};
                votesM.forEach((voterUid, targetUid) {
                  compteurVotes[targetUid as String] = (compteurVotes[targetUid] ?? 0) + 1;
                });

                // Quand tout le monde a voté → passer à la carte
                if (votesCount >= totalPlayers && totalPlayers > 0 && !_navigated) {
                  _navigated = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CarteIaScreen(
                            code: widget.code,
                            playerName: widget.playerName,
                          ),
                        ),
                      );
                    }
                  });
                }

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      // HEADER
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.withValues(alpha: 0.3),
                              Colors.orange.withValues(alpha: 0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber, width: 2),
                        ),
                        child: Column(
                          children: [
                            const Text('🔮', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 8),
                            const Text(
                              'VOTE PRÉDICTIF',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Avant le débat — Qui pensez-vous\nque le groupe accusera à la fin ?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Text(
                                '🎁 +2 points si ton pronostic est correct !',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Votes : $votesCount / $totalPlayers',
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_hasVoted) ...[
                        // AFFICHAGE RÉSULTATS EN TEMPS RÉEL
                        const Text(
                          'PRONOSTICS EN DIRECT',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: players.length,
                            itemBuilder: (context, index) {
                              final p = players[index];
                              final data = p.data() as Map<String, dynamic>;
                              final uid = p.id;
                              final name = data['name'] as String? ?? '???';
                              final nbVotes = compteurVotes[uid] ?? 0;
                              final pct = totalPlayers > 0 ? nbVotes / totalPlayers : 0.0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: nbVotes > 0 ? Colors.amber.withValues(alpha: 0.5) : Colors.white12,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.amber.withValues(alpha: 0.3),
                                          child: Text(
                                            name[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '$nbVotes vote${nbVotes > 1 ? "s" : ""}',
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        backgroundColor: Colors.white12,
                                        color: Colors.amber,
                                        minHeight: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'En attente des autres joueurs ($votesCount/$totalPlayers)...',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const CircularProgressIndicator(color: Colors.amber),
                        const SizedBox(height: 16),
                      ] else ...[
                        // LISTE DE SÉLECTION
                        Expanded(
                          child: ListView.builder(
                            itemCount: players.length,
                            itemBuilder: (context, index) {
                              final p = players[index];
                              final data = p.data() as Map<String, dynamic>;
                              final uid = p.id;
                              final name = data['name'] as String? ?? '???';
                              final isMe = uid == _myUid;
                              final isSelected = _selectedUid == uid;

                              return GestureDetector(
                                onTap: isMe ? null : () => setState(() => _selectedUid = uid),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.amber.withValues(alpha: 0.2)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? Colors.amber : Colors.white24,
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isMe
                                            ? Colors.grey
                                            : isSelected
                                                ? Colors.amber
                                                : Colors.white24,
                                        child: Text(
                                          name[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          isMe ? '$name (toi)' : name,
                                          style: TextStyle(
                                            color: isMe ? Colors.grey : Colors.white,
                                            fontSize: 18,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(Icons.check_circle, color: Colors.amber, size: 28),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (_selectedUid == null || _isSubmitting)
                                ? null
                                : _submitVotePredictif,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator(color: Colors.black)
                                : const Text(
                                    '🔮 Valider mon pronostic',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
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

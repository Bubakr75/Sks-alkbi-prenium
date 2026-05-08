import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'classement_manche_screen.dart';
import 'finale_screen.dart';

class VoteScreen extends StatefulWidget {
  final String code;
  final String playerName;

  const VoteScreen({super.key, required this.code, required this.playerName});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  String? _selectedUid;
  bool _hasVoted = false;
  bool _isSubmitting = false;
  bool _navigated = false;

  Future<void> _submitVote() async {
    if (_selectedUid == null) return;
    setState(() => _isSubmitting = true);

    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (myUid == null) return;

      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.code);
      final roomSnap = await roomRef.get();
      final roomData = roomSnap.data() ?? {};
      final manche = roomData['manche'] ?? 1;
      final mancheKey = 'manche_$manche';
      final hostUid = roomData['hostUid'];
      final coupablesParManche = List<dynamic>.from(roomData['coupablesParManche'] ?? []);

      // 1. Enregistrer le vote dans votesParManche.manche_X
      await roomRef.update({
        'votesParManche.$mancheKey.$myUid': _selectedUid,
      });

      // 2. L hote enregistre le coupable de la manche (une seule fois)
      if (myUid == hostUid && coupablesParManche.length < manche) {
        final joueursSnap = await roomRef.collection('players').get();
        String? coupableUid;
        for (var j in joueursSnap.docs) {
          final d = j.data();
          if (d['roleKey'] == 'coupable') {
            coupableUid = j.id;
            break;
          }
        }
        if (coupableUid != null) {
          coupablesParManche.add(coupableUid);
          await roomRef.update({'coupablesParManche': coupablesParManche});
        }
      }

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
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Phase de vote'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.code)
            .collection('players')
            .snapshots(),
        builder: (context, playersSnap) {
          if (!playersSnap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          final players = playersSnap.data!.docs;
          final totalPlayers = players.length;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .doc(widget.code)
                .snapshots(),
            builder: (context, roomSnap) {
              final roomData = Map<String, dynamic>.from(roomSnap.data?.data() as Map? ?? {});
              final manche = roomData['manche'] ?? 1;
              final totalManches = roomData['totalManches'] ?? 3;
              final votesParManche = Map<String, dynamic>.from((roomData['votesParManche'] ?? {}) as Map? ?? {});
              final votesM = Map<String, dynamic>.from((votesParManche['manche_$manche'] ?? {}) as Map? ?? {});
              final votesCount = votesM.length;

              // Quand tous ont vote, redirection vers Classement ou Finale
              if (votesCount >= totalPlayers && totalPlayers > 0 && !_navigated) {
                _navigated = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => manche >= totalManches
                            ? FinaleScreen(code: widget.code)
                            : ClassementMancheScreen(
                                code: widget.code,
                                mancheTerminee: manche,
                                totalManches: totalManches,
                              ),
                      ),
                    );
                  }
                });
              }

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'MANCHE $manche / $totalManches',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Qui est le coupable ?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Votes : $votesCount / $totalPlayers',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '🔒 Vote secret - non revele avant la finale',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_hasVoted)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock,
                                  color: Colors.amber, size: 80),
                              const SizedBox(height: 16),
                              const Text(
                                'Ton vote secret est enregistre !',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'En attente des autres joueurs ($votesCount/$totalPlayers)',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 24),
                              const CircularProgressIndicator(
                                  color: Colors.amber),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final p = players[index];
                            final data = p.data() as Map<String, dynamic>;
                            final uid = p.id;
                            final name = data['name'] as String? ?? '???';
                            final isMe = uid == myUid;
                            final isSelected = _selectedUid == uid;

                            return Card(
                              color: isSelected
                                  ? Colors.purple.withValues(alpha: 0.3)
                                  : const Color(0xFF2A2A3E),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.purple
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ListTile(
                                onTap: isMe
                                    ? null
                                    : () => setState(() => _selectedUid = uid),
                                leading: CircleAvatar(
                                  backgroundColor: isMe
                                      ? Colors.grey
                                      : (isSelected
                                          ? Colors.purple
                                          : Colors.green),
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  isMe ? '$name (toi)' : name,
                                  style: TextStyle(
                                    color: isMe ? Colors.grey : Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.purple)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    if (!_hasVoted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_selectedUid == null || _isSubmitting)
                              ? null
                              : _submitVote,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'VALIDER MON VOTE',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}


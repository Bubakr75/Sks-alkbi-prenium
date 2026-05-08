import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vote_screen.dart';
import 'defis_secrets_screen.dart';

class CarteIaScreen extends StatefulWidget {
  final String code;
  final String playerName;

  const CarteIaScreen({
    super.key,
    required this.code,
    required this.playerName,
  });

  @override
  State<CarteIaScreen> createState() => _CarteIaScreenState();
}

class _CarteIaScreenState extends State<CarteIaScreen> {
  bool _secretRevealed = false;
  bool _defiRevealed = false;
  bool _indiceRevealed = false;
  bool _voteRequested = false;
  bool _isLoading = true;
  bool _navigated = false;

  Map<String, dynamic> _carte = {};
  String _histoire = '';
  String _theme = '';
  String _myUid = '';

  @override
  void initState() {
    super.initState();
    _chargerCarte();
  }

  Future<void> _chargerCarte() async {
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.code);

    final roomSnap = await roomRef.get();
    final roomData = roomSnap.data() ?? {};
    _histoire = roomData['iaHistoire'] as String? ?? '';
    _theme = roomData['iaTheme'] as String? ?? '';

    final playerSnap = await roomRef.collection('players').doc(_myUid).get();
    final playerData = playerSnap.data() ?? {};
    _carte = playerData['carte'] as Map<String, dynamic>? ?? {};

    setState(() => _isLoading = false);
  }

  Future<void> _demanderVote() async {
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.code)
          .collection('voteRequests')
          .doc(_myUid)
          .set({
        'uid': _myUid,
        'name': widget.playerName,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() => _voteRequested = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Color _couleurRole(String role) {
    switch (role) {
      case 'coupable': return Colors.red;
      case 'enqueteur': return Colors.blue;
      case 'malchanceux': return Colors.orange;
      default: return Colors.green;
    }
  }

  String _emojiRole(String role) {
    switch (role) {
      case 'coupable': return '🔴';
      case 'enqueteur': return '🕵️';
      case 'malchanceux': return '😰';
      default: return '✅';
    }
  }

  String _labelRole(String role) {
    switch (role) {
      case 'coupable': return 'LE COUPABLE';
      case 'enqueteur': return 'L\'ENQUÊTEUR';
      case 'malchanceux': return 'LE MALCHANCEUX';
      default: return 'INNOCENT';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    final role = _carte['role'] as String? ?? 'innocent';
    final quiTuEs = _carte['roleDansHistoire'] as String? ?? '';
    final defend = _carte['secretConnu'] as String? ?? '';
    final cache = _carte['secretInavouable'] as String? ?? '';
    final accuse = _carte['accuse'] as String? ?? '';
    final defi = _carte['defi'] as String? ?? '';
    final indice = _carte['indice'] as String?;
    final couleur = _couleurRole(role);
    final isCoupable = role == 'coupable';
    final isEnqueteur = role == 'enqueteur';

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
            final totalPlayers = playersSnap.data?.docs.length ?? 0;
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.code)
                  .collection('voteRequests')
                  .snapshots(),
              builder: (context, reqSnap) {
                final reqCount = reqSnap.data?.docs.length ?? 0;

                if (reqCount >= totalPlayers && totalPlayers > 0 && reqCount > 0 && !_navigated) {
                  _navigated = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => VoteScreen(
                            code: widget.code,
                            playerName: widget.playerName,
                          ),
                        ),
                      );
                    }
                  });
                }

                return Column(
                  children: [
                    if (reqCount > 0 && reqCount < totalPlayers)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        color: Colors.purple.withValues(alpha: 0.3),
                        child: Text(
                          'Prêts à voter : $reqCount / $totalPlayers',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // HISTOIRE
                            if (_histoire.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.amber, width: 2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const Icon(Icons.menu_book, color: Colors.amber),
                                      const SizedBox(width: 8),
                                      Text(
                                        '📖 HISTOIRE — $_theme'.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.amber,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ]),
                                    const SizedBox(height: 10),
                                    Text(
                                      _histoire,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        height: 1.5,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // CARTE IDENTITE
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: couleur, width: 3),
                                color: couleur.withValues(alpha: 0.1),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    widget.playerName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_emojiRole(role)} ${_labelRole(role)}',
                                    style: TextStyle(
                                      color: couleur,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  if (quiTuEs.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      quiTuEs,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // CE QUE TU DEFENDS
                            if (defend.isNotEmpty)
                              _bloc('🛡️ CE QUE TU DÉFENDS', Colors.lightBlue, defend),
                            const SizedBox(height: 8),

                            // CE QUE TU CACHES (cliquable)
                            GestureDetector(
                              onTap: () => setState(() => _secretRevealed = !_secretRevealed),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isCoupable
                                      ? Colors.red.withValues(alpha: 0.15)
                                      : Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCoupable ? Colors.red : Colors.white38,
                                    width: isCoupable ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _secretRevealed ? Icons.lock_open : Icons.lock,
                                          color: isCoupable ? Colors.red : Colors.white54,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _secretRevealed
                                              ? '🤐 CE QUE TU CACHES'
                                              : '🤐 CE QUE TU CACHES (appuie pour voir)',
                                          style: TextStyle(
                                            color: isCoupable ? Colors.red : Colors.white54,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_secretRevealed && cache.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        cache,
                                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // QUI ACCUSER
                            if (accuse.isNotEmpty)
                              _bloc('🎯 QUI TU ACCUSES', Colors.orange, accuse),
                            const SizedBox(height: 8),

                            // DEFI SECRET
                            if (defi.isNotEmpty)
                              GestureDetector(
                                onTap: () => setState(() => _defiRevealed = !_defiRevealed),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.purple, width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Icon(
                                          _defiRevealed ? Icons.lock_open : Icons.lock,
                                          color: Colors.purple,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _defiRevealed
                                              ? '⚡ TON DÉFI SECRET'
                                              : '⚡ TON DÉFI SECRET (appuie pour voir)',
                                          style: const TextStyle(
                                            color: Colors.purple,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ]),
                                      if (_defiRevealed) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          defi,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                            // INDICE ENQUETEUR
                            if (isEnqueteur && indice != null && indice.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => setState(() => _indiceRevealed = !_indiceRevealed),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue, width: 2),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Icon(
                                          _indiceRevealed ? Icons.lock_open : Icons.lock,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _indiceRevealed
                                              ? '🔍 TON INDICE SECRET'
                                              : '🔍 TON INDICE SECRET (appuie pour voir)',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ]),
                                      if (_indiceRevealed) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          indice,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // BOUTON DÉFI SECRET
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DefisSecretsScreen(
                                      code: widget.code,
                                      playerName: widget.playerName,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.flash_on, color: Colors.white),
                              label: const Text(
                                'MON DÉFI SECRET ⚡',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // BOUTON VOTE
                            ElevatedButton.icon(
                              onPressed: _voteRequested ? null : _demanderVote,
                              icon: const Icon(Icons.how_to_vote, color: Colors.white),
                              label: Text(
                                _voteRequested
                                    ? 'En attente des autres...'
                                    : 'PASSER AU VOTE',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _bloc(String titre, Color couleur, String contenu) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: TextStyle(
              color: couleur,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            contenu,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}



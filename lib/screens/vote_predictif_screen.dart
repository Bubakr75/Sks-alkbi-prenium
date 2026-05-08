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

class _VotePredictifScreenState extends State<VotePredictifScreen>
    with TickerProviderStateMixin {
  String? _selectedUid;
  bool _hasVoted = false;
  bool _isSubmitting = false;
  bool _navigated = false;
  String _myUid = '';

  late AnimationController _glowController;
  late AnimationController _enterController;
  late Animation<double> _glowAnim;
  late Animation<double> _enterAnim;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _enterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _enterAnim = CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _enterController.forward();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  Future<void> _submitVotePredictif() async {
    if (_selectedUid == null) return;
    setState(() => _isSubmitting = true);
    try {
      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.code);
      final roomSnap = await roomRef.get();
      final manche = roomSnap.data()?['manche'] as int? ?? 1;
      await roomRef.update({'votesPredictifs.manche_$manche.$_myUid': _selectedUid});
      setState(() { _hasVoted = true; _isSubmitting = false; });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red.shade800),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('rooms').doc(widget.code).collection('players').snapshots(),
          builder: (context, playersSnap) {
            if (!playersSnap.hasData) {
              return const Center(child: CircularProgressIndicator(color: Colors.amber));
            }
            final players = playersSnap.data!.docs;
            final totalPlayers = players.length;

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('rooms').doc(widget.code).snapshots(),
              builder: (context, roomSnap) {
                if (!roomSnap.hasData) return const Center(child: CircularProgressIndicator());
                final roomData = roomSnap.data!.data() as Map<String, dynamic>?;
                final manche = roomData?['manche'] as int? ?? 1;
                final votesPredictifs = (roomData?['votesPredictifs'] ?? {}) as Map<String, dynamic>;
                final votesM = (votesPredictifs['manche_$manche'] ?? {}) as Map<String, dynamic>;
                final votesCount = votesM.length;

                final Map<String, int> compteurVotes = {};
                votesM.forEach((voterUid, targetUid) {
                  compteurVotes[targetUid as String] = (compteurVotes[targetUid] ?? 0) + 1;
                });

                if (votesCount >= totalPlayers && totalPlayers > 0 && !_navigated) {
                  _navigated = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(
                        builder: (_) => CarteIaScreen(code: widget.code, playerName: widget.playerName),
                      ));
                    }
                  });
                }

                return FadeTransition(
                  opacity: _enterAnim,
                  child: Column(
                    children: [
                      // ── HEADER ─────────────────────────────────────────────
                      AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (context, child) => Container(
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2A1A00), Color(0xFF1A1000)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: _glowAnim.value * 0.8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: _glowAnim.value * 0.25),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                        child: Column(
                          children: [
                            const Text('🔮', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            const Text(
                              'VOTE PRÉDICTIF',
                              style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Avant le débat — Qui sera accusé\npar le groupe à la fin ?',
                              style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🎁', style: TextStyle(fontSize: 16)),
                                  SizedBox(width: 8),
                                  Text(
                                    '+2 points si ton pronostic est correct !',
                                    style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Barre de votes
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ...List.generate(totalPlayers, (i) => Container(
                                  width: 28, height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: i < votesCount ? Colors.amber : Colors.white12,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: i < votesCount
                                        ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 6)]
                                        : [],
                                  ),
                                )),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$votesCount / $totalPlayers ont voté',
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (_hasVoted)
                        // ── RÉSULTATS EN DIRECT ──────────────────────────────
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.bar_chart_rounded, color: Colors.amber, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('PRONOSTICS EN DIRECT', style: TextStyle(color: Colors.amber, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: players.length,
                                  itemBuilder: (context, index) {
                                    final p = players[index];
                                    final data = p.data() as Map<String, dynamic>;
                                    final uid = p.id;
                                    final name = data['name'] as String? ?? '???';
                                    final nbVotes = compteurVotes[uid] ?? 0;
                                    final pct = totalPlayers > 0 ? nbVotes / totalPlayers : 0.0;
                                    final isLeading = nbVotes > 0 && nbVotes == compteurVotes.values.fold(0, (a, b) => a > b ? a : b);

                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 400),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: isLeading
                                            ? LinearGradient(colors: [Colors.amber.withValues(alpha: 0.2), Colors.orange.withValues(alpha: 0.05)])
                                            : null,
                                        color: isLeading ? null : const Color(0xFF141428),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isLeading ? Colors.amber.withValues(alpha: 0.6) : Colors.white12,
                                          width: isLeading ? 1.5 : 1,
                                        ),
                                        boxShadow: isLeading
                                            ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.2), blurRadius: 15)]
                                            : [],
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 42, height: 42,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    colors: isLeading
                                                        ? [Colors.amber, Colors.orange]
                                                        : [Colors.white24, Colors.white10],
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(name[0].toUpperCase(),
                                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(name,
                                                  style: TextStyle(
                                                    color: isLeading ? Colors.white : Colors.white70,
                                                    fontSize: 16,
                                                    fontWeight: isLeading ? FontWeight.bold : FontWeight.normal,
                                                  )),
                                              ),
                                              if (isLeading) const Text('🎯', style: TextStyle(fontSize: 20)),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: nbVotes > 0 ? Colors.amber.withValues(alpha: 0.2) : Colors.white10,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '$nbVotes vote${nbVotes > 1 ? "s" : ""}',
                                                  style: TextStyle(
                                                    color: nbVotes > 0 ? Colors.amber : Colors.white38,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Stack(
                                            children: [
                                              Container(height: 8, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                                              AnimatedFractionallySizedBox(
                                                duration: const Duration(milliseconds: 600),
                                                curve: Curves.easeOut,
                                                widthFactor: pct,
                                                child: Container(
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(colors: isLeading
                                                        ? [Colors.amber, Colors.orange]
                                                        : [Colors.amber.withValues(alpha: 0.5), Colors.amber.withValues(alpha: 0.2)]),
                                                    borderRadius: BorderRadius.circular(4),
                                                    boxShadow: isLeading ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 8)] : [],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
                                    const SizedBox(width: 12),
                                    Text('En attente ($votesCount/$totalPlayers)...', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // ── SÉLECTION JOUEUR ─────────────────────────────────
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_search_rounded, color: Colors.white38, size: 16),
                                    const SizedBox(width: 8),
                                    const Text('Sélectionne un suspect', style: TextStyle(color: Colors.white38, fontSize: 13, letterSpacing: 1)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? LinearGradient(colors: [Colors.amber.withValues(alpha: 0.2), Colors.orange.withValues(alpha: 0.05)])
                                              : null,
                                          color: isMe ? const Color(0xFF0F0F1E) : (isSelected ? null : const Color(0xFF141428)),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected ? Colors.amber : (isMe ? Colors.white12 : Colors.white12),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 15)]
                                              : [],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 46, height: 46,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: isMe
                                                      ? [Colors.white12, Colors.white10]
                                                      : isSelected
                                                          ? [Colors.amber, Colors.orange]
                                                          : [Colors.white24, Colors.white10],
                                                ),
                                                boxShadow: isSelected
                                                    ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 12)]
                                                    : [],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  isMe ? '🚫' : name[0].toUpperCase(),
                                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                isMe ? '$name (toi — non sélectionnable)' : name,
                                                style: TextStyle(
                                                  color: isMe ? Colors.white24 : (isSelected ? Colors.white : Colors.white70),
                                                  fontSize: 16,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 200),
                                              child: isSelected
                                                  ? const Icon(Icons.check_circle_rounded, color: Colors.amber, size: 28, key: ValueKey('check'))
                                                  : (isMe
                                                      ? const SizedBox(key: ValueKey('none'))
                                                      : const Icon(Icons.radio_button_unchecked, color: Colors.white24, size: 26, key: ValueKey('empty'))),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Bouton valider
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                                child: GestureDetector(
                                  onTap: (_selectedUid == null || _isSubmitting) ? null : _submitVotePredictif,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    decoration: BoxDecoration(
                                      gradient: _selectedUid != null
                                          ? const LinearGradient(colors: [Colors.amber, Color(0xFFFF6F00)])
                                          : null,
                                      color: _selectedUid == null ? Colors.white12 : null,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: _selectedUid != null
                                          ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))]
                                          : [],
                                    ),
                                    child: Center(
                                      child: _isSubmitting
                                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text('🔮', style: TextStyle(fontSize: 20, color: _selectedUid != null ? Colors.black : Colors.white24)),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'Valider mon pronostic',
                                                  style: TextStyle(
                                                    color: _selectedUid != null ? Colors.black : Colors.white24,
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

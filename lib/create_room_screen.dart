import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import 'game_screen.dart';
import 'screens/questionnaire_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  final String scenarioId;
  const CreateRoomScreen({super.key, this.scenarioId = 'ia'});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool _nameFocused = false;

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _createRoom() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entre ton prénom !', style: GoogleFonts.spaceGrotesk()),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final auth = FirebaseAuth.instance;
      await auth.signInAnonymously();
      final uid = auth.currentUser!.uid;
      final code = _generateCode();

      await FirebaseFirestore.instance.collection('rooms').doc(code).set({
        'code': code,
        'hostUid': uid,
        'scenarioId': widget.scenarioId,
        'status': 'waiting',
        'totalManches': 3,
        'manche': 0,
        'votesParManche': {},
        'coupablesParManche': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('rooms').doc(code).collection('players').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'isHost': true,
      });

      if (mounted) {
        Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (ctx, a1, a2) => LobbyScreen(code: code, playerName: _nameController.text.trim(), isHost: true),
          transitionsBuilder: (ctx, anim, a2, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red.shade800),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: _GlowCircle(color: const Color(0xFF6C63FF), size: 300)),
          Positioned(bottom: -100, left: -80, child: _GlowCircle(color: const Color(0xFF00C9A7), size: 250)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),

                  // Icône
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3A3580)]),
                      boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.4), blurRadius: 30)],
                    ),
                    child: const Center(child: Text('🏠', style: TextStyle(fontSize: 36))),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut).fadeIn(),

                  const SizedBox(height: 20),
                  Text('Créer un salon', style: GoogleFonts.spaceGrotesk(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white))
                    .animate().slideY(begin: 0.2, duration: 400.ms, delay: 100.ms).fadeIn(delay: 100.ms),
                  const SizedBox(height: 6),
                  Text('Entre ton prénom pour créer la salle', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 14))
                    .animate().fadeIn(duration: 400.ms, delay: 200.ms),

                  const Spacer(flex: 2),

                  // Champ nom
                  Focus(
                    onFocusChange: (f) => setState(() => _nameFocused = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: _nameFocused ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _nameFocused ? const Color(0xFF6C63FF) : Colors.white12,
                          width: _nameFocused ? 1.5 : 1,
                        ),
                        boxShadow: _nameFocused
                            ? [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.2), blurRadius: 20)]
                            : [],
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Ton prénom...',
                          hintStyle: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 18),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 16, right: 8),
                            child: Text('👤', style: TextStyle(fontSize: 22)),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        ),
                      ),
                    ),
                  ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 300.ms).fadeIn(delay: 300.ms),

                  const SizedBox(height: 16),

                  // Info thème
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        const Text('🎭', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Text('Thème : ', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 13)),
                        Text(widget.scenarioId.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

                  const Spacer(flex: 3),

                  // Bouton créer
                  GestureDetector(
                    onTap: _isLoading ? null : _createRoom,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3A3580)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.4), blurRadius: 25, offset: const Offset(0, 8))],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('🚀', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Text('Créer le salon', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                                ],
                              ),
                      ),
                    ),
                  ).animate().slideY(begin: 0.3, duration: 400.ms, delay: 500.ms).fadeIn(delay: 500.ms),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── LOBBY SCREEN ──────────────────────────────────────────────────────────────
class LobbyScreen extends StatefulWidget {
  final String code;
  final String playerName;
  final bool isHost;

  const LobbyScreen({super.key, required this.code, required this.playerName, required this.isHost});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> with TickerProviderStateMixin {
  bool _isStarting = false;
  bool _navigated = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    setState(() => _isStarting = true);
    try {
      final playersSnap = await FirebaseFirestore.instance
          .collection('rooms').doc(widget.code).collection('players').get();

      if (playersSnap.docs.length < 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Il faut au moins 3 joueurs !', style: GoogleFonts.spaceGrotesk()),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        setState(() => _isStarting = false);
        return;
      }

      await FirebaseFirestore.instance.collection('rooms').doc(widget.code).update({
        'status': 'questionnaire',
        'manche': 1,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red.shade800),
        );
      }
    }
    if (mounted) setState(() => _isStarting = false);
  }

  void _copierCode() {
    Clipboard.setData(ClipboardData(text: widget.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code copié !', style: GoogleFonts.spaceGrotesk()),
        backgroundColor: const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      body: Stack(
        children: [
          Positioned(top: -60, left: -60, child: _GlowCircle(color: const Color(0xFF6C63FF), size: 280)),
          Positioned(bottom: -80, right: -60, child: _GlowCircle(color: const Color(0xFF00C9A7), size: 240)),
          SafeArea(
            child: Column(
              children: [
                // ── HEADER ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 20),
                        ),
                      ),
                      const Spacer(),
                      Text('SALON', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── CODE SALON ───────────────────────────────────────────
                GestureDetector(
                  onTap: _copierCode,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A1A35), Color(0xFF0D0D20)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                      boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.15), blurRadius: 30)],
                    ),
                    child: Column(
                      children: [
                        Text('CODE DU SALON', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: Text(
                            widget.code,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy_rounded, color: const Color(0xFF6C63FF).withValues(alpha: 0.7), size: 14),
                            const SizedBox(width: 6),
                            Text('Appuie pour copier', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut).fadeIn(),

                const SizedBox(height: 24),

                // ── JOUEURS ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text('JOUEURS CONNECTÉS', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('rooms').doc(widget.code).collection('players').snapshots(),
                        builder: (context, snap) {
                          final count = snap.data?.docs.length ?? 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: count >= 3 ? Colors.green.withValues(alpha: 0.15) : Colors.white10,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: count >= 3 ? Colors.green.withValues(alpha: 0.4) : Colors.white12),
                            ),
                            child: Text('$count / 6',
                              style: GoogleFonts.spaceGrotesk(color: count >= 3 ? Colors.green : Colors.white38, fontSize: 12, fontWeight: FontWeight.w700)),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('rooms').doc(widget.code).collection('players').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
                      }
                      final players = snapshot.data!.docs;
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index].data() as Map<String, dynamic>;
                          final isPlayerHost = player['isHost'] == true;
                          final name = player['name'] as String? ?? 'Joueur';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: isPlayerHost
                                  ? LinearGradient(colors: [
                                      const Color(0xFF6C63FF).withValues(alpha: 0.15),
                                      const Color(0xFF6C63FF).withValues(alpha: 0.05),
                                    ])
                                  : null,
                              color: isPlayerHost ? null : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isPlayerHost ? const Color(0xFF6C63FF).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.07),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: isPlayerHost
                                          ? [const Color(0xFF6C63FF), const Color(0xFF3A3580)]
                                          : [Colors.white24, Colors.white10],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      name[0].toUpperCase(),
                                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(name, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                                if (isPlayerHost)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('👑', style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 4),
                                        Text('Hôte', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF6C63FF), fontSize: 11, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00C9A7)),
                                  ),
                              ],
                            ),
                          ).animate(delay: (index * 60).ms).slideX(begin: 0.2, duration: 300.ms).fadeIn(duration: 300.ms);
                        },
                      );
                    },
                  ),
                ),

                // StreamBuilder redirection
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('rooms').doc(widget.code).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final status = data['status'] as String? ?? 'waiting';
                      final manche = data['manche'] as int? ?? 1;

                      if (status == 'questionnaire' && !_navigated) {
                        _navigated = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.pushReplacement(context, MaterialPageRoute(
                              builder: (c) => QuestionnaireScreen(code: widget.code, playerName: widget.playerName, manche: manche),
                            ));
                          }
                        });
                      }
                      if (status == 'playing' && !_navigated) {
                        _navigated = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            Navigator.pushReplacement(context, MaterialPageRoute(
                              builder: (c) => GameScreen(code: widget.code, playerName: widget.playerName),
                            ));
                          }
                        });
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // ── BOUTON LANCER ────────────────────────────────────────
                if (widget.isHost)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: GestureDetector(
                      onTap: _isStarting ? null : _startGame,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF006B5A)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: const Color(0xFF00C9A7).withValues(alpha: 0.4), blurRadius: 25, offset: const Offset(0, 8))],
                        ),
                        child: Center(
                          child: _isStarting
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('🚀', style: TextStyle(fontSize: 22)),
                                    const SizedBox(width: 10),
                                    Text('Lancer la partie !', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)),
                          const SizedBox(width: 12),
                          Text("En attente que l'hôte lance...", style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.0)]),
      ),
    );
  }
}

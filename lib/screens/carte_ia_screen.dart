import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'vote_screen.dart';
import 'defis_secrets_screen.dart';

class CarteIaScreen extends StatefulWidget {
  final String code;
  final String playerName;

  const CarteIaScreen({super.key, required this.code, required this.playerName});

  @override
  State<CarteIaScreen> createState() => _CarteIaScreenState();
}

class _CarteIaScreenState extends State<CarteIaScreen> with TickerProviderStateMixin {
  bool _secretRevealed = false;
  bool _defiRevealed = false;
  bool _indiceRevealed = false;
  bool _voteRequested = false;
  bool _isLoading = true;
  bool _navigated = false;
  bool _histoireExpanded = false;

  Map<String, dynamic> _carte = {};
  String _histoire = '';
  String _theme = '';
  String _myUid = '';

  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _chargerCarte();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
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
          .collection('rooms').doc(widget.code)
          .collection('voteRequests').doc(_myUid)
          .set({'uid': _myUid, 'name': widget.playerName, 'timestamp': FieldValue.serverTimestamp()});
      setState(() => _voteRequested = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  // ── COULEURS ET STYLES PAR RÔLE ──────────────────────────────────────────
  Color _couleurRole(String role) {
    switch (role) {
      case 'coupable': return const Color(0xFFFF4757);
      case 'enqueteur': return const Color(0xFF2196F3);
      case 'malchanceux': return const Color(0xFFFF9800);
      default: return const Color(0xFF00C9A7);
    }
  }

  List<Color> _gradientRole(String role) {
    switch (role) {
      case 'coupable': return [const Color(0xFF8B0000), const Color(0xFF2D0000)];
      case 'enqueteur': return [const Color(0xFF0D3B6E), const Color(0xFF051525)];
      case 'malchanceux': return [const Color(0xFF5C3000), const Color(0xFF1A0D00)];
      default: return [const Color(0xFF003D35), const Color(0xFF001510)];
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

  String _descriptionRole(String role) {
    switch (role) {
      case 'coupable': return 'Tu es l\'auteur du crime. Ne te fais pas démasquer.';
      case 'enqueteur': return 'Tu as un indice secret. Trouve le coupable sans te dévoiler.';
      case 'malchanceux': return 'Tu crois être innocent, mais les indices pointent vers toi.';
      default: return 'Tu es innocent. Aide à trouver le vrai coupable.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF080818),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🃏', style: TextStyle(fontSize: 60))
                .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text('Chargement de ta carte...', style: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 16)),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Color(0xFF6C63FF)),
            ],
          ),
        ),
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
    final gradient = _gradientRole(role);
    final isCoupable = role == 'coupable';
    final isEnqueteur = role == 'enqueteur';

    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      body: Stack(
        children: [
          // Fond lumineux selon le rôle
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, child) => Positioned(
              top: -100, left: -100,
              child: Container(
                width: 400, height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    couleur.withValues(alpha: _glowAnim.value * 0.12),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ),

          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('rooms').doc(widget.code).collection('players').snapshots(),
              builder: (context, playersSnap) {
                final totalPlayers = playersSnap.data?.docs.length ?? 0;
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('rooms').doc(widget.code).collection('voteRequests').snapshots(),
                  builder: (context, reqSnap) {
                    final reqCount = reqSnap.data?.docs.length ?? 0;

                    if (reqCount >= totalPlayers && totalPlayers > 0 && reqCount > 0 && !_navigated) {
                      _navigated = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (c) => VoteScreen(code: widget.code, playerName: widget.playerName),
                          ));
                        }
                      });
                    }

                    return Column(
                      children: [
                        // ── BARRE VOTE EN COURS ────────────────────────────
                        if (reqCount > 0 && reqCount < totalPlayers)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [couleur.withValues(alpha: 0.3), couleur.withValues(alpha: 0.1)]),
                              border: Border(bottom: BorderSide(color: couleur.withValues(alpha: 0.3))),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)),
                                const SizedBox(width: 10),
                                Text('Prêts à voter : $reqCount / $totalPlayers',
                                  style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ).animate().fadeIn(),

                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [

                                // ── HISTOIRE ─────────────────────────────────
                                if (_histoire.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => setState(() => _histoireExpanded = !_histoireExpanded),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [const Color(0xFF2A1800), const Color(0xFF0D0800)],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                        boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.15), blurRadius: 20)],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                                                ),
                                                child: Text('📖 $_theme'.toUpperCase(),
                                                  style: GoogleFonts.spaceGrotesk(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                                              ),
                                              const Spacer(),
                                              Icon(_histoireExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.amber.withValues(alpha: 0.6)),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _histoireExpanded ? _histoire : (_histoire.length > 120 ? '${_histoire.substring(0, 120)}...' : _histoire),
                                            style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 14, height: 1.6, fontStyle: FontStyle.italic),
                                          ),
                                          if (!_histoireExpanded && _histoire.length > 120) ...[
                                            const SizedBox(height: 6),
                                            Text('Appuie pour lire la suite →',
                                              style: GoogleFonts.spaceGrotesk(color: Colors.amber.withValues(alpha: 0.6), fontSize: 12)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ).animate().slideY(begin: 0.2, duration: 400.ms).fadeIn(),

                                // ── CARTE IDENTITÉ RÔLE ───────────────────────
                                AnimatedBuilder(
                                  animation: _glowAnim,
                                  builder: (context, child) => Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: gradient,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: couleur.withValues(alpha: _glowAnim.value * 0.7), width: 1.5),
                                      boxShadow: [BoxShadow(color: couleur.withValues(alpha: _glowAnim.value * 0.25), blurRadius: 30)],
                                    ),
                                    child: child,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(_emojiRole(role), style: const TextStyle(fontSize: 48))
                                        .animate().scale(duration: 500.ms, curve: Curves.elasticOut, delay: 200.ms),
                                      const SizedBox(height: 12),
                                      Text(widget.playerName,
                                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800))
                                        .animate().slideY(begin: 0.2, duration: 400.ms, delay: 300.ms).fadeIn(delay: 300.ms),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: couleur.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: couleur.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(_labelRole(role),
                                          style: GoogleFonts.spaceGrotesk(color: couleur, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
                                      ).animate().fadeIn(delay: 400.ms),
                                      const SizedBox(height: 10),
                                      Text(_descriptionRole(role),
                                        style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 13, height: 1.4),
                                        textAlign: TextAlign.center)
                                        .animate().fadeIn(delay: 500.ms),
                                      if (quiTuEs.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.white12),
                                          ),
                                          child: Text(quiTuEs,
                                            style: GoogleFonts.spaceGrotesk(color: Colors.white60, fontSize: 13, fontStyle: FontStyle.italic, height: 1.4),
                                            textAlign: TextAlign.center),
                                        ).animate().fadeIn(delay: 600.ms),
                                      ],
                                    ],
                                  ),
                                ).animate().scale(duration: 500.ms, curve: Curves.easeOut).fadeIn(),

                                // ── CE QUE TU DÉFENDS ─────────────────────────
                                if (defend.isNotEmpty)
                                  _buildBloc(
                                    titre: 'CE QUE TU DÉFENDS',
                                    emoji: '🛡️',
                                    couleur: const Color(0xFF2196F3),
                                    contenu: defend,
                                    delay: 100,
                                  ),

                                const SizedBox(height: 10),

                                // ── SECRET (cliquable) ────────────────────────
                                if (cache.isNotEmpty)
                                  _buildSecretBloc(
                                    titre: 'CE QUE TU CACHES',
                                    emoji: '🤐',
                                    couleur: isCoupable ? const Color(0xFFFF4757) : Colors.white54,
                                    contenu: cache,
                                    revealed: _secretRevealed,
                                    onTap: () => setState(() => _secretRevealed = !_secretRevealed),
                                    delay: 200,
                                  ),

                                const SizedBox(height: 10),

                                // ── QUI ACCUSER ───────────────────────────────
                                if (accuse.isNotEmpty)
                                  _buildBloc(
                                    titre: 'QUI TU ACCUSES',
                                    emoji: '🎯',
                                    couleur: const Color(0xFFFF9800),
                                    contenu: accuse,
                                    delay: 300,
                                  ),

                                const SizedBox(height: 10),

                                // ── DÉFI SECRET (cliquable) ───────────────────
                                if (defi.isNotEmpty)
                                  _buildSecretBloc(
                                    titre: 'TON DÉFI SECRET',
                                    emoji: '⚡',
                                    couleur: const Color(0xFFAB47BC),
                                    contenu: defi,
                                    revealed: _defiRevealed,
                                    onTap: () => setState(() => _defiRevealed = !_defiRevealed),
                                    delay: 400,
                                  ),

                                // ── INDICE ENQUÊTEUR (cliquable) ──────────────
                                if (isEnqueteur && indice != null && indice.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _buildSecretBloc(
                                    titre: 'TON INDICE SECRET',
                                    emoji: '🔍',
                                    couleur: const Color(0xFF2196F3),
                                    contenu: indice,
                                    revealed: _indiceRevealed,
                                    onTap: () => setState(() => _indiceRevealed = !_indiceRevealed),
                                    delay: 500,
                                    highlighted: true,
                                  ),
                                ],

                                const SizedBox(height: 28),
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

          // ── BOUTONS BAS FIXÉS ─────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFF080818).withValues(alpha: 0), const Color(0xFF080818)],
                ),
              ),
              child: Row(
                children: [
                  // Bouton défi
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (c) => DefisSecretsScreen(code: widget.code, playerName: widget.playerName),
                      )),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6A0DAD), Color(0xFF3A0070)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: const Color(0xFF6A0DAD).withValues(alpha: 0.4), blurRadius: 15)],
                        ),
                        child: Column(
                          children: [
                            const Text('⚡', style: TextStyle(fontSize: 20)),
                            Text('Mon défi', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Bouton vote
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _voteRequested ? null : _demanderVote,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: _voteRequested
                              ? null
                              : LinearGradient(colors: [couleur, couleur.withValues(alpha: 0.6)]),
                          color: _voteRequested ? Colors.white12 : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _voteRequested ? [] : [BoxShadow(color: couleur.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 4))],
                        ),
                        child: Center(
                          child: _voteRequested
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)),
                                    const SizedBox(width: 8),
                                    Text('En attente...', style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 14)),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('🗳️', style: TextStyle(fontSize: 20)),
                                    const SizedBox(width: 8),
                                    Text('PASSER AU VOTE', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BLOCS UI ───────────────────────────────────────────────────────────────
  Widget _buildBloc({required String titre, required String emoji, required Color couleur, required String contenu, int delay = 0}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(titre, style: GoogleFonts.spaceGrotesk(color: couleur, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 10),
          Text(contenu, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, height: 1.5)),
        ],
      ),
    ).animate(delay: delay.ms).slideY(begin: 0.15, duration: 300.ms).fadeIn(duration: 300.ms);
  }

  Widget _buildSecretBloc({
    required String titre, required String emoji, required Color couleur,
    required String contenu, required bool revealed, required VoidCallback onTap,
    int delay = 0, bool highlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: revealed ? couleur.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: revealed ? couleur.withValues(alpha: 0.6) : (highlighted ? couleur.withValues(alpha: 0.3) : Colors.white12),
            width: revealed ? 1.5 : 1,
          ),
          boxShadow: revealed ? [BoxShadow(color: couleur.withValues(alpha: 0.2), blurRadius: 15)] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(revealed ? '🔓' : '🔒', style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(titre, style: GoogleFonts.spaceGrotesk(
                  color: revealed ? couleur : Colors.white38,
                  fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
                const Spacer(),
                Text(revealed ? 'Masquer' : 'Appuie pour voir',
                  style: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 11)),
              ],
            ),
            if (revealed && contenu.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(contenu, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, height: 1.5)),
            ],
          ],
        ),
      ),
    ).animate(delay: delay.ms).slideY(begin: 0.15, duration: 300.ms).fadeIn(duration: 300.ms);
  }
}



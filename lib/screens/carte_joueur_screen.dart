import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sks_alibi/models/scenario_model.dart';
import 'vote_screen.dart';

class CarteJoueurScreen extends StatefulWidget {
  final Carte carte;
  final String prenomJoueur;
  final String titreScenario;
  final String? code;
  final String introScenario;
  final Map<int, String> slotToName;
  final List<EvenementDebat> evenements;
  final DateTime? gameStartedAt;

  const CarteJoueurScreen({
    super.key,
    required this.carte,
    required this.prenomJoueur,
    required this.titreScenario,
    this.code,
    this.introScenario = '',
    this.slotToName = const {},
    this.evenements = const [],
    this.gameStartedAt,
  });

  @override
  State<CarteJoueurScreen> createState() => _CarteJoueurScreenState();
}

class _CarteJoueurScreenState extends State<CarteJoueurScreen> {
  bool _secretRevealed = false;
  bool _voteRequested = false;
  bool _introExpanded = true;

  Timer? _ticker;
  int _evenementsDeclenches = 0;
  bool _showFlashBanner = false;
  static const int _delaiPremierEvtSecondes = 90;
  static const int _delaiEntreEvtSecondes = 90;

  @override
  void initState() {
    super.initState();
    if (widget.gameStartedAt != null && widget.evenements.isNotEmpty) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _verifierEvenements();
      });
      _verifierEvenements();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _verifierEvenements() {
    if (widget.gameStartedAt == null) return;
    final now = DateTime.now();
    final secondesEcoulees = now.difference(widget.gameStartedAt!).inSeconds;
    final dejaDeclenchesAttendus = _evtsCensesEtreDeclenches(secondesEcoulees);
    if (dejaDeclenchesAttendus > _evenementsDeclenches &&
        dejaDeclenchesAttendus <= widget.evenements.length) {
      setState(() {
        _evenementsDeclenches = dejaDeclenchesAttendus;
        _showFlashBanner = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showFlashBanner = false);
      });
    }
  }

  int _evtsCensesEtreDeclenches(int secondes) {
    if (secondes < _delaiPremierEvtSecondes) return 0;
    return 1 + ((secondes - _delaiPremierEvtSecondes) ~/ _delaiEntreEvtSecondes);
  }

  String _nameForSlot(int slot) {
    return widget.slotToName[slot] ?? 'Joueur $slot';
  }

  Future<void> _demanderVote() async {
    if (widget.code == null) return;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.code)
          .collection('voteRequests')
          .doc(uid)
          .set({
        'uid': uid,
        'name': widget.prenomJoueur,
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

  @override
  Widget build(BuildContext context) {
    final isCoupable = widget.carte.role == 'coupable';
    final secretInav = _safeString(() => (widget.carte as dynamic).secretInavouable);
    final missionSec = _safeString(() => (widget.carte as dynamic).missionSecrete);

    Widget bodyContent = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.introScenario.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: _introExpanded,
                  onExpansionChanged: (v) => setState(() => _introExpanded = v),
                  iconColor: Colors.amber,
                  collapsedIconColor: Colors.amber,
                  title: const Row(
                    children: [
                      Icon(Icons.menu_book, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('HISTOIRE',
                          style: TextStyle(
                              color: Colors.amber,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        widget.introScenario,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ..._buildEvenementsDeclenches(),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCoupable ? Colors.red : Colors.green,
                width: 3,
              ),
              color: isCoupable
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
            ),
            child: Column(
              children: [
                Text(
                  widget.prenomJoueur,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_emojiPourRole(widget.carte.role)} ${widget.carte.roleDansHistoire}',
                  style: TextStyle(
                    color: isCoupable ? Colors.red : Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isCoupable && secretInav.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _secretRevealed = !_secretRevealed),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          _secretRevealed
                              ? 'TON SECRET INAVOUABLE'
                              : 'TON SECRET INAVOUABLE (cliquer)',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_secretRevealed) ...[
                      const SizedBox(height: 12),
                      Text(
                        secretInav,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          _section('🔍 Ce que les autres savent sur toi', Colors.amber,
              widget.carte.secretConnu),
          _sectionList('🛡️ Tes 3 munitions de defense', Colors.lightBlue,
              _safeStringList(() => (widget.carte as dynamic).munitions)),
          _sectionListQuestions('🎤 Tes questions a poser', Colors.purple,
              _safeList<Question>(() => (widget.carte as dynamic).questions)),
          _sectionListAccusations('🎯 Tes accusations preparees', Colors.orange,
              _safeList<Accusation>(() => (widget.carte as dynamic).accusations)),
          _sectionLien(_safeObj<Lien>(() => (widget.carte as dynamic).lienFort)),
          _sectionListObservations('👁️ Tes observations', Colors.tealAccent,
              _safeList<Observation>(() => (widget.carte as dynamic).observations)),
          _sectionListTemoignages('💬 Reponses preparees aux questions',
              Colors.lightGreenAccent,
              _safeList<Temoignage>(() => (widget.carte as dynamic).temoignages)),
          _sectionDilemme(_safeObj<Dilemme>(() => (widget.carte as dynamic).dilemme)),
          if (isCoupable && missionSec.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎯 MISSION SECRETE',
                      style: TextStyle(
                          color: Colors.purple,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(missionSec,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (widget.code != null)
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
                    color: Colors.white),
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
    );

    Widget mainScaffold = Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(widget.titreScenario),
      ),
      body: Stack(
        children: [
          if (widget.code == null)
            bodyContent
          else
            StreamBuilder<QuerySnapshot>(
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
                    if (reqCount >= totalPlayers && totalPlayers > 0 && reqCount > 0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => VoteScreen(
                                code: widget.code!,
                                playerName: widget.prenomJoueur,
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
                              'Joueurs prets a voter : $reqCount / $totalPlayers',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        Expanded(child: bodyContent),
                      ],
                    );
                  },
                );
              },
            ),
          if (_showFlashBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Container(
                    color: Colors.red.withValues(alpha: value),
                    padding: const EdgeInsets.all(16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Text(
                          '🚨 NOUVEL EVENEMENT !',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );

    return mainScaffold;
  }

  List<Widget> _buildEvenementsDeclenches() {
    final widgets = <Widget>[];
    for (var i = 0; i < _evenementsDeclenches && i < widget.evenements.length; i++) {
      final evt = widget.evenements[i];
      final reaction = _findReactionForEvent(evt.id);
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent, width: 2),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              iconColor: Colors.redAccent,
              collapsedIconColor: Colors.redAccent,
              title: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'EVENEMENT ${i + 1} : ${evt.titre}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evt.texte,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      if (reaction != null) ...[
                        const Divider(color: Colors.white24, height: 24),
                        const Text(
                          '👤 TA POSITION OFFICIELLE',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reaction.positionOfficielle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (reaction.explications.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            '💡 EXPLICATIONS POSSIBLES',
                            style: TextStyle(
                              color: Colors.lightBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...reaction.explications.map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ',
                                        style: TextStyle(color: Colors.lightBlue)),
                                    Expanded(
                                      child: Text(e,
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                        if (reaction.opportuniteStrategique != null &&
                            reaction.opportuniteStrategique!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🎯 OPPORTUNITE STRATEGIQUE',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  reaction.opportuniteStrategique!,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  ReactionEvenement? _findReactionForEvent(String eventId) {
    try {
      final reactions = (widget.carte as dynamic).reactionsEvenements as List<ReactionEvenement>;
      for (final r in reactions) {
        if (r.evenementId == eventId) return r;
      }
    } catch (_) {}
    return null;
  }

  String _safeString(String? Function() getter) {
    try { return getter() ?? ''; } catch (_) { return ''; }
  }

  List<String> _safeStringList(dynamic Function() getter) {
    try {
      final v = getter();
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    } catch (_) { return []; }
  }

  List<T> _safeList<T>(dynamic Function() getter) {
    try {
      final v = getter();
      if (v is List<T>) return v;
      if (v is List) return v.cast<T>();
      return <T>[];
    } catch (_) { return <T>[]; }
  }

  T? _safeObj<T>(dynamic Function() getter) {
    try {
      final v = getter();
      if (v is T) return v;
      return null;
    } catch (_) { return null; }
  }

  String _emojiPourRole(String role) {
    switch (role) {
      case 'coupable': return '🔴';
      case 'temoin': return '👁️';
      case 'detective': return '🕵️';
      default: return '🎭';
    }
  }

  Widget _section(String titre, Color couleur, String contenu) {
    return Card(
      color: const Color(0xFF2A2A3E),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        iconColor: couleur,
        collapsedIconColor: couleur,
        title: Text(titre,
            style: TextStyle(color: couleur, fontSize: 16, fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(contenu,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _sectionList(String titre, Color couleur, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFF2A2A3E),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        iconColor: couleur,
        collapsedIconColor: couleur,
        title: Text(titre,
            style: TextStyle(color: couleur, fontSize: 16, fontWeight: FontWeight.bold)),
        children: items.map((e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('• ', style: TextStyle(color: couleur)),
                Expanded(child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 14))),
              ]),
            )).toList(),
      ),
    );
  }

  Widget _sectionListQuestions(String titre, Color couleur, List<Question> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFF2A2A3E),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        iconColor: couleur,
        collapsedIconColor: couleur,
        title: Text(titre,
            style: TextStyle(color: couleur, fontSize: 16, fontWeight: FontWeight.bold)),
        children: items.map((q) {
          final cible = _nameForSlot(q.cibleSlot);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('➡️ Pose à $cible',
                      style: TextStyle(
                          color: couleur,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Text('« ${q.texte} »',
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionListAccusations(String titre, Color couleur, List<Accusation> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFF2A2A3E),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        iconColor: couleur,
        collapsedIconColor: couleur,
        title: Text(titre,
            style: TextStyle(color: couleur, fontSize: 16, fontWeight: FontWeight.bold)),
        children: items.map((a) {
          final cible = _nameForSlot(a.cibleSlot);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('🎯 Contre $cible',
                      style: TextStyle(
                          color: couleur,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Text('« ${a.texte} »',
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionLien(Lien? lien) {
    if (lien == null) return const SizedBox.shrink();
    final cible = _nameForSlot(lien.cibleSlot);
    return Card(
      color: const Color(0xFF2A2A3E),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        iconColor: Colors.cyan,
        collapsedIconColor: Colors.cyan,
        title: Text('🔗 Ton lien fort avec $cible',
            style: const TextStyle(color: Colors.cyan, fontSize: 16, fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lien.description, style: const TextStyle(color: Colors.white, fontSize: 14)),
                if (lien.avertissement.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('⚠️ ${lien.avertissement}',
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionListObservations(String titre, Color couleur, List<Observation> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFF2A2A3E),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        iconColor: couleur,
        collapsedIconColor: couleur,
        title: Text(titre,
            style: TextStyle(color: couleur, fontSize: 16, fontWeight: FontWeight.bold)),
        children: items.map((o) {
          final cible = _nameForSlot(o.cibleSlot);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sur $cible',
                    style: TextStyle(color: couleur, fontSize: 13, fontWeight: FontWeight.bold)),
                Text('• ${o.texte}', style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionListTemoignages(String titre, Color couleur, List<Temoignage> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFF2A2A3E),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        iconColor: couleur,
        collapsedIconColor: couleur,
        title: Text(titre,
            style: TextStyle(color: couleur, fontSize: 16, fontWeight: FontWeight.bold)),
        children: items.map((t) {
          final demandeur = _nameForSlot(t.demandeurSlot);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: couleur.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Si $demandeur te demande...',
                      style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 6),
                Text(t.contexte,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                _temoignageOption('VERITE', Colors.green, t.optionVerite, '+${t.pointsVerite} pt'),
                const SizedBox(height: 8),
                _temoignageOption('ENFONCER', Colors.orange, t.optionEnfoncer,
                    '+${t.pointsEnfoncerReussi} si ca marche, ${t.pointsEnfoncerEchec} sinon'),
                const SizedBox(height: 8),
                _temoignageOption('MENTIR', Colors.red, t.optionMentir,
                    '+${t.pointsMentirReussi} si credible, ${t.pointsMentirEchec} si grille'),
                const Divider(color: Colors.white24, height: 24),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _temoignageOption(String label, Color color, String texte, String points) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              Text('($points)',
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(texte, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _sectionDilemme(Dilemme? d) {
    if (d == null) return const SizedBox.shrink();
    return Card(
      color: const Color(0xFF2A2A3E),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        iconColor: Colors.pinkAccent,
        collapsedIconColor: Colors.pinkAccent,
        title: const Text('⚡ Ton dilemme (1 fois max)',
            style: TextStyle(color: Colors.pinkAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Option A : ${d.optionATitre}',
                    style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                Text(d.optionADescription, style: const TextStyle(color: Colors.white70)),
                Text('+ ${d.optionAAvantage}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                Text('- ${d.optionARisque}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                const SizedBox(height: 12),
                Text('Option B : ${d.optionBTitre}',
                    style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                Text(d.optionBDescription, style: const TextStyle(color: Colors.white70)),
                Text('+ ${d.optionBAvantage}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                Text('- ${d.optionBRisque}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                const SizedBox(height: 12),
                Text('Option C : ${d.optionCTitre}',
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                Text(d.optionCDescription, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

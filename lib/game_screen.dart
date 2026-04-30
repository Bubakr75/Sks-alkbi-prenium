import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sks_alibi/models/scenario_model.dart';
import 'package:sks_alibi/screens/carte_joueur_screen.dart';

class GameScreen extends StatefulWidget {
  final String code;
  final String playerName;

  const GameScreen({super.key, required this.code, required this.playerName});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Carte? _maCarte;
  String _titreScenario = '';
  String _introScenario = '';
  Map<int, String> _slotToName = {};
  List<EvenementDebat> _evenements = [];
  DateTime? _gameStartedAt;
  bool _isLoading = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _chargerMaCarte();
  }

  Future<void> _chargerMaCarte() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _isLoading = false;
          _erreur = 'Utilisateur non connecte';
        });
        return;
      }

      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.code)
          .get();

      if (!roomDoc.exists) {
        setState(() {
          _isLoading = false;
          _erreur = 'Salon introuvable';
        });
        return;
      }

      final scenarioId = roomDoc.data()?['scenarioId'] as String?;
      if (scenarioId == null || scenarioId.isEmpty) {
        setState(() {
          _isLoading = false;
          _erreur = 'Aucun scenario assigne au salon';
        });
        return;
      }

      final gameStartTs = roomDoc.data()?['gameStartedAt'];
      DateTime? gameStartedAt;
      if (gameStartTs is Timestamp) {
        gameStartedAt = gameStartTs.toDate();
      }

      final scenarioDoc = await FirebaseFirestore.instance
          .collection('scenarios')
          .doc(scenarioId)
          .get();
      final titre = scenarioDoc.data()?['titre'] as String? ?? 'Scenario';
      final intro = scenarioDoc.data()?['intro'] as String? ?? '';

      final evenementsRaw = scenarioDoc.data()?['evenements'] as List<dynamic>? ?? [];
      final evenements = evenementsRaw
          .map((e) => EvenementDebat.fromMap(e as Map<String, dynamic>))
          .toList();

      final playersSnap = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.code)
          .collection('players')
          .get();

      final Map<int, String> slotToName = {};
      for (final p in playersSnap.docs) {
        final data = p.data();
        final carte = data['carte'] as Map<String, dynamic>?;
        final slot = carte?['slot'] as int?;
        final name = data['name'] as String? ?? '???';
        if (slot != null) {
          slotToName[slot] = name;
        }
      }

      final playerDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.code)
          .collection('players')
          .doc(uid)
          .get();

      final carteData = playerDoc.data()?['carte'] as Map<String, dynamic>?;
      if (carteData == null) {
        setState(() {
          _isLoading = false;
          _erreur = 'Aucune carte trouvee. La partie n a peut-etre pas demarre.';
        });
        return;
      }

      final carte = Carte.fromMap(carteData);

      setState(() {
        _maCarte = carte;
        _titreScenario = titre;
        _introScenario = intro;
        _slotToName = slotToName;
        _evenements = evenements;
        _gameStartedAt = gameStartedAt;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _erreur = 'Erreur : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 24),
              Text(
                'Distribution des cartes...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_erreur != null || _maCarte == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Text('Salon ${widget.code}'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  _erreur ?? 'Carte introuvable',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _chargerMaCarte,
                  child: const Text('Reessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CarteJoueurScreen(
      carte: _maCarte!,
      prenomJoueur: widget.playerName,
      titreScenario: _titreScenario,
      code: widget.code,
      introScenario: _introScenario,
      slotToName: _slotToName,
      evenements: _evenements,
      gameStartedAt: _gameStartedAt,
    );
  }
}

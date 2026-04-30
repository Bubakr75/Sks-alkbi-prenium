import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'game_screen.dart';
import 'services/scenario_service.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _createRoom() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre ton prenom !')),
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
        'status': 'waiting',
        'scenarioId': 'penalty_manque',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(code)
          .collection('players')
          .doc(uid)
          .set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'isHost': true,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(
              code: code,
              playerName: _nameController.text.trim(),
              isHost: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Creer un salon'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏠', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Ton prenom',
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white38),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Creer le salon',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LobbyScreen extends StatefulWidget {
  final String code;
  final String playerName;
  final bool isHost;

  const LobbyScreen({
    super.key,
    required this.code,
    required this.playerName,
    required this.isHost,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool _isStarting = false;

  Future<void> _startGame() async {
    setState(() => _isStarting = true);

    try {
      // 1. Recuperer la liste des joueurs du salon
      final playersSnap = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.code)
          .collection('players')
          .get();

      final players = playersSnap.docs;

      // 2. Charger le scenario
      final service = ScenarioService();
      final scenario = await service.chargerScenario('penalty_manque');

      if (scenario == null) {
        throw Exception('Scenario introuvable');
      }

      // 3. Verifier le nombre de joueurs
      if (players.length < scenario.minJoueurs ||
          players.length > scenario.maxJoueurs) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Il faut entre ${scenario.minJoueurs} et ${scenario.maxJoueurs} joueurs (actuel : ${players.length})',
              ),
            ),
          );
        }
        setState(() => _isStarting = false);
        return;
      }

      // 4. Construire la liste des JoueurInfo
      final joueurs = players.map((doc) {
        final data = doc.data();
        return JoueurInfo(
          id: data['uid'] as String,
          prenom: data['name'] as String,
        );
      }).toList();

      // 5. Distribuer les cartes (melange aleatoire + personnalisation)
      final cartesParJoueur = service.distribuerCartes(
        scenario: scenario,
        joueurs: joueurs,
      );

      // 6. Sauvegarder chaque carte sous le joueur correspondant
      for (final joueur in joueurs) {
        final carte = cartesParJoueur[joueur.id]!;
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.code)
            .collection('players')
            .doc(joueur.id)
            .update({
          'carte': carte.toMap(),
          'roleKey': carte.role,
        });
      }

      // 7. Passer le statut a "playing"
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.code)
          .update({'status': 'playing', 'gameStartedAt': FieldValue.serverTimestamp()});

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }

    if (mounted) {
      setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Salon'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Code du salon :', style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              widget.code,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Partage ce code avec tes amis !',
              style: TextStyle(color: Colors.green, fontSize: 14),
            ),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Joueurs connectes :',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.code)
                    .collection('players')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.green));
                  }
                  final players = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index].data() as Map<String, dynamic>;
                      final isPlayerHost = player['isHost'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPlayerHost ? Colors.green : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              isPlayerHost ? '👑' : '🎭',
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              player['name'] ?? 'Joueur',
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                            ),
                            if (isPlayerHost)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  'Hote',
                                  style: TextStyle(color: Colors.green, fontSize: 12),
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
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.code)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final status = (snapshot.data!.data() as Map<String, dynamic>)['status'];
                  if (status == 'playing') {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GameScreen(
                            code: widget.code,
                            playerName: widget.playerName,
                          ),
                        ),
                      );
                    });
                  }
                }
                return const SizedBox.shrink();
              },
            ),
            if (widget.isHost) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isStarting ? null : _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isStarting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Lancer la partie !',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


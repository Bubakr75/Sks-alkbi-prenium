import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DefisSecretsScreen extends StatefulWidget {
  final String code;
  final String playerName;

  const DefisSecretsScreen({
    super.key,
    required this.code,
    required this.playerName,
  });

  @override
  State<DefisSecretsScreen> createState() => _DefisSecretsScreenState();
}

class _DefisSecretsScreenState extends State<DefisSecretsScreen> {
  bool _isLoading = true;
  bool _defiRevealed = false;
  Map<String, dynamic> _monDefi = {};
  String _myUid = '';

  static const List<Map<String, dynamic>> _tousLesDefis = [
    {
      'id': 'defi_1',
      'texte': 'Défends un joueur que tu es censé accuser... puis retourne-toi contre lui à la fin du débat.',
      'pointsReussi': 5,
      'pointsEchec': -3,
    },
    {
      'id': 'defi_2',
      'texte': 'Fais avouer son secret à un autre joueur sans jamais le lui demander directement.',
      'pointsReussi': 4,
      'pointsEchec': -2,
    },
    {
      'id': 'defi_3',
      'texte': 'Pose à ta cible une question qui la met mal à l\'aise. Tu sauras que ça a marché si elle hésite à répondre.',
      'pointsReussi': 3,
      'pointsEchec': -1,
    },
    {
      'id': 'defi_4',
      'texte': 'Amène un joueur à contredire ce qu\'il a dit précédemment dans le débat.',
      'pointsReussi': 4,
      'pointsEchec': -2,
    },
    {
      'id': 'defi_5',
      'texte': 'Protège secrètement l\'enquêteur. Si personne ne vote contre lui à la fin, tu gagnes.',
      'pointsReussi': 5,
      'pointsEchec': -3,
    },
    {
      'id': 'defi_6',
      'texte': 'Accuse quelqu\'un avec une telle conviction que les autres commencent à te soupçonner toi-même.',
      'pointsReussi': 4,
      'pointsEchec': -2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _chargerOuAttribuerDefi();
  }

  Future<void> _chargerOuAttribuerDefi() async {
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.code);
    final roomSnap = await roomRef.get();
    final roomData = roomSnap.data() ?? {};
    final manche = roomData['manche'] as int? ?? 1;
    final mancheKey = 'manche_$manche';

    // Vérifier si un défi est déjà attribué
    final defisAttribues = (roomData['defisAttribues'] ?? {}) as Map<String, dynamic>;
    final defisM = (defisAttribues[mancheKey] ?? {}) as Map<String, dynamic>;

    if (defisM.containsKey(_myUid)) {
      setState(() {
        _monDefi = defisM[_myUid] as Map<String, dynamic>;
        _isLoading = false;
      });
      return;
    }

    // Attribuer un défi aléatoire non encore utilisé
    final defisUtilises = defisM.values
        .map((d) => (d as Map<String, dynamic>)['id'] as String)
        .toList();

    final defisDisponibles = _tousLesDefis
        .where((d) => !defisUtilises.contains(d['id']))
        .toList();

    if (defisDisponibles.isEmpty) {
      // Tous les défis utilisés — on recommence
      defisDisponibles.addAll(_tousLesDefis);
    }

    defisDisponibles.shuffle();
    final defiChoisi = defisDisponibles.first;

    await roomRef.update({
      'defisAttribues.$mancheKey.$_myUid': defiChoisi,
    });

    setState(() {
      _monDefi = defiChoisi;
      _isLoading = false;
    });
  }

  Future<void> _validerReussite(bool reussi) async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.code);
    final roomSnap = await roomRef.get();
    final manche = roomSnap.data()?['manche'] as int? ?? 1;
    final mancheKey = 'manche_$manche';
    final points = reussi
        ? _monDefi['pointsReussi'] as int
        : _monDefi['pointsEchec'] as int;

    await roomRef.update({
      'defisResultats.$mancheKey.$_myUid': {
        'defiId': _monDefi['id'],
        'reussi': reussi,
        'points': points,
      },
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reussi
                ? '🎉 Défi réussi ! +$points points'
                : '❌ Défi échoué... $points points',
          ),
          backgroundColor: reussi ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: Colors.purple)),
      );
    }

    final pointsReussi = _monDefi['pointsReussi'] as int? ?? 0;
    final pointsEchec = _monDefi['pointsEchec'] as int? ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Ton Défi Secret'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.4),
                    Colors.deepPurple.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple, width: 2),
              ),
              child: Column(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 50)),
                  const SizedBox(height: 12),
                  const Text(
                    'DÉFI SECRET',
                    style: TextStyle(
                      color: Colors.purple,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Accomplis ce défi pendant le débat\nsans te faire repérer !',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // DÉFI (cliquable pour révéler)
            GestureDetector(
              onTap: () => setState(() => _defiRevealed = !_defiRevealed),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _defiRevealed
                      ? Colors.purple.withValues(alpha: 0.2)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _defiRevealed ? Colors.purple : Colors.white38,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _defiRevealed ? Icons.lock_open : Icons.lock,
                          color: Colors.purple,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _defiRevealed ? 'TON DÉFI' : 'APPUIE POUR VOIR TON DÉFI',
                          style: const TextStyle(
                            color: Colors.purple,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    if (_defiRevealed) ...[
                      const SizedBox(height: 16),
                      Text(
                        _monDefi['texte'] as String? ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Text(
                              '✅ Réussi : +$pointsReussi pts',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Text(
                              '❌ Échoué : $pointsEchec pts',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // BOUTONS RÉSULTAT (après le débat)
            const Text(
              'APRÈS LE DÉBAT — As-tu réussi ton défi ?',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _validerReussite(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '✅ Réussi !',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _validerReussite(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '❌ Échoué',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

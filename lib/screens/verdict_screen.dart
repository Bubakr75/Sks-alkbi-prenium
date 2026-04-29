import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerdictScreen extends StatefulWidget {
  final String code;
  final String playerName;

  const VerdictScreen({super.key, required this.code, required this.playerName});

  @override
  State<VerdictScreen> createState() => _VerdictScreenState();
}

class _VerdictScreenState extends State<VerdictScreen> {
  bool _isLoading = true;
  String? _erreur;

  String _coupableUid = '';
  String _coupableName = '';
  String _coupableRole = '';

  List<Map<String, dynamic>> _votes = [];
  Map<String, String> _playerNames = {};
  Map<String, String> _playerRoles = {};
  Map<String, int> _voteCount = {};
  String _accuseUid = '';
  String _accuseName = '';

  int _myPoints = 0;
  String _myUid = '';
  String _myVoteTarget = '';

  @override
  void initState() {
    super.initState();
    _calculerVerdict();
  }

  Future<void> _calculerVerdict() async {
    try {
      _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

      final playersSnap = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.code)
          .collection('players')
          .get();

      for (final p in playersSnap.docs) {
        final data = p.data();
        final uid = data['uid'] as String? ?? p.id;
        final name = data['name'] as String? ?? '???';
        final carte = data['carte'] as Map<String, dynamic>?;
        final role = carte?['role'] as String? ?? '';

        _playerNames[uid] = name;
        _playerRoles[uid] = role;

        if (role == 'coupable') {
          _coupableUid = uid;
          _coupableName = name;
          _coupableRole = carte?['roleDansHistoire'] as String? ?? 'Le Coupable';
        }
      }

      final votesSnap = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.code)
          .collection('votes')
          .get();

      for (final v in votesSnap.docs) {
        final data = v.data();
        final voterUid = data['voterUid'] as String? ?? '';
        final voterName = data['voterName'] as String? ?? '???';
        final targetUid = data['targetUid'] as String? ?? '';

        _votes.add({
          'voterUid': voterUid,
          'voterName': voterName,
          'targetUid': targetUid,
          'targetName': _playerNames[targetUid] ?? '???',
        });

        _voteCount[targetUid] = (_voteCount[targetUid] ?? 0) + 1;

        if (voterUid == _myUid) {
          _myVoteTarget = targetUid;
        }
      }

      if (_voteCount.isNotEmpty) {
        final sorted = _voteCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        _accuseUid = sorted.first.key;
        _accuseName = _playerNames[_accuseUid] ?? '???';
      }

      _calculerMesPoints();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _erreur = 'Erreur : $e';
      });
    }
  }

  void _calculerMesPoints() {
    final isCoupableDemasque = _accuseUid == _coupableUid;
    final maRole = _playerRoles[_myUid] ?? '';

    if (maRole == 'coupable') {
      _myPoints = isCoupableDemasque ? -2 : 5;
    } else {
      if (_myVoteTarget == _coupableUid) {
        _myPoints = 3;
      } else {
        _myPoints = 0;
      }
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
              CircularProgressIndicator(color: Colors.amber),
              SizedBox(height: 24),
              Text(
                'Calcul du verdict...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_erreur != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              _erreur!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isCoupableDemasque = _accuseUid == _coupableUid;
    final maRole = _playerRoles[_myUid] ?? '';
    final jeSuisCoupable = maRole == 'coupable';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('VERDICT'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCoupableDemasque
                      ? [Colors.green.shade700, Colors.green.shade900]
                      : [Colors.red.shade700, Colors.red.shade900],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    isCoupableDemasque ? Icons.gavel : Icons.warning,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isCoupableDemasque
                        ? 'COUPABLE DEMASQUE !'
                        : 'LE COUPABLE A ECHAPPE !',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Le coupable etait :',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_coupableName ($_coupableRole)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Column(
                children: [
                  const Text(
                    'TES POINTS',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _myPoints >= 0 ? '+$_myPoints pts' : '$_myPoints pts',
                    style: TextStyle(
                      color: _myPoints >= 0 ? Colors.green : Colors.red,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getReasonText(jeSuisCoupable, isCoupableDemasque),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Recapitulatif des votes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._votes.map((v) => Card(
                  color: const Color(0xFF2A2A3E),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.how_to_vote,
                        color: Colors.purple),
                    title: Text(
                      '${v['voterName']} a vote contre ${v['targetName']}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: v['targetUid'] == _coupableUid
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.cancel, color: Colors.red),
                  ),
                )),
            const SizedBox(height: 20),
            const Text(
              'Tous les roles',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._playerNames.entries.map((e) {
              final uid = e.key;
              final name = e.value;
              final role = _playerRoles[uid] ?? '???';
              final isCoup = role == 'coupable';
              return Card(
                color: isCoup
                    ? Colors.red.withValues(alpha: 0.2)
                    : const Color(0xFF2A2A3E),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    isCoup ? Icons.dangerous : Icons.person,
                    color: isCoup ? Colors.red : Colors.green,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: isCoup ? Colors.red : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'RETOUR A L ACCUEIL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getReasonText(bool jeSuisCoupable, bool isDemasque) {
    if (jeSuisCoupable) {
      return isDemasque
          ? 'Tu as ete demasque ! (-2 pts)'
          : 'Tu as survecu au vote ! (+5 pts)';
    } else {
      if (_myVoteTarget == _coupableUid) {
        return 'Tu as devine le coupable ! (+3 pts)';
      } else {
        return 'Tu as vote pour la mauvaise personne (0 pt)';
      }
    }
  }
}

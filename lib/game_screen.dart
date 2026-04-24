import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameScreen extends StatefulWidget {
  final String code;
  final String playerName;

  const GameScreen({super.key, required this.code, required this.playerName});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String _role = '';
  String _mission = '';
  bool _roleRevealed = false;

  final List<Map<String, String>> _roles = [
    {
      'role': 'Le Coupable',
      'emoji': '😈',
      'mission': 'Tu es le coupable ! Mens, esquive et fais accuser quelquun dautre.',
    },
    {
      'role': 'Le Temoin',
      'emoji': '👀',
      'mission': 'Tu as tout vu ! Trouve le coupable sans te faire eliminer.',
    },
    {
      'role': 'Le Complice',
      'emoji': '🤝',
      'mission': 'Tu protèges le coupable ! Aide-le sans te faire reperer.',
    },
    {
      'role': 'L Innocent',
      'emoji': '😇',
      'mission': 'Tu nes coupable de rien ! Prouve ton innocence et trouve le vrai coupable.',
    },
    {
      'role': 'Le Provocateur',
      'emoji': '😏',
      'mission': 'Seme le chaos ! Fais douter tout le monde de tout le monde.',
    },
    {
      'role': 'Le Detektiv',
      'emoji': '🕵️',
      'mission': 'Analyse, observe et demasque le coupable avant le vote final.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMyRole();
  }

  Future<void> _loadMyRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final playerDoc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.code)
        .collection('players')
        .doc(uid)
        .get();

    final roleKey = playerDoc.data()?['roleKey'] ?? '';

    if (roleKey.isNotEmpty) {
      final role = _roles.firstWhere(
        (r) => r['role'] == roleKey,
        orElse: () => _roles[0],
      );
      setState(() {
        _role = role['role']!;
        _mission = role['mission']!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('Salon ${widget.code}'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ton role secret',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => setState(() => _roleRevealed = !_roleRevealed),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _roleRevealed ? Colors.green.withOpacity(0.15) : Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _roleRevealed ? Colors.green : Colors.white24,
                    width: 2,
                  ),
                ),
                child: _role.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.green),
                      )
                    : _roleRevealed
                        ? Column(
                            children: [
                              Text(
                                _roles.firstWhere((r) => r['role'] == _role)['emoji']!,
                                style: const TextStyle(fontSize: 60),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _role,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _mission,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            children: [
                              Text('🎭', style: TextStyle(fontSize: 60)),
                              SizedBox(height: 16),
                              Text(
                                'Appuie pour voir ton role',
                                style: TextStyle(color: Colors.white54, fontSize: 18),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Assure-toi que personne ne regarde !',
                                style: TextStyle(color: Colors.white38, fontSize: 14),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 32),
            if (_roleRevealed)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => setState(() => _roleRevealed = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Cacher mon role', style: TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

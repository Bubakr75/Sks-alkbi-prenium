import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/test_mode_service.dart';
import 'questionnaire_screen.dart';

class TestModeSetupScreen extends StatefulWidget {
  const TestModeSetupScreen({super.key});

  @override
  State<TestModeSetupScreen> createState() => _TestModeSetupScreenState();
}

class _TestModeSetupScreenState extends State<TestModeSetupScreen> {
  final _nomController = TextEditingController(text: 'Moi');
  String _themeChoisi = 'trahison';
  bool _isLoading = false;

  static const _themes = [
    {'id': 'trahison', 'label': 'Trahison', 'emoji': '🗡️'},
    {'id': 'vol',      'label': 'Vol',       'emoji': '💰'},
    {'id': 'tromperie','label': 'Tromperie', 'emoji': '🎭'},
  ];

  Future<void> _lancerModeTest() async {
    setState(() => _isLoading = true);
    try {
      final nom = _nomController.text.trim().isEmpty ? 'Moi' : _nomController.text.trim();
      final result = await TestModeService.creerSalonTest(themeId: _themeChoisi, monNom: nom);
      final code = result['code']!;
      final iaUids = result['iaUids']!.split(',');
      final myUid = FirebaseAuth.instance.currentUser!.uid;
      final tousLesUids = [myUid, ...iaUids];

      await FirebaseFirestore.instance.collection('rooms').doc(code).update({
        'status': 'questionnaire',
        'manche': 1,
      });

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => TestModeQuestionnaireWrapper(
            code: code,
            playerName: nom,
            manche: 1,
            iaUids: iaUids,
            tousLesUids: tousLesUids,
          ),
        ));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('⚠️ MODE TEST', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Text('🤖', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '2 joueurs IA simulés. Leurs réponses sont automatiques. Tu joues seul !',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text('TON NOM', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 2)),
              const SizedBox(height: 8),
              TextField(
                controller: _nomController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.orange)),
                  hintText: 'Ton prénom',
                  hintStyle: const TextStyle(color: Colors.white24),
                ),
              ),
              const SizedBox(height: 24),
              const Text('THÈME', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 2)),
              const SizedBox(height: 10),
              Row(
                children: _themes.map((t) {
                  final isSelected = _themeChoisi == t['id'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _themeChoisi = t['id']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orange.withValues(alpha: 0.2) : Colors.white10,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isSelected ? Colors.orange : Colors.white12, width: isSelected ? 2 : 1),
                        ),
                        child: Column(
                          children: [
                            Text(t['emoji']!, style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(t['label']!, style: TextStyle(color: isSelected ? Colors.orange : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _isLoading ? null : _lancerModeTest,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.orange, Color(0xFFFF6F00)]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('🚀 Lancer le test', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TestModeQuestionnaireWrapper extends StatefulWidget {
  final String code;
  final String playerName;
  final int manche;
  final List<String> iaUids;
  final List<String> tousLesUids;

  const TestModeQuestionnaireWrapper({
    super.key,
    required this.code,
    required this.playerName,
    required this.manche,
    required this.iaUids,
    required this.tousLesUids,
  });

  @override
  State<TestModeQuestionnaireWrapper> createState() => _TestModeQuestionnaireWrapperState();
}

class _TestModeQuestionnaireWrapperState extends State<TestModeQuestionnaireWrapper> {
  bool _iaSimulated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), _simulerIA);
  }

  Future<void> _simulerIA() async {
    if (_iaSimulated) return;
    _iaSimulated = true;
    final questions = [
      {'trait': 'calme'}, {'trait': 'nerveux'}, {'trait': 'patient'},
      {'trait': 'zen'}, {'trait': 'flemmard'}, {'trait': 'procrastinateur'},
      {'trait': 'retardataire'}, {'trait': 'negociateur'}, {'trait': 'manipulateur'},
      {'trait': 'voyeur'},
    ];
    await TestModeService.simulerQuestionnaire(
      code: widget.code,
      iaUids: widget.iaUids,
      tousLesUids: widget.tousLesUids,
      manche: widget.manche,
      questions: questions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return QuestionnaireScreen(
      code: widget.code,
      playerName: widget.playerName,
      manche: widget.manche,
    );
  }
}

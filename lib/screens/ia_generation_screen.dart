import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../game_screen.dart';
import 'vote_predictif_screen.dart';

class IaGenerationScreen extends StatefulWidget {
  final String code;
  final String playerName;
  final int manche;
  final Map<String, Map<String, double>> profils;
  final Map<String, String> noms;

  const IaGenerationScreen({
    super.key,
    required this.code,
    required this.playerName,
    required this.manche,
    required this.profils,
    required this.noms,
  });

  @override
  State<IaGenerationScreen> createState() => _IaGenerationScreenState();
}

class _IaGenerationScreenState extends State<IaGenerationScreen> {
  String _statut = 'Préparation de la requête...';
  bool _erreur = false;
  bool _navigated = false;

  static const String _apiKey = 'AIzaSyB2-EEc6HBg3Amc8cfP8vun9RO64qDHHx4';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  @override
  void initState() {
    super.initState();
    _generer();
  }

  String _buildPrompt() {
    final themes = ['Trahison', 'Vol', 'Tromperie'];
    themes.shuffle();
    final theme = themes.first;

    final profilsTexte = widget.noms.entries.map((e) {
      final uid = e.key;
      final nom = e.value;
      final traits = widget.profils[uid] ?? {};
      final sorted = traits.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top3 = sorted.take(3).map((t) =>
        '${t.key.replaceAll("_", " ")} (${t.value.toStringAsFixed(0)}%)'
      ).join(', ');
      return '$nom → $top3';
    }).join('\n');

    final joueurs = widget.noms.values.join(', ');

    return '''
Tu es le narrateur d'un jeu social de déduction psychologique.
Génère une histoire ULTRA-COURTE et ${widget.noms.length} cartes de rôle personnalisées.

THÈME : $theme
JOUEURS : $joueurs

PROFILS PSYCHOLOGIQUES (basés sur votes du groupe) :
$profilsTexte

RÈGLES ABSOLUES :
- Histoire : 60-80 mots maximum, lisible en 30 secondes
- Chaque carte : 8 lignes maximum
- Univers 100% original (aucun film, aucun événement réel)
- L'histoire DOIT refléter les profils : si un joueur est perçu comme manipulateur, place-le dans une situation compromettante
- Tout le monde a un petit secret, même les innocents
- 1 seul coupable, 1 enquêteur (avec indice concret), 1 malchanceux (se croit innocent), reste = innocents

RÉPONDS UNIQUEMENT EN JSON STRICT (aucun texte avant ou après) :
{
  "theme": "$theme",
  "histoire": "...",
  "roles": {
    "NOM_JOUEUR": {
      "role": "coupable|enquêteur|malchanceux|innocent",
      "qui_tu_es": "1 ligne",
      "defend": "2-3 lignes",
      "cache": "2-3 lignes",
      "accuse": "NOM du joueur à accuser",
      "defi": "1 ligne",
      "indice": "indice concret (enquêteur uniquement, sinon null)"
    }
  }
}
''';
  }

  Future<void> _generer() async {
    try {
      setState(() => _statut = 'Connexion à l\'IA...');

      final prompt = _buildPrompt();

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 2000,
          },
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        throw Exception('Erreur API : ${response.statusCode}');
      }

      setState(() => _statut = 'Histoire générée ! Traitement...');

      final data = jsonDecode(response.body);
      final raw = data['candidates'][0]['content']['parts'][0]['text'] as String;
      final cleaned = raw
          .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'```\s*', multiLine: true), '')
          .trim();

      final Map<String, dynamic> result = jsonDecode(cleaned);
      final histoire = result['histoire'] as String;
      final theme = result['theme'] as String;
      final roles = result['roles'] as Map<String, dynamic>;

      setState(() => _statut = 'Sauvegarde des cartes...');

      final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.code);

      // Sauvegarder l'histoire dans Firestore
      await roomRef.update({
        'iaHistoire': histoire,
        'iaTheme': theme,
        'manche': widget.manche,
      });

      // Mapper noms -> uids
      final Map<String, String> nomVersUid = {};
      widget.noms.forEach((uid, nom) => nomVersUid[nom] = uid);

      // Attribuer les rôles aux joueurs et sauvegarder les cartes
      final batch = FirebaseFirestore.instance.batch();
      roles.forEach((nomJoueur, carteData) {
        final uid = nomVersUid[nomJoueur];
        if (uid == null) return;
        final carte = carteData as Map<String, dynamic>;
        batch.update(
          roomRef.collection('players').doc(uid),
          {
            'carte': {
              'role': carte['role'],
              'roleDansHistoire': carte['qui_tu_es'],
              'secretConnu': carte['defend'],
              'secretInavouable': carte['cache'],
              'accuse': carte['accuse'],
              'defi': carte['defi'],
              'indice': carte['indice'],
            },
            'roleKey': carte['role'],
          },
        );
      });
      await batch.commit();

      // Passer le statut à "playing"
      await roomRef.update({
        'status': 'playing',
        'gameStartedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _statut = 'Tout est prêt ! Lancement...');

      if (mounted && !_navigated) {
        _navigated = true;
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VotePredictifScreen(code: widget.code, playerName: widget.playerName,),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _statut = 'Erreur : $e';
        _erreur = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🤖', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 32),
                const Text(
                  'L\'IA crée votre histoire',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _statut,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (!_erreur)
                  const CircularProgressIndicator(color: Colors.green)
                else ...[
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _erreur = false;
                        _statut = 'Nouvelle tentative...';
                      });
                      _generer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      '🔄 Réessayer',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}




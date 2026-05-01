import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'create_room_screen.dart';
import 'screens/choix_scenario_screen.dart';
import 'join_room_screen.dart';
import 'utils/seed_scenarios.dart';
import 'services/scenario_service.dart';
import 'screens/carte_joueur_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await seedScenarios();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKS Alibi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _testerCarte(BuildContext context) async {
    // Afficher un loader pendant le chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final service = ScenarioService();

      // Charger le scenario depuis Firestore
      final scenario = await service.chargerScenario('penalty_manque');

      if (scenario == null) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scenario introuvable !')),
          );
        }
        return;
      }

      // Simuler 3 joueurs de test
      final joueurs = [
        JoueurInfo(id: 'boss123', prenom: 'Boss'),
        JoueurInfo(id: 'boub456', prenom: 'Boubakar'),
        JoueurInfo(id: 'isma789', prenom: 'Ismael'),
      ];

      // Distribuer les cartes (melange aleatoire)
      final cartesParJoueur = service.distribuerCartes(
        scenario: scenario,
        joueurs: joueurs,
      );

      // Recuperer la carte de "Boss" pour l afficher
      final maCarte = cartesParJoueur['boss123']!;

      if (context.mounted) {
        Navigator.pop(context); // Fermer le loader

        // Naviguer vers l ecran de carte
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CarteJoueurScreen(
              carte: maCarte,
              prenomJoueur: 'Boss',
              titreScenario: scenario.titre,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎭', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              const Text(
                'SKS : Alibi',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Le jeu du bluff et de l\'enquete',
                style: TextStyle(fontSize: 16, color: Colors.white54),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChoixScenarioScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '🏠 Creer un salon',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JoinRoomScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '🔑 Rejoindre un salon',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _testerCarte(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '🧪 TESTER ma carte',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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


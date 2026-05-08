import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/choix_scenario_screen.dart';
import 'screens/test_mode_screen.dart';
import 'join_room_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKS Alibi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // LOGO
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2D5016), Color(0xFF1A3A0A)],
                  ),
                  boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 40)],
                ),
                child: const Center(child: Text('🎭', style: TextStyle(fontSize: 56))),
              ),
              const SizedBox(height: 28),
              const Text(
                'SKS : Alibi',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              const Text(
                'Le jeu du bluff et de l\'enquête',
                style: TextStyle(fontSize: 15, color: Colors.white38),
              ),

              const Spacer(flex: 2),

              // BOUTON CRÉER
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChoixScenarioScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2D7A1F), Color(0xFF1A5C10)]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🏠', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 10),
                      Text('Créer un salon', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // BOUTON REJOINDRE
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinRoomScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🔑', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 10),
                      Text('Rejoindre un salon', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ⚠️ BOUTON MODE TEST — A SUPPRIMER AVANT PRODUCTION
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TestModeSetupScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.4), style: BorderStyle.solid),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🤖', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Text('Mode Test (solo + IA)', style: TextStyle(color: Colors.orange, fontSize: 15, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Text('⚠️', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // VERSION
              const Text('v2.0 — Beta', style: TextStyle(color: Colors.white12, fontSize: 12)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

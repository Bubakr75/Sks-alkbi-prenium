import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ⚠️ MODE TEST UNIQUEMENT — A SUPPRIMER AVANT PRODUCTION
class TestModeService {
  static const List<String> _nomsIA = ['Alex_IA', 'Jordan_IA', 'Sam_IA'];
  static final _rng = Random();

  // Génère un code salon aléatoire
  static String _genererCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  // Crée un salon test avec 2 joueurs IA + toi
  static Future<Map<String, String>> creerSalonTest({
    required String themeId,
    required String monNom,
  }) async {
    // Auth anonyme
    await FirebaseAuth.instance.signInAnonymously();
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final code = _genererCode();
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(code);

    // Créer le salon
    await roomRef.set({
      'code': code,
      'hostUid': myUid,
      'status': 'waiting',
      'scenarioId': themeId,
      'totalManches': 3,
      'manche': 0,
      'votesParManche': {},
      'coupablesParManche': [],
      'createdAt': FieldValue.serverTimestamp(),
      'modeTest': true, // ⚠️ flag test
    });

    // Ajouter le vrai joueur (toi)
    await roomRef.collection('players').doc(myUid).set({
      'name': monNom,
      'uid': myUid,
      'isIA': false,
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // Ajouter les joueurs IA
    final iaUids = <String>[];
    for (int i = 0; i < 2; i++) {
      final iaUid = 'ia_bot_${_rng.nextInt(99999)}';
      iaUids.add(iaUid);
      await roomRef.collection('players').doc(iaUid).set({
        'name': _nomsIA[i],
        'uid': iaUid,
        'isIA': true,
        'joinedAt': FieldValue.serverTimestamp(),
      });
    }

    return {'code': code, 'myUid': myUid, 'iaUids': iaUids.join(',')};
  }

  // Simule les réponses IA au questionnaire
  static Future<void> simulerQuestionnaire({
    required String code,
    required List<String> iaUids,
    required List<String> tousLesUids,
    required int manche,
    required List<Map<String, String>> questions,
  }) async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(code);
    final mancheKey = 'manche_$manche';

    for (final iaUid in iaUids) {
      final Map<String, dynamic> reponses = {};
      for (final q in questions) {
        final trait = q['trait']!;
        // L'IA vote pour un joueur aléatoire (pas elle-même)
        final autresUids = tousLesUids.where((u) => u != iaUid).toList();
        if (autresUids.isNotEmpty) {
          final cible = autresUids[_rng.nextInt(autresUids.length)];
          reponses['questionnaire.$mancheKey.$iaUid.$trait'] = cible;
        }
      }
      // Batch update
      await roomRef.update(reponses);
      await roomRef.update({'questionnaireReady.$mancheKey.$iaUid': true});

      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  // Simule le vote prédictif des IA
  static Future<void> simulerVotePredictif({
    required String code,
    required List<String> iaUids,
    required List<String> tousLesUids,
    required int manche,
  }) async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(code);
    for (final iaUid in iaUids) {
      final autresUids = tousLesUids.where((u) => u != iaUid).toList();
      if (autresUids.isNotEmpty) {
        final cible = autresUids[_rng.nextInt(autresUids.length)];
        await roomRef.update({'votesPredictifs.manche_$manche.$iaUid': cible});
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  // Simule le vote final des IA
  static Future<void> simulerVoteFinal({
    required String code,
    required List<String> iaUids,
    required List<String> tousLesUids,
    required int manche,
  }) async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(code);
    for (final iaUid in iaUids) {
      final autresUids = tousLesUids.where((u) => u != iaUid).toList();
      if (autresUids.isNotEmpty) {
        final cible = autresUids[_rng.nextInt(autresUids.length)];
        await roomRef.update({'votesParManche.manche_$manche.$iaUid': cible});
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  // Supprime le salon test après usage
  static Future<void> nettoyerSalonTest(String code) async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(code);
    final players = await roomRef.collection('players').get();
    for (final p in players.docs) {
      await p.reference.delete();
    }
    await roomRef.delete();
  }
}


// lib/services/scenario_service.dart
//
// Service qui gere le chargement et la distribution des scenarios.

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sks_alibi/models/scenario_model.dart';

class ScenarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════
  // 1. CHARGER UN SCENARIO depuis Firestore
  // ═══════════════════════════════════════════════════════════
  Future<Scenario?> chargerScenario(String scenarioId) async {
    try {
      final doc = await _firestore.collection('scenarios').doc(scenarioId).get();
      if (!doc.exists) {
        // ignore: avoid_print
        print('Scenario "$scenarioId" introuvable dans Firestore.');
        return null;
      }
      return Scenario.fromFirestore(doc);
    } catch (e) {
      // ignore: avoid_print
      print('Erreur chargement scenario : $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 2. LISTER tous les scenarios disponibles
  // ═══════════════════════════════════════════════════════════
  Future<List<Scenario>> listerScenarios() async {
    try {
      final snapshot = await _firestore.collection('scenarios').get();
      return snapshot.docs.map((doc) => Scenario.fromFirestore(doc)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Erreur listage scenarios : $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 3. DISTRIBUER les cartes aux joueurs
  // ═══════════════════════════════════════════════════════════
  // Prend une liste de joueurs (avec leurs IDs et prenoms)
  // et leur attribue chacun une carte du scenario, de maniere aleatoire.
  // Retourne un Map { idJoueur -> Carte personnalisee }
  Map<String, Carte> distribuerCartes({
    required Scenario scenario,
    required List<JoueurInfo> joueurs,
  }) {
    if (joueurs.length < scenario.minJoueurs ||
        joueurs.length > scenario.maxJoueurs) {
      throw Exception(
        'Nombre de joueurs invalide : ${joueurs.length} '
        '(min: ${scenario.minJoueurs}, max: ${scenario.maxJoueurs})',
      );
    }

    // Melanger les cartes pour assignation aleatoire
    final cartesDispo = List<Carte>.from(scenario.cartes);
    cartesDispo.shuffle(Random());

    // Creer le mapping slot -> joueurInfo (qui a recu quelle carte)
    final Map<int, JoueurInfo> slotVersJoueur = {};
    final Map<String, Carte> resultat = {};

    for (int i = 0; i < joueurs.length; i++) {
      final joueur = joueurs[i];
      final carteOriginale = cartesDispo[i];
      slotVersJoueur[carteOriginale.slot] = joueur;
    }

    // Personnaliser chaque carte avec les vrais prenoms
    for (int i = 0; i < joueurs.length; i++) {
      final joueur = joueurs[i];
      final carteOriginale = cartesDispo[i];
      final cartePersonnalisee = _personnaliserCarte(
        carteOriginale,
        slotVersJoueur,
      );
      resultat[joueur.id] = cartePersonnalisee;
    }

    return resultat;
  }

  // ═══════════════════════════════════════════════════════════
  // 4. PERSONNALISER une carte (remplacer {joueur} par les vrais prenoms)
  // ═══════════════════════════════════════════════════════════
  Carte _personnaliserCarte(Carte carte, Map<int, JoueurInfo> slotVersJoueur) {
    return Carte(
      slot: carte.slot,
      role: carte.role,
      roleDansHistoire: carte.roleDansHistoire,
      secretInavouable: carte.secretInavouable,
      secretConnu: carte.secretConnu,
      munitions: carte.munitions
          .map((m) => _remplacerVariables(m, slotVersJoueur))
          .toList(),
      questions: carte.questions
          .map((q) => Question(
                cibleSlot: q.cibleSlot,
                texte: _remplacerVariables(q.texte, slotVersJoueur,
                    slotCible: q.cibleSlot),
              ))
          .toList(),
      accusations: carte.accusations
          .map((a) => Accusation(
                cibleSlot: a.cibleSlot,
                texte: _remplacerVariables(a.texte, slotVersJoueur,
                    slotCible: a.cibleSlot),
              ))
          .toList(),
      lienFort: Lien(
        cibleSlot: carte.lienFort.cibleSlot,
        description: _remplacerVariables(
          carte.lienFort.description,
          slotVersJoueur,
          slotCible: carte.lienFort.cibleSlot,
        ),
        avertissement: _remplacerVariables(
          carte.lienFort.avertissement,
          slotVersJoueur,
          slotCible: carte.lienFort.cibleSlot,
        ),
      ),
      observations: carte.observations
          .map((o) => Observation(
                cibleSlot: o.cibleSlot,
                texte: _remplacerVariables(o.texte, slotVersJoueur,
                    slotCible: o.cibleSlot),
              ))
          .toList(),
      temoignages: carte.temoignages,
      dilemme: Dilemme(
        optionATitre: carte.dilemme.optionATitre,
        optionADescription: _remplacerVariables(
            carte.dilemme.optionADescription, slotVersJoueur),
        optionAAvantage: _remplacerVariables(
            carte.dilemme.optionAAvantage, slotVersJoueur),
        optionARisque: _remplacerVariables(
            carte.dilemme.optionARisque, slotVersJoueur),
        optionBTitre: _remplacerVariables(
            carte.dilemme.optionBTitre, slotVersJoueur),
        optionBDescription: _remplacerVariables(
            carte.dilemme.optionBDescription, slotVersJoueur),
        optionBAvantage: _remplacerVariables(
            carte.dilemme.optionBAvantage, slotVersJoueur),
        optionBRisque: _remplacerVariables(
            carte.dilemme.optionBRisque, slotVersJoueur),
        optionCTitre: carte.dilemme.optionCTitre,
        optionCDescription: carte.dilemme.optionCDescription,
      ),
      missionSecrete: carte.missionSecrete != null
          ? _remplacerVariables(carte.missionSecrete!, slotVersJoueur)
          : null,
      reactionsEvenements: carte.reactionsEvenements
          .map((r) => ReactionEvenement(
                evenementId: r.evenementId,
                positionOfficielle: _remplacerVariables(
                    r.positionOfficielle, slotVersJoueur),
                explications: r.explications
                    .map((e) => _remplacerVariables(e, slotVersJoueur))
                    .toList(),
                opportuniteStrategique: r.opportuniteStrategique != null
                    ? _remplacerVariables(
                        r.opportuniteStrategique!, slotVersJoueur)
                    : null,
              ))
          .toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 5. REMPLACER les variables {joueur} dans un texte
  // ═══════════════════════════════════════════════════════════
  // Si slotCible est fourni, remplace {joueur} par le prenom du joueur
  // assigne a ce slot. Sinon, essaie de detecter automatiquement.
  String _remplacerVariables(
    String texte,
    Map<int, JoueurInfo> slotVersJoueur, {
    int? slotCible,
  }) {
    String resultat = texte;

    // Cas 1 : remplacer {joueur} simple par le prenom du slotCible
    if (slotCible != null && slotVersJoueur.containsKey(slotCible)) {
      resultat = resultat.replaceAll('{joueur}', slotVersJoueur[slotCible]!.prenom);
    }

    // Cas 2 : remplacer {joueur du SLOT X} par le prenom du slot X
    final regex = RegExp(r'\{joueur du SLOT (\d+)\}');
    resultat = resultat.replaceAllMapped(regex, (match) {
      final slot = int.parse(match.group(1)!);
      if (slotVersJoueur.containsKey(slot)) {
        return slotVersJoueur[slot]!.prenom;
      }
      return match.group(0)!;
    });

    return resultat;
  }
}

// ═══════════════════════════════════════════════════════════
// CLASSE UTILITAIRE : info d un joueur
// ═══════════════════════════════════════════════════════════

class JoueurInfo {
  final String id;       // ID unique du joueur (Firebase ou UUID)
  final String prenom;   // prenom affiche

  JoueurInfo({required this.id, required this.prenom});
}

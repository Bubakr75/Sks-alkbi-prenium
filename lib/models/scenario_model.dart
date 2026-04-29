import 'package:cloud_firestore/cloud_firestore.dart';

class Scenario {
  final String id;
  final String titre;
  final String theme;
  final String intro;
  final int minJoueurs;
  final int maxJoueurs;
  final List<Carte> cartes;
  final List<EvenementDebat> evenements;

  Scenario({
    required this.id,
    required this.titre,
    required this.theme,
    required this.intro,
    required this.minJoueurs,
    required this.maxJoueurs,
    required this.cartes,
    required this.evenements,
  });

  factory Scenario.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Scenario(
      id: doc.id,
      titre: data['titre'] ?? '',
      theme: data['theme'] ?? '',
      intro: data['intro'] ?? '',
      minJoueurs: data['minJoueurs'] ?? 2,
      maxJoueurs: data['maxJoueurs'] ?? 10,
      cartes: (data['cartes'] as List<dynamic>? ?? [])
          .map((c) => Carte.fromMap(c as Map<String, dynamic>))
          .toList(),
      evenements: (data['evenements'] as List<dynamic>? ?? [])
          .map((e) => EvenementDebat.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'theme': theme,
      'intro': intro,
      'minJoueurs': minJoueurs,
      'maxJoueurs': maxJoueurs,
      'cartes': cartes.map((c) => c.toMap()).toList(),
      'evenements': evenements.map((e) => e.toMap()).toList(),
    };
  }
}

class Carte {
  final int slot;
  final String role;
  final String roleDansHistoire;
  final String? secretInavouable;
  final String secretConnu;
  final List<String> munitions;
  final List<Question> questions;
  final List<Accusation> accusations;
  final Lien lienFort;
  final List<Observation> observations;
  final List<Temoignage> temoignages;
  final Dilemme dilemme;
  final String? missionSecrete;
  final List<ReactionEvenement> reactionsEvenements;

  Carte({
    required this.slot,
    required this.role,
    required this.roleDansHistoire,
    this.secretInavouable,
    required this.secretConnu,
    required this.munitions,
    required this.questions,
    required this.accusations,
    required this.lienFort,
    required this.observations,
    required this.temoignages,
    required this.dilemme,
    this.missionSecrete,
    required this.reactionsEvenements,
  });

  factory Carte.fromMap(Map<String, dynamic> map) {
    return Carte(
      slot: map['slot'] ?? 0,
      role: map['role'] ?? '',
      roleDansHistoire: map['roleDansHistoire'] ?? '',
      secretInavouable: map['secretInavouable'],
      secretConnu: map['secretConnu'] ?? '',
      munitions: List<String>.from(map['munitions'] ?? []),
      questions: (map['questions'] as List<dynamic>? ?? [])
          .map((q) => Question.fromMap(q as Map<String, dynamic>))
          .toList(),
      accusations: (map['accusations'] as List<dynamic>? ?? [])
          .map((a) => Accusation.fromMap(a as Map<String, dynamic>))
          .toList(),
      lienFort: Lien.fromMap(map['lienFort'] as Map<String, dynamic>? ?? {}),
      observations: (map['observations'] as List<dynamic>? ?? [])
          .map((o) => Observation.fromMap(o as Map<String, dynamic>))
          .toList(),
      temoignages: (map['temoignages'] as List<dynamic>? ?? [])
          .map((t) => Temoignage.fromMap(t as Map<String, dynamic>))
          .toList(),
      dilemme: Dilemme.fromMap(map['dilemme'] as Map<String, dynamic>? ?? {}),
      missionSecrete: map['missionSecrete'],
      reactionsEvenements: (map['reactionsEvenements'] as List<dynamic>? ?? [])
          .map((r) => ReactionEvenement.fromMap(r as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slot': slot,
      'role': role,
      'roleDansHistoire': roleDansHistoire,
      'secretInavouable': secretInavouable,
      'secretConnu': secretConnu,
      'munitions': munitions,
      'questions': questions.map((q) => q.toMap()).toList(),
      'accusations': accusations.map((a) => a.toMap()).toList(),
      'lienFort': lienFort.toMap(),
      'observations': observations.map((o) => o.toMap()).toList(),
      'temoignages': temoignages.map((t) => t.toMap()).toList(),
      'dilemme': dilemme.toMap(),
      'missionSecrete': missionSecrete,
      'reactionsEvenements': reactionsEvenements.map((r) => r.toMap()).toList(),
    };
  }
}

class Question {
  final int cibleSlot;
  final String texte;
  Question({required this.cibleSlot, required this.texte});
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(cibleSlot: map['cibleSlot'] ?? 0, texte: map['texte'] ?? '');
  }
  Map<String, dynamic> toMap() => {'cibleSlot': cibleSlot, 'texte': texte};
}

class Accusation {
  final int cibleSlot;
  final String texte;
  Accusation({required this.cibleSlot, required this.texte});
  factory Accusation.fromMap(Map<String, dynamic> map) {
    return Accusation(cibleSlot: map['cibleSlot'] ?? 0, texte: map['texte'] ?? '');
  }
  Map<String, dynamic> toMap() => {'cibleSlot': cibleSlot, 'texte': texte};
}

class Lien {
  final int cibleSlot;
  final String description;
  final String avertissement;
  Lien({required this.cibleSlot, required this.description, required this.avertissement});
  factory Lien.fromMap(Map<String, dynamic> map) {
    return Lien(
      cibleSlot: map['cibleSlot'] ?? 0,
      description: map['description'] ?? '',
      avertissement: map['avertissement'] ?? '',
    );
  }
  Map<String, dynamic> toMap() => {
        'cibleSlot': cibleSlot,
        'description': description,
        'avertissement': avertissement,
      };
}

class Observation {
  final int cibleSlot;
  final String texte;
  Observation({required this.cibleSlot, required this.texte});
  factory Observation.fromMap(Map<String, dynamic> map) {
    return Observation(cibleSlot: map['cibleSlot'] ?? 0, texte: map['texte'] ?? '');
  }
  Map<String, dynamic> toMap() => {'cibleSlot': cibleSlot, 'texte': texte};
}

class Temoignage {
  final int demandeurSlot;
  final String contexte;
  final String optionVerite;
  final int pointsVerite;
  final String optionEnfoncer;
  final int pointsEnfoncerReussi;
  final int pointsEnfoncerEchec;
  final String optionMentir;
  final int pointsMentirReussi;
  final int pointsMentirEchec;

  Temoignage({
    required this.demandeurSlot,
    required this.contexte,
    required this.optionVerite,
    required this.pointsVerite,
    required this.optionEnfoncer,
    required this.pointsEnfoncerReussi,
    required this.pointsEnfoncerEchec,
    required this.optionMentir,
    required this.pointsMentirReussi,
    required this.pointsMentirEchec,
  });

  factory Temoignage.fromMap(Map<String, dynamic> map) {
    return Temoignage(
      demandeurSlot: map['demandeurSlot'] ?? 0,
      contexte: map['contexte'] ?? '',
      optionVerite: map['optionVerite'] ?? '',
      pointsVerite: map['pointsVerite'] ?? 1,
      optionEnfoncer: map['optionEnfoncer'] ?? '',
      pointsEnfoncerReussi: map['pointsEnfoncerReussi'] ?? 3,
      pointsEnfoncerEchec: map['pointsEnfoncerEchec'] ?? -2,
      optionMentir: map['optionMentir'] ?? '',
      pointsMentirReussi: map['pointsMentirReussi'] ?? 2,
      pointsMentirEchec: map['pointsMentirEchec'] ?? -3,
    );
  }

  Map<String, dynamic> toMap() => {
        'demandeurSlot': demandeurSlot,
        'contexte': contexte,
        'optionVerite': optionVerite,
        'pointsVerite': pointsVerite,
        'optionEnfoncer': optionEnfoncer,
        'pointsEnfoncerReussi': pointsEnfoncerReussi,
        'pointsEnfoncerEchec': pointsEnfoncerEchec,
        'optionMentir': optionMentir,
        'pointsMentirReussi': pointsMentirReussi,
        'pointsMentirEchec': pointsMentirEchec,
      };
}

class Dilemme {
  final String optionATitre;
  final String optionADescription;
  final String optionAAvantage;
  final String optionARisque;
  final String optionBTitre;
  final String optionBDescription;
  final String optionBAvantage;
  final String optionBRisque;
  final String optionCTitre;
  final String optionCDescription;

  Dilemme({
    required this.optionATitre,
    required this.optionADescription,
    required this.optionAAvantage,
    required this.optionARisque,
    required this.optionBTitre,
    required this.optionBDescription,
    required this.optionBAvantage,
    required this.optionBRisque,
    required this.optionCTitre,
    required this.optionCDescription,
  });

  factory Dilemme.fromMap(Map<String, dynamic> map) {
    return Dilemme(
      optionATitre: map['optionATitre'] ?? '',
      optionADescription: map['optionADescription'] ?? '',
      optionAAvantage: map['optionAAvantage'] ?? '',
      optionARisque: map['optionARisque'] ?? '',
      optionBTitre: map['optionBTitre'] ?? '',
      optionBDescription: map['optionBDescription'] ?? '',
      optionBAvantage: map['optionBAvantage'] ?? '',
      optionBRisque: map['optionBRisque'] ?? '',
      optionCTitre: map['optionCTitre'] ?? 'Esquiver le dilemme',
      optionCDescription: map['optionCDescription'] ?? 'Tu ne prends aucun risque.',
    );
  }

  Map<String, dynamic> toMap() => {
        'optionATitre': optionATitre,
        'optionADescription': optionADescription,
        'optionAAvantage': optionAAvantage,
        'optionARisque': optionARisque,
        'optionBTitre': optionBTitre,
        'optionBDescription': optionBDescription,
        'optionBAvantage': optionBAvantage,
        'optionBRisque': optionBRisque,
        'optionCTitre': optionCTitre,
        'optionCDescription': optionCDescription,
      };
}

class EvenementDebat {
  final String id;
  final int ordre;
  final String titre;
  final String texte;
  EvenementDebat({required this.id, required this.ordre, required this.titre, required this.texte});
  factory EvenementDebat.fromMap(Map<String, dynamic> map) {
    return EvenementDebat(
      id: map['id'] ?? '',
      ordre: map['ordre'] ?? 0,
      titre: map['titre'] ?? '',
      texte: map['texte'] ?? '',
    );
  }
  Map<String, dynamic> toMap() => {'id': id, 'ordre': ordre, 'titre': titre, 'texte': texte};
}

class ReactionEvenement {
  final String evenementId;
  final String positionOfficielle;
  final List<String> explications;
  final String? opportuniteStrategique;

  ReactionEvenement({
    required this.evenementId,
    required this.positionOfficielle,
    required this.explications,
    this.opportuniteStrategique,
  });

  factory ReactionEvenement.fromMap(Map<String, dynamic> map) {
    return ReactionEvenement(
      evenementId: map['evenementId'] ?? '',
      positionOfficielle: map['positionOfficielle'] ?? '',
      explications: List<String>.from(map['explications'] ?? []),
      opportuniteStrategique: map['opportuniteStrategique'],
    );
  }

  Map<String, dynamic> toMap() => {
        'evenementId': evenementId,
        'positionOfficielle': positionOfficielle,
        'explications': explications,
        'opportuniteStrategique': opportuniteStrategique,
      };
}

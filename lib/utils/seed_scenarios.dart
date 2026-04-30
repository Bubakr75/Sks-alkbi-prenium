// lib/utils/seed_scenarios.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sks_alibi/models/scenario_model.dart';

Future<void> seedScenarios() async {
  final firestore = FirebaseFirestore.instance;

  // On force la mise a jour pour avoir la derniere version du scenario
  final scenario = _buildPenaltyManque();
  await firestore
      .collection('scenarios')
      .doc(scenario.id)
      .set(scenario.toMap());

  // ignore: avoid_print
  print('Scenario "penalty_manque" mis a jour avec succes !');
}

Scenario _buildPenaltyManque() {
  final evt1 = EvenementDebat(
    id: 'evt_photo_vestiaire',
    ordre: 1,
    titre: 'FLASH INFO : Une photo a fuite !',
    texte:
        'Un photographe a publie une photo prise dans le vestiaire 2 minutes avant le penalty. On y voit le tireur recevoir une enveloppe blanche d\'une main que personne ne reconnait. Tous les joueurs doivent expliquer ou ils etaient a ce moment-la.',
  );

  // ============================================================
  // SLOT 0 - LE COUPABLE - Le Tireur
  // ============================================================
  final coupable = Carte(
    slot: 0,
    role: 'coupable',
    roleDansHistoire: 'Le Tireur',
    secretInavouable:
        'Tu as recu 5000 EUR de la mafia pour rater volontairement ce penalty. L\'enveloppe contenait l\'argent. Tu dois absolument cacher ca a tout prix.',
    secretConnu:
        'Tout le monde sait que tu as rate le penalty decisif. Ton tir etait mou, central, le gardien l\'a arrete sans difficulte.',
    munitions: [
      'J\'ai glisse au moment de frapper, le terrain etait detrempe par la pluie.',
      'J\'avais une douleur au mollet depuis la 60e minute, le coach voulait me sortir mais j\'ai insiste.',
      'Le gardien a bouge avant que je tire, ca m\'a deconcentre au dernier moment.',
    ],
    questions: [
      Question(
          cibleSlot: 1,
          texte:
              'On t\'a vu sortir du vestiaire 8 minutes a la mi-temps. C\'etait pour quel appel telephonique aussi long ?'),
      Question(
          cibleSlot: 2,
          texte:
              'Pourquoi tu n\'as pas couru sur la derniere action de la 89e ? Tu marchais litteralement.'),
      Question(
          cibleSlot: 1,
          texte:
              'Tu as crie quelque chose juste avant que je tire le penalty. C\'etait quoi exactement ?'),
    ],
    accusations: [
      Accusation(
          cibleSlot: 1,
          texte:
              'Le gardien a bouge avant le tir, c\'est pour ca que j\'ai rate. C\'est lui le vrai sabotage.'),
      Accusation(
          cibleSlot: 2,
          texte:
              'Le milieu n\'a pas couru sur la derniere action defensive, on aurait jamais du en arriver au penalty.'),
    ],
    lienFort: Lien(
      cibleSlot: 2,
      description:
          'Tu as parle 5 minutes au milieu juste avant le coup d\'envoi. Vous etiez seuls dans le couloir. De quoi avez-vous parle vraiment ?',
      avertissement:
          'Le milieu sait que cette conversation a eu lieu. Si vos versions ne collent pas, vous etes grilles tous les deux.',
    ),
    observations: [
      Observation(
          cibleSlot: 1,
          texte:
              'Tu as remarque que le gardien a regarde son telephone juste avant la mi-temps avec une expression bizarre.'),
    ],
    temoignages: [
      Temoignage(
        demandeurSlot: 2,
        contexte:
            'Le milieu (Detective) va te demander pourquoi tu transpirais autant a l\'echauffement de la 2e mi-temps.',
        optionVerite:
            'Vrai : tu transpirais a cause du stress de l\'enveloppe. Reponds : "J\'avais juste chaud, c\'etait la pression du match."',
        pointsVerite: 1,
        optionEnfoncer:
            'Retourne l\'attaque : "C\'est marrant que tu remarques ca toi qui n\'as pas couru sur la derniere action."',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir:
            'Mens : "C\'etait l\'energie defensive, j\'ai sprint pour aider en defense pendant que d\'autres marchaient."',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
      Temoignage(
        demandeurSlot: 1,
        contexte:
            'Le gardien va t\'accuser d\'avoir glisse volontairement.',
        optionVerite:
            'Vrai : tu as bien glisse volontairement. Reponds : "Le terrain etait vraiment detrempe, regarde mes crampons."',
        pointsVerite: 1,
        optionEnfoncer:
            'Retourne : "Toi tu as quitte le vestiaire 8 minutes, on parle de qui exactement ?"',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir:
            'Mens : "Mon mollet a lache au moment du tir, j\'ai consulte le doc apres le match."',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
    ],
    dilemme: Dilemme(
      optionATitre: 'Aveu partiel strategique',
      optionADescription:
          'Reconnais avoir mal tire mais blame le terrain et la pluie. Ca fait honnete sans te griller.',
      optionAAvantage:
          'Si les autres y croient, ils arretent de chercher plus loin (+2 pts).',
      optionARisque:
          'Si quelqu\'un mentionne l\'enveloppe, l\'aveu te rend suspect (-2 pts).',
      optionBTitre: 'Contre-attaque violente',
      optionBDescription:
          'Accuse directement le gardien d\'avoir bouge en premier et le milieu d\'avoir abandonne sa defense.',
      optionBAvantage:
          'Cree la confusion, peut faire eliminer un innocent a ta place (+3 pts).',
      optionBRisque:
          'Si tu es demasque ensuite, l\'agressivite sera retenue contre toi (-3 pts).',
      optionCTitre: 'Esquiver',
      optionCDescription: 'Reste vague, ne prends pas position sur le dilemme.',
    ),
    missionSecrete:
        'Survis au vote sans etre demasque pour gagner +5 pts et le trophee "Le Renard". Si tu es demasque : -2 pts.',
    reactionsEvenements: [
      ReactionEvenement(
        evenementId: 'evt_photo_vestiaire',
        positionOfficielle:
            'Tu etais bien au fond du vestiaire pres des casiers. Tu dois absolument expliquer l\'enveloppe sans avouer ce qu\'elle contenait.',
        explications: [
          'C\'etait une lettre de mes parents pour me motiver, ils m\'envoient ca avant chaque grand match.',
          'C\'est mon contrat de sponsor que mon agent venait de me donner, je devais le signer apres le match.',
          'Une carte de bonne chance d\'un fan, on me l\'a passee dans le vestiaire.',
        ],
        opportuniteStrategique:
            'Profite du flou pour rediriger les soupcons vers le gardien qui etait absent du vestiaire pendant 8 minutes.',
      ),
    ],
  );

  // ============================================================
  // SLOT 1 - LE TEMOIN - Le Gardien
  // ============================================================
  final temoin = Carte(
    slot: 1,
    role: 'temoin',
    roleDansHistoire: 'Le Gardien',
    secretInavouable: null,
    secretConnu:
        'Tu as quitte le vestiaire 8 minutes a la mi-temps pour passer un appel telephonique. Tout le monde t\'a vu sortir nerveusement.',
    munitions: [
      'C\'etait ma soeur qui venait d\'avoir un accident de voiture, elle pleurait au telephone.',
      'Mon agent m\'appelait pour un transfert urgent qui devait se boucler ce week-end.',
      'J\'avais besoin d\'air frais, je faisais une crise d\'angoisse avant la 2e mi-temps.',
    ],
    questions: [
      Question(
          cibleSlot: 0,
          texte:
              'Pourquoi tu transpirais autant a la 75e minute alors qu\'il faisait froid et que tu n\'avais pas couru depuis 10 minutes ?'),
      Question(
          cibleSlot: 0,
          texte:
              'On t\'a vu parler au milieu 5 minutes avant le coup d\'envoi. De quoi vous avez parle exactement ?'),
      Question(
          cibleSlot: 2,
          texte:
              'Tu n\'as pas couru sur la derniere action defensive. Tu savais qu\'on allait perdre ?'),
    ],
    accusations: [
      Accusation(
          cibleSlot: 0,
          texte:
              'Ton tir etait beaucoup trop mou et central pour quelqu\'un qui s\'entraine aux penalties tous les jours.'),
      Accusation(
          cibleSlot: 2,
          texte:
              'Tu as parle au tireur juste avant. Vous prepariez quelque chose ensemble ?'),
    ],
    lienFort: Lien(
      cibleSlot: 0,
      description:
          'Tu as vu le tireur recevoir quelque chose dans le couloir des vestiaires juste apres ta sortie pour ton appel. Une enveloppe blanche, mais tu n\'as pas vu qui la lui donnait.',
      avertissement:
          'Si tu reveles l\'enveloppe, tu dois expliquer pourquoi tu etais dans le couloir 8 minutes au lieu d\'etre au vestiaire avec l\'equipe.',
    ),
    observations: [
      Observation(
          cibleSlot: 2,
          texte:
              'Le milieu a recu un message sur son telephone a la mi-temps qui l\'a rendu nerveux.'),
    ],
    temoignages: [
      Temoignage(
        demandeurSlot: 0,
        contexte:
            'Le tireur va te demander pourquoi tu as quitte le vestiaire 8 minutes.',
        optionVerite:
            'Vrai (au choix) : "C\'etait ma soeur, elle a eu un accident, elle pleurait." Tu peux la faire venir comme temoin.',
        pointsVerite: 1,
        optionEnfoncer:
            'Retourne sur le tireur : "Bizarre que tu poses la question, toi qui as glisse mysterieusement sur un terrain sec en 1ere mi-temps."',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir:
            'Mens (plus risque) : "Mon agent m\'appelait pour un transfert au Real Madrid, je ne pouvais pas refuser." (Personne ne pourra verifier facilement)',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
      Temoignage(
        demandeurSlot: 2,
        contexte:
            'Le milieu va te demander si tu as bouge avant le tir du penalty.',
        optionVerite:
            'Vrai : tu as bouge tres tot. Reponds : "J\'ai anticipe sur la droite, c\'est mon job de gardien."',
        pointsVerite: 1,
        optionEnfoncer:
            'Retourne : "Plutot que de me regarder moi, demande-toi pourquoi tu marchais sur la derniere action defensive."',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir:
            'Mens : "Je suis reste sur ma ligne, le tir etait juste mou et central." (Mais la video peut te contredire)',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
    ],
    dilemme: Dilemme(
      optionATitre: 'Reveler l\'enveloppe',
      optionADescription:
          'Tu confesses avoir vu une enveloppe passer au tireur. Ca change tout pour l\'enquete.',
      optionAAvantage:
          'Si l\'accuse est confondu, +3 pts pour toi en tant que temoin clef.',
      optionARisque:
          'Tu dois expliquer pourquoi tu etais dans le couloir au lieu du vestiaire (-2 pts si suspect).',
      optionBTitre: 'Garder le silence',
      optionBDescription:
          'Tu ne mentionnes jamais l\'enveloppe pour proteger ton propre alibi de l\'appel telephonique.',
      optionBAvantage:
          'Tu restes en dehors des soupcons (+1 pt si tu survis au vote).',
      optionBRisque:
          'Si quelqu\'un d\'autre revele l\'enveloppe et que tu admets l\'avoir vue trop tard, tu passes pour complice (-2 pts).',
      optionCTitre: 'Esquiver',
      optionCDescription: 'Reste vague et ne prends pas position.',
    ),
    missionSecrete: null,
    reactionsEvenements: [
      ReactionEvenement(
        evenementId: 'evt_photo_vestiaire',
        positionOfficielle:
            'Tu n\'etais pas sur la photo car tu etais dans le couloir au telephone. Tu peux soit l\'admettre, soit pretendre etre passe aux toilettes.',
        explications: [
          'J\'etais aux toilettes juste a cote, je ne suis revenu qu\'apres la photo.',
          'Je rappelais mon agent dans le couloir, j\'avais besoin d\'etre seul pour parler.',
          'Ma soeur venait d\'avoir un accident, je l\'avais au telephone.',
        ],
        opportuniteStrategique:
            'Si tu es honnete, tu peux mentionner avoir vu une enveloppe passer dans le couloir. Mais attention : tu devras justifier ta presence la-bas.',
      ),
    ],
  );

  // ============================================================
  // SLOT 2 - LE DETECTIVE - Le Milieu
  // ============================================================
  final detective = Carte(
    slot: 2,
    role: 'detective',
    roleDansHistoire: 'Le Milieu de Terrain',
    secretInavouable: null,
    secretConnu:
        'Tu n\'as pas couru sur la derniere action defensive de la 89e minute, tu marchais litteralement. C\'est ce qui a permis l\'attaque qui a force le penalty.',
    munitions: [
      'J\'avais une crampe au mollet depuis la 60e minute, le kine m\'avait dit de tenir sans forcer.',
      'Je gardais ma position pour la contre-attaque, c\'etait une consigne tactique du coach.',
      'L\'arbitre allait siffler une faute pour moi a la 88e, j\'attendais le coup-franc.',
    ],
    questions: [
      Question(
          cibleSlot: 0,
          texte:
              'Pourquoi tu m\'as parle 5 minutes avant le coup d\'envoi dans le couloir ? On n\'avait jamais fait ca avant un match.'),
      Question(
          cibleSlot: 0,
          texte:
              'Tu transpirais tres anormalement a la 75e. Tu avais quoi a cacher exactement ?'),
      Question(
          cibleSlot: 1,
          texte:
              'Tu as quitte le vestiaire 8 minutes. Si c\'etait ta soeur qui pleurait, pourquoi tu n\'as rien dit a l\'equipe en revenant ?'),
      Question(
          cibleSlot: 1,
          texte:
              'Pourquoi tu as bouge si vite a droite avant que le tireur frappe le penalty ? Comme si tu savais ou ca allait.'),
    ],
    accusations: [
      Accusation(
          cibleSlot: 0,
          texte:
              'Tu as recu une enveloppe dans le vestiaire et ton tir etait suspicieusement mou.'),
      Accusation(
          cibleSlot: 1,
          texte:
              'Ton appel telephonique mysterieux a la mi-temps, suivi de ton anticipation parfaite sur le penalty, ca fait beaucoup de coincidences.'),
    ],
    lienFort: Lien(
      cibleSlot: 0,
      description:
          'Le tireur t\'a parle 5 minutes avant le coup d\'envoi, dans le couloir. Il avait l\'air stresse et t\'a demande "qu\'est-ce que tu ferais a ma place ?" sans contexte.',
      avertissement:
          'Le tireur sait que cette conversation a eu lieu. Tu dois decider si tu reveles cette phrase enigmatique ou si tu la caches.',
    ),
    observations: [
      Observation(
          cibleSlot: 1,
          texte:
              'Tu as vu le gardien sortir tres nerveusement du vestiaire avec son telephone a la mi-temps.'),
    ],
    temoignages: [
      Temoignage(
        demandeurSlot: 0,
        contexte:
            'Le tireur va te demander pourquoi tu n\'as pas couru sur la derniere action.',
        optionVerite:
            'Vrai : tu avais bien une crampe. Reponds : "Mon mollet etait dur depuis la 60e, le kine m\'avait dit de gerer."',
        pointsVerite: 1,
        optionEnfoncer:
            'Retourne sur le tireur : "Etrange que tu poses la question, toi qui as recu une enveloppe mysterieuse 5 min avant le penalty."',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir:
            'Mens : "C\'etait une consigne tactique, je devais rester en hauteur pour la contre-attaque." (Le coach pourrait te contredire)',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
      Temoignage(
        demandeurSlot: 1,
        contexte:
            'Le gardien va te demander de quoi tu as parle avec le tireur 5 min avant le match.',
        optionVerite:
            'Vrai : tu reveles la phrase "Qu\'est-ce que tu ferais a ma place ?" Reponds : "Il etait stresse, il m\'a juste pose une question bizarre."',
        pointsVerite: 1,
        optionEnfoncer:
            'Retourne : "Toi tu as disparu 8 minutes a la mi-temps, tu peux nous dire ou exactement ?"',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir:
            'Mens : "On parlait juste tactique, rien d\'important." (Tu protege le tireur, tu peux le regretter)',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
    ],
    dilemme: Dilemme(
      optionATitre: 'Reveler la phrase enigmatique',
      optionADescription:
          'Tu reveles que le tireur t\'a demande "qu\'est-ce que tu ferais a ma place ?" 5 min avant le match.',
      optionAAvantage:
          'Si l\'accuse est confondu grace a ton temoignage, +3 pts.',
      optionARisque:
          'Tu te trompes peut-etre de cible, et tu te grilles le seul vrai allie possible (-2 pts).',
      optionBTitre: 'Cacher la conversation',
      optionBDescription:
          'Tu pretends que vous n\'avez parle de rien d\'important, juste tactique.',
      optionBAvantage:
          'Tu gardes le tireur comme allie potentiel, +1 pt si l\'accusation passe ailleurs.',
      optionBRisque:
          'Si quelqu\'un d\'autre confirme la conversation et que ton mensonge est decouvert, -3 pts.',
      optionCTitre: 'Esquiver',
      optionCDescription: 'Reste vague, ne prends pas position sur le dilemme.',
    ),
    missionSecrete:
        'En tant que detective, identifie correctement le coupable au vote pour gagner +3 pts. Si tu trouves : trophee "L\'Inspecteur".',
    reactionsEvenements: [
      ReactionEvenement(
        evenementId: 'evt_photo_vestiaire',
        positionOfficielle:
            'Tu etais bien au centre du vestiaire en train de t\'etirer a cause de ta crampe au mollet.',
        explications: [
          'Je m\'etirais le mollet droit qui etait raide depuis la 1ere mi-temps.',
          'Le kine etait avec moi, il peut confirmer mon massage.',
          'J\'avais sorti mon telephone pour regarder la meteo, on parlait du terrain.',
        ],
        opportuniteStrategique:
            'En tant que detective, profite de cette photo pour relier l\'enveloppe au tireur. Mais attention : ne te rate pas, le tireur va contre-attaquer.',
      ),
    ],
  );

  return Scenario(
    id: 'penalty_manque',
    titre: 'Le Penalty Manque',
    theme: 'football',
    intro:
        'Finale du championnat. 90e minute. Score 1-1. Penalty pour notre equipe. Le tireur s\'avance, nerveux. Il frappe... et rate. Tir mou, central. Le gardien adverse l\'arrete sans difficulte. On perd la finale 2-1 aux tirs au but qui suivent. Mais quelque chose ne colle pas. Dans le vestiaire, le silence est lourd. Les regards se croisent. Quelqu\'un a sabote ce match. Vous avez maintenant la mission de demasquer le coupable parmi vous. Que la verite eclate.',
    minJoueurs: 3,
    maxJoueurs: 3,
    cartes: [coupable, temoin, detective],
    evenements: [evt1],
  );
}

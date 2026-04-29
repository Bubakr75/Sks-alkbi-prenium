// lib/utils/seed_scenarios.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sks_alibi/models/scenario_model.dart';

Future<void> seedScenarios() async {
  final firestore = FirebaseFirestore.instance;

  final existing = await firestore.collection('scenarios').doc('penalty_manque').get();
  if (existing.exists) {
    // ignore: avoid_print
    print('Scenario "penalty_manque" deja present dans Firestore.');
    return;
  }

  final scenario = _buildPenaltyManque();

  await firestore
      .collection('scenarios')
      .doc(scenario.id)
      .set(scenario.toMap());

  // ignore: avoid_print
  print('Scenario "penalty_manque" uploade avec succes !');
}

Scenario _buildPenaltyManque() {
  final evt1 = EvenementDebat(
    id: 'evt_photo_vestiaire',
    ordre: 1,
    titre: 'FLASH INFO',
    texte:
        'Un journaliste a publie une photo du vestiaire a la mi-temps. '
        'On y voit clairement quelqu un a l arriere du vestiaire en train '
        'de tenir une enveloppe blanche. Qui etait a l arriere a ce moment-la ?',
  );

  final coupable = Carte(
    slot: 0,
    role: 'coupable',
    roleDansHistoire: 'Le Tireur',
    secretInavouable:
        'Tu as accepte 5000 euros de la mafia des paris pour rater le penalty. '
        'Le virement est arrive sur ton compte ce matin. Personne ne doit le savoir.',
    secretConnu:
        'Tout le monde a vu que tu as envoye le ballon volontairement '
        'a 10 metres au-dessus de la barre.',
    munitions: [
      'J ai glisse au moment de frapper, le terrain etait trempe.',
      'J avais une douleur au mollet depuis la 60eme, j ai rien dit.',
      'Le gardien a bouge avant que je tire, j ai panique.',
    ],
    questions: [
      Question(cibleSlot: 1, texte: 'Pourquoi tu es sorti du vestiaire 8 minutes pendant la pause ?'),
      Question(cibleSlot: 2, texte: 'Pourquoi tu n as pas couru sur la derniere action defensive ?'),
    ],
    accusations: [
      Accusation(cibleSlot: 1, texte: 'Tu as recu un appel suspect a la mi-temps. Qui c etait vraiment ?'),
      Accusation(cibleSlot: 2, texte: 'Tu marchais alors que tout le monde sprintait. C est suspect.'),
    ],
    lienFort: Lien(
      cibleSlot: 1,
      description:
          'Tu as croise {joueur} dans le couloir avant le penalty. Il avait l air agressif, '
          'comme s il te menacait.',
      avertissement: 'Attention : {joueur} a une version differente de cette rencontre.',
    ),
    observations: [
      Observation(cibleSlot: 2, texte: 'Tu as remarque que {joueur} envoyait des messages bizarres a la mi-temps.'),
    ],
    temoignages: [],
    dilemme: Dilemme(
      optionATitre: 'L AVEU PARTIEL (risque)',
      optionADescription: 'Avoue avoir recu un virement, mais pretends que c est ton pere qui te remboursait.',
      optionAAvantage: 'Tu apparais transparent, certains te croient.',
      optionARisque: 'Si quelqu un te demande des preuves bancaires, tu es coince.',
      optionBTitre: 'LA CONTRE-ACCUSATION (tres risque)',
      optionBDescription: 'Accuse {joueur du SLOT 1} d etre le commanditaire qui t a force a rater.',
      optionBAvantage: 'Le debat bascule sur lui, tu peux t en sortir.',
      optionBRisque: 'Si on ne te croit pas, tu deviens la cible n 1.',
      optionCTitre: 'ESQUIVER LE DILEMME',
      optionCDescription: 'Tu joues prudent, uniquement avec tes munitions et accusations.',
    ),
    missionSecrete:
        'Tu dois SURVIVRE au vote sans etre demasque. '
        'Astuce : ne te defends pas trop fort, ca parait suspect. '
        'Laisse les autres s accuser et n interviens que si necessaire.',
    reactionsEvenements: [
      ReactionEvenement(
        evenementId: 'evt_photo_vestiaire',
        positionOfficielle: 'Tu etais effectivement a l arriere du vestiaire a la mi-temps. Tu dois l assumer.',
        explications: [
          'Je rangeais mon sac, j avais perdu mon protege-tibia.',
          'Je recuperais mon spray anti-douleur dans mon casier pour mon mollet.',
          'J etais au telephone avec ma copine, elle stressait.',
        ],
        opportuniteStrategique:
            'ATTENTION : ne mentionne PAS l enveloppe. Si on t accuse d en avoir une, '
            'utilise ta munition n 2 (douleur au mollet) pour detourner.',
      ),
    ],
  );

  final temoin = Carte(
    slot: 1,
    role: 'temoin',
    roleDansHistoire: 'Le Gardien',
    secretInavouable: null,
    secretConnu:
        'Tu as recu un appel telephonique etrange a la mi-temps '
        'et tu es sorti du vestiaire pendant 8 minutes.',
    munitions: [
      'C etait ma soeur, elle venait d avoir un accident de voiture.',
      'Mon agent voulait me parler d un transfert urgent.',
      'Je devais juste prendre l air, j etais stresse.',
    ],
    questions: [
      Question(cibleSlot: 0, texte: 'Tu peux nous expliquer pourquoi tu transpirais autant a la mi-temps ?'),
      Question(cibleSlot: 2, texte: 'Pourquoi tu n as pas defendu sur la derniere action ?'),
    ],
    accusations: [
      Accusation(cibleSlot: 0, texte: 'Je t ai vu consulter ton telephone dans les toilettes. Qui t ecrivait ?'),
      Accusation(cibleSlot: 2, texte: 'Tu as change de crampons en plein match. Pourquoi ?'),
    ],
    lienFort: Lien(
      cibleSlot: 0,
      description:
          'Tu as croise {joueur} dans le couloir avant le penalty. Il avait l air panique, '
          'comme s il avait peur de quelque chose.',
      avertissement: 'Attention : {joueur} a une version differente de cette rencontre.',
    ),
    observations: [
      Observation(cibleSlot: 2, texte: 'Tu as remarque que {joueur} regardait souvent vers les tribunes.'),
    ],
    temoignages: [],
    dilemme: Dilemme(
      optionATitre: 'REVELER L APPEL (risque)',
      optionADescription: 'Avoue ce que tu as vraiment fait pendant ces 8 minutes.',
      optionAAvantage: 'Tu te debarrasses de ton secret connu, plus rien a cacher.',
      optionARisque: 'Selon ce que tu reveles, tu peux devenir suspect d autre chose.',
      optionBTitre: 'ACCUSER {joueur du SLOT 0} (tres risque)',
      optionBDescription: 'Revele que tu as vu {joueur} consulter son telephone juste avant le penalty.',
      optionBAvantage: 'Tu detournes l attention sur lui, +2 pts si il est elimine.',
      optionBRisque: 'Si tu te trompes, tu passes pour un manipulateur, -2 pts.',
      optionCTitre: 'ESQUIVER LE DILEMME',
      optionCDescription: 'Tu joues prudent, uniquement avec tes munitions et accusations.',
    ),
    missionSecrete: null,
    reactionsEvenements: [
      ReactionEvenement(
        evenementId: 'evt_photo_vestiaire',
        positionOfficielle: 'Tu etais aux toilettes pendant 8 minutes. Tu n es donc PAS sur la photo.',
        explications: [
          'En revenant, j ai vu deux joueurs a l arriere du vestiaire.',
          'Je n ai pas vu d enveloppe, juste des sacs ouverts.',
          'Je n ai rien remarque de special, j etais focalise sur ma preparation.',
        ],
        opportuniteStrategique:
            'Tu peux profiter de cet evenement pour temoigner que tu as vu '
            '{joueur du SLOT 0} a l arriere. Ca le met en difficulte.',
      ),
    ],
  );

  final detective = Carte(
    slot: 2,
    role: 'detective',
    roleDansHistoire: 'Le Milieu',
    secretInavouable: null,
    secretConnu:
        'Tu n as pas couru sur la derniere action defensive avant le penalty. '
        'Tu marchais alors que les autres sprintaient.',
    munitions: [
      'J avais une crampe, je ne pouvais plus courir.',
      'Je gardais ma position pour la contre-attaque.',
      'L arbitre avait deja siffle la faute, ca ne servait a rien.',
    ],
    questions: [
      Question(cibleSlot: 0, texte: 'Pourquoi tu as change de crampons a la mi-temps ?'),
      Question(cibleSlot: 1, texte: 'Tu as parle a qui exactement pendant ces 8 minutes dehors ?'),
    ],
    accusations: [
      Accusation(cibleSlot: 0, texte: 'Tu as refuse de boire la boisson energetique du staff. Pourquoi ?'),
      Accusation(cibleSlot: 1, texte: 'Mon cousin a vu un appel etrange sur ton numero. Tu confirmes ?'),
    ],
    lienFort: Lien(
      cibleSlot: 0,
      description:
          'Tu as vu {joueur} prendre quelque chose dans son casier juste avant le penalty. '
          'Une enveloppe ? Tu n as pas pu bien voir.',
      avertissement: 'Attention : {joueur} a une version differente de cette scene.',
    ),
    observations: [
      Observation(cibleSlot: 1, texte: 'Tu as entendu {joueur} parler en arabe au telephone, alors qu il dit toujours appeler sa soeur en francais.'),
    ],
    temoignages: [],
    dilemme: Dilemme(
      optionATitre: 'L INSTINCT DE DETECTIVE (risque)',
      optionADescription: 'Affirme avec conviction que tu sais qui est le coupable, meme sans preuve.',
      optionAAvantage: 'Tu influences fortement le vote des autres.',
      optionARisque: 'Si tu te trompes, tu perds toute credibilite et -3 pts.',
      optionBTitre: 'L ACCUSATION CHOC (tres risque)',
      optionBDescription: 'Accuse publiquement {joueur du SLOT 0} d avoir une enveloppe dans son casier.',
      optionBAvantage: 'Si vrai, +4 pts et tu deviens le heros de la partie.',
      optionBRisque: 'Si {joueur} prouve son innocence, -4 pts et tu es elimine.',
      optionCTitre: 'ESQUIVER LE DILEMME',
      optionCDescription: 'Tu joues prudent, uniquement avec tes munitions et accusations.',
    ),
    missionSecrete: null,
    reactionsEvenements: [
      ReactionEvenement(
        evenementId: 'evt_photo_vestiaire',
        positionOfficielle: 'Tu etais a l arriere du vestiaire, a cote de {joueur du SLOT 0}.',
        explications: [
          'Je remplissais ma gourde au robinet du fond.',
          'Je faisais des etirements pour mon ischio.',
          'Je rangeais mes crampons de rechange dans mon casier.',
        ],
        opportuniteStrategique:
            'Tu peux RETOURNER l evenement contre {joueur du SLOT 0} : '
            '"J ai vu {joueur} prendre quelque chose dans son casier. Une enveloppe..."',
      ),
    ],
  );

  return Scenario(
    id: 'penalty_manque',
    titre: 'Le Penalty Manque',
    theme: 'football',
    intro:
        'Finale du championnat. 90eme minute. 1-1. L equipe obtient un penalty decisif. '
        'Le tireur s avance... et envoie le ballon a 10 metres au-dessus de la barre. Volontairement. '
        'La defaite est totale. Dans le vestiaire, c est le silence. Quelqu un a trahi l equipe. '
        'Mais qui ? Et pourquoi ?',
    minJoueurs: 3,
    maxJoueurs: 3,
    cartes: [coupable, temoin, detective],
    evenements: [evt1],
  );
}

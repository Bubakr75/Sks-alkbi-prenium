// lib/utils/seed_scenarios.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sks_alibi/models/scenario_model.dart';

Future<void> seedScenarios() async {
  final firestore = FirebaseFirestore.instance;

  // Force la mise a jour des scenarios a chaque demarrage
  final penalty = _buildPenaltyManque();
  await firestore.collection('scenarios').doc(penalty.id).set(penalty.toMap());

  final taupe = _buildLaTaupe();
  await firestore.collection('scenarios').doc(taupe.id).set(taupe.toMap());

  // ignore: avoid_print
  print('Scenarios mis a jour avec succes !');
}

// ============================================================
// SCENARIO 1 : LE PENALTY MANQUE (FOOTBALL)
// ============================================================
Scenario _buildPenaltyManque() {
  final evt1 = EvenementDebat(
    id: 'evt_photo_vestiaire',
    ordre: 1,
    titre: 'FLASH INFO : Une photo a fuite !',
    texte:
        'Un photographe a publie une photo prise dans le vestiaire 2 minutes avant le penalty. On y voit le tireur recevoir une enveloppe blanche d\'une main que personne ne reconnait. Tous les joueurs doivent expliquer ou ils etaient a ce moment-la.',
  );

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
      Question(cibleSlot: 1, texte: 'On t\'a vu sortir du vestiaire 8 minutes a la mi-temps. C\'etait pour quel appel telephonique aussi long ?'),
      Question(cibleSlot: 2, texte: 'Pourquoi tu n\'as pas couru sur la derniere action de la 89e ? Tu marchais litteralement.'),
      Question(cibleSlot: 1, texte: 'Tu as crie quelque chose juste avant que je tire le penalty. C\'etait quoi exactement ?'),
    ],
    accusations: [
      Accusation(cibleSlot: 1, texte: 'Le gardien a bouge avant le tir, c\'est pour ca que j\'ai rate.'),
      Accusation(cibleSlot: 2, texte: 'Le milieu n\'a pas couru sur la derniere action defensive.'),
    ],
    lienFort: Lien(
      cibleSlot: 2,
      description: 'Tu as parle 5 minutes au milieu juste avant le coup d\'envoi. Vous etiez seuls dans le couloir.',
      avertissement: 'Le milieu sait que cette conversation a eu lieu. Si vos versions ne collent pas, vous etes grilles tous les deux.',
    ),
    observations: [
      Observation(cibleSlot: 1, texte: 'Tu as remarque que le gardien a regarde son telephone juste avant la mi-temps avec une expression bizarre.'),
    ],
    temoignages: [
      Temoignage(
        demandeurSlot: 2,
        contexte: 'Le milieu va te demander pourquoi tu transpirais autant a l\'echauffement de la 2e mi-temps.',
        optionVerite: 'Vrai : "J\'avais juste chaud, c\'etait la pression du match."',
        pointsVerite: 1,
        optionEnfoncer: 'Retourne : "C\'est marrant que tu remarques ca toi qui n\'as pas couru sur la derniere action."',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir: 'Mens : "C\'etait l\'energie defensive, j\'ai sprint pour aider en defense."',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
      Temoignage(
        demandeurSlot: 1,
        contexte: 'Le gardien va t\'accuser d\'avoir glisse volontairement.',
        optionVerite: 'Vrai : "Le terrain etait vraiment detrempe, regarde mes crampons."',
        pointsVerite: 1,
        optionEnfoncer: 'Retourne : "Toi tu as quitte le vestiaire 8 minutes, on parle de qui exactement ?"',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir: 'Mens : "Mon mollet a lache au moment du tir, j\'ai consulte le doc apres."',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
    ],
    dilemme: Dilemme(
      optionATitre: 'Aveu partiel strategique',
      optionADescription: 'Reconnais avoir mal tire mais blame le terrain et la pluie.',
      optionAAvantage: 'Si les autres y croient, ils arretent de chercher (+2 pts).',
      optionARisque: 'Si quelqu\'un mentionne l\'enveloppe, l\'aveu te rend suspect (-2 pts).',
      optionBTitre: 'Contre-attaque violente',
      optionBDescription: 'Accuse le gardien d\'avoir bouge et le milieu d\'avoir abandonne sa defense.',
      optionBAvantage: 'Cree la confusion, peut faire eliminer un innocent (+3 pts).',
      optionBRisque: 'Si demasque ensuite, l\'agressivite te grille (-3 pts).',
      optionCTitre: 'Esquiver',
      optionCDescription: 'Reste vague, ne prends pas position.',
    ),
    missionSecrete: 'Survis au vote sans etre demasque pour gagner +5 pts et le trophee "Le Renard". Si tu es demasque : -2 pts.',
    reactionsEvenements: [
      ReactionEvenement(
        evenementId: 'evt_photo_vestiaire',
        positionOfficielle: 'Tu etais bien au fond du vestiaire pres des casiers. Tu dois absolument expliquer l\'enveloppe sans avouer ce qu\'elle contenait.',
        explications: [
          'C\'etait une lettre de mes parents pour me motiver.',
          'C\'est mon contrat de sponsor que mon agent venait de me donner.',
          'Une carte de bonne chance d\'un fan.',
        ],
        opportuniteStrategique: 'Profite du flou pour rediriger les soupcons vers le gardien qui etait absent du vestiaire pendant 8 minutes.',
      ),
    ],
  );

  final temoin = Carte(
    slot: 1,
    role: 'temoin',
    roleDansHistoire: 'Le Gardien',
    secretInavouable: null,
    secretConnu: 'Tu as quitte le vestiaire 8 minutes a la mi-temps pour passer un appel telephonique.',
    munitions: [
      'C\'etait ma soeur qui venait d\'avoir un accident de voiture.',
      'Mon agent m\'appelait pour un transfert urgent.',
      'J\'avais besoin d\'air frais, je faisais une crise d\'angoisse.',
    ],
    questions: [
      Question(cibleSlot: 0, texte: 'Pourquoi tu transpirais autant a la 75e minute alors qu\'il faisait froid ?'),
      Question(cibleSlot: 0, texte: 'On t\'a vu parler au milieu 5 minutes avant le coup d\'envoi. De quoi vous avez parle ?'),
      Question(cibleSlot: 2, texte: 'Tu n\'as pas couru sur la derniere action defensive. Tu savais qu\'on allait perdre ?'),
    ],
    accusations: [
      Accusation(cibleSlot: 0, texte: 'Ton tir etait beaucoup trop mou et central pour un specialiste.'),
      Accusation(cibleSlot: 2, texte: 'Tu as parle au tireur juste avant. Vous prepariez quelque chose ?'),
    ],
    lienFort: Lien(
      cibleSlot: 0,
      description: 'Tu as vu le tireur recevoir une enveloppe blanche dans le couloir des vestiaires juste apres ta sortie.',
      avertissement: 'Si tu reveles l\'enveloppe, tu dois expliquer pourquoi tu etais dans le couloir 8 minutes.',
    ),
    observations: [
      Observation(cibleSlot: 2, texte: 'Le milieu a recu un message sur son telephone a la mi-temps qui l\'a rendu nerveux.'),
    ],
    temoignages: [
      Temoignage(
        demandeurSlot: 0,
        contexte: 'Le tireur va te demander pourquoi tu as quitte le vestiaire 8 minutes.',
        optionVerite: 'Vrai : "C\'etait ma soeur, elle a eu un accident, elle pleurait."',
        pointsVerite: 1,
        optionEnfoncer: 'Retourne : "Bizarre que tu poses la question, toi qui as glisse mysterieusement."',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir: 'Mens : "Mon agent m\'appelait pour un transfert au Real Madrid."',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
      Temoignage(
        demandeurSlot: 2,
        contexte: 'Le milieu va te demander si tu as bouge avant le tir du penalty.',
        optionVerite: 'Vrai : "J\'ai anticipe sur la droite, c\'est mon job de gardien."',
        pointsVerite: 1,
        optionEnfoncer: 'Retourne : "Plutot que me regarder, demande-toi pourquoi tu marchais."',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir: 'Mens : "Je suis reste sur ma ligne, le tir etait juste mou et central."',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
    ],
    dilemme: Dilemme(
      optionATitre: 'Reveler l\'enveloppe',
      optionADescription: 'Tu confesses avoir vu une enveloppe passer au tireur.',
      optionAAvantage: 'Si l\'accuse est confondu, +3 pts pour toi en tant que temoin clef.',
      optionARisque: 'Tu dois expliquer ta presence dans le couloir (-2 pts si suspect).',
      optionBTitre: 'Garder le silence',
      optionBDescription: 'Tu ne mentionnes jamais l\'enveloppe pour proteger ton alibi.',
      optionBAvantage: 'Tu restes en dehors des soupcons (+1 pt si tu survis).',
      optionBRisque: 'Si quelqu\'un revele l\'enveloppe et que tu admets l\'avoir vue trop tard, tu passes pour complice (-2 pts).',
      optionCTitre: 'Esquiver',
      optionCDescription: 'Reste vague et ne prends pas position.',
    ),
    missionSecrete: null,
    reactionsEvenements: [
      ReactionEvenement(
        evenementId: 'evt_photo_vestiaire',
        positionOfficielle: 'Tu n\'etais pas sur la photo car tu etais dans le couloir au telephone.',
        explications: [
          'J\'etais aux toilettes juste a cote.',
          'Je rappelais mon agent dans le couloir.',
          'Ma soeur venait d\'avoir un accident, je l\'avais au telephone.',
        ],
        opportuniteStrategique: 'Si tu es honnete, tu peux mentionner avoir vu une enveloppe passer dans le couloir.',
      ),
    ],
  );

  final detective = Carte(
    slot: 2,
    role: 'detective',
    roleDansHistoire: 'Le Milieu de Terrain',
    secretInavouable: null,
    secretConnu: 'Tu n\'as pas couru sur la derniere action defensive de la 89e minute, tu marchais litteralement.',
    munitions: [
      'J\'avais une crampe au mollet depuis la 60e minute.',
      'Je gardais ma position pour la contre-attaque, c\'etait une consigne tactique.',
      'L\'arbitre allait siffler une faute pour moi a la 88e.',
    ],
    questions: [
      Question(cibleSlot: 0, texte: 'Pourquoi tu m\'as parle 5 minutes avant le coup d\'envoi dans le couloir ?'),
      Question(cibleSlot: 0, texte: 'Tu transpirais tres anormalement a la 75e. Tu avais quoi a cacher ?'),
      Question(cibleSlot: 1, texte: 'Tu as quitte le vestiaire 8 minutes. Pourquoi tu n\'as rien dit a l\'equipe en revenant ?'),
      Question(cibleSlot: 1, texte: 'Pourquoi tu as bouge si vite a droite avant le tir ? Comme si tu savais ou ca allait.'),
    ],
    accusations: [
      Accusation(cibleSlot: 0, texte: 'Tu as recu une enveloppe dans le vestiaire et ton tir etait suspicieusement mou.'),
      Accusation(cibleSlot: 1, texte: 'Ton appel telephonique mysterieux suivi de ton anticipation parfaite, ca fait beaucoup.'),
    ],
    lienFort: Lien(
      cibleSlot: 0,
      description: 'Le tireur t\'a parle 5 minutes avant le coup d\'envoi et t\'a demande "qu\'est-ce que tu ferais a ma place ?"',
      avertissement: 'Le tireur sait que cette conversation a eu lieu. A toi de decider si tu reveles cette phrase.',
    ),
    observations: [
      Observation(cibleSlot: 1, texte: 'Tu as vu le gardien sortir tres nerveusement du vestiaire avec son telephone a la mi-temps.'),
    ],
    temoignages: [
      Temoignage(
        demandeurSlot: 0,
        contexte: 'Le tireur va te demander pourquoi tu n\'as pas couru sur la derniere action.',
        optionVerite: 'Vrai : "Mon mollet etait dur depuis la 60e, le kine m\'avait dit de gerer."',
        pointsVerite: 1,
        optionEnfoncer: 'Retourne : "Etrange, toi qui as recu une enveloppe mysterieuse."',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir: 'Mens : "C\'etait une consigne tactique."',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
      Temoignage(
        demandeurSlot: 1,
        contexte: 'Le gardien va te demander de quoi tu as parle avec le tireur 5 min avant le match.',
        optionVerite: 'Vrai : "Il m\'a juste pose une question bizarre : qu\'est-ce que tu ferais a ma place ?"',
        pointsVerite: 1,
        optionEnfoncer: 'Retourne : "Toi tu as disparu 8 minutes, tu peux nous dire ou exactement ?"',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir: 'Mens : "On parlait juste tactique, rien d\'important."',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
    ],
    dilemme: Dilemme(
      optionATitre: 'Reveler la phrase enigmatique',
      optionADescription: 'Tu reveles que le tireur t\'a demande "qu\'est-ce que tu ferais a ma place ?"',
      optionAAvantage: 'Si l\'accuse est confondu, +3 pts.',
      optionARisque: 'Tu te trompes peut-etre de cible (-2 pts).',
      optionBTitre: 'Cacher la conversation',
      optionBDescription: 'Tu pretends que vous n\'avez parle de rien d\'important.',
      optionBAvantage: 'Tu gardes le tireur comme allie potentiel (+1 pt).',
      optionBRisque: 'Si le mensonge est decouvert, -3 pts.',
      optionCTitre: 'Esquiver',
      optionCDescription: 'Reste vague.',
    ),
    missionSecrete: 'Identifie le coupable au vote pour gagner +3 pts. Si tu trouves : trophee "L\'Inspecteur".',
    reactionsEvenements: [
      ReactionEvenement(
        evenementId: 'evt_photo_vestiaire',
        positionOfficielle: 'Tu etais bien au centre du vestiaire en train de t\'etirer a cause de ta crampe.',
        explications: [
          'Je m\'etirais le mollet droit qui etait raide.',
          'Le kine etait avec moi, il peut confirmer.',
          'J\'avais sorti mon telephone pour regarder la meteo.',
        ],
        opportuniteStrategique: 'Profite de la photo pour relier l\'enveloppe au tireur.',
      ),
    ],
  );

  return Scenario(
    id: 'penalty_manque',
    titre: 'Le Penalty Manque',
    theme: 'football',
    intro: 'Finale du championnat. 90e minute. Score 1-1. Penalty pour notre equipe. Le tireur s\'avance, nerveux. Il frappe... et rate. Tir mou, central. Le gardien adverse l\'arrete sans difficulte. On perd la finale 2-1 aux tirs au but. Mais quelque chose ne colle pas. Dans le vestiaire, le silence est lourd. Quelqu\'un a sabote ce match. A vous de demasquer le coupable.',
    minJoueurs: 3,
    maxJoueurs: 3,
    cartes: [coupable, temoin, detective],
    evenements: [evt1],
  );
}

// ============================================================
// SCENARIO 2 : LA TAUPE (POLICIER)
// ============================================================
Scenario _buildLaTaupe() {
  final evt1 = EvenementDebat(
    id: 'evt_releve_bancaire',
    ordre: 1,
    titre: 'BREAKING : Un releve bancaire fuit !',
    texte:
        'Les Affaires Internes viennent d\'envoyer un dossier au commissaire : un des trois flics presents a recu un virement crypte de 50 000 EUR via une banque offshore 48h avant le braquage. Le nom du beneficiaire est masque, mais le virement provient d\'une societe-ecran liee a la mafia Petrov. Tout le monde doit justifier ses comptes.',
  );

  // SLOT 0 - LA TAUPE - Le Lieutenant
  final lieutenant = Carte(
    slot: 0,
    role: 'coupable',
    roleDansHistoire: 'Le Lieutenant',
    secretInavouable:
        'Tu es la taupe. Tu as recu 50 000 EUR de la mafia Petrov pour leur fournir l\'heure et le lieu exacts du raid. Le virement crypte est sur ton telephone perso (pas le pro). Tu as efface l\'historique mais l\'app reste installee.',
    secretConnu:
        'Tout le monde sait que tu etais le seul a avoir l\'acces complet au dossier numerique du raid. Tu as travaille tard la veille au commissariat, seul devant les ordinateurs.',
    munitions: [
      'Je preparais le briefing operationnel pour le matin, c\'est ma fonction de lieutenant.',
      'J\'ai consulte le dossier oui, mais je n\'ai jamais quitte le commissariat avec une copie - les logs informatiques le prouvent.',
      'Si j\'etais la taupe, pourquoi j\'aurais ete sur le terrain a risquer ma peau pendant le raid ?',
    ],
    questions: [
      Question(cibleSlot: 1, texte: 'Tu as passe un appel suspect 2h avant le raid avec un numero non identifie. C\'etait qui ?'),
      Question(cibleSlot: 2, texte: 'Tu n\'etais pas au point de rendez-vous a l\'heure prevue. Ou etais-tu exactement cette nuit-la ?'),
      Question(cibleSlot: 1, texte: 'Pourquoi tu connaissais aussi precisement les noms des suspects avant le briefing officiel ?'),
    ],
    accusations: [
      Accusation(cibleSlot: 1, texte: 'Le capitaine connaissait l\'operation depuis trop longtemps. Il a eu le temps de la balancer.'),
      Accusation(cibleSlot: 2, texte: 'L\'inspecteur etait absent du raid, il avait son telephone eteint. Tres pratique pour une taupe.'),
    ],
    lienFort: Lien(
      cibleSlot: 1,
      description: 'Tu as bu un verre avec le capitaine la veille du raid. Vous avez parle longuement des suspects. Il t\'a confie certaines informations qu\'il n\'aurait pas du divulguer.',
      avertissement: 'Le capitaine se souvient de cette soiree. Si vos versions different, vous etes grilles tous les deux.',
    ),
    observations: [
      Observation(cibleSlot: 2, texte: 'Tu as remarque que l\'inspecteur n\'a jamais repondu aux radios pendant la phase 2 du raid. Silence radio total pendant 30 minutes.'),
    ],
    temoignages: [
      Temoignage(
        demandeurSlot: 2,
        contexte: 'L\'inspecteur va te demander pourquoi tu as travaille seul au commissariat la veille.',
        optionVerite: 'Vrai : "Je preparais le brief operationnel, c\'est dans mes attributions, les logs le prouvent."',
        pointsVerite: 1,
        optionEnfoncer: 'Retourne : "Toi tu n\'etais meme pas au rendez-vous a l\'heure, on parle de qui exactement ?"',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir: 'Mens : "Je n\'etais pas seul, le capitaine est passe en debut de soiree." (Mais le capitaine peut te contredire)',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
      Temoignage(
        demandeurSlot: 1,
        contexte: 'Le capitaine va te questionner sur ton telephone perso jamais remis aux Affaires Internes.',
        optionVerite: 'Vrai : "Mon perso est confidentiel, j\'ai le droit, je n\'ai pas a le remettre sans mandat."',
        pointsVerite: 1,
        optionEnfoncer: 'Retourne : "Tu sais que ton appel suspect est trace dans les operateurs, on devrait y regarder de pres."',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir: 'Mens : "Mon telephone perso, je l\'ai deja donne aux IGS la semaine derniere." (Verifiable rapidement)',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
    ],
    dilemme: Dilemme(
      optionATitre: 'Aveu partiel - sponsoring',
      optionADescription: 'Tu admets avoir des dettes et avoir parle informellement a un "ami" que tu pensais inoffensif.',
      optionAAvantage: 'Si les autres y croient, ils te voient comme victime naive (+2 pts).',
      optionARisque: 'Si quelqu\'un mentionne le virement crypte, l\'aveu te rend immediatement coupable (-2 pts).',
      optionBTitre: 'Contre-attaque agressive',
      optionBDescription: 'Tu accuses directement le capitaine d\'avoir vendu les infos a son cousin mafieux et l\'inspecteur d\'avoir fait expres d\'etre absent.',
      optionBAvantage: 'Cree la confusion totale, peut faire eliminer un innocent (+3 pts).',
      optionBRisque: 'Si tu es demasque ensuite, ton agressivite preuve de ta culpabilite (-3 pts).',
      optionCTitre: 'Esquiver',
      optionCDescription: 'Reste vague et bureaucratique. Refuse de te livrer.',
    ),
    missionSecrete: 'Survis a l\'enquete interne sans etre demasque pour gagner +5 pts et le trophee "Le Renard". Si tu es demasque : -2 pts.',
    reactionsEvenements: [
      ReactionEvenement(
        evenementId: 'evt_releve_bancaire',
        positionOfficielle: 'Tu dois absolument detourner les soupcons du virement. Tes comptes officiels sont propres - le virement etait sur un compte offshore que tu peux nier connaitre. Insiste sur le fait que tes comptes officiels sont accessibles et clairs.',
        explications: [
          'Mes comptes officiels sont a la disposition des Affaires Internes, je n\'ai rien a cacher.',
          'Si quelqu\'un avait recu 50 000 EUR, il aurait deja achete une voiture neuve - ce n\'est pas mon cas.',
          'Le virement provient d\'une societe-ecran : n\'importe qui peut envoyer de l\'argent a quelqu\'un sans que ce dernier soit complice.',
        ],
        opportuniteStrategique: 'Profite du flou sur le beneficiaire pour rediriger les soupcons vers le capitaine (cousin mafieux) ou l\'inspecteur (absent du raid).',
      ),
    ],
  );

  // SLOT 1 - LE TEMOIN - Le Capitaine
  final capitaine = Carte(
    slot: 1,
    role: 'temoin',
    roleDansHistoire: 'Le Capitaine',
    secretInavouable: null,
    secretConnu: 'Tout le monde sait que tu as passe un appel telephonique de 12 minutes avec un numero non identifie environ 2h avant le raid. L\'appel est dans les enregistrements telephoniques.',
    munitions: [
      'C\'etait mon ex-femme, elle voulait me parler de la garde des enfants - je ne voulais pas qu\'on sache qu\'on se reparlait.',
      'C\'etait mon medecin, j\'ai des problemes de sante que je veux garder confidentiels.',
      'C\'etait un informateur sur une autre affaire en cours, je ne peux pas reveler son identite.',
    ],
    questions: [
      Question(cibleSlot: 0, texte: 'Pourquoi tu as passe la nuit entiere au commissariat la veille du raid ? Personne ne fait ca pour un simple briefing.'),
      Question(cibleSlot: 0, texte: 'Pourquoi tu as exige d\'etre celui qui dirigerait l\'entree dans la planque ?'),
      Question(cibleSlot: 2, texte: 'Tu n\'as pas repondu aux radios pendant 30 minutes pendant le raid. Tu peux justifier ce silence ?'),
    ],
    accusations: [
      Accusation(cibleSlot: 0, texte: 'Le lieutenant avait l\'acces complet au dossier numerique. Personne d\'autre n\'aurait pu fuiter avec autant de precision.'),
      Accusation(cibleSlot: 2, texte: 'L\'inspecteur etait absent du raid avec son telephone eteint. Coincidence ?'),
    ],
    lienFort: Lien(
      cibleSlot: 0,
      description: 'Tu as bu un verre avec le lieutenant la veille du raid au "Coq Rouge". Tu lui as confie en confidence qu\'un de tes cousins eloignes a des liens avec la pegre - c\'est un secret que personne d\'autre ne sait.',
      avertissement: 'Le lieutenant connait cette information. S\'il decide de la reveler, ta carriere est finie. Tu dois decider si tu denonces le lieutenant en premier ou si tu negocies avec lui.',
    ),
    observations: [
      Observation(cibleSlot: 0, texte: 'Tu as vu le lieutenant utiliser son telephone perso (pas le pro) pendant les heures de service ce mois-ci. Tres anormal.'),
    ],
    temoignages: [
      Temoignage(
        demandeurSlot: 0,
        contexte: 'Le lieutenant va te questionner sur ton appel telephonique de 12 minutes.',
        optionVerite: 'Vrai (au choix) : "C\'etait mon ex pour la garde des enfants, je ne voulais pas que ca se sache au boulot."',
        pointsVerite: 1,
        optionEnfoncer: 'Retourne : "C\'est interessant que tu sois si curieux toi qui as bosse seul toute la nuit avec acces total au dossier."',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir: 'Mens : "C\'etait un informateur, je ne peux pas reveler son identite, ordre de la hierarchie." (Difficile a verifier mais peut etre traque)',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
      Temoignage(
        demandeurSlot: 2,
        contexte: 'L\'inspecteur va te demander pourquoi tu connaissais aussi precisement les suspects avant le briefing.',
        optionVerite: 'Vrai : "J\'avais lu le dossier preparatoire que j\'avais demande au lieutenant la veille."',
        pointsVerite: 1,
        optionEnfoncer: 'Retourne : "Et toi pourquoi t\'es absent du raid ? Vu ton silence radio, on dirait que t\'avais autre chose a faire."',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir: 'Mens : "Un informateur m\'avait briefe verbalement, je ne peux pas le citer." (Risque de denonciation pour faute professionnelle)',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
    ],
    dilemme: Dilemme(
      optionATitre: 'Reveler le secret du lieutenant',
      optionADescription: 'Tu balances que le lieutenant utilise son telephone perso anormalement pendant les heures de service depuis un mois.',
      optionAAvantage: 'Si le lieutenant est confondu, +3 pts pour toi en tant que temoin clef.',
      optionARisque: 'Le lieutenant peut alors reveler ton cousin mafieux par vengeance (-2 pts et carriere finie).',
      optionBTitre: 'Garder le secret',
      optionBDescription: 'Tu protege le lieutenant en ne mentionnant pas son comportement louche, esperant qu\'il fasse de meme.',
      optionBAvantage: 'Tu evites le risque de denonciation reciproque (+1 pt si tu survis au vote).',
      optionBRisque: 'Si quelqu\'un d\'autre revele le truc et que tu admets l\'avoir vu trop tard, tu passes pour complice (-2 pts).',
      optionCTitre: 'Esquiver',
      optionCDescription: 'Reste vague sur les comportements louches que tu as observes.',
    ),
    missionSecrete: null,
    reactionsEvenements: [
      ReactionEvenement(
        evenementId: 'evt_releve_bancaire',
        positionOfficielle: 'Tes comptes officiels sont propres mais tu as recu un petit virement de 2000 EUR de ton cousin il y a 6 mois (cadeau de mariage). Tu dois le justifier sans paniquer.',
        explications: [
          'Tous mes comptes sont accessibles aux Affaires Internes, je n\'ai rien a cacher.',
          'Le virement de 2000 EUR vient de mon cousin pour mon mariage, j\'ai les preuves.',
          'Mon ex-femme me verse une pension qui peut etre confondue avec autre chose, je peux fournir les actes.',
        ],
        opportuniteStrategique: 'Profite-en pour pointer le lieutenant qui utilise un telephone perso (potentiel deuxieme compte cache).',
      ),
    ],
  );

  // SLOT 2 - LE DETECTIVE - L'Inspecteur
  final inspecteur = Carte(
    slot: 2,
    role: 'detective',
    roleDansHistoire: 'L\'Inspecteur',
    secretInavouable: null,
    secretConnu: 'Tout le monde sait que tu n\'etais pas au point de rendez-vous a l\'heure prevue pour le debut du raid. Tu es arrive avec 30 minutes de retard et tu n\'avais pas repondu aux radios.',
    munitions: [
      'Je suis tombe en panne sur le chemin, ma voiture a refuse de demarrer.',
      'J\'avais une fuite dans mon equipement et je suis passe au quartier general pour le changer.',
      'Mon GPS a deconne et m\'a fait perdre 30 minutes dans des rues a sens unique.',
    ],
    questions: [
      Question(cibleSlot: 0, texte: 'Pourquoi tu as bosse seul au commissariat toute la nuit precedente ? Personne ne fait ca pour un simple brief.'),
      Question(cibleSlot: 0, texte: 'Pourquoi ton telephone perso n\'a jamais ete remis aux Affaires Internes ?'),
      Question(cibleSlot: 1, texte: 'Ton appel de 12 minutes 2h avant le raid avec un numero crypte, c\'etait qui exactement ?'),
      Question(cibleSlot: 1, texte: 'Tu connaissais les suspects avant le briefing officiel. Comment c\'est possible ?'),
    ],
    accusations: [
      Accusation(cibleSlot: 0, texte: 'Acces complet au dossier + soiree seul + telephone perso suspect. Trois indices qui pointent vers toi.'),
      Accusation(cibleSlot: 1, texte: 'Cousin mafieux + appel suspect + connaissance avancee des suspects. Tu peux expliquer ?'),
    ],
    lienFort: Lien(
      cibleSlot: 0,
      description: 'Tu as remarque que le lieutenant te regardait bizarrement le matin du raid. Il t\'a dit en passant : "Si t\'arrives en retard, ils ne te le pardonneront jamais." Une phrase etrange qui ressemblait a un avertissement.',
      avertissement: 'Le lieutenant ne sait pas que tu te souviens de cette phrase. Tu peux l\'utiliser pour le piquer ou la garder en reserve.',
    ),
    observations: [
      Observation(cibleSlot: 1, texte: 'Tu as vu le capitaine fermer brusquement son ordinateur quand tu es entre dans son bureau la semaine derniere. Comme s\'il cachait quelque chose.'),
    ],
    temoignages: [
      Temoignage(
        demandeurSlot: 0,
        contexte: 'Le lieutenant va te demander pourquoi tu n\'as pas repondu aux radios pendant 30 minutes.',
        optionVerite: 'Vrai : "J\'etais en panne sur le bord de la route, mon talkie etait dans le coffre, j\'ai panique."',
        pointsVerite: 1,
        optionEnfoncer: 'Retourne : "C\'est etrange, toi qui m\'as dit ce matin que je ne devais pas etre en retard - comme si tu savais quelque chose."',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir: 'Mens : "Mon talkie etait casse depuis 2 jours, j\'avais demande un remplacement." (Verifiable au depot)',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
      Temoignage(
        demandeurSlot: 1,
        contexte: 'Le capitaine va te demander pourquoi tu etais aussi en retard ce jour-la.',
        optionVerite: 'Vrai : "Ma voiture est tombee en panne, j\'ai du attendre la depanneuse."',
        pointsVerite: 1,
        optionEnfoncer: 'Retourne : "Toi tu etais bizarrement bien informe sur les suspects, et tu as ferme ton ordi quand je suis entre la semaine derniere. Tu cachais quoi ?"',
        pointsEnfoncerReussi: 3,
        pointsEnfoncerEchec: -2,
        optionMentir: 'Mens : "Une urgence familiale m\'a retarde, c\'est confidentiel." (Difficile a tracer mais soulevera des questions)',
        pointsMentirReussi: 2,
        pointsMentirEchec: -3,
      ),
    ],
    dilemme: Dilemme(
      optionATitre: 'Reveler la phrase suspecte',
      optionADescription: 'Tu reveles que le lieutenant t\'a dit "Si t\'arrives en retard, ils ne te le pardonneront jamais" comme un avertissement etrange.',
      optionAAvantage: 'Si le lieutenant est confondu grace a ton temoignage, +3 pts.',
      optionARisque: 'Tu te trompes peut-etre de cible et perds ton meilleur allie potentiel (-2 pts).',
      optionBTitre: 'Garder la phrase en reserve',
      optionBDescription: 'Tu pretends ne rien avoir remarque d\'inhabituel chez le lieutenant.',
      optionBAvantage: 'Tu gardes le lieutenant comme allie potentiel et un argument en reserve (+1 pt).',
      optionBRisque: 'Si quelqu\'un d\'autre confirme la phrase et que ton mensonge est decouvert, -3 pts.',
      optionCTitre: 'Esquiver',
      optionCDescription: 'Reste vague et focalise sur d\'autres elements.',
    ),
    missionSecrete: 'En tant que detective, identifie correctement la taupe au vote pour gagner +3 pts. Si tu trouves : trophee "L\'Inspecteur".',
    reactionsEvenements: [
      ReactionEvenement(
        evenementId: 'evt_releve_bancaire',
        positionOfficielle: 'Tes comptes sont vraiment propres mais tu as un decouvert recurrent que tu cachais. Tu dois jouer la transparence totale pour ne pas avoir l\'air suspect.',
        explications: [
          'Mes comptes sont a 100% accessibles, j\'ai meme un petit decouvert que je n\'ai pas honte d\'admettre.',
          'Si j\'avais 50 000 EUR caches, je ne serais pas a decouvert tous les mois.',
          'Je peux fournir mes 12 derniers mois de relevés immediatement, je n\'ai rien a cacher.',
        ],
        opportuniteStrategique: 'Joue la transparence totale et profite-en pour exiger la meme chose des deux autres - le coupable refusera ou hesitera.',
      ),
    ],
  );

  return Scenario(
    id: 'la_taupe',
    titre: 'La Taupe',
    theme: 'policier',
    intro:
        'Trois jours apres l\'arrestation rate des hommes du parrain Petrov, le commissaire vous a tous reunis. Le braquage de la BNP Centre devait etre l\'aboutissement de 6 mois d\'enquete. Mais a l\'arrivee du raid, les criminels avaient deja vide les lieux. Ils savaient. Quelqu\'un a parle. Le commissaire vient de quitter la salle. Officiellement c\'est un debrief. En realite, vous etes devant les Affaires Internes en huis clos. Trois flics, une trahison, et 50 000 EUR qui ont change de mains. La taupe est dans cette salle. Trouvez-la.',
    minJoueurs: 3,
    maxJoueurs: 3,
    cartes: [lieutenant, capitaine, inspecteur],
    evenements: [evt1],
  );
}

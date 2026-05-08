# CONTEXTE PROJET — SKS : Alibi Premium

Nom : SKS Alibi | Flutter + Firebase | GitHub : https://github.com/Bubakr75/Sks-alkbi-prenium
IA : Gemini 2.5 Flash (cle en dur dans ia_generation_screen.dart - a securiser)
Packages : firebase_core, cloud_firestore, firebase_auth, google_fonts ^6.2.1, flutter_animate ^4.5.0, audioplayers ^6.1.0, http ^1.2.2, uuid, shared_preferences, provider

FICHIERS :
lib/main.dart | lib/create_room_screen.dart | lib/join_room_screen.dart
lib/services/sound_service.dart | lib/services/test_mode_service.dart
lib/screens/choix_scenario_screen.dart | questionnaire_screen.dart | scoring_screen.dart
lib/screens/ia_generation_screen.dart | vote_predictif_screen.dart | carte_ia_screen.dart
lib/screens/vote_screen.dart | defis_secrets_screen.dart | classement_manche_screen.dart
lib/screens/finale_screen.dart | test_mode_screen.dart
assets/sounds/ : click.mp3 reveal.mp3 vote.mp3 success.mp3 suspense.mp3 finale.mp3 wrong.mp3 correct.mp3

FLUX : Accueil > Choix Theme > Lobby > Questionnaire > Scoring > Generation IA > Vote Predictif > Carte Identite > Vote Final > Classement > Finale

FIRESTORE : rooms/{code}/ : code, hostUid, status, totalManches(3), manche, scenarioId, iaHistoire, iaTheme, votesParManche, votesPredictifs, coupablesParManche, profils / players/{uid} : name, isHost, carteIA/{manche_X}

SOUNDSERVICE : onQuestionAnswer | onPlayerSelect | onVote | onReveal | onSuspense | onFinale | onCorrect | onWrong | onGameStart | onSuccess

ETAT (2026-05-08) :
FAIT : UI premium tous ecrans, theme Firestore dans _generer(), mode test solo, questions profondes auto-advance, SoundService cree, sons/vibrations integres
A FAIRE : securiser cle Gemini, tests end-to-end, publication stores

REGLES : flutter analyze 0 erreurs avant commit | -Encoding UTF8 PowerShell | ne pas publier avec cle Gemini exposee

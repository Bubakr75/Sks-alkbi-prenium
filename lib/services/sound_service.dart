import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;
  bool _hapticEnabled = true;

  // ── Activer/désactiver ──────────────────────────────────────
  void setSoundEnabled(bool v) => _soundEnabled = v;
  void setHapticEnabled(bool v) => _hapticEnabled = v;

  // ── Jouer un son ────────────────────────────────────────────
  Future<void> _play(String asset) async {
    if (!_soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$asset'));
    } catch (_) {}
  }

  // ── Vibrations ──────────────────────────────────────────────
  void _vibrate(HapticType type) {
    if (!_hapticEnabled) return;
    switch (type) {
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }

  // ── Événements du jeu ───────────────────────────────────────

  /// Clic sur une réponse dans le questionnaire
  void onQuestionAnswer() {
    _play('click.mp3');
    _vibrate(HapticType.light);
  }

  /// Révélation d'un secret / carte identité
  void onReveal() {
    _play('reveal.mp3');
    _vibrate(HapticType.heavy);
  }

  /// Vote soumis
  void onVote() {
    _play('vote.mp3');
    _vibrate(HapticType.medium);
  }

  /// Succès / confirmation
  void onSuccess() {
    _play('success.mp3');
    _vibrate(HapticType.medium);
  }

  /// Ambiance suspense (début génération IA)
  void onSuspense() {
    _play('suspense.mp3');
    _vibrate(HapticType.light);
  }

  /// Grande finale révélée
  void onFinale() {
    _play('finale.mp3');
    _vibrate(HapticType.vibrate);
  }

  /// Mauvaise réponse / erreur
  void onWrong() {
    _play('wrong.mp3');
    _vibrate(HapticType.light);
  }

  /// Bonne réponse / coupable trouvé
  void onCorrect() {
    _play('correct.mp3');
    _vibrate(HapticType.heavy);
  }

  /// Sélection d'un joueur dans un vote
  void onPlayerSelect() {
    _play('click.mp3');
    _vibrate(HapticType.selection);
  }

  /// Lancement de la partie
  void onGameStart() {
    _play('success.mp3');
    _vibrate(HapticType.heavy);
  }

  void dispose() {
    _player.dispose();
  }
}

enum HapticType { light, medium, heavy, selection, vibrate }

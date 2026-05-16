import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class CallSoundImpl {
  final AudioPlayer _player = AudioPlayer();
  bool _unlocked = false;

  bool get isUnlocked => _unlocked;

  void unlockFromGesture() {
    unlock();
  }

  Future<void> unlock() async {
    if (_unlocked) return;
    _unlocked = true;
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('sounds/senha_chamada.wav'));
    } catch (e) {
      if (kDebugMode) debugPrint('[CallSound] unlock: $e');
    }
  }

  Future<void> playCallSound() async {
    if (!_unlocked) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/senha_chamada.wav'));
    } catch (e) {
      if (kDebugMode) debugPrint('[CallSound] play: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
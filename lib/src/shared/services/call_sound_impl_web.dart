import 'dart:html' as html;

/// Audio via HTML5 - play() deve ser chamado sincronamente no gesto do usuario (web).
class CallSoundImpl {
  html.AudioElement? _audio;
  bool _unlocked = false;

  bool get isUnlocked => _unlocked;

  static const String _assetPath = '/assets/assets/sounds/senha_chamada.wav';

  String get _assetUrl {
    final origin = html.window.location.origin;
    return '$origin$_assetPath';
  }

  /// Chamado diretamente no onPointerDown - nao usar await antes do play().
  void unlockFromGesture() {
    if (_unlocked) return;
    _unlocked = true;
    _audio = html.AudioElement(_assetUrl)..preload = 'auto';
    _audio!.play();
  }

  Future<void> unlock() async {
    unlockFromGesture();
  }

  Future<void> playCallSound() async {
    if (!_unlocked) return;
    try {
      final audio = html.AudioElement(_assetUrl)..preload = 'auto';
      await audio.play();
    } catch (_) {
      if (_audio != null) {
        _audio!.currentTime = 0;
        await _audio!.play();
      }
    }
  }

  void dispose() {
    _audio = null;
  }
}
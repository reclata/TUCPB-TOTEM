import 'call_sound_platform.dart';

class CallSoundService {
  CallSoundService._();
  static final CallSoundService instance = CallSoundService._();

  final CallSoundImpl _impl = CallSoundImpl();

  bool get isUnlocked => _impl.isUnlocked;

  void unlockFromGesture() => _impl.unlockFromGesture();

  Future<void> unlock() => _impl.unlock();

  Future<void> playCallSound() => _impl.playCallSound();

  void dispose() => _impl.dispose();
}
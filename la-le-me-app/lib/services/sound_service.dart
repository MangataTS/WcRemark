import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';

class SoundService {
  static AudioPlayer? _player;

  static Future<void> playWaterDrop(AppSettings settings) async {
    HapticFeedback.mediumImpact();

    if (settings.soundEffect != SoundEffect.none) {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.setVolume(settings.soundVolume);
      await _player!.play(AssetSource('sounds/water.mp3'));
    }
  }

  static void dispose() {
    _player?.dispose();
    _player = null;
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioHelper {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool isSoundEnabled = true;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isSoundEnabled = prefs.getBool('is_sound_enabled') ?? true;
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_sound_enabled', enabled);
    isSoundEnabled = enabled;
  }

  static Future<void> playCashSound() async {
    if (!isSoundEnabled) return;
    try {
      // Play sound from assets
      await _audioPlayer.play(AssetSource('cash_register.mp3'));
    } catch (e) {
      // Audio might fail in mock environments
    }
  }
}

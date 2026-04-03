import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;

  Future<bool> init() async {
    _isAvailable = await _speech.initialize();
    return _isAvailable;
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_isAvailable) await init();
    if (_isAvailable) {
      await _speech.listen(onResult: (result) {
        onResult(result.recognizedWords);
      });
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }
}

final speechServiceProvider = Provider((ref) => SpeechService());

import 'dart:js_interop';
import 'package:web/web.dart' as web;

web.HTMLAudioElement? _audioElement;

Future<void> reproduzirAudioWeb(String url) async {
  // Para qualquer áudio anterior
  _audioElement?.pause();
  _audioElement = null;

  final audio = web.HTMLAudioElement();
  audio.src = url;
  audio.controls = false;
  _audioElement = audio;

  await audio.play().toDart;
}

void pausarAudioWeb() {
  _audioElement?.pause();
}

bool get audioWebReproduzindo =>
    _audioElement != null && !_audioElement!.paused;
import 'dart:js_interop';
import 'package:web/web.dart' as web;

web.HTMLAudioElement? _audioElement;

Future<void> reproduzirAudioWeb(String url, {void Function()? onEnd}) async {
  _audioElement?.pause();
  _audioElement = null;

  final audio = web.HTMLAudioElement();
  audio.src = url;
  audio.controls = false;
  _audioElement = audio;

  // Detecta fim da reprodução na web
  if (onEnd != null) {
    audio.addEventListener(
      'ended',
      (web.Event e) {
        onEnd();
      }.toJS,
    );
  }

  await audio.play().toDart;
}

void pausarAudioWeb() {
  _audioElement?.pause();
}

bool get audioWebReproduzindo =>
    _audioElement != null && !_audioElement!.paused;
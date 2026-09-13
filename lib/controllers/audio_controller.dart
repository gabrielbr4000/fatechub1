import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:fatechub2/utils/blob_helper.dart';
import 'package:fatechub2/utils/audio_web_player.dart';

class AudioController extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _gravando = false;
  bool _reproduzindo = false;
  bool _carregandoUpload = false;
  String? _urlAtual; // URL sendo reproduzida no momento

  bool get gravando => _gravando;
  bool get reproduzindo => _reproduzindo;
  bool get carregandoUpload => _carregandoUpload;
  String? get urlAtual => _urlAtual;

  AudioController() {
    // Atualiza estado ao terminar de reproduzir
    _player.onPlayerComplete.listen((_) {
      _reproduzindo = false;
      _urlAtual = null;
      notifyListeners();
    });
  }

  // ─── Gravação ────────────────────────────────────────────────────────────────

  Future<void> iniciarGravacao() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    final encoder = kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc;
    final path = kIsWeb ? '' : await _getCaminhoAudio();

    await _recorder.start(RecordConfig(encoder: encoder), path: path);

    _gravando = true;
    notifyListeners();
  }

  Future<String?> pararGravacao() async {
    final path = await _recorder.stop();
    _gravando = false;
    notifyListeners();
    return path;
  }

  Future<void> cancelarGravacao() async {
    await _recorder.cancel();
    _gravando = false;
    notifyListeners();
  }

  // ─── Upload para Firebase Storage ────────────────────────────────────────────

  Future<String?> uploadAudio(String caminhoOuBlob, String conversaId) async {
    _carregandoUpload = true;
    notifyListeners();

    try {
      final nomeArquivo =
          'audio_${DateTime.now().millisecondsSinceEpoch}.${kIsWeb ? 'webm' : 'm4a'}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('audios')
          .child(conversaId)
          .child(nomeArquivo);

      if (kIsWeb) {
        debugPrint('📦 Convertendo blob para bytes...');
        final bytes = await fetchBlobBytes(caminhoOuBlob); // <- usa o helper
        if (bytes == null) {
          debugPrint('❌ Falha ao converter blob');
          return null;
        }
        debugPrint('✅ Bytes obtidos: ${bytes.length} bytes');
        await ref.putData(bytes, SettableMetadata(contentType: 'audio/webm'));
      } else {
        await ref.putFile(
          File(caminhoOuBlob),
          SettableMetadata(contentType: 'audio/m4a'),
        );
      }

      final url = await ref.getDownloadURL();
      debugPrint('✅ Upload concluído: $url');
      return url;
    } catch (e) {
      debugPrint('❌ Erro no upload: $e');
      return null;
    } finally {
      _carregandoUpload = false;
      notifyListeners();
    }
  }

  // Converte blob URL para bytes (somente web)
  Future<Uint8List?> _fetchBlobBytes(String blobUrl) async {
    try {
      // Usa XMLHttpRequest via dart:html na web
      if (kIsWeb) {
        // ignore: avoid_web_libraries_in_flutter
        // Retorna null — implementar com dart:js_interop se necessário
        debugPrint('Blob URL: $blobUrl');
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── Reprodução ──────────────────────────────────────────────────────────────

  Future<void> reproduzir(String url) async {
  if (_reproduzindo && _urlAtual == url) {
    await pausar();
    return;
  }

  _urlAtual = url;

  if (kIsWeb) {
    await reproduzirAudioWeb(url);
  } else {
    await _player.stop();
    await _player.play(UrlSource(url));
  }

  _reproduzindo = true;
  notifyListeners();
}

Future<void> pausar() async {
  if (kIsWeb) {
    pausarAudioWeb();
  } else {
    await _player.pause();
  }
  _reproduzindo = false;
  notifyListeners();
}

  bool estaReproduzindo(String url) => _reproduzindo && _urlAtual == url;

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Future<String> _getCaminhoAudio() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }
}

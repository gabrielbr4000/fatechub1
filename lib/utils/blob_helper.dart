import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

Future<Uint8List?> fetchBlobBytes(String blobUrl) async {
  if (!kIsWeb) return null;

  final completer = Completer<Uint8List?>();

  try {
    final response = await web.window.fetch(blobUrl.toJS).toDart;
    final arrayBuffer = await response.arrayBuffer().toDart;
    final bytes = Uint8List.view(arrayBuffer.toDart);
    completer.complete(bytes);
  } catch (e) {
    debugPrint('Erro ao buscar blob: $e');
    completer.complete(null);
  }

  return completer.future;
}
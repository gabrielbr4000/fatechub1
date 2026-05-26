import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uidAtual => _auth.currentUser!.uid;

  // ─── Buscar usuários pelo nome ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> buscarUsuarios(String nome) async {
    final nomeLower = nome.trim().toLowerCase();

    final resultado = await _db
        .collection('usuarios')
        .where('nomeLower', isGreaterThanOrEqualTo: nomeLower)
        .where('nomeLower', isLessThanOrEqualTo: '$nomeLower\uf8ff')
        .get();

    return resultado.docs
        .map((doc) => {'uid': doc.id, ...doc.data()})
        .where((u) => u['uid'] != _uidAtual)
        .toList();
  }

  // ─── Criar ou abrir conversa entre dois usuários ──────────────────────────

  Future<String> abrirOuCriarConversa(String uidOutro) async {
    final existente = await _db
        .collection('conversas')
        .where('participantes', arrayContains: _uidAtual)
        .get();

    for (final doc in existente.docs) {
      final participantes = List<String>.from(doc['participantes']);
      if (participantes.contains(uidOutro)) {
        return doc.id;
      }
    }

    final novaConversa = await _db.collection('conversas').add({
      'participantes': [_uidAtual, uidOutro],
      'ultimaMensagem': '',
      'ultimoHorario': FieldValue.serverTimestamp(),
      'naoLidas': {},
    });

    return novaConversa.id;
  }

  // ─── Enviar mensagem ──────────────────────────────────────────────────────

  Future<void> enviarMensagem(String conversaId, String texto, String uidOutro) async {
    final horario = FieldValue.serverTimestamp();

    await _db
        .collection('conversas')
        .doc(conversaId)
        .collection('mensagens')
        .add({
      'texto': texto,
      'remetente': _uidAtual,
      'horario': horario,
    });

    await _db.collection('conversas').doc(conversaId).update({
      'ultimaMensagem': texto,
      'ultimoHorario': horario,
      'naoLidas.$uidOutro': FieldValue.increment(1), // incrementa para o destinatário
    });
  }

  // ─── Zerar mensagens não lidas ao abrir o chat ───────────────────────────

  Future<void> zerarNaoLidas(String conversaId) async {
    await _db.collection('conversas').doc(conversaId).update({
      'naoLidas.$_uidAtual': 0,
    });
  }

  // ─── Ouvir mensagens em tempo real ───────────────────────────────────────

  Stream<QuerySnapshot> ouvirMensagens(String conversaId) {
    return _db
        .collection('conversas')
        .doc(conversaId)
        .collection('mensagens')
        .orderBy('horario', descending: false)
        .snapshots();
  }

  // ─── Ouvir conversas do usuário logado ───────────────────────────────────

  Stream<QuerySnapshot> ouvirConversas() {
    return _db
        .collection('conversas')
        .where('participantes', arrayContains: _uidAtual)
        .snapshots();
  }

  // ─── Buscar dados de um usuário pelo UID ─────────────────────────────────

  Future<Map<String, dynamic>?> buscarUsuarioPorUid(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (!doc.exists) return null;
    return {'uid': doc.id, ...doc.data()!};
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum ContaEstado { inicial, carregando, sucesso, erro }

class ContaController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ContaEstado _estado = ContaEstado.inicial;
  String? _mensagemErro;
  Map<String, dynamic>? _dadosUsuario;

  ContaEstado get estado => _estado;
  bool get carregando => _estado == ContaEstado.carregando;
  String? get mensagemErro => _mensagemErro;
  Map<String, dynamic>? get dadosUsuario => _dadosUsuario;

  // ─── Buscar dados do usuário no Firestore ────────────────────────────────────

  Future<void> buscarDados() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _estado = ContaEstado.carregando;
    notifyListeners();

    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      _dadosUsuario = doc.data();
      _estado = ContaEstado.inicial;
    } catch (e) {
      _estado = ContaEstado.erro;
      _mensagemErro = 'Erro ao carregar dados. Tente novamente.';
    }

    notifyListeners();
  }

  // ─── Alterar senha ───────────────────────────────────────────────────────────

  Future<bool> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
    required String confirmarSenha,
  }) async {
    // Validações
    if (senhaAtual.isEmpty) {
      _mensagemErro = 'Informe a senha atual.';
      notifyListeners();
      return false;
    }
    if (novaSenha.length < 6) {
      _mensagemErro = 'A nova senha deve ter pelo menos 6 caracteres.';
      notifyListeners();
      return false;
    }
    if (novaSenha != confirmarSenha) {
      _mensagemErro = 'As senhas não coincidem.';
      notifyListeners();
      return false;
    }

    _estado = ContaEstado.carregando;
    _mensagemErro = null;
    notifyListeners();

    try {
      final user = _auth.currentUser!;

      // Reautentica com a senha atual antes de alterar
      final credencial = EmailAuthProvider.credential(
        email: user.email!,
        password: senhaAtual.trim(),
      );
      await user.reauthenticateWithCredential(credencial);

      // Atualiza a senha
      await user.updatePassword(novaSenha.trim());

      _estado = ContaEstado.sucesso;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _estado = ContaEstado.erro;
      _mensagemErro = _traduzirErro(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _estado = ContaEstado.erro;
      _mensagemErro = 'Erro inesperado. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  // ─── Alterar nome ───────────────────────────────────────────────────────────

  Future<bool> alterarNome(String novoNome) async {
  if (novoNome.trim().isEmpty) {
    _mensagemErro = 'O nome não pode estar vazio.';
    notifyListeners();
    return false;
  }

  _estado = ContaEstado.carregando;
  _mensagemErro = null;
  notifyListeners();

  try {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("Usuário não autenticado");

    // Atualiza o campo 'nome' no documento do usuário
    await _db.collection('usuarios').doc(uid).update({
      'nome': novoNome.trim(),
    });

    _estado = ContaEstado.sucesso;
    notifyListeners();
    return true;
  } catch (e) {
    _estado = ContaEstado.erro;
    _mensagemErro = 'Erro ao atualizar o nome. Tente novamente.';
    notifyListeners();
    return false;
  }
}

  // ─── Resetar estado ──────────────────────────────────────────────────────────

  void resetarEstado() {
    _estado = ContaEstado.inicial;
    _mensagemErro = null;
    notifyListeners();
  }

  // ─── Tradução de erros ───────────────────────────────────────────────────────

  String _traduzirErro(String code) {
    return switch (code) {
      'wrong-password'        => 'Senha atual incorreta.',
      'weak-password'         => 'A nova senha é muito fraca.',
      'requires-recent-login' => 'Faça login novamente antes de alterar a senha.',
      'network-request-failed'=> 'Sem conexão. Verifique sua internet.',
      _                       => 'Erro ao alterar senha. Tente novamente.',
    };
  }
}
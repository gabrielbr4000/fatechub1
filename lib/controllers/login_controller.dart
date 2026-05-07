import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum LoginEstado { inicial, carregando, sucesso, erro }

class LoginController extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  LoginEstado _estado = LoginEstado.inicial;
  bool _senhaVisivel = false;
  String? _mensagemErro;

  LoginEstado get estado => _estado;
  bool get senhaVisivel => _senhaVisivel;
  bool get carregando => _estado == LoginEstado.carregando;
  String? get mensagemErro => _mensagemErro;

  void toggleSenhaVisivel() {         // Função para alternar a visibilidade da senha no campo de input
    _senhaVisivel = !_senhaVisivel;
    notifyListeners();
  }

  Future<void> login() async {
  if (!_validar()) return;

  _estado = LoginEstado.carregando;
  _mensagemErro = null;
  notifyListeners();

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: senhaController.text.trim(),
    );

    _estado = LoginEstado.sucesso;

  } on FirebaseAuthException catch (e) {
    _estado = LoginEstado.erro;
    _mensagemErro = _traduzirErro(e.code);

  } catch (e) {
    _estado = LoginEstado.erro;
    _mensagemErro = 'Erro ao conectar. Tente novamente.';
  }

  notifyListeners();
}
// Traduz os códigos de erro do Firebase para português
String _traduzirErro(String code) {
  return switch (code) {
    'user-not-found'          => 'E-mail não encontrado.',
    'wrong-password'          => 'Senha incorreta.',
    'invalid-email'           => 'E-mail inválido.',
    'user-disabled'           => 'Usuário desativado.',
    'too-many-requests'       => 'Muitas tentativas. Tente mais tarde.',
    _                         => 'Erro ao fazer login. Tente novamente.',

  };
}

  bool _validar() {
    if (emailController.text.trim().isEmpty) {
      _mensagemErro = 'Informe o RA.';
      _estado = LoginEstado.erro;
      notifyListeners();
      return false;
    }
    if (senhaController.text.trim().isEmpty) {
      _mensagemErro = 'Informe a senha.';
      _estado = LoginEstado.erro;
      notifyListeners();
      return false;
    }
    return true;
  }

  void resetarErro() {
    if (_estado == LoginEstado.erro) {
      _estado = LoginEstado.inicial;
      _mensagemErro = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }
}
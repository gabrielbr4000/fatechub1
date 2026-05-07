import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
 
enum CadastroEstado { inicial, carregando, sucesso, erro }
 
class CadastroController extends ChangeNotifier {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController raController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController = TextEditingController();
 
  CadastroEstado _estado = CadastroEstado.inicial;
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  String? _mensagemErro;
 
  CadastroEstado get estado => _estado;
  bool get senhaVisivel => _senhaVisivel;
  bool get confirmarSenhaVisivel => _confirmarSenhaVisivel;
  bool get carregando => _estado == CadastroEstado.carregando;
  String? get mensagemErro => _mensagemErro;
 
  void toggleSenhaVisivel() {
    _senhaVisivel = !_senhaVisivel;
    notifyListeners();
  }
 
  void toggleConfirmarSenhaVisivel() {
    _confirmarSenhaVisivel = !_confirmarSenhaVisivel;
    notifyListeners();
  }
 
  void resetarErro() {
    if (_estado == CadastroEstado.erro) {
      _estado = CadastroEstado.inicial;
      _mensagemErro = null;
      notifyListeners();
    }
  }
 
  bool validar() {
    if (nomeController.text.trim().isEmpty) {
      _mensagemErro = 'Informe o nome.';
      _estado = CadastroEstado.erro;
      notifyListeners();
      return false;
    }
    if (raController.text.trim().isEmpty) {
      _mensagemErro = 'Informe o RA.';
      _estado = CadastroEstado.erro;
      notifyListeners();
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      _mensagemErro = 'Informe o e-mail.';
      _estado = CadastroEstado.erro;
      notifyListeners();
      return false;
    }
    if (senhaController.text.isEmpty) {
      _mensagemErro = 'Informe a senha.';
      _estado = CadastroEstado.erro;
      notifyListeners();
      return false;
    }
    if (senhaController.text.length < 6) {
      _mensagemErro = 'A senha deve ter pelo menos 6 caracteres.';
      _estado = CadastroEstado.erro;
      notifyListeners();
      return false;
    }
    if (confirmarSenhaController.text != senhaController.text) {
      _mensagemErro = 'As senhas não coincidem.';
      _estado = CadastroEstado.erro;
      notifyListeners();
      return false;
    }
    return true;
  }
 
  Future<void> cadastrar() async {
    if (!validar()) return;
 
    _estado = CadastroEstado.carregando;
    _mensagemErro = null;
    notifyListeners();
 
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text.trim(),
      );
 
      await FirebaseAuth.instance.currentUser?.updateDisplayName(
        nomeController.text.trim(),
      );
 
      _estado = CadastroEstado.sucesso;
    } on FirebaseAuthException catch (e) {
      _estado = CadastroEstado.erro;
      _mensagemErro = _traduzirErro(e.code);
    } catch (e) {
      _estado = CadastroEstado.erro;
      _mensagemErro = 'Erro inesperado. Tente novamente.';
    }
 
    notifyListeners();
  }
 
  String _traduzirErro(String code) {
    return switch (code) {
      'email-already-in-use'   => 'Este e-mail já está em uso.',
      'invalid-email'          => 'E-mail inválido.',
      'weak-password'          => 'A senha deve ter pelo menos 6 caracteres.',
      'network-request-failed' => 'Sem conexão. Verifique sua internet.',
      _                        => 'Erro ao cadastrar. Tente novamente.',
    };
  }
 
  @override
  void dispose() {
    nomeController.dispose();
    raController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }
}
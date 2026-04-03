import 'package:flutter/material.dart';

enum LoginEstado { inicial, carregando, sucesso, erro }

class LoginController extends ChangeNotifier {
  final TextEditingController raController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

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
      // Substituir pela chamada real da API mais tarde
      await Future.delayed(const Duration(seconds: 2));

      final ra = raController.text.trim();
      final senha = senhaController.text.trim();

      // Simulação de autenticação — remover quando integrar com o backend
      if (ra == 'admin' && senha == 'admin') {
        _estado = LoginEstado.sucesso;
      } else {
        _estado = LoginEstado.erro;
        _mensagemErro = 'RA ou senha inválidos.';
      }
    } catch (e) {
      _estado = LoginEstado.erro;
      _mensagemErro = 'Erro ao conectar. Tente novamente.';
    }

    notifyListeners();
  }

  bool _validar() {
    if (raController.text.trim().isEmpty) {
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
    raController.dispose();
    senhaController.dispose();
    super.dispose();
  }
}
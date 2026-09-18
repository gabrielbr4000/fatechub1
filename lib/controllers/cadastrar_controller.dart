import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum CadastroEstado { inicial, carregando, sucesso, erro }

class CadastroController extends ChangeNotifier {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController raController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController confirmarSenhaController =
      TextEditingController();

  CadastroEstado _estado = CadastroEstado.inicial;

  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  String? _mensagemErro;
  String? _cursoSelecionado;
  String? _disciplinaSelecionada;
  String? _turnoSelecionado;
  int? _semestreSelecionado;

  // ─── Cursos (para aluno) ──────────────────────────────────────────────────

  static const List<String> cursos = [
    'Análise e Desenvolvimento de Sistemas',
    'Gestão de Recursos Humanos',
    'Gestão de Negócios e Inovação',
    'Sistemas Biomédicos',
  ];

  // ─── Semestres (para aluno) ───────────────────────────────────────────────

  static const List<int> semestres = [1, 2, 3, 4, 5, 6];

  // ─── Disciplinas ADS (para professor) ────────────────────────────────────

  static const List<String> disciplinasADS = [
    // 1º Semestre
    'Engenharia de Software I',
    'Sistemas Operacionais',
    'Comunicação e Expressão',
    'Inglês I',
    'PI ADS I',
    'Algoritmos e Lógica de Programação',
    'Arquitetura e Organização de Computadores',

    // 2º Semestre
    'Cibersegurança e Segurança da Informação',
    'Linguagem de Programação I',
    'Inglês II',
    'Engenharia de Software II',
    'PI ADS II',
    'Banco de Dados I',
    'Desenvolvimento Web',
  ];

  // ─── Getters ─────────────────────────────────────────────────────────────

  CadastroEstado get estado => _estado;

  bool get senhaVisivel => _senhaVisivel;

  bool get confirmarSenhaVisivel => _confirmarSenhaVisivel;

  bool get carregando => _estado == CadastroEstado.carregando;

  String? get mensagemErro => _mensagemErro;

  String? get cursoSelecionado => _cursoSelecionado;

  String? get disciplinaSelecionada => _disciplinaSelecionada;

  String? get turnoSelecionado => _turnoSelecionado;

  int? get semestreSelecionado => _semestreSelecionado;

  // ─── Seleções ────────────────────────────────────────────────────────────

  void selecionarCurso(String? curso) {
    _cursoSelecionado = curso;
    notifyListeners();
  }

  void selecionarDisciplina(String? disciplina) {
    _disciplinaSelecionada = disciplina;
    notifyListeners();
  }

  void selecionarSemestre(int? semestre) {
    _semestreSelecionado = semestre;
    notifyListeners();
  }

  void selecionarTurno(String? turno) {
    _turnoSelecionado = turno;
    notifyListeners();
  }

  // ─── Senha ───────────────────────────────────────────────────────────────

  void toggleSenhaVisivel() {
    _senhaVisivel = !_senhaVisivel;
    notifyListeners();
  }

  void toggleConfirmarSenhaVisivel() {
    _confirmarSenhaVisivel = !_confirmarSenhaVisivel;
    notifyListeners();
  }

  // ─── Erros ───────────────────────────────────────────────────────────────

  void resetarErro() {
    if (_estado == CadastroEstado.erro) {
      _estado = CadastroEstado.inicial;
      _mensagemErro = null;
      notifyListeners();
    }
  }

  // ─── Validação do aluno ─────────────────────────────────────────────────

  bool validarAluno() {
    if (nomeController.text.trim().isEmpty) {
      return _setErro('Informe o nome.');
    }

    if (raController.text.trim().isEmpty) {
      return _setErro('Informe o RA.');
    }

    if (_cursoSelecionado == null) {
      return _setErro('Selecione o seu curso.');
    }

    if (_semestreSelecionado == null) {
      return _setErro('Selecione o seu semestre.');
    }

    if (_turnoSelecionado == null) {
      return _setErro('Selecione o seu turno.');
    }

    if (emailController.text.trim().isEmpty) {
      return _setErro('Informe o e-mail.');
    }

    if (senhaController.text.isEmpty) {
      return _setErro('Informe a senha.');
    }

    if (senhaController.text.length < 6) {
      return _setErro(
        'A senha deve ter pelo menos 6 caracteres.',
      );
    }

    if (confirmarSenhaController.text != senhaController.text) {
      return _setErro('As senhas não coincidem.');
    }

    return true;
  }

  // ─── Validação do professor ─────────────────────────────────────────────

  bool validarProfessor() {
    if (nomeController.text.trim().isEmpty) {
      return _setErro('Informe o nome.');
    }

    if (_disciplinaSelecionada == null) {
      return _setErro('Selecione sua disciplina.');
    }

    if (emailController.text.trim().isEmpty) {
      return _setErro('Informe o e-mail.');
    }

    if (senhaController.text.isEmpty) {
      return _setErro('Informe a senha.');
    }

    if (senhaController.text.length < 6) {
      return _setErro(
        'A senha deve ter pelo menos 6 caracteres.',
      );
    }

    if (confirmarSenhaController.text != senhaController.text) {
      return _setErro('As senhas não coincidem.');
    }

    return true;
  }

  bool _setErro(String mensagem) {
    _mensagemErro = mensagem;
    _estado = CadastroEstado.erro;
    notifyListeners();
    return false;
  }

  // ─── Cadastro do aluno ──────────────────────────────────────────────────

  Future<void> cadastrarAluno() async {
    if (!validarAluno()) return;

    await _cadastrar(
      perfil: 'aluno',
      extras: {
        'ra': raController.text.trim(),
        'curso': _cursoSelecionado,
        'semestre': _semestreSelecionado,
        'turno': _turnoSelecionado,
      },
    );
  }

  // ─── Cadastro do professor ──────────────────────────────────────────────

  Future<void> cadastrarProfessor() async {
    if (!validarProfessor()) return;

    await _cadastrar(
      perfil: 'professor',
      extras: {
        'disciplina': _disciplinaSelecionada,
        'curso': 'Análise e Desenvolvimento de Sistemas',
      },
    );
  }

  // ─── Cadastro no Firebase ────────────────────────────────────────────────

  Future<void> _cadastrar({
    required String perfil,
    required Map<String, dynamic> extras,
  }) async {
    _estado = CadastroEstado.carregando;
    _mensagemErro = null;
    notifyListeners();

    try {
      final credencial =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text.trim(),
      );

      final uid = credencial.user!.uid;

      await credencial.user!.updateDisplayName(
        nomeController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .set({
        'uid': uid,
        'nome': nomeController.text.trim(),
        'nomeLower': nomeController.text.trim().toLowerCase(),
        'email': emailController.text.trim(),
        'perfil': perfil,
        'criadoEm': FieldValue.serverTimestamp(),
        ...extras,
      });

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

  // ─── Tradução dos erros do Firebase ─────────────────────────────────────

  String _traduzirErro(String code) {
    return switch (code) {
      'email-already-in-use' => 'Este e-mail já está em uso.',
      'invalid-email' => 'E-mail inválido.',
      'weak-password' => 'A senha deve ter pelo menos 6 caracteres.',
      'network-request-failed' =>
        'Sem conexão. Verifique sua internet.',
      _ => 'Erro ao cadastrar. Tente novamente.',
    };
  }

  // ─── Dispose ────────────────────────────────────────────────────────────

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


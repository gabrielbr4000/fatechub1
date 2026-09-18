import '../controllers/cadastrar_controller.dart';
import 'package:flutter/material.dart';
import 'package:fatechub2/controllers/theme_controller.dart';
import 'app_shell.dart';

class TelaCadastro extends StatefulWidget {
  final ThemeController themeController;

  const TelaCadastro({
    super.key,
    required this.themeController,
  });

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final CadastroController _controller = CadastroController();
  String? _perfilSelecionado;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onEstadoMudou);
  }

  void _onEstadoMudou() {
    if (_controller.estado == CadastroEstado.sucesso) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AppShell(
            themeController: widget.themeController,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onEstadoMudou);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 80),
                      _buildLogo(),
                      const SizedBox(height: 40),
                      if (_perfilSelecionado == null)
                        _buildSelecaoPerfil()
                      else if (_perfilSelecionado == 'aluno')
                        _buildFormularioAluno()
                      else
                        _buildFormularioProfessor(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              _buildRodape(),
            ],
          );
        },
      ),
    );
  }

  // ─── Seleção de perfil ────────────────────────────────────────────────────

  Widget _buildSelecaoPerfil() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            children: [
              Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Voltar',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Quem é você?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecione o seu perfil para continuar o cadastro.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        _buildBotaoPerfil(
          label: 'Aluno',
          icone: Icons.school_outlined,
          onTap: () {
            setState(() => _perfilSelecionado = 'aluno');
          },
        ),
        const SizedBox(height: 16),
        _buildBotaoPerfil(
          label: 'Professor',
          icone: Icons.person_outlined,
          onTap: () {
            setState(() => _perfilSelecionado = 'professor');
          },
        ),
      ],
    );
  }

  Widget _buildBotaoPerfil({
    required String label,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surface,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF8B0000)
                .withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset:
                  const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              color:
                  const Color(0xFF8B0000),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Formulário Aluno ─────────────────────────────────────────────────────

  Widget _buildFormularioAluno() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        _buildBotaoVoltar(),
        const SizedBox(height: 20),

        _buildLabel('Nome'),
        const SizedBox(height: 6),
        _buildCampoNome(),

        const SizedBox(height: 20),

        _buildLabel('RA'),
        const SizedBox(height: 6),
        _buildCampoRA(),

        const SizedBox(height: 20),

        _buildLabel('Curso'),
        const SizedBox(height: 6),
        _buildDropdownCurso(),

        const SizedBox(height: 20),

        _buildLabel('Semestre'),
        const SizedBox(height: 6),
        _buildDropdownSemestre(),

        // ─── NOVO CAMPO: TURNO ────────────────────────────────────────

        const SizedBox(height: 20),

        _buildLabel('Turno'),
        const SizedBox(height: 6),
        _buildDropdownTurno(),

        // ──────────────────────────────────────────────────────────────

        const SizedBox(height: 20),

        _buildLabel('Email'),
        const SizedBox(height: 6),
        _buildCampoEmail(),

        const SizedBox(height: 20),

        _buildLabel('Senha'),
        const SizedBox(height: 6),
        _buildCampoSenha(),

        const SizedBox(height: 6),

        _buildLabel('Confirmar Senha'),
        const SizedBox(height: 6),
        _buildCampoConfSenha(),

        if (_controller.mensagemErro != null) ...[
          const SizedBox(height: 12),
          _buildMensagemErro(),
        ],

        const SizedBox(height: 28),

        _buildBotaoCadastrar(
          onPressed: _controller.cadastrarAluno,
        ),
      ],
    );
  }

  // ─── Formulário Professor ─────────────────────────────────────────────────

  Widget _buildFormularioProfessor() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        _buildBotaoVoltar(),
        const SizedBox(height: 20),

        _buildLabel('Nome'),
        const SizedBox(height: 6),
        _buildCampoNome(),

        const SizedBox(height: 20),

        _buildLabel('Disciplina que leciona'),
        const SizedBox(height: 6),
        _buildDropdownDisciplina(),

        const SizedBox(height: 20),

        _buildLabel('Email'),
        const SizedBox(height: 6),
        _buildCampoEmail(),

        const SizedBox(height: 20),

        _buildLabel('Senha'),
        const SizedBox(height: 6),
        _buildCampoSenha(),

        const SizedBox(height: 6),

        _buildLabel('Confirmar Senha'),
        const SizedBox(height: 6),
        _buildCampoConfSenha(),

        if (_controller.mensagemErro != null) ...[
          const SizedBox(height: 12),
          _buildMensagemErro(),
        ],

        const SizedBox(height: 28),

        _buildBotaoCadastrar(
          onPressed:
              _controller.cadastrarProfessor,
        ),
      ],
    );
  }

  // ─── Dropdowns ────────────────────────────────────────────────────────────

  Widget _buildDropdownCurso() {
    return DropdownButtonFormField<String>(
      value: _controller.cursoSelecionado,
      hint: Text(
        'Selecione o seu curso',
        style: TextStyle(
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      decoration: _inputDecoration(),
      items: CadastroController.cursos
          .map(
            (c) => DropdownMenuItem<String>(
              value: c,
              child: Text(c),
            ),
          )
          .toList(),
      onChanged: (value) {
        _controller.selecionarCurso(value);
        _controller.resetarErro();
      },
    );
  }

  // ─── Dropdown Semestre ────────────────────────────────────────────────────

  Widget _buildDropdownSemestre() {
    return DropdownButtonFormField<int>(
      value: _controller.semestreSelecionado,
      hint: Text(
        'Selecione o seu semestre',
        style: TextStyle(
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      decoration: _inputDecoration(),
      items: CadastroController.semestres
          .map(
            (semestre) =>
                DropdownMenuItem<int>(
              value: semestre,
              child: Text('$semestreº Semestre'),
            ),
          )
          .toList(),
      onChanged: (value) {
        _controller.selecionarSemestre(value);
        _controller.resetarErro();
      },
    );
  }

  // ─── Dropdown Turno ───────────────────────────────────────────────────────

  Widget _buildDropdownTurno() {
    return DropdownButtonFormField<String>(
      value: _controller.turnoSelecionado,
      hint: Text(
        'Selecione o seu turno',
        style: TextStyle(
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      decoration: _inputDecoration(),
      items: const [
        DropdownMenuItem<String>(
          value: 'MANHA',
          child: Text('Manhã'),
        ),
        DropdownMenuItem<String>(
          value: 'NOITE',
          child: Text('Noite'),
        ),
      ],
      onChanged: (value) {
        _controller.selecionarTurno(value);
        _controller.resetarErro();
      },
    );
  }

  Widget _buildDropdownDisciplina() {
    return DropdownButtonFormField<String>(
      value:
          _controller.disciplinaSelecionada,
      hint: Text(
        'Selecione a sua disciplina',
        style: TextStyle(
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      decoration: _inputDecoration(),
      isExpanded: true,
      items: CadastroController.disciplinasADS
          .map(
            (d) => DropdownMenuItem<String>(
              value: d,
              child: Text(d),
            ),
          )
          .toList(),
      onChanged: (value) {
        _controller.selecionarDisciplina(value);
        _controller.resetarErro();
      },
    );
  }

  // ─── Campos comuns ────────────────────────────────────────────────────────

  Widget _buildBotaoVoltar() {
    return GestureDetector(
      onTap: () {
        setState(() => _perfilSelecionado = null);
      },
      child: Row(
        children: [
          Icon(
            Icons.arrow_back_ios,
            size: 16,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            'Voltar',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Text(
          'Fatec',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Theme.of(context)
                .colorScheme
                .onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Faculdade de Tecnologia',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context)
                .colorScheme
                .onSurface,
            fontWeight:
                FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String texto) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 15,
        color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant,
        fontWeight:
            FontWeight.w500,
      ),
    );
  }

  Widget _buildCampoNome() {
    return TextField(
      controller:
          _controller.nomeController,
      keyboardType:
          TextInputType.text,
      onChanged: (_) =>
          _controller.resetarErro(),
      decoration:
          _inputDecoration(),
    );
  }

  Widget _buildCampoEmail() {
    return TextField(
      controller:
          _controller.emailController,
      keyboardType:
          TextInputType.emailAddress,
      onChanged: (_) =>
          _controller.resetarErro(),
      decoration:
          _inputDecoration(),
    );
  }

  Widget _buildCampoRA() {
    return TextField(
      controller:
          _controller.raController,
      keyboardType:
          TextInputType.number,
      onChanged: (_) =>
          _controller.resetarErro(),
      decoration:
          _inputDecoration(),
    );
  }

  Widget _buildCampoSenha() {
    return TextField(
      controller:
          _controller.senhaController,
      obscureText:
          !_controller.senhaVisivel,
      onChanged: (_) =>
          _controller.resetarErro(),
      decoration:
          _inputDecoration(
        suffixIcon:
            IconButton(
          icon: Icon(
            _controller.senhaVisivel
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
            size: 22,
          ),
          onPressed:
              _controller
                  .toggleSenhaVisivel,
        ),
      ),
    );
  }

  Widget _buildCampoConfSenha() {
    return TextField(
      controller:
          _controller.confirmarSenhaController,
      obscureText:
          !_controller.confirmarSenhaVisivel,
      onChanged: (_) =>
          _controller.resetarErro(),
      decoration:
          _inputDecoration(
        suffixIcon:
            IconButton(
          icon: Icon(
            _controller.confirmarSenhaVisivel
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
            size: 22,
          ),
          onPressed:
              _controller
                  .toggleConfirmarSenhaVisivel,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(4),
        borderSide:
            BorderSide(
          color: Theme.of(context)
              .colorScheme
              .onSurface,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(4),
        borderSide:
            BorderSide(
          color: Theme.of(context)
              .colorScheme
              .onSurface,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(4),
        borderSide:
            const BorderSide(
          color: Color(0xFF8B0000),
          width: 1.5,
        ),
      ),
      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(4),
        borderSide:
            const BorderSide(
          color: Color(0xFF8B0000),
        ),
      ),
    );
  }

  Widget _buildMensagemErro() {
    return Text(
      _controller.mensagemErro!,
      style: const TextStyle(
        color: Color(0xFF8B0000),
        fontSize: 13,
      ),
    );
  }

  Widget _buildBotaoCadastrar({
    required VoidCallback onPressed,
  }) {
    return Center(
      child: SizedBox(
        width: 120,
        height: 44,
        child: ElevatedButton(
          onPressed:
              _controller.carregando
                  ? null
                  : onPressed,
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF8B0000),
            disabledBackgroundColor:
                const Color(0xFF8B0000)
                    .withOpacity(0.6),
            foregroundColor:
                Colors.white,
            elevation: 2,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(6),
            ),
          ),
          child:
              _controller.carregando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Cadastrar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildRodape() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1A1A),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 20,
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _RodapeTexto(
            negrito: 'ALUNO:',
            normal:
                ' Faça login com seu e-mail e senha.',
          ),
          SizedBox(height: 10),
          _RodapeTexto(
            negrito: 'PROFESSOR:',
            normal:
                ' Faça login com seu e-mail e senha.',
          ),
        ],
      ),
    );
  }
}

class _RodapeTexto extends StatelessWidget {
  final String negrito;
  final String normal;

  const _RodapeTexto({
    required this.negrito,
    required this.normal,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: negrito,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          TextSpan(
            text: normal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight:
                  FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../controllers/cadastrar_controller.dart';
import 'app_shell.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final CadastroController _controller = CadastroController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onEstadoMudou);
  }

  void _onEstadoMudou() {
    if (_controller.estado == CadastroEstado.sucesso) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()), // Após realizar o login, ele chama a navbar para a aplicação
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
      backgroundColor: Colors.white,
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 80),
                      _buildLogo(),
                      const SizedBox(height: 60),
                      _buildLabel('Nome'),
                      const SizedBox(height: 6),
                      _buildCampoNome(),
                      const SizedBox(height: 20),
                      _buildLabel('RA'),
                      const SizedBox(height: 6),
                      _buildCampoRA(),
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
                      const SizedBox(height: 6),
                      if (_controller.mensagemErro != null) ...[
                        const SizedBox(height: 12),
                        _buildMensagemErro(),
                      ],
                      const SizedBox(height: 28),
                      _buildBotaoCadastrar(),
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

  Widget _buildLogo() {
    return Column(
      children: [
        Text(
          'Fatec',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Faculdade de Tecnologia',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF424242),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildCampoNome() {
    return TextField(
      controller: _controller.nomeController,
      keyboardType: TextInputType.number,
      onChanged: (_) => _controller.resetarErro(),
      decoration: _inputDecoration(),
    );
  }

  Widget _buildCampoEmail() {
    return TextField(
      controller: _controller.emailController,
      keyboardType: TextInputType.number,
      onChanged: (_) => _controller.resetarErro(),
      decoration: _inputDecoration(),
    );
  }

  Widget _buildCampoRA() {
    return TextField(
      controller: _controller.raController,
      keyboardType: TextInputType.number,
      onChanged: (_) => _controller.resetarErro(),
      decoration: _inputDecoration(),
    );
  }

  Widget _buildCampoSenha() {
    return TextField(
      controller: _controller.senhaController,
      obscureText: !_controller.senhaVisivel,
      onChanged: (_) => _controller.resetarErro(),
      decoration: _inputDecoration(
        suffixIcon: IconButton(
          icon: Icon(
            _controller.senhaVisivel
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey[600],
            size: 22,
          ),
          onPressed: _controller.toggleSenhaVisivel,
        ),
      ),
    );
  }

  Widget _buildCampoConfSenha() {
    return TextField(
      controller: _controller.confirmarSenhaController,
      obscureText: !_controller.confirmarSenhaVisivel,
      onChanged: (_) => _controller.resetarErro(),
      decoration: _inputDecoration(
        suffixIcon: IconButton(
          icon: Icon(
            _controller.confirmarSenhaVisivel
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey[600],
            size: 22,
          ),
          onPressed: _controller.toggleConfirmarSenhaVisivel,
        ),
      ),
    );
  }


  InputDecoration _inputDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF8B0000), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF8B0000)),
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

  Widget _buildBotaoCadastrar() {
    return Center(
      child: SizedBox(
        width: 120,
        height: 44,
        child: ElevatedButton(
          onPressed: _controller.carregando ? null : () => _controller.cadastrar(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B0000),
            disabledBackgroundColor: const Color(0xFF8B0000).withOpacity(0.6),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: _controller.carregando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Cadastrar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Widget _buildRodape() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RodapeTexto(
            negrito: 'ALUNO:',
            normal: ' Faça login com seu RA e senha.',
          ),
          SizedBox(height: 10),
          _RodapeTexto(
            negrito: 'PROFESSOR:',
            normal: ' Faça login com seu usuário de rede interna.',
          ),
        ],
      ),
    );
  }
}

class _RodapeTexto extends StatelessWidget {
  final String negrito;
  final String normal;

  const _RodapeTexto({required this.negrito, required this.normal});

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
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: normal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
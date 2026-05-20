import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TelaRecuperarSenha extends StatefulWidget {
  const TelaRecuperarSenha({super.key});

  @override
  State<TelaRecuperarSenha> createState() => _TelaRecuperarSenhaState();
}

class _TelaRecuperarSenhaState extends State<TelaRecuperarSenha> {
  final TextEditingController _emailController = TextEditingController();
  bool _carregando = false;
  bool _enviado = false;
  String? _mensagemErro;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _mensagemErro = 'Informe o e-mail.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _mensagemErro = 'E-mail inválido.');
      return;
    }

    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      setState(() => _enviado = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _mensagemErro = _traduzirErro(e.code));
    } catch (e) {
      if (!mounted) return;
      setState(() => _mensagemErro = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _traduzirErro(String code) {
    return switch (code) {
      'user-not-found'         => 'Nenhuma conta encontrada com este e-mail.',
      'invalid-email'          => 'E-mail inválido.',
      'network-request-failed' => 'Sem conexão. Verifique sua internet.',
      _                        => 'Erro ao enviar. Tente novamente.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80),
                  _buildLogo(),
                  const SizedBox(height: 40),
                  _buildTitulo(),
                  const SizedBox(height: 12),
                  _buildSubtitulo(),
                  const SizedBox(height: 32),
                  _enviado ? _buildSucesso() : _buildFormulario(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildRodape(),
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
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Faculdade de Tecnologia',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildTitulo() {
    return Text(
      'Recuperar senha',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSubtitulo() {
    return Text(
      'Informe seu e-mail institucional e enviaremos um link para redefinir sua senha.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
    );
  }

  Widget _buildFormulario(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Label
        Text(
          'E-mail institucional',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),

        // Campo e-mail
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() => _mensagemErro = null),
          decoration: InputDecoration(
            hintText: 'exemplo@fatec.sp.gov.br',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide:
                  const BorderSide(color: Color(0xFF8B0000), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF8B0000)),
            ),
          ),
        ),

        // Mensagem de erro
        if (_mensagemErro != null) ...[
          const SizedBox(height: 8),
          Text(
            _mensagemErro!,
            style: const TextStyle(
              color: Color(0xFF8B0000),
              fontSize: 13,
            ),
          ),
        ],

        const SizedBox(height: 28),

        // Botão enviar
        Center(
          child: SizedBox(
            width: 160,
            height: 44,
            child: ElevatedButton(
              onPressed: _carregando ? null : _enviarEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                disabledBackgroundColor:
                    const Color(0xFF8B0000).withOpacity(0.6),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: _carregando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Enviar link',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Voltar para login
        _buildVoltarLogin(context),
      ],
    );
  }

  // Tela de confirmação após envio
  Widget _buildSucesso() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF8B0000).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: Color(0xFF8B0000),
            size: 38,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'E-mail enviado!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Verifique sua caixa de entrada e siga as instruções para redefinir sua senha.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        _buildVoltarLogin(context),
      ],
    );
  }

  Widget _buildVoltarLogin(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Lembrou a senha? ',
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        GestureDetector(
          onTap: () => Navigator.of(this.context).pop(),
          child: const Text(
            'Entrar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B0000),
            ),
          ),
        ),
      ],
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
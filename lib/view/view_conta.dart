import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:fatechub2/controllers/conta_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TelaConta extends StatefulWidget {
  const TelaConta({super.key});

  @override
  State<TelaConta> createState() => _TelaContaState();
}

class _TelaContaState extends State<TelaConta> {

  final ContaController _contaController = ContaController();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _senhaAtualController = TextEditingController();
  final TextEditingController _novaSenhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController = TextEditingController();

  late Future<Map<String, dynamic>?> _dadosUsuarioFuture;

  @override
  void initState() {
    super.initState();
    // Buscando os dados uma única vez ao iniciar a tela
    _dadosUsuarioFuture = _buscarDadosUsuario();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _buscarDadosUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(uid)
      .get();

    return doc.data();
  }

  

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
        future: _dadosUsuarioFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              appBar: AppBarPadrao(nomeUsuario: 'Carregando...'),
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final dados = snapshot.data;
          if (dados == null) {
            return const Scaffold(
              body: Center(child: Text('Erro ao carregar dados.')),
            );
          }

          final nome = dados['nome'] ?? 'Usuário';

          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
            appBar: AppBarPadrao(nomeUsuario: nome),
            body: _buildBody(context, dados),
          );
        });
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> dados) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCabecalho(context),
        const SizedBox(height: 12),

        _buildCardPerfil(context, dados),
        const SizedBox(height: 12),

        _buildCardInfo(
          context: context,
          itens: [
            _InfoItem(label: 'RA:', valor: dados['ra'] ?? ''),
            _InfoItem(label: 'Email:', valor: dados['email'] ?? ''),
            _InfoItem(label: 'Curso:', valor: dados['curso'] ?? ''),
            _InfoItem(label: 'Turno:', valor: dados['turno'] ?? ''),
            _InfoItem(label: 'Ciclo:', valor: dados['ciclo'] ?? ''),
          ],
        ),
        const SizedBox(height: 12),

        _buildItem(
          context: context,
          icone: Icons.settings_outlined,
          label: 'Mudar senha',
          onTap: () => _exibirModalAlterarSenha(context),
        ),
      ],
    );
  }

  void _exibirModalAlterarSenha(BuildContext context) {
    _senhaAtualController.clear();
    _novaSenhaController.clear();
    _confirmarSenhaController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ListenableBuilder(
          listenable: _contaController,
          builder: (context, child) {
            final carregando = _contaController.estado == ContaEstado.carregando;

            return AlertDialog(
              title: const Text('Alterar Senha', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _senhaAtualController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha Atual'),
                      enabled: !carregando,
                    ),
                    TextField(
                      controller: _novaSenhaController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Nova Senha'),
                      enabled: !carregando,
                    ),
                    TextField(
                      controller: _confirmarSenhaController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirmar Nova Senha'),
                      enabled: !carregando,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: carregando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000)),
                  onPressed: carregando
                      ? null
                      : () async {
                          final sucesso = await _contaController.alterarSenha(
                            senhaAtual: _senhaAtualController.text,
                            novaSenha: _novaSenhaController.text,
                            confirmarSenha: _confirmarSenhaController.text,
                          );

                          if (sucesso && context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Senha alterada com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_contaController.mensagemErro ?? 'Erro desconhecido'),
                                backgroundColor: const Color(0xFF8B0000),
                              ),
                            );
                          }
                        },
                  child: carregando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Confirmar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCabecalho(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.undo, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'CONTA',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPerfil(BuildContext context, Map<String, dynamic> dados) {
    final nomeAtual = dados['nome'] ?? 'Nome não encontrado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey.shade400, width: 1.5),
            ),
            child: Icon(Icons.person, color: Colors.grey[600], size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              nomeAtual,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF8B0000), size: 22),
            onPressed: () => _exibirModalAlterarNome(context, nomeAtual),
          ),
        ],
      ),
    );
  }

  void _exibirModalAlterarNome(BuildContext context, String nomeAtual) {
    _nomeController.text = nomeAtual;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ListenableBuilder(
          listenable: _contaController,
          builder: (context, child) {
            final carregando = _contaController.estado == ContaEstado.carregando;

            return AlertDialog(
              title: const Text('Alterar Nome', style: TextStyle(fontWeight: FontWeight.bold)),
              content: TextField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome completo'),
                enabled: !carregando,
                textCapitalization: TextCapitalization.words,
              ),
              actions: [
                TextButton(
                  onPressed: carregando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000)),
                  onPressed: carregando ? null : () async {
                    final sucesso = await _contaController.alterarNome(_nomeController.text);

                    if (sucesso && context.mounted) {
                      Navigator.of(context).pop(); 
                          

                      setState(() {
                        _dadosUsuarioFuture = _buscarDadosUsuario();
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nome alterado com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_contaController.mensagemErro ?? 'Erro ao alterar nome'),
                          backgroundColor: const Color(0xFF8B0000),
                        ),
                      );
                    }
                  },
                  child: carregando ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ) : const Text('Salvar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCardInfo({
    required BuildContext context,
    required List<_InfoItem> itens
    }) 
    {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: itens
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${item.label}  ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: item.valor,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required IconData icone,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icone, color: Theme.of(context).colorScheme.onSurface, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface, size: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String valor;
  const _InfoItem({required this.label, required this.valor});
}
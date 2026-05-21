import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> buscarDadosUsuario() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(uid)
      .get();

  return doc.data();
}

class TelaConta extends StatelessWidget {
  const TelaConta({super.key});

  Future<Map<String, dynamic>?> buscarDadosUsuario() async {
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
      future: buscarDadosUsuario(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return Scaffold(
            appBar: const AppBarPadrao(nomeUsuario: 'Carregando...'),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final dados = snapshot.data;
        final nome = dados?['nome'] ?? 'Usuário';


        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          appBar: AppBarPadrao(nomeUsuario: nome),
          body: _buildBody(context),
        );
      }
    );
  }

  Widget _buildBody(BuildContext context) {

    return FutureBuilder<Map<String, dynamic>?>(
      future: buscarDadosUsuario(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        final dados = snapshot.data;
        if (dados == null) {
          return const Text('Erro ao carregar dados.');
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cabeçalho com botão voltar
            _buildCabecalho(context),
            const SizedBox(height: 12),

            // Card avatar + nome
            // Importar do banco de dados através da futura API
            // Fazer botão para alteração depois com backend
            _buildCardPerfil(context, dados),
            const SizedBox(height: 12),

            // Card dados acadêmicos
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

            // Adicionar opções para mudar o nome e a senha posteriormente

            /*_buildItem(
              context: context,
              icone: Icons.settings_outlined,
              label: 'Mudar nome',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TelaMudarNome(
                    themeController: themeController,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            _buildItem(
              context: context,
              icone: Icons.settings_outlined,
              label: 'Mudar senha',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TelaMudarSenha(
                    themeController: themeController,
                  ),
                ),
              ),
            ), */
          ],
        );
      }
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

  Widget _buildCardPerfil(BuildContext context, Map<String, dynamic>? dados) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
          Text(
            dados?['nome'] ?? 'Nome não encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
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
import 'package:fatechub2/view/view_acessibilidade.dart';
import 'package:fatechub2/view/view_conta.dart';
import 'package:fatechub2/view/view_login.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class TelaConfiguracoes extends StatelessWidget {
  const TelaConfiguracoes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: const AppBarPadrao(),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildItem(
          icone: Icons.account_circle_outlined,
          label: 'Conta',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TelaConta()),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildItem(
          icone: Icons.settings_outlined,
          label: 'Acessibilidade',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TelaAcessibilidade()),
            );
          },   
        ),
        const SizedBox(height: 10),
        _buildItem(
          icone: Icons.folder_outlined,
          label: 'Solicitar documentos',
          onTap: () {},   // Adicionar após fazer a aba 'solicitar documentos'
        ),
        const SizedBox(height: 10),
        _buildItem(
          icone: Icons.logout,
          label: 'Log Out',
          onTap: () {
            Navigator.of(context).pushAndRemoveUntil(               // pushAndRemoveUntil faz com que o usuário não possa voltar a tela sem relogar
              MaterialPageRoute(builder: (_) => const TelaLogin()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildItem({
    required IconData icone,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Icon(icone, color: const Color(0xFF424242), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF212121),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600], size: 24),
          ],
        ),
      ),
    );
  }
}
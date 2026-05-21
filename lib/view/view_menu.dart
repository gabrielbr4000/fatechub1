import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fatechub2/view/view_acessibilidade.dart';
import 'package:fatechub2/view/view_conta.dart';
import 'package:fatechub2/view/view_login.dart';
import 'package:fatechub2/controllers/theme_controller.dart';
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

class TelaConfiguracoes extends StatelessWidget {
  final ThemeController themeController;
 
  const TelaConfiguracoes({super.key, required this.themeController});
 
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: buscarDadosUsuario(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return Scaffold(
            body: const Center(child: CircularProgressIndicator()),
          );
        }


        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          body: _buildBody(context),
        );
      }
    );
  }
 
  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildItem(
          context: context,
          icone: Icons.account_circle_outlined,
          label: 'Conta',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TelaConta()),
          ),
        ),
        const SizedBox(height: 10),
        _buildItem(
          context: context,
          icone: Icons.settings_outlined,
          label: 'Acessibilidade',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TelaAcessibilidade(
                themeController: themeController,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildItem(
          context: context,
          icone: Icons.folder_outlined,
          label: 'Solicitar documentos',
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _buildItem(
          context: context,
          icone: Icons.logout,
          label: 'Log Out',
          onTap: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => TelaLogin( // <- sem const
                themeController: themeController,
              ),
            ),
            (route) => false,
          ),
        ),
      ],
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
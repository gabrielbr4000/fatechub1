import 'package:fatechub2/view/view_conta.dart';
import 'package:flutter/material.dart';

class AppBarPadrao extends StatelessWidget implements PreferredSizeWidget {
  final String nomeUsuario;
  final bool mostrarVoltar;

const AppBarPadrao({
  super.key,
  required this.nomeUsuario,
  this.mostrarVoltar = false,
});


  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
   return AppBar(
  backgroundColor: const Color(0xFF8B0000),
  elevation: 0,
  automaticallyImplyLeading: mostrarVoltar,

  iconTheme: const IconThemeData(
    color: Colors.white,
  ),

      title: GestureDetector(
        onTap: () {
          bool isCurrent = false;
          Navigator.popUntil(context, (route) {
            if (route.settings.name == '/telaConta') {
              isCurrent = true;
            }
            return true; // Não remove nada
          });

          if (!isCurrent) {
            Navigator.of(context).push(
              MaterialPageRoute(
                settings: const RouteSettings(name: '/telaConta'),
                builder: (_) => const TelaConta(),
              ),
            );
          }
        },
        
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Olá, $nomeUsuario',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
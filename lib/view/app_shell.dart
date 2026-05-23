import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fatechub2/controllers/navigation_controller.dart';
import 'package:fatechub2/controllers/theme_controller.dart';
import 'package:fatechub2/view/view_home.dart';
import 'package:fatechub2/view/view_menu.dart';
import 'package:fatechub2/view/view_messenger.dart';
import 'package:fatechub2/view/view_turma.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  final ThemeController themeController;

  const AppShell({super.key, required this.themeController});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final NavigationController _navController = NavigationController();
  late final PageController _pageController;

  bool _navegandoProgramaticamente = false;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined, label: 'Home'),
    _NavItem(icon: Icons.message, label: 'Mensagens'),
    _NavItem(icon: Icons.school_outlined, label: 'Turma'),
    _NavItem(icon: Icons.grid_view_outlined, label: 'Menu'),
  ];

  Stream<DocumentSnapshot<Map<String, dynamic>>> _escutarDadosUsuario() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("Usuário não autenticado");
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _navController.currentIndex);

    _navController.addListener(() {
      if (_pageController.hasClients) {
        _navegandoProgramaticamente = true;
        _pageController
            .animateToPage(
              _navController.currentIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            )
            .then((_) => _navegandoProgramaticamente = false);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _escutarDadosUsuario(),
      builder: (context, usuarioSnapshot) {
        if (usuarioSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            appBar: AppBarPadrao(nomeUsuario: 'Carregando...'),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final dados = usuarioSnapshot.data?.data();
        final nomeUsuario = dados?['nome'] ?? 'Usuário';

        final telas = [
          TelaHome(nomeUsuario: nomeUsuario),
          TelaMessenger(nomeUsuario: nomeUsuario),
          TelaTurmas(nomeUsuario: nomeUsuario),
          TelaConfiguracoes(
            themeController: widget.themeController,
            nomeUsuario: nomeUsuario,
          ),
        ];

        return ListenableBuilder(
          listenable: _navController,
          builder: (context, _) {
            return Scaffold(
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerLow,
              body: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  if (!_navegandoProgramaticamente) {
                    _navController.goTo(index);
                  }
                },
                children: telas,
              ),
              bottomNavigationBar: _buildBottomNavBar(),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _navItems.length,
              (index) => _buildNavItem(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final bool isSelected = _navController.currentIndex == index;
    final item = _navItems[index];

    return GestureDetector(
      onTap: () => _navController.goTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C2C2C) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
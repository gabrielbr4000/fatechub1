import 'package:flutter/material.dart';
import 'package:fatechub2/controllers/navigation_controller.dart';

// Importar futuras telas aqui
import 'package:fatechub2/view/view_messenger.dart';
// import 'package:fatechub2/view/view_tela_home.dart';
// import 'package:fatechub2/view/view_tela_turma.dart';
// import 'package:fatechub2/view/view_tela_menu.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final NavigationController _navController = NavigationController();

  // Adicionar as telas na ordem dos itens do nav bar
  final List<Widget> _telas = [
    const Placeholder(), // Home        — trocar por TelaHome()
    const TelaMessenger(), // Mensagens
    const Placeholder(), // Turma       — trocar por TelaTurma()
    const Placeholder(), // Menu        — trocar por TelaMenu()
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined, label: 'Home'),
    _NavItem(icon: Icons.message, label: 'Mensagens'),
    _NavItem(icon: Icons.school_outlined, label: 'Turma'),
    _NavItem(icon: Icons.grid_view_outlined, label: 'Menu'),
  ];

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _navController,
      builder: (context, _) {
        return Scaffold(
          // IndexedStack mantém o estado de todas as telas em memória
          body: IndexedStack(
            index: _navController.currentIndex,
            children: _telas,
          ),
          bottomNavigationBar: _buildBottomNavBar(),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modelo interno para os itens do nav bar
class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
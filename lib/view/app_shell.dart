import 'package:flutter/material.dart';
import 'package:fatechub2/controllers/navigation_controller.dart';

// Importar futuras telas aqui
import 'package:fatechub2/view/view_messenger.dart';
import 'package:fatechub2/view/view_home.dart';
import 'package:fatechub2/view/view_turma.dart';
import 'package:fatechub2/view/view_menu.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final NavigationController _navController = NavigationController();
  late final PageController _pageController;

  // Flag para evitar conflito entre nav bar e arrasto
  bool _navegandoProgramaticamente = false;

  // Adicionar as telas na ordem dos itens do nav bar
  final List<Widget> _telas = [
    const TelaHome(), // Home        
    const TelaMessenger(), // Mensagens
    const TelaTurmas(), // Turma       
    const TelaConfiguracoes(), // Menu        — trocar por TelaMenu()
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined, label: 'Home'),
    _NavItem(icon: Icons.message, label: 'Mensagens'),
    _NavItem(icon: Icons.school_outlined, label: 'Turma'),
    _NavItem(icon: Icons.grid_view_outlined, label: 'Menu'),
  ];

    @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _navController.currentIndex);
 
    // Sincroniza o controller com o PageView
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
    return ListenableBuilder(
      listenable: _navController,
      builder: (context, _) {
        return Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              // Só atualiza o nav bar se o usuário arrastou (não programático)
              if (!_navegandoProgramaticamente) {
                _navController.goTo(index);
              }
            },
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
 
class _NavItem {
  final IconData icon;
  final String label;
 
  const _NavItem({required this.icon, required this.label});
}
 
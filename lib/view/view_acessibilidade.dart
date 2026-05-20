import 'package:fatechub2/controllers/theme_controller.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class TelaAcessibilidade extends StatefulWidget {
  final ThemeController themeController;
  const TelaAcessibilidade({super.key, required this.themeController});

  @override
  State<TelaAcessibilidade> createState() => _TelaAcessibilidadeState();
}

class _TelaAcessibilidadeState extends State<TelaAcessibilidade> {
  bool _altoContraste = false;
  bool _movReduzido = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: const AppBarPadrao(),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cabeçalho
        _buildCabecalho(context),
        const SizedBox(height: 12),

        // Toggles
        _buildItemToggle(
          icone: Icons.format_italic,
          label: 'Alto-contraste',
          valor: _altoContraste,
          onChanged: (v) => setState(() => _altoContraste = v),   // Fazer implementação
        ),
        const SizedBox(height: 10),
        _buildItemToggle(
          icone: Icons.wb_sunny_outlined,
          label: 'Modo Escuro',
          valor: widget.themeController.modoEscuro,
          onChanged: (_) => widget.themeController.toggle(),

          // NOTA PARA DESENVOLVER OS TEMAS
          // Fundo =            Theme.of(context).colorScheme.surfaceContainerLow
          // Cards =            Theme.of(context).colorScheme.surface
          // Texto principal =  Theme.of(context).colorScheme.onSurface
          // Texto secundario = Theme.of(context).colorScheme.onSurfaceVariant
          // NÃO MUDAR AS CORES VERMELHAS, SÃO A IDENTIDADE VISUAL DO PROJETO

        ),
        const SizedBox(height: 10),
        _buildItemToggle(
          icone: Icons.gif_outlined,
          label: 'Mov. Reduzido',
          valor: _movReduzido,
          onChanged: (v) => setState(() => _movReduzido = v),     // Fazer implementação
        ),
        const SizedBox(height: 10),

        // Apagar Cache
        _buildItemAcao(
          icone: Icons.delete_outline,
          label: 'Apagar Cache',
          onTap: () {},         // Posteriormente adicionar após terminar o backend da tela Messenger
        ),
      ],
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
            'ACESSIBILIDADE',
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

  Widget _buildItemToggle({
    required IconData icone,
    required String label,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
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
          Switch(
            value: valor,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF8B0000),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildItemAcao({
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
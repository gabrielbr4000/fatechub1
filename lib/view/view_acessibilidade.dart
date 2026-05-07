import 'package:fatechub2/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class TelaAcessibilidade extends StatefulWidget {
  const TelaAcessibilidade({super.key});

  @override
  State<TelaAcessibilidade> createState() => _TelaAcessibilidadeState();
}

class _TelaAcessibilidadeState extends State<TelaAcessibilidade> {
  bool _altoContraste = false;
  bool _modoEscuro = false;
  bool _movReduzido = false;

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
          valor: _modoEscuro,
          onChanged: (v) => setState(() => _modoEscuro = v),      // Fazer implementação
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
          const Text(
            'ACESSIBILIDADE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
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
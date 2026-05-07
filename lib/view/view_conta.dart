import 'package:fatechub2/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class TelaConta extends StatelessWidget {
  const TelaConta({super.key});

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
        // Cabeçalho com botão voltar
        _buildCabecalho(context),
        const SizedBox(height: 12),

        // Card avatar + nome
        // Importar do banco de dados através da futura API
        // Fazer botão para alteração depois com backend
        _buildCardPerfil(),
        const SizedBox(height: 12),

        // Card dados acadêmicos
        // Importar do banco de dados através da futura API
        _buildCardInfo(
          itens: const [
            _InfoItem(label: 'RA:', valor: '1234567890987'),
            _InfoItem(label: 'Email:', valor: 'fulano.silva@aluno.cps.sp.gov.br'),
            _InfoItem(label: 'Curso:', valor: 'Análise e Desenv. de Sistemas'),
            _InfoItem(label: 'Turno:', valor: 'Manhã'),
            _InfoItem(label: 'Ciclo:', valor: '4'),
          ],
        ),
        const SizedBox(height: 12),

        // Card dados pessoais
        // Importar do banco de dados através da futura API
        _buildCardInfo(
          itens: const [
            _InfoItem(label: 'CPF:', valor: '123.456.789-09'),
            _InfoItem(label: 'Nome:', valor: 'Fulano da Silva'),
            _InfoItem(label: 'Nome social:', valor: 'Fulano da Silva'),
          ],
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
            'CONTA',
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

  Widget _buildCardPerfil() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
          const Text(
            'Fulano da Silva',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfo({required List<_InfoItem> itens}) {
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121),
                        ),
                      ),
                      TextSpan(
                        text: item.valor,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF212121),
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
}

class _InfoItem {
  final String label;
  final String valor;
  const _InfoItem({required this.label, required this.valor});
}
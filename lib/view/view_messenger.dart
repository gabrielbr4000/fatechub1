import 'package:fatechub2/widgets/app_bar.dart';
import 'package:fatechub2/view/view_chat.dart';
import 'package:flutter/material.dart';

class TelaMessenger extends StatefulWidget {
  const TelaMessenger({super.key});

  @override
  State<TelaMessenger> createState() => _TelaMessengerState();
}

class _TelaMessengerState extends State<TelaMessenger>
    with AutomaticKeepAliveClientMixin {

  // Fazer essas conversas serem interativas e funcionais
  final List<Map<String, dynamic>> _conversas = [
    {
      'nome': 'Prof. Isabelly',
      'mensagem': 'Mensagens +3',
      'cor': Colors.orange,
    },
    {
      'nome': 'Lucas A.',
      'mensagem': 'Visto',
      'cor': Colors.blue,
    },
    {
      'nome': 'Maria V.',
      'mensagem': 'Mensagem 1',
      'cor': Colors.green,
    },
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: const AppBarPadrao(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildNovaConversa(),
        const SizedBox(height: 12),
        ..._conversas.map(
          (conversa) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildConversaItem(conversa),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Acabou as conversas abertas',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNovaConversa() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[500],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Nova conversa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildConversaItem(Map<String, dynamic> conversa) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TelaChat(
              nomeContato: conversa['nome'] as String,
              corAvatar: conversa['cor'] as Color,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: conversa['cor'] as Color,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversa['nome'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversa['mensagem'] as String,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600], size: 24),
          ],
        ),
      ),
    );
  }
}

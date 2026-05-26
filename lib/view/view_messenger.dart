import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fatechub2/services/chat_service.dart';
import 'package:fatechub2/view/nova_conversa.dart';
import 'package:fatechub2/view/view_chat.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TelaMessenger extends StatefulWidget {
  final String nomeUsuario;

  const TelaMessenger({super.key, required this.nomeUsuario});

  @override
  State<TelaMessenger> createState() => _TelaMessengerState();
}

class _TelaMessengerState extends State<TelaMessenger>
    with AutomaticKeepAliveClientMixin {
  final ChatService _chatService = ChatService();
  final String _uidAtual = FirebaseAuth.instance.currentUser!.uid;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBarPadrao(nomeUsuario: widget.nomeUsuario),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.ouvirConversas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final conversas = snapshot.data?.docs ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNovaConversa(),
            const SizedBox(height: 12),

            if (conversas.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhuma conversa ainda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...conversas.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final conversaId = doc.id;
                final ultimaMensagem = data['ultimaMensagem'] ?? '';
                final participantes = List<String>.from(data['participantes']);
                final uidOutro = participantes.firstWhere(
                  (uid) => uid != _uidAtual,
                  orElse: () => '',
                );
                final naoLidas = (data['naoLidas'] as Map<String, dynamic>?)?[_uidAtual];
                final qtdNaoLidas = (naoLidas is int) ? naoLidas : 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildConversaItem(
                    conversaId: conversaId,
                    uidOutro: uidOutro,
                    ultimaMensagem: ultimaMensagem,
                    qtdNaoLidas: qtdNaoLidas,
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildNovaConversa() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TelaNovaConversa()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onSurface,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Nova conversa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversaItem({
    required String conversaId,
    required String uidOutro,
    required String ultimaMensagem,
    required int qtdNaoLidas,
  }) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _chatService.buscarUsuarioPorUid(uidOutro),
      builder: (context, snapshot) {
        final nome = snapshot.data?['nome'] ?? 'Usuário';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TelaChat(
                  nomeContato: nome,
                  corAvatar: Colors.blueGrey,
                  conversaId: conversaId,
                  uidOutro: uidOutro,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blueGrey,
                  child: const Icon(Icons.person, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),

                // Nome e última mensagem
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: qtdNaoLidas > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ultimaMensagem.isEmpty ? 'Nenhuma mensagem' : ultimaMensagem,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: qtdNaoLidas > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: qtdNaoLidas > 0
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Badge de não lidas
                if (qtdNaoLidas > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      qtdNaoLidas > 99 ? '99+' : '$qtdNaoLidas',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
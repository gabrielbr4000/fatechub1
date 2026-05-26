import 'package:fatechub2/services/chat_service.dart';
import 'package:fatechub2/view/view_chat.dart';
import 'package:flutter/material.dart';

class TelaNovaConversa extends StatefulWidget {
  const TelaNovaConversa({super.key});

  @override
  State<TelaNovaConversa> createState() => _TelaNovaConversaState();
}

class _TelaNovaConversaState extends State<TelaNovaConversa> {
  final TextEditingController _buscaController = TextEditingController();
  final ChatService _chatService = ChatService();

  List<Map<String, dynamic>> _resultados = [];
  bool _carregando = false;
  bool _buscou = false;

  void _buscar(String nome) async {
    if (nome.trim().isEmpty) {
      setState(() {
        _resultados = [];
        _buscou = false;
      });
      return;
    }

    setState(() => _carregando = true);

    final resultados = await _chatService.buscarUsuarios(nome.trim());

    setState(() {
      _resultados = resultados;
      _carregando = false;
      _buscou = true;
    });
  }

  void _abrirConversa(Map<String, dynamic> usuario) async {
    final uidOutro = usuario['uid'] as String;
    final conversaId = await _chatService.abrirOuCriarConversa(uidOutro);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TelaChat(
          nomeContato: usuario['nome'] ?? 'Usuário',
          corAvatar: Colors.blueGrey,
          conversaId: conversaId,
          uidOutro: uidOutro,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        title: const Text(
          'Nova conversa',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _buscaController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onChanged: _buscar,
              decoration: InputDecoration(
                hintText: 'Buscar usuário pelo nome...',
                hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8B0000)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : !_buscou
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search_outlined,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(
                              'Digite um nome para buscar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _resultados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_off_outlined,
                                    size: 48,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                                const SizedBox(height: 12),
                                Text(
                                  'Nenhum usuário encontrado',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _resultados.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final usuario = _resultados[index];
                              return GestureDetector(
                                onTap: () => _abrirConversa(usuario),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blueGrey,
                                        ),
                                        child: const Icon(Icons.person,
                                            color: Colors.white, size: 26),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              usuario['nome'] ?? 'Usuário',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                            if (usuario['email'] != null)
                                              Text(
                                                usuario['email'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
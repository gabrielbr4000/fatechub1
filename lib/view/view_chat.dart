import 'package:flutter/material.dart';

class TelaChat extends StatefulWidget {
  final String nomeContato;
  final Color corAvatar;

  const TelaChat({
    super.key,
    required this.nomeContato,
    required this.corAvatar,
  });

  @override
  State<TelaChat> createState() => _TelaChatState();
}

class _TelaChatState extends State<TelaChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Integrar com API futuramente
  final List<_Mensagem> _mensagens = [];

  void _enviarMensagem() {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _mensagens.add(_Mensagem(
        texto: texto,
        euEnviei: true,
        horario: _horarioAgora(),
      ));
    });

    _controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _anexarArquivo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _OpcaoAnexo(
              icone: Icons.image_outlined,
              label: 'Imagem da galeria',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            _OpcaoAnexo(
              icone: Icons.camera_alt_outlined,
              label: 'Câmera',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            _OpcaoAnexo(
              icone: Icons.insert_drive_file_outlined,
              label: 'Arquivo',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _horarioAgora() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.corAvatar,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 10),
            Text(
              widget.nomeContato,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: Colors.white, // <- adiciona isso
          onSelected: (value) {},
          itemBuilder: (_) => const [
              PopupMenuItem(value: 'perfil',   child: Text('Ver perfil')),
              PopupMenuItem(value: 'limpar',   child: Text('Limpar conversa')),
              PopupMenuItem(value: 'bloquear', child: Text('Bloquear')),
           ],
        ),
        ],
      ),
      body: Column(
        children: [
          // ── Lista de mensagens / aviso vazio ──
          Expanded(
            child: _mensagens.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma mensagem ainda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _mensagens.length,
                    itemBuilder: (context, index) {
                      return _BolhaMensagem(mensagem: _mensagens[index]);
                    },
                  ),
          ),

          // ── Campo de entrada ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Botão anexar
                  GestureDetector(
                    onTap: _anexarArquivo,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B0000).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.attach_file,
                        color: Color(0xFF8B0000),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Campo de texto
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade400, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _enviarMensagem(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Botão enviar
                  GestureDetector(
                    onTap: _enviarMensagem,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B0000),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bolha de mensagem ────────────────────────────────────────────────────────

class _BolhaMensagem extends StatelessWidget {
  final _Mensagem mensagem;

  const _BolhaMensagem({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    final euEnviei = mensagem.euEnviei;

    return Align(
      alignment: euEnviei ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: euEnviei ? const Color(0xFF8B0000) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(euEnviei ? 16 : 4),
            bottomRight: Radius.circular(euEnviei ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              euEnviei ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              mensagem.texto,
              style: TextStyle(
                fontSize: 14,
                color: euEnviei ? Colors.white : const Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mensagem.horario,
              style: TextStyle(
                fontSize: 10,
                color: euEnviei ? Colors.white60 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Opção do bottom sheet de anexo ──────────────────────────────────────────

class _OpcaoAnexo extends StatelessWidget {
  final IconData icone;
  final String label;
  final VoidCallback onTap;

  const _OpcaoAnexo({
    required this.icone,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icone, color: const Color(0xFF8B0000), size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF212121),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modelo de mensagem ───────────────────────────────────────────────────────

class _Mensagem {
  final String texto;
  final bool euEnviei;
  final String horario;

  const _Mensagem({
    required this.texto,
    required this.euEnviei,
    required this.horario,
  });
}
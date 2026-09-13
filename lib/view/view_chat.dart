import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fatechub2/controllers/audio_controller.dart';
import 'package:fatechub2/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TelaChat extends StatefulWidget {
  final String nomeContato;
  final Color corAvatar;
  final String conversaId;
  final String uidOutro;

  const TelaChat({
    super.key,
    required this.nomeContato,
    required this.corAvatar,
    required this.conversaId,
    required this.uidOutro,
  });

  @override
  State<TelaChat> createState() => _TelaChatState();
}

class _TelaChatState extends State<TelaChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final AudioController _audioController = AudioController();
  final String _uidAtual = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _chatService.zerarNaoLidas(widget.conversaId);
    _controller.addListener(() => setState(() {}));
    _audioController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _audioController.dispose();
    super.dispose();
  }

  // ─── Texto ───────────────────────────────────────────────────────────────────

  Future<void> _enviarMensagem() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;
    _controller.clear();
    await _chatService.enviarMensagem(
      widget.conversaId,
      texto,
      widget.uidOutro,
    );
    _rolarParaBaixo();
  }

  // ─── Áudio ───────────────────────────────────────────────────────────────────

  Future<void> _iniciarGravacao() async {
    await _audioController.iniciarGravacao();
  }

  Future<void> _pararEEnviarAudio() async {
    final caminho = await _audioController.pararGravacao();
    if (caminho == null) return;

    // Faz upload e pega a URL pública
    final url = await _audioController.uploadAudio(
      caminho,
      widget.conversaId,
    );

    if (url != null) {
      // Salva no Firestore com type: 'audio'
      await _chatService.enviarAudio(
        widget.conversaId,
        url,
        widget.uidOutro,
      );
      _rolarParaBaixo();
    }
  }

  Future<void> _cancelarGravacao() async {
    await _audioController.cancelarGravacao();
  }

  // ─── Scroll ──────────────────────────────────────────────────────────────────

  void _rolarParaBaixo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Anexo ───────────────────────────────────────────────────────────────────

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

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  String _formatarHorario(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
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
            color: Theme.of(context).colorScheme.surface,
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
          // ── Lista de mensagens ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.ouvirMensagens(widget.conversaId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final mensagens = snapshot.data?.docs ?? [];

                if (mensagens.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma mensagem ainda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final i = mensagens.length - 1 - index;
                    final data =
                        mensagens[i].data() as Map<String, dynamic>;
                    final euEnviei = data['remetente'] == _uidAtual;
                    final horario =
                        _formatarHorario(data['horario'] as Timestamp?);
                    final tipo = data['tipo'] ?? 'texto';

                    // Bolha de áudio ou texto
                    if (tipo == 'audio') {
                      return _BolhaAudio(
                        url: data['url'] ?? '',
                        euEnviei: euEnviei,
                        horario: horario,
                        audioController: _audioController,
                      );
                    }

                    return _BolhaMensagem(
                      texto: data['texto'] ?? '',
                      euEnviei: euEnviei,
                      horario: horario,
                    );
                  },
                );
              },
            ),
          ),

          // ── Campo de entrada ──
          AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: _buildInputBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final gravando = _audioController.gravando;
    final carregando = _audioController.carregandoUpload;
    final temTexto = _controller.text.trim().isNotEmpty;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Botão cancelar gravação
            if (gravando)
              GestureDetector(
                onTap: _cancelarGravacao,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.delete_outline,
                      color: Colors.red, size: 26),
                ),
              ),

            // Botão de anexo (some ao gravar ou carregar)
            if (!gravando && !carregando) ...[
              GestureDetector(
                onTap: _anexarArquivo,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.attach_file,
                      color: Color(0xFF8B0000), size: 20),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Campo de texto / indicador de gravação / loading
            Expanded(
              child: carregando
                  ? _buildIndicadorUpload()
                  : gravando
                      ? _buildIndicadorGravacao()
                      : TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Digite uma mensagem...',
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
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

            // Botão principal — send / mic / stop
            if (!carregando)
              GestureDetector(
                onTap: temTexto && !gravando ? _enviarMensagem : null,
                onLongPressStart:
                    !temTexto && !gravando ? (_) => _iniciarGravacao() : null,
                onLongPressEnd:
                    gravando ? (_) => _pararEEnviarAudio() : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        gravando ? Colors.red : const Color(0xFF8B0000),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    gravando
                        ? Icons.stop
                        : temTexto
                            ? Icons.send
                            : Icons.mic,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicadorGravacao() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Text(
            'Gravando... solte para enviar',
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadorUpload() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF8B0000),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Enviando áudio...',
            style: TextStyle(color: Color(0xFF8B0000), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Bolha de texto ───────────────────────────────────────────────────────────

class _BolhaMensagem extends StatelessWidget {
  final String texto;
  final bool euEnviei;
  final String horario;

  const _BolhaMensagem({
    required this.texto,
    required this.euEnviei,
    required this.horario,
  });

  @override
  Widget build(BuildContext context) {
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
              color: Colors.black.withValues(alpha: 0.05),
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
              texto,
              style: TextStyle(
                fontSize: 14,
                color: euEnviei ? Colors.white : const Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              horario,
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

// ─── Bolha de áudio ───────────────────────────────────────────────────────────

class _BolhaAudio extends StatelessWidget {
  final String url;
  final bool euEnviei;
  final String horario;
  final AudioController audioController;

  const _BolhaAudio({
    required this.url,
    required this.euEnviei,
    required this.horario,
    required this.audioController,
  });

  @override
  Widget build(BuildContext context) {
    final reproduzindo = audioController.estaReproduzindo(url);

    return Align(
      alignment: euEnviei ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              euEnviei ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botão play/pause
                GestureDetector(
                  onTap: () => audioController.reproduzir(url),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: euEnviei
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFF8B0000).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      reproduzindo ? Icons.pause : Icons.play_arrow,
                      color: euEnviei ? Colors.white : const Color(0xFF8B0000),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Barra de áudio simulada
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BarraAudio(euEnviei: euEnviei, reproduzindo: reproduzindo),
                    const SizedBox(height: 2),
                    Text(
                      'Áudio',
                      style: TextStyle(
                        fontSize: 11,
                        color: euEnviei
                            ? Colors.white70
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              horario,
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

// ─── Barra de áudio animada ───────────────────────────────────────────────────

class _BarraAudio extends StatelessWidget {
  final bool euEnviei;
  final bool reproduzindo;

  const _BarraAudio({required this.euEnviei, required this.reproduzindo});

  @override
  Widget build(BuildContext context) {
    final cor = euEnviei ? Colors.white : const Color(0xFF8B0000);
    final alturas = [0.4, 0.8, 0.5, 1.0, 0.6, 0.9, 0.4, 0.7, 0.5, 0.8];

    return Row(
      children: List.generate(alturas.length, (i) {
        return AnimatedContainer(
          duration: Duration(milliseconds: reproduzindo ? 300 + i * 50 : 200),
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 3,
          height: reproduzindo ? 20 * alturas[i] : 8,
          decoration: BoxDecoration(
            color: cor.withValues(alpha: reproduzindo ? 1.0 : 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
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
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icone, color: const Color(0xFF8B0000), size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
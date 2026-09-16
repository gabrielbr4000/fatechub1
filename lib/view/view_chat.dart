import 'dart:async';
import 'dart:math';
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
        widget.conversaId, texto, widget.uidOutro);
    _rolarParaBaixo();
  }

  // ─── Áudio ───────────────────────────────────────────────────────────────────

  Future<void> _iniciarGravacao() async {
    await _audioController.iniciarGravacao();
  }

  Future<void> _pararEEnviarAudio() async {
    final caminho = await _audioController.pararGravacao();
    if (caminho == null) return;

    final url =
        await _audioController.uploadAudio(caminho, widget.conversaId);
    if (url != null) {
      await _chatService.enviarAudio(widget.conversaId, url, widget.uidOutro);
      _rolarParaBaixo();
    }
  }

  Future<void> _cancelarGravacao() async =>
      _audioController.cancelarGravacao();

  // ─── Deletar mensagem ─────────────────────────────────────────────────────

  Future<void> _deletarMensagem({
    required String mensagemId,
    String? audioUrl,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deletar mensagem'),
        content: const Text('Deseja apagar esta mensagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Deleta o arquivo do Storage se for áudio
    if (audioUrl != null) {
      await _audioController.deletarAudio(audioUrl);
    }

    // Deleta o documento do Firestore
    await FirebaseFirestore.instance
        .collection('conversas')
        .doc(widget.conversaId)
        .collection('mensagens')
        .doc(mensagemId)
        .delete();
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
            CircleAvatar(
              radius: 21,
              backgroundColor: widget.corAvatar,
              child:
                  const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              widget.nomeContato,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Theme.of(context).colorScheme.surface,
            onSelected: (value) {},
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'perfil', child: Text('Ver perfil')),
              PopupMenuItem(value: 'limpar', child: Text('Limpar conversa')),
              PopupMenuItem(value: 'bloquear', child: Text('Bloquear')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
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
                        Text('Nenhuma mensagem ainda',
                            style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
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
                    final doc = mensagens[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final euEnviei = data['remetente'] == _uidAtual;
                    final horario =
                        _formatarHorario(data['horario'] as Timestamp?);
                    final tipo = data['tipo'] ?? 'texto';

                    if (tipo == 'audio') {
                      return _BolhaAudio(
                        mensagemId: doc.id,
                        url: data['url'] ?? '',
                        euEnviei: euEnviei,
                        horario: horario,
                        audioController: _audioController,
                        onDeletar: euEnviei
                            ? () => _deletarMensagem(
                                  mensagemId: doc.id,
                                  audioUrl: data['url'],
                                )
                            : null,
                      );
                    }

                    return _BolhaMensagem(
                      mensagemId: doc.id,
                      texto: data['texto'] ?? '',
                      euEnviei: euEnviei,
                      horario: horario,
                      onDeletar: euEnviei
                          ? () => _deletarMensagem(mensagemId: doc.id)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
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
            if (gravando)
              GestureDetector(
                onTap: _cancelarGravacao,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.delete_outline,
                      color: Colors.red, size: 26),
                ),
              ),
            if (!gravando && !carregando) ...[
              GestureDetector(
                onTap: _anexarArquivo,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF8B0000).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.attach_file,
                      color: Color(0xFF8B0000), size: 20),
                ),
              ),
              const SizedBox(width: 8),
            ],
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
                                fontSize: 14),
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
            if (!carregando)
              GestureDetector(
                onTap:
                    temTexto && !gravando ? _enviarMensagem : null,
                onLongPressStart: !temTexto && !gravando
                    ? (_) => _iniciarGravacao()
                    : null,
                onLongPressEnd:
                    gravando ? (_) => _pararEEnviarAudio() : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: gravando
                        ? Colors.red
                        : const Color(0xFF8B0000),
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
          Text('Gravando... solte para enviar',
              style:
                  TextStyle(color: Colors.red.shade700, fontSize: 13)),
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
                strokeWidth: 2, color: Color(0xFF8B0000)),
          ),
          SizedBox(width: 10),
          Text('Enviando áudio...',
              style: TextStyle(color: Color(0xFF8B0000), fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Bolha de texto ───────────────────────────────────────────────────────────

class _BolhaMensagem extends StatelessWidget {
  final String mensagemId;
  final String texto;
  final bool euEnviei;
  final String horario;
  final VoidCallback? onDeletar;

  const _BolhaMensagem({
    required this.mensagemId,
    required this.texto,
    required this.euEnviei,
    required this.horario,
    this.onDeletar,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          euEnviei ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onDeletar != null
            ? () => _mostrarOpcoes(context)
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72),
          decoration: BoxDecoration(
            color:
                euEnviei ? const Color(0xFF8B0000) : Colors.white,
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
            crossAxisAlignment: euEnviei
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                texto,
                style: TextStyle(
                    fontSize: 14,
                    color: euEnviei
                        ? Colors.white
                        : const Color(0xFF212121)),
              ),
              const SizedBox(height: 4),
              Text(horario,
                  style: TextStyle(
                      fontSize: 10,
                      color: euEnviei
                          ? Colors.white60
                          : Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarOpcoes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Deletar mensagem',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDeletar?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bolha de áudio com animação ─────────────────────────────────────────────

class _BolhaAudio extends StatefulWidget {
  final String mensagemId;
  final String url;
  final bool euEnviei;
  final String horario;
  final AudioController audioController;
  final VoidCallback? onDeletar;

  const _BolhaAudio({
    required this.mensagemId,
    required this.url,
    required this.euEnviei,
    required this.horario,
    required this.audioController,
    this.onDeletar,
  });

  @override
  State<_BolhaAudio> createState() => _BolhaAudioState();
}

class _BolhaAudioState extends State<_BolhaAudio> {
  @override
  void initState() {
    super.initState();
    widget.audioController.addListener(_onAudioChanged);
  }

  void _onAudioChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.audioController.removeListener(_onAudioChanged);
    super.dispose();
  }

  void _mostrarOpcoes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Deletar áudio',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                widget.onDeletar?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reproduzindo =
        widget.audioController.estaReproduzindo(widget.url);
    final corIcone =
        widget.euEnviei ? Colors.white : const Color(0xFF8B0000);
    final corBolha = widget.euEnviei
        ? const Color(0xFF8B0000)
        : Colors.white;

    return Align(
      alignment: widget.euEnviei
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: widget.onDeletar != null
            ? () => _mostrarOpcoes(context)
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72),
          decoration: BoxDecoration(
            color: corBolha,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft:
                  Radius.circular(widget.euEnviei ? 16 : 4),
              bottomRight:
                  Radius.circular(widget.euEnviei ? 4 : 16),
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
            crossAxisAlignment: widget.euEnviei
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão play/pause
                  GestureDetector(
                    onTap: () => widget.audioController
                        .reproduzir(widget.url),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: corIcone.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        reproduzindo
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: corIcone,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Barra de ondas animada
                  _BarraOndasAnimada(
                    reproduzindo: reproduzindo,
                    cor: corIcone,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic,
                      size: 10,
                      color: widget.euEnviei
                          ? Colors.white60
                          : Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text(
                    widget.horario,
                    style: TextStyle(
                        fontSize: 10,
                        color: widget.euEnviei
                            ? Colors.white60
                            : Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Barra de ondas animada ───────────────────────────────────────────────────

class _BarraOndasAnimada extends StatefulWidget {
  final bool reproduzindo;
  final Color cor;

  const _BarraOndasAnimada({
    required this.reproduzindo,
    required this.cor,
  });

  @override
  State<_BarraOndasAnimada> createState() => _BarraOndasAnimadaState();
}

class _BarraOndasAnimadaState extends State<_BarraOndasAnimada> {
  final _random = Random();
  Timer? _timer;

  // Alturas base fixas da forma de onda
  final List<double> _alturas = [
    0.4, 0.7, 0.5, 1.0, 0.6, 0.8, 0.3, 0.9,
    0.5, 0.7, 0.4, 0.6, 0.8, 0.5, 1.0, 0.4,
  ];

  // Alturas atuais que serão animadas
  late List<double> _alturasDinamicas;

  @override
  void initState() {
    super.initState();
    _alturasDinamicas = List.from(_alturas);
    _atualizarTimer();
  }

  @override
  void didUpdateWidget(_BarraOndasAnimada oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reproduzindo != widget.reproduzindo) {
      _atualizarTimer();
    }
  }

  void _atualizarTimer() {
    _timer?.cancel();
    if (widget.reproduzindo) {
      // Atualiza as alturas a cada 120ms para simular a onda
      _timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
        if (!mounted) return;
        setState(() {
          for (int i = 0; i < _alturasDinamicas.length; i++) {
            // Cada barra oscila aleatoriamente ao redor da sua altura base
            final base = _alturas[i];
            final variacao = (_random.nextDouble() - 0.5) * 0.5;
            _alturasDinamicas[i] = (base + variacao).clamp(0.2, 1.0);
          }
        });
      });
    } else {
      // Parado — volta para alturas base
      if (mounted) {
        setState(() {
          _alturasDinamicas = List.from(_alturas);
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(_alturasDinamicas.length, (i) {
        final altura = widget.reproduzindo
            ? 4 + _alturasDinamicas[i] * 18
            : 4 + _alturas[i] * 6;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 3,
          height: altura,
          decoration: BoxDecoration(
            color: widget.cor.withValues(
                alpha: widget.reproduzindo ? 1.0 : 0.5),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
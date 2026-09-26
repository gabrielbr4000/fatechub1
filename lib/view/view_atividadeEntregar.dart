import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TelaAtividade extends StatefulWidget {
  final String nomeUsuario;
  final String nomeTurma;
  final String atividadeId;
  final String nome;
  final String dataEntrega;
  final String descricao;
  final String? disciplina;
  final bool isProfessor;
  final List<Map<String, dynamic>> anexosProfessor;

  const TelaAtividade({
    super.key,
    required this.nomeUsuario,
    required this.nomeTurma,
    required this.atividadeId,
    required this.nome,
    required this.dataEntrega,
    required this.descricao,
    this.disciplina,
    required this.isProfessor,
    this.anexosProfessor = const [],
  });

  @override
  State<TelaAtividade> createState() => _TelaAtividadeState();
}

class _TelaAtividadeState extends State<TelaAtividade> {
  final TextEditingController _linkController = TextEditingController();
  final String _uidAtual = FirebaseAuth.instance.currentUser!.uid;

  static const int _limiteBytes = 50 * 1024 * 1024; // 50 MB

  bool _enviando = false;
  Map<String, dynamic>? _entregaAtual;
  bool _carregandoEntrega = true;

  // Arquivo selecionado pelo aluno
  String? _nomeArquivo;
  Uint8List? _bytesArquivo;

  @override
  void initState() {
    super.initState();
    if (!widget.isProfessor) _carregarEntrega();
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  // ─── Carrega entrega do aluno ─────────────────────────────────────────────

  Future<void> _carregarEntrega() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('turmas')
          .doc(widget.nomeTurma)
          .collection('atividades')
          .doc(widget.atividadeId)
          .collection('entregas')
          .doc(_uidAtual)
          .get();

      if (mounted) {
        setState(() {
          _entregaAtual = doc.exists ? doc.data() : null;
          _carregandoEntrega = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _carregandoEntrega = false);
    }
  }

  // ─── Selecionar arquivo do aluno ──────────────────────────────────────────

  Future<void> _selecionarArquivo() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg', 'zip'],
      withData: true,
    );

    if (resultado == null || resultado.files.isEmpty) return;

    final arquivo = resultado.files.first;

    // Valida limite de 50 MB
    if (arquivo.size > _limiteBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arquivo muito grande. O limite é 50 MB.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _nomeArquivo = arquivo.name;
      _bytesArquivo = arquivo.bytes;
      _linkController.clear(); // limpa o link se havia
    });
  }

  void _removerArquivo() {
    setState(() {
      _nomeArquivo = null;
      _bytesArquivo = null;
    });
  }

  // ─── Enviar entrega ───────────────────────────────────────────────────────

  Future<void> _enviarEntrega() async {
    final temLink = _linkController.text.trim().isNotEmpty;
    final temArquivo = _nomeArquivo != null && _bytesArquivo != null;

    if (!temLink && !temArquivo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Anexe um arquivo ou informe um link.')),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      if (temArquivo) {
        // Upload do arquivo para o Storage
        final ref = FirebaseStorage.instance
            .ref()
            .child('entregas')
            .child(widget.nomeTurma)
            .child(widget.atividadeId)
            .child(_uidAtual)
            .child(_nomeArquivo!);

        await ref.putData(
          _bytesArquivo!,
          SettableMetadata(contentType: _contentType(_nomeArquivo!)),
        );

        final url = await ref.getDownloadURL();
        await _salvarEntrega(tipo: 'arquivo', valor: url, nomeArquivo: _nomeArquivo);
      } else {
        await _salvarEntrega(tipo: 'link', valor: _linkController.text.trim());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao enviar. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _salvarEntrega({
    required String tipo,
    required String valor,
    String? nomeArquivo,
  }) async {
    await FirebaseFirestore.instance
        .collection('turmas')
        .doc(widget.nomeTurma)
        .collection('atividades')
        .doc(widget.atividadeId)
        .collection('entregas')
        .doc(_uidAtual)
        .set({
      'uid': _uidAtual,
      'tipo': tipo,
      'valor': valor,
      'nomeArquivo': nomeArquivo,
      'entregueEm': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('turmas')
        .doc(widget.nomeTurma)
        .collection('atividades')
        .doc(widget.atividadeId)
        .update({'entregue': true});

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Atividade entregue com sucesso!'),
        backgroundColor: Color(0xFF8B0000),
      ),
    );

    _linkController.clear();
    setState(() {
      _nomeArquivo = null;
      _bytesArquivo = null;
    });

    await _carregarEntrega();
  }

  // ─── Cancelar entrega ─────────────────────────────────────────────────────

  Future<void> _cancelarEntrega() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar entrega?'),
        content: const Text(
            'Deseja remover sua entrega? Você poderá enviar novamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Não', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );

    if (confirmar == null || !confirmar) return;
    if (!mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('turmas')
          .doc(widget.nomeTurma)
          .collection('atividades')
          .doc(widget.atividadeId)
          .collection('entregas')
          .doc(_uidAtual)
          .delete();

      if (!mounted) return;

      final entregas = await FirebaseFirestore.instance
          .collection('turmas')
          .doc(widget.nomeTurma)
          .collection('atividades')
          .doc(widget.atividadeId)
          .collection('entregas')
          .get();

      if (!mounted) return;

      if (entregas.docs.isEmpty) {
        await FirebaseFirestore.instance
            .collection('turmas')
            .doc(widget.nomeTurma)
            .collection('atividades')
            .doc(widget.atividadeId)
            .update({'entregue': false});
      }

      if (!mounted) return;

      setState(() => _entregaAtual = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega cancelada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao cancelar entrega.')),
      );
    }
  }

  // ─── Abrir URL ────────────────────────────────────────────────────────────

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _contentType(String nome) {
    final ext = nome.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf'  => 'application/pdf',
      'doc'  => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'png'  => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'zip'  => 'application/zip',
      _ => 'application/octet-stream',
    };
  }

  IconData _iconeArquivo(String nome) {
    final ext = nome.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf'  => Icons.picture_as_pdf_outlined,
      'doc' || 'docx' => Icons.description_outlined,
      'png' || 'jpg' || 'jpeg' => Icons.image_outlined,
      'zip'  => Icons.folder_zip_outlined,
      _ => Icons.attach_file,
    };
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBarPadrao(
        nomeUsuario: widget.nomeUsuario,
        mostrarVoltar: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCardAtividade(),
            const SizedBox(height: 16),

            // Anexos do professor
            if (widget.anexosProfessor.isNotEmpty) ...[
              _buildAnexosProfessor(),
              const SizedBox(height: 16),
            ],

            // Seção do aluno
            if (!widget.isProfessor)
              _carregandoEntrega
                  ? const Center(child: CircularProgressIndicator())
                  : _entregaAtual != null
                      ? _buildEntregaRealizada()
                      : _buildFormEntrega(),

            // Seção do professor
            if (widget.isProfessor) _buildListaEntregasProfessor(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardAtividade() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.nome,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (widget.disciplina != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.disciplina!,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: Color(0xFF8B0000)),
              const SizedBox(width: 6),
              Text(
                'Data de entrega: ${widget.dataEntrega}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B0000),
                ),
              ),
            ],
          ),
          if (widget.descricao.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              widget.descricao,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Anexos do professor ──────────────────────────────────────────────────

  Widget _buildAnexosProfessor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Materiais anexados',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.anexosProfessor.map((anexo) {
          final nome = anexo['nome'] as String? ?? 'arquivo';
          final url = anexo['url'] as String? ?? '';
          return GestureDetector(
            onTap: () => _abrirUrl(url),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF8B0000).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(_iconeArquivo(nome),
                      color: const Color(0xFF8B0000), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      nome,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.download_outlined,
                      color: Color(0xFF8B0000), size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Formulário de entrega (aluno) ────────────────────────────────────────

  Widget _buildFormEntrega() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sua entrega',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo de link
              Text(
                'Link (Google Drive, GitHub...)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _linkController,
                keyboardType: TextInputType.url,
                onChanged: (_) {
                  if (_nomeArquivo != null) _removerArquivo();
                },
                decoration: InputDecoration(
                  hintText: 'Cole o link aqui...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: const Icon(Icons.link, size: 20),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Color(0xFF8B0000), width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Separador
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'ou',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 16),

              // Arquivo selecionado ou botão de selecionar
              if (_nomeArquivo != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          const Color(0xFF8B0000).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_iconeArquivo(_nomeArquivo!),
                          color: const Color(0xFF8B0000), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _nomeArquivo!,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: _removerArquivo,
                        icon: const Icon(Icons.close, size: 18),
                        color: Colors.grey[600],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: _selecionarArquivo,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.upload_file_outlined,
                            color: Color(0xFF8B0000), size: 28),
                        const SizedBox(height: 6),
                        Text(
                          'Selecionar arquivo',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PDF, DOC, imagens, ZIP — máx. 50 MB',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Botão enviar
        ElevatedButton.icon(
          onPressed: _enviando ? null : _enviarEntrega,
          icon: _enviando
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send, size: 19),
          label: Text(_enviando ? 'Enviando...' : 'Enviar atividade'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B0000),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  // ─── Entrega realizada (aluno) ────────────────────────────────────────────

  Widget _buildEntregaRealizada() {
    final tipo = _entregaAtual!['tipo'] as String? ?? '';
    final valor = _entregaAtual!['valor'] as String? ?? '';
    final nomeArquivo = _entregaAtual!['nomeArquivo'] as String?;
    final entregueEm = _entregaAtual!['entregueEm'] as Timestamp?;

    String horario = '';
    if (entregueEm != null) {
      final dt = entregueEm.toDate();
      horario =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 22),
              const SizedBox(width: 8),
              Text(
                'Atividade entregue!',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Entrega
          GestureDetector(
            onTap: tipo == 'arquivo' || tipo == 'link'
                ? () => _abrirUrl(valor)
                : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    tipo == 'link'
                        ? Icons.link
                        : _iconeArquivo(nomeArquivo ?? ''),
                    size: 20,
                    color: const Color(0xFF8B0000),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tipo == 'arquivo'
                          ? (nomeArquivo ?? valor)
                          : valor,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF8B0000),
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.open_in_new,
                      size: 16, color: Color(0xFF8B0000)),
                ],
              ),
            ),
          ),

          if (horario.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Entregue em: $horario',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cancelarEntrega,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancelar entrega'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B0000),
                side: const BorderSide(color: Color(0xFF8B0000)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Lista de entregas (professor) ────────────────────────────────────────

  Widget _buildListaEntregasProfessor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entregas dos alunos',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('turmas')
              .doc(widget.nomeTurma)
              .collection('atividades')
              .doc(widget.atividadeId)
              .collection('entregas')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final entregas = snapshot.data?.docs ?? [];

            if (entregas.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Nenhuma entrega ainda.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: entregas.map((doc) {
                final dados = doc.data() as Map<String, dynamic>;
                return _buildCardEntregaProfessor(dados);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCardEntregaProfessor(Map<String, dynamic> dados) {
    final tipo = dados['tipo'] as String? ?? '';
    final valor = dados['valor'] as String? ?? '';
    final nomeArquivo = dados['nomeArquivo'] as String?;
    final uid = dados['uid'] as String? ?? '';
    final entregueEm = dados['entregueEm'] as Timestamp?;

    String horario = '';
    if (entregueEm != null) {
      final dt = entregueEm.toDate();
      horario =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final nomeAluno =
            (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null &&
                snapshot.data!.exists)
            ? (data?['nome'] as String?) ?? uid
            : uid;

        return GestureDetector(
          onTap: () => _abrirUrl(valor),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      color: Color(0xFF8B0000), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomeAluno,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            tipo == 'link'
                                ? Icons.link
                                : _iconeArquivo(nomeArquivo ?? ''),
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tipo == 'arquivo'
                                  ? (nomeArquivo ?? valor)
                                  : valor,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8B0000),
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (horario.isNotEmpty)
                  Text(
                    horario,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
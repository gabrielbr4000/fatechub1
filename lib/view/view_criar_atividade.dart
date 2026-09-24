import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TelaCriarAtividade extends StatefulWidget {
  final String nomeUsuario;
  final String nomeTurma;
  final String? disciplina;

  const TelaCriarAtividade({
    super.key,
    required this.nomeUsuario,
    required this.nomeTurma,
    this.disciplina,
  });

  @override
  State<TelaCriarAtividade> createState() => _TelaCriarAtividadeState();
}

class _TelaCriarAtividadeState extends State<TelaCriarAtividade> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _prazoController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _postando = false;

  // Arquivos anexados
  final List<_Anexo> _anexos = [];

  @override
  void dispose() {
    _tituloController.dispose();
    _prazoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  // ─── Selecionar arquivo ───────────────────────────────────────────────────

  Future<void> _selecionarArquivo() async {
    final resultado = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
      withData: true, // necessário para web
    );

    if (resultado == null || resultado.files.isEmpty) return;

    for (final arquivo in resultado.files) {
      // Evita duplicatas
      if (_anexos.any((a) => a.nome == arquivo.name)) continue;

      setState(() {
        _anexos.add(_Anexo(
          nome: arquivo.name,
          bytes: arquivo.bytes,
          tamanho: arquivo.size,
        ));
      });
    }
  }

  void _removerAnexo(int index) {
    setState(() => _anexos.removeAt(index));
  }

  // ─── Fazer upload dos arquivos ────────────────────────────────────────────

  Future<List<Map<String, String>>> _uploadAnexos(String atividadeId) async {
    final urls = <Map<String, String>>[];

    for (final anexo in _anexos) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('atividades')
            .child(widget.nomeTurma)
            .child(atividadeId)
            .child(anexo.nome);

        if (kIsWeb && anexo.bytes != null) {
          await ref.putData(
            anexo.bytes!,
            SettableMetadata(contentType: _contentType(anexo.nome)),
          );
        }

        final url = await ref.getDownloadURL();
        urls.add({'nome': anexo.nome, 'url': url});
      } catch (e) {
        debugPrint('Erro ao enviar ${anexo.nome}: $e');
      }
    }

    return urls;
  }

  String _contentType(String nome) {
    final ext = nome.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf'  => 'application/pdf',
      'doc'  => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'png'  => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }

  // ─── Postar atividade ─────────────────────────────────────────────────────

  Future<void> _postar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _postando = true);

    try {
      // Cria o documento da atividade primeiro para obter o ID
      final docRef = await FirebaseFirestore.instance
          .collection('turmas')
          .doc(widget.nomeTurma)
          .collection('atividades')
          .add({
        'nome': _tituloController.text.trim(),
        'dataEntrega': _prazoController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'entregue': false,
        'disciplina': widget.disciplina ?? widget.nomeTurma,
        'turma': widget.nomeTurma,
        'criadoEm': FieldValue.serverTimestamp(),
        'anexos': [], // será atualizado após o upload
      });

      // Faz upload dos arquivos se houver
      if (_anexos.isNotEmpty) {
        final urls = await _uploadAnexos(docRef.id);
        await docRef.update({'anexos': urls});
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Atividade publicada com sucesso!'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível publicar a atividade.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _postando = false);
    }
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTituloPagina(),
              const SizedBox(height: 24),
              _buildCampoTitulo(),
              const SizedBox(height: 18),
              _buildCampoPrazo(),
              const SizedBox(height: 18),
              _buildCampoDescricao(),
              const SizedBox(height: 18),
              _buildSecaoAnexos(),
              const SizedBox(height: 30),
              _buildBotoes(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTituloPagina() {
    return SizedBox(
      width: double.infinity,
      child: Text(
        'Enviar atividade',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildCampoTitulo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Título'),
        const SizedBox(height: 7),
        TextFormField(
          controller: _tituloController,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoracaoCampo(hint: 'Digite o título da atividade'),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Informe o título.' : null,
        ),
      ],
    );
  }

  Widget _buildCampoPrazo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Prazo'),
        const SizedBox(height: 7),
        TextFormField(
          controller: _prazoController,
          keyboardType: TextInputType.datetime,
          decoration: _decoracaoCampo(hint: 'Digite o prazo da atividade'),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Informe o prazo.' : null,
        ),
      ],
    );
  }

  Widget _buildCampoDescricao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Descrição'),
        const SizedBox(height: 7),
        TextFormField(
          controller: _descricaoController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 6,
          decoration: _decoracaoCampo(hint: 'Digite a descrição da atividade'),
        ),
      ],
    );
  }

  Widget _buildSecaoAnexos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Anexos'),
        const SizedBox(height: 7),

        // Botão de adicionar arquivo
        GestureDetector(
          onTap: _postando ? null : _selecionarArquivo,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.attach_file,
                    color: Color(0xFF8B0000), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Adicionar arquivo',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Lista de arquivos selecionados
        if (_anexos.isNotEmpty) ...[
          const SizedBox(height: 10),
          ..._anexos.asMap().entries.map((entry) {
            final i = entry.key;
            final anexo = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: const Color(0xFF8B0000).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(_iconeArquivo(anexo.nome),
                      color: const Color(0xFF8B0000), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anexo.nome,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatarTamanho(anexo.tamanho),
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removerAnexo(i),
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.grey[600],
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildBotoes() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _postando ? null : _selecionarArquivo,
            icon: const Icon(Icons.attach_file, size: 19),
            label: Text(_anexos.isEmpty
                ? 'Anexar'
                : '${_anexos.length} anexo(s)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _postando ? null : _postar,
            icon: _postando
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.subdirectory_arrow_right, size: 19),
            label: Text(_postando ? 'Postando...' : 'Postar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String texto) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  InputDecoration _decoracaoCampo({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide:
            const BorderSide(color: Color(0xFF8B0000), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  IconData _iconeArquivo(String nome) {
    final ext = nome.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf'  => Icons.picture_as_pdf_outlined,
      'doc' || 'docx' => Icons.description_outlined,
      'png' || 'jpg' || 'jpeg' => Icons.image_outlined,
      _ => Icons.attach_file,
    };
  }

  String _formatarTamanho(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─── Modelo de anexo ──────────────────────────────────────────────────────────

class _Anexo {
  final String nome;
  final Uint8List? bytes;
  final int tamanho;

  const _Anexo({
    required this.nome,
    required this.bytes,
    required this.tamanho,
  });
}
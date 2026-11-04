import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class TelaAvaliarEntrega extends StatefulWidget {
  final String nomeUsuario;
  final String nomeTurma;
  final String atividadeId;
  final String nomeAtividade;
  final String nomeAluno;
  final String uidAluno;
  final String tipoEntrega;   // 'link' ou 'arquivo'
  final String valorEntrega;  // URL do arquivo ou link
  final String? nomeArquivo;
  final Timestamp? entregueEm;

  const TelaAvaliarEntrega({
    super.key,
    required this.nomeUsuario,
    required this.nomeTurma,
    required this.atividadeId,
    required this.nomeAtividade,
    required this.nomeAluno,
    required this.uidAluno,
    required this.tipoEntrega,
    required this.valorEntrega,
    this.nomeArquivo,
    this.entregueEm,
  });

  @override
  State<TelaAvaliarEntrega> createState() => _TelaAvaliarEntregaState();
}

class _TelaAvaliarEntregaState extends State<TelaAvaliarEntrega> {
  final TextEditingController _notaController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  bool _salvando = false;
  Map<String, dynamic>? _avaliacaoExistente;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarAvaliacao();
  }

  @override
  void dispose() {
    _notaController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  // ─── Carrega avaliação existente ──────────────────────────────────────────

  Future<void> _carregarAvaliacao() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('turmas')
          .doc(widget.nomeTurma)
          .collection('atividades')
          .doc(widget.atividadeId)
          .collection('entregas')
          .doc(widget.uidAluno)
          .get();

      if (doc.exists) {
        final dados = doc.data()!;
        final nota = dados['nota'];
        final feedback = dados['feedback'] as String? ?? '';

        setState(() {
          _avaliacaoExistente = dados;
          if (nota != null) _notaController.text = nota.toString();
          if (feedback.isNotEmpty) _feedbackController.text = feedback;
          _carregando = false;
        });
      } else {
        setState(() => _carregando = false);
      }
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  // ─── Salvar avaliação ─────────────────────────────────────────────────────

  Future<void> _salvarAvaliacao() async {
    final notaTexto = _notaController.text.trim();
    final feedback = _feedbackController.text.trim();

    // Valida nota
    if (notaTexto.isNotEmpty) {
      final nota = double.tryParse(notaTexto.replaceAll(',', '.'));
      if (nota == null || nota < 0 || nota > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nota inválida. Informe um valor entre 0 e 10.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _salvando = true);

    try {
      await FirebaseFirestore.instance
          .collection('turmas')
          .doc(widget.nomeTurma)
          .collection('atividades')
          .doc(widget.atividadeId)
          .collection('entregas')
          .doc(widget.uidAluno)
          .update({
        'nota': notaTexto.isNotEmpty
            ? double.parse(notaTexto.replaceAll(',', '.'))
            : null,
        'feedback': feedback,
        'avaliadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avaliação salva com sucesso!'),
          backgroundColor: Color(0xFF8B0000),
        ),
      );

      await _carregarAvaliacao();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar avaliação.')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // ─── Abrir arquivo/link ───────────────────────────────────────────────────

  Future<void> _abrirEntrega() async {
    final uri = Uri.tryParse(widget.valorEntrega);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _formatarHorario(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCabecalho(),
                  const SizedBox(height: 16),
                  _buildCardEntrega(),
                  const SizedBox(height: 16),
                  _buildCardAvaliacao(),
                  const SizedBox(height: 16),
                  _buildBotaoSalvar(),
                ],
              ),
            ),
    );
  }

  // ─── Cabeçalho ────────────────────────────────────────────────────────────

  Widget _buildCabecalho() {
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
          // Aluno
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person,
                    color: Color(0xFF8B0000), size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nomeAluno,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    widget.nomeAtividade,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Nota atual (se já avaliado)
          if (_avaliacaoExistente?['nota'] != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.grade_outlined,
                    color: Color(0xFF8B0000), size: 18),
                const SizedBox(width: 6),
                Text(
                  'Nota atual: ${_avaliacaoExistente!['nota']}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B0000),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Avaliado em: ${_formatarHorario(_avaliacaoExistente!['avaliadoEm'] as Timestamp?)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Card da entrega do aluno ─────────────────────────────────────────────

  Widget _buildCardEntrega() {
    final label = widget.tipoEntrega == 'arquivo'
        ? (widget.nomeArquivo ?? 'Arquivo enviado')
        : widget.valorEntrega;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entrega do aluno',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),

        // Data de entrega
        if (widget.entregueEm != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Enviado em: ${_formatarHorario(widget.entregueEm)}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

        // Arquivo ou link
        GestureDetector(
          onTap: _abrirEntrega,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B0000).withValues(alpha: 0.3),
              ),
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
                Icon(
                  widget.tipoEntrega == 'link'
                      ? Icons.link
                      : _iconeArquivo(widget.nomeArquivo ?? ''),
                  color: const Color(0xFF8B0000),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.tipoEntrega == 'arquivo'
                            ? Icons.download_outlined
                            : Icons.open_in_new,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.tipoEntrega == 'arquivo'
                            ? 'Baixar'
                            : 'Abrir',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Card de avaliação ────────────────────────────────────────────────────

  Widget _buildCardAvaliacao() {
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
            'Avaliação',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Campo de nota
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nota (0 – 10)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notaController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]')),
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B0000),
                      ),
                      decoration: InputDecoration(
                        hintText: '—',
                        hintStyle: TextStyle(
                          fontSize: 22,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
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
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Atalhos de nota rápida
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atalhos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
                          .map((n) => GestureDetector(
                                onTap: () => setState(() =>
                                    _notaController.text =
                                        n % 1 == 0
                                            ? n.toInt().toString()
                                            : n.toString()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _notaController.text ==
                                            (n % 1 == 0
                                                ? n.toInt().toString()
                                                : n.toString())
                                        ? const Color(0xFF8B0000)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    n % 1 == 0
                                        ? n.toInt().toString()
                                        : n.toString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _notaController.text ==
                                              (n % 1 == 0
                                                  ? n.toInt().toString()
                                                  : n.toString())
                                          ? Colors.white
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Campo de feedback
          Text(
            'Feedback',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _feedbackController,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText:
                  'Escreva um comentário ou feedback para o aluno...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.all(14),
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
        ],
      ),
    );
  }

  Widget _buildBotaoSalvar() {
    return ElevatedButton.icon(
      onPressed: _salvando ? null : _salvarAvaliacao,
      icon: _salvando
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save_outlined, size: 20),
      label: Text(_salvando ? 'Salvando...' : 'Salvar avaliação'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
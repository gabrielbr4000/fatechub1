import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TelaAtividade extends StatefulWidget {
  final String nomeUsuario;
  final String nomeTurma;
  final String atividadeId;
  final String nome;
  final String dataEntrega;
  final String descricao;
  final String? disciplina;
  final bool isProfessor;

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
  });

  @override
  State<TelaAtividade> createState() => _TelaAtividadeState();
}

class _TelaAtividadeState extends State<TelaAtividade> {
  final TextEditingController _linkController = TextEditingController();
  final String _uidAtual = FirebaseAuth.instance.currentUser!.uid;

  bool _enviando = false;
  Map<String, dynamic>? _entregaAtual;
  bool _carregandoEntrega = true;

  @override
  void initState() {
    super.initState();
    _carregarEntrega();
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

      if (doc.exists) {
        setState(() {
          _entregaAtual = doc.data();
          _carregandoEntrega = false;
        });
      } else {
        setState(() => _carregandoEntrega = false);
      }
    } catch (e) {
      setState(() => _carregandoEntrega = false);
    }
  }

  // ─── Enviar link ──────────────────────────────────────────────────────────

  Future<void> _enviarLink() async {
    final link = _linkController.text.trim();

    // A validação que impedia o envio se o link estivesse vazio foi removida.

    setState(() => _enviando = true);

    try {
      // Define um valor padrão caso o utilizador não tenha preenchido nada
      final valorFinal = link.isEmpty ? 'Entregue sem anexo' : link;
      final tipoFinal = link.isEmpty ? 'texto' : 'link';

      await _salvarEntrega(tipo: tipoFinal, valor: valorFinal);
      _linkController.clear();
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // ─── Enviar arquivo (simulado) ────────────────────────────────────────────

  Future<void> _enviarArquivo() async {
    // TODO: integrar com file_picker + Firebase Storage
    // Por enquanto mostra um dialog explicativo
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anexar arquivo'),
        content: const Text(
          'Para enviar um arquivo, integre o pacote file_picker com o Firebase Storage.\n\nPor enquanto, use o campo de link para compartilhar via Google Drive ou similar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  // ─── Salva entrega no Firestore ───────────────────────────────────────────

  Future<void> _salvarEntrega({
    required String tipo,
    required String valor,
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
          'entregueEm': FieldValue.serverTimestamp(),
        });

    // Atualiza o campo 'entregue' na atividade
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

    await _carregarEntrega();
  }

  // ─── Cancelar entrega ─────────────────────────────────────────────────────

  Future<void> _cancelarEntrega() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // <- use dialogContext aqui
        title: const Text('Cancelar entrega?'),
        content: const Text(
          'Deseja remover sua entrega? Você poderá enviar novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(false), // <- dialogContext
            child: Text('Não', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(true), // <- dialogContext
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!mounted) return; // <- verifica antes de continuar

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entrega cancelada.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao cancelar entrega.')),
      );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card principal da atividade
            _buildCardAtividade(),
            const SizedBox(height: 16),

            // Seção de entrega (só para aluno)
            if (!widget.isProfessor) ...[
              _carregandoEntrega
                  ? const Center(child: CircularProgressIndicator())
                  : _entregaAtual != null
                  ? _buildEntregaRealizada()
                  : _buildFormEntrega(),
            ],

            // Seção de entregas (só para professor)
            if (widget.isProfessor) ...[_buildListaEntregasProfessor()],
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
          // Título
          Text(
            widget.nome,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Disciplina
          if (widget.disciplina != null)
            Text(
              widget.disciplina!,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),

          const SizedBox(height: 12),

          // Data de entrega
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Color(0xFF8B0000),
              ),
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

        // Campo de link
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
              Text(
                'Link',
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
                decoration: InputDecoration(
                  hintText: 'Cole o link aqui (Google Drive, GitHub...)',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: const Icon(Icons.link, size: 20),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF8B0000),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Botões
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _enviando ? null : _enviarArquivo,
                icon: const Icon(Icons.attach_file, size: 19),
                label: const Text('Anexar PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: const Color(0xFF8B0000),
                  elevation: 1,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF8B0000)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _enviando ? null : _enviarLink,
                icon: _enviando
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 19),
                label: Text(_enviando ? 'Enviando...' : 'Enviar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Entrega realizada (aluno) ────────────────────────────────────────────

  Widget _buildEntregaRealizada() {
    final tipo = _entregaAtual!['tipo'] as String? ?? '';
    final valor = _entregaAtual!['valor'] as String? ?? '';
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

          // Tipo e valor da entrega
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  tipo == 'texto'
                      ? Icons.check
                      : (tipo == 'link' ? Icons.link : Icons.attach_file),
                  size: 20,
                  color: const Color(0xFF8B0000),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    valor,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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

          // Botão cancelar entrega
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
                  borderRadius: BorderRadius.circular(8),
                ),
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
    final uid = dados['uid'] as String? ?? '';
    final entregueEm = dados['entregueEm'] as Timestamp?;

    String horario = '';
    if (entregueEm != null) {
      final dt = entregueEm.toDate();
      horario =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final nomeAluno =
            (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null &&
                snapshot.data!.exists)
            ? (data?['nome'] as String?) ?? uid
            : uid;

        return Container(
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
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF8B0000),
                  size: 22,
                ),
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
                          tipo == 'link' ? Icons.link : Icons.attach_file,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            valor,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF8B0000),
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
        );
      },
    );
  }
}

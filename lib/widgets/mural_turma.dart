import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color _vinho = Color(0xFF8B0000);

String _formatarHorarioMural(Timestamp? ts) {
  // Logo após publicar, o servidor ainda não devolveu o horário
  if (ts == null) return 'agora';

  final dt = ts.toDate();
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  final dia = dt.day.toString().padLeft(2, '0');
  final mes = dt.month.toString().padLeft(2, '0');

  return '$h:$min $dia/$mes/${dt.year}';
}

InputDecoration _decoracaoMural(BuildContext context, String hint) {
  final cs = Theme.of(context).colorScheme;

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
    filled: true,
    fillColor: cs.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _vinho, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
  );
}

// ─── Mural da turma ───────────────────────────────────────────────────────────
//
// Firestore:
//   turmas/{turmaId}/mural/{postId}
//     titulo, texto, autorUid, autorNome, criadoEm,
//     curtidas: [uid, ...], totalComentarios: int
//   turmas/{turmaId}/mural/{postId}/comentarios/{id}
//     texto, autorUid, autorNome, criadoEm

class MuralTurma extends StatefulWidget {
  /// ID do documento da turma (ex.: "ALG-L-P-MANHA")
  final String nomeTurma;

  const MuralTurma({super.key, required this.nomeTurma});

  @override
  State<MuralTurma> createState() => _MuralTurmaState();
}

class _MuralTurmaState extends State<MuralTurma> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  String? _perfil;
  String _nomeUsuario = 'Usuário';

  bool get _ehProfessor => _perfil == 'professor';

  CollectionReference<Map<String, dynamic>> get _muralRef =>
      FirebaseFirestore.instance
          .collection('turmas')
          .doc(widget.nomeTurma)
          .collection('mural');

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_uid)
          .get();

      if (!mounted) return;

      setState(() {
        _perfil = doc.data()?['perfil'] as String?;
        _nomeUsuario = doc.data()?['nome'] as String? ?? 'Usuário';
      });
    } catch (_) {
      // Sem perfil, o usuário só visualiza o mural
    }
  }

  // ─── Ações ────────────────────────────────────────────────────────────────

  Future<void> _abrirNovaPublicacao() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (_) => _NovaPublicacaoSheet(
        muralRef: _muralRef,
        uid: _uid,
        nomeAutor: _nomeUsuario,
      ),
    );
  }

  void _abrirComentarios(DocumentReference<Map<String, dynamic>> postRef) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.65,
          child: _ComentariosSheet(
            postRef: postRef,
            uid: _uid,
            nomeUsuario: _nomeUsuario,
            ehProfessor: _ehProfessor,
          ),
        ),
      ),
    );
  }

  Future<void> _alternarCurtida(
    DocumentReference<Map<String, dynamic>> ref,
    bool curtiu,
  ) async {
    try {
      await ref.update({
        'curtidas': curtiu
            ? FieldValue.arrayRemove([_uid])
            : FieldValue.arrayUnion([_uid]),
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível curtir. Tente novamente.')),
      );
    }
  }

  Future<void> _excluirPost(DocumentReference<Map<String, dynamic>> ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir publicação?'),
        content: const Text('Os comentários também serão apagados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _vinho,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      // O Firestore não apaga subcoleções sozinho
      final comentarios = await ref.collection('comentarios').get();

      final batch = FirebaseFirestore.instance.batch();
      for (final c in comentarios.docs) {
        batch.delete(c.reference);
      }
      batch.delete(ref);
      await batch.commit();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a publicação.')),
      );
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFaixaTitulo(),
        if (_ehProfessor) _buildBotaoNovaPublicacao(),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _muralRef.orderBy('criadoEm', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return _buildMensagem(
                icone: Icons.error_outline,
                titulo: 'Não foi possível carregar o mural.',
              );
            }

            final posts = snapshot.data?.docs ?? [];

            if (posts.isEmpty) {
              return _buildMensagem(
                icone: Icons.campaign_outlined,
                titulo: 'Nenhuma publicação ainda',
                subtitulo: _ehProfessor
                    ? 'Toque em "Nova publicação" para postar um aviso.'
                    : 'Os avisos do professor aparecerão aqui.',
              );
            }

            return Column(children: posts.map(_buildPost).toList());
          },
        ),
      ],
    );
  }

  Widget _buildFaixaTitulo() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Text(
        'COMEÇO DO MURAL',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildBotaoNovaPublicacao() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: ElevatedButton.icon(
        onPressed: _abrirNovaPublicacao,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Nova publicação'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _vinho,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ),
    );
  }

  Widget _buildMensagem({
    required IconData icone,
    required String titulo,
    String? subtitulo,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      child: Column(
        children: [
          Icon(icone, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPost(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final cs = Theme.of(context).colorScheme;
    final dados = doc.data();

    final titulo = dados['titulo']?.toString() ?? '';
    final texto = dados['texto']?.toString() ?? '';
    final autor = dados['autorNome']?.toString() ?? 'Professor';
    final autorUid = dados['autorUid']?.toString();
    final curtidas =
        List<String>.from((dados['curtidas'] as List<dynamic>?) ?? []);
    final totalComentarios = (dados['totalComentarios'] as num?)?.toInt() ?? 0;
    final horario = _formatarHorarioMural(dados['criadoEm'] as Timestamp?);

    final curtiu = curtidas.contains(_uid);
    final podeExcluir = _ehProfessor && autorUid == _uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.surfaceContainerHighest,
                child: Icon(Icons.person, size: 20, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            autor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          horario,
                          style: TextStyle(
                            fontSize: 9,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (podeExcluir)
                          SizedBox(
                            width: 28,
                            height: 20,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              icon: Icon(Icons.more_vert,
                                  size: 18, color: cs.onSurfaceVariant),
                              onSelected: (valor) {
                                if (valor == 'excluir') {
                                  _excluirPost(doc.reference);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'excluir',
                                  child: Text('Excluir publicação'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      texto,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              InkWell(
                onTap: () => _alternarCurtida(doc.reference, curtiu),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Icon(
                        curtiu ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: curtiu ? _vinho : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${curtidas.length}',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => _abrirComentarios(doc.reference),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '$totalComentarios',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sheet: nova publicação (professor) ───────────────────────────────────────

class _NovaPublicacaoSheet extends StatefulWidget {
  final CollectionReference<Map<String, dynamic>> muralRef;
  final String uid;
  final String nomeAutor;

  const _NovaPublicacaoSheet({
    required this.muralRef,
    required this.uid,
    required this.nomeAutor,
  });

  @override
  State<_NovaPublicacaoSheet> createState() => _NovaPublicacaoSheetState();
}

class _NovaPublicacaoSheetState extends State<_NovaPublicacaoSheet> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _textoController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _publicando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _textoController.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _publicando = true);

    try {
      await widget.muralRef.add({
        'titulo': _tituloController.text.trim(),
        'texto': _textoController.text.trim(),
        'autorUid': widget.uid,
        'autorNome': widget.nomeAutor,
        'criadoEm': FieldValue.serverTimestamp(),
        'curtidas': [],
        'totalComentarios': 0,
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _publicando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível publicar. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nova publicação',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Título',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 7),
              TextFormField(
                controller: _tituloController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoracaoMural(context, 'Ex.: Aviso sobre a prova'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o título.' : null,
              ),
              const SizedBox(height: 14),
              Text(
                'Mensagem',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 7),
              TextFormField(
                controller: _textoController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 4,
                maxLines: 8,
                decoration:
                    _decoracaoMural(context, 'Escreva o aviso para a turma...'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Escreva a mensagem.' : null,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _publicando ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _vinho,
                        side: const BorderSide(color: _vinho),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _publicando ? null : _publicar,
                      icon: _publicando
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, size: 18),
                      label: Text(_publicando ? 'Publicando...' : 'Publicar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _vinho,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
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

// ─── Sheet: comentários ───────────────────────────────────────────────────────

class _ComentariosSheet extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> postRef;
  final String uid;
  final String nomeUsuario;
  final bool ehProfessor;

  const _ComentariosSheet({
    required this.postRef,
    required this.uid,
    required this.nomeUsuario,
    required this.ehProfessor,
  });

  @override
  State<_ComentariosSheet> createState() => _ComentariosSheetState();
}

class _ComentariosSheetState extends State<_ComentariosSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() => _enviando = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final novo = widget.postRef.collection('comentarios').doc();

      batch.set(novo, {
        'texto': texto,
        'autorUid': widget.uid,
        'autorNome': widget.nomeUsuario,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      batch.update(widget.postRef, {
        'totalComentarios': FieldValue.increment(1),
      });

      await batch.commit();
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível comentar.')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _excluirComentario(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(ref);
      batch.update(widget.postRef, {
        'totalComentarios': FieldValue.increment(-1),
      });
      await batch.commit();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir o comentário.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          'Comentários',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const Divider(height: 18),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: widget.postRef
                .collection('comentarios')
                .orderBy('criadoEm')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final comentarios = snapshot.data?.docs ?? [];

              if (comentarios.isEmpty) {
                return Center(
                  child: Text(
                    'Seja o primeiro a comentar.',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: comentarios.length,
                itemBuilder: (context, index) =>
                    _buildComentario(comentarios[index]),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _enviar(),
                    decoration: _decoracaoMural(context, 'Escreva um comentário...')
                        .copyWith(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _enviando ? null : _enviar,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _enviando ? Colors.grey : _vinho,
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
    );
  }

  Widget _buildComentario(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final cs = Theme.of(context).colorScheme;
    final dados = doc.data();

    final autor = dados['autorNome']?.toString() ?? 'Usuário';
    final texto = dados['texto']?.toString() ?? '';
    final horario = _formatarHorarioMural(dados['criadoEm'] as Timestamp?);
    final podeExcluir = widget.ehProfessor || dados['autorUid'] == widget.uid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: cs.surfaceContainerHighest,
            child: Icon(Icons.person, size: 16, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        autor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      horario,
                      style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  texto,
                  style: TextStyle(fontSize: 12, height: 1.4, color: cs.onSurface),
                ),
              ],
            ),
          ),
          if (podeExcluir)
            InkWell(
              onTap: () => _excluirComentario(doc.reference),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.delete_outline,
                    size: 18, color: cs.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
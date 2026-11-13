import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _vinho = Color(0xFF8B0000);
const Color _corPasta = Color(0xFFE0A526);
const int _limiteBytes = 50 * 1024 * 1024; // 50 MB por arquivo
const String _raiz = 'raiz';

// ─── Tela de arquivos da turma (estilo Windows Explorer) ──────────────────────
//
// Firestore:
//   turmas/{turmaId}/arquivos/{itemId}
//     tipo: 'pasta' | 'arquivo'
//     nome, pastaId ('raiz' ou o id da pasta pai), criadoEm, autorUid
//     (só arquivos) url, storagePath, tamanho
//
// Storage:
//   materiais/{turmaId}/{itemId}/{nome do arquivo}

class _PastaCaminho {
  final String id;
  final String nome;

  const _PastaCaminho(this.id, this.nome);
}

class TelaArquivos extends StatefulWidget {
  final String nomeUsuario;
  final String nomeTurma;
  final String? disciplina;

  const TelaArquivos({
    super.key,
    required this.nomeUsuario,
    required this.nomeTurma,
    this.disciplina,
  });

  @override
  State<TelaArquivos> createState() => _TelaArquivosState();
}

class _TelaArquivosState extends State<TelaArquivos> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  final ScrollController _caminhoScroll = ScrollController();

  // Pastas pelas quais o usuário navegou (vazio = raiz)
  final List<_PastaCaminho> _caminho = [];

  String? _perfil;

  // Banner de progresso (envio / exclusão)
  String? _status;
  double? _progresso; // null = indeterminado

  // O stream é guardado para não reassinar a cada setState
  // (senão a lista pisca durante o progresso do upload)
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  bool get _ehProfessor => _perfil == 'professor';
  bool get _ocupado => _status != null;
  String get _pastaAtualId => _caminho.isEmpty ? _raiz : _caminho.last.id;

  CollectionReference<Map<String, dynamic>> get _arquivosRef =>
      FirebaseFirestore.instance
          .collection('turmas')
          .doc(widget.nomeTurma)
          .collection('arquivos');

  Stream<QuerySnapshot<Map<String, dynamic>>> _criarStream() {
    return _arquivosRef.where('pastaId', isEqualTo: _pastaAtualId).snapshots();
  }

  @override
  void initState() {
    super.initState();
    _stream = _criarStream();
    _carregarPerfil();
  }

  @override
  void dispose() {
    _caminhoScroll.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_uid)
          .get();

      if (!mounted) return;
      setState(() => _perfil = doc.data()?['perfil'] as String?);
    } catch (_) {
      // Sem perfil, o usuário só visualiza e baixa
    }
  }

  void _aviso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  // ─── Navegação entre pastas ───────────────────────────────────────────────

  void _abrirPasta(String id, String nome) {
    setState(() {
      _caminho.add(_PastaCaminho(id, nome));
      _stream = _criarStream();
    });
    _rolarCaminhoParaFim();
  }

  // Mantém apenas as primeiras [quantidade] pastas do caminho
  void _voltarAteNivel(int quantidade) {
    if (quantidade >= _caminho.length) return;

    setState(() {
      _caminho.removeRange(quantidade, _caminho.length);
      _stream = _criarStream();
    });
  }

  void _subir() {
    if (_caminho.isEmpty) return;
    _voltarAteNivel(_caminho.length - 1);
  }

  void _rolarCaminhoParaFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_caminhoScroll.hasClients) {
        _caminhoScroll.jumpTo(_caminhoScroll.position.maxScrollExtent);
      }
    });
  }

  // ─── Nomes ────────────────────────────────────────────────────────────────

  Future<bool> _nomeDisponivel(
    String nome,
    String pastaId, {
    String? ignorarId,
  }) async {
    final snap =
        await _arquivosRef.where('pastaId', isEqualTo: pastaId).get();

    return !snap.docs.any((d) =>
        d.id != ignorarId &&
        (d.data()['nome']?.toString() ?? '').toLowerCase() ==
            nome.toLowerCase());
  }

  Future<Set<String>> _nomesNaPasta(String pastaId) async {
    final snap =
        await _arquivosRef.where('pastaId', isEqualTo: pastaId).get();

    return snap.docs
        .map((d) => (d.data()['nome']?.toString() ?? '').toLowerCase())
        .toSet();
  }

  // "aula.pdf" -> "aula (2).pdf" quando já existe um arquivo com esse nome
  String _nomeUnico(String nome, Set<String> existentes) {
    if (!existentes.contains(nome.toLowerCase())) return nome;

    final ponto = nome.lastIndexOf('.');
    final base = ponto > 0 ? nome.substring(0, ponto) : nome;
    final ext = ponto > 0 ? nome.substring(ponto) : '';

    var i = 2;
    while (existentes.contains('$base ($i)$ext'.toLowerCase())) {
      i++;
    }
    return '$base ($i)$ext';
  }

  Future<String?> _pedirNome({
    required String titulo,
    required String rotulo,
    String inicial = '',
    bool ehArquivo = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _DialogNome(
        titulo: titulo,
        rotulo: rotulo,
        inicial: inicial,
        ehArquivo: ehArquivo,
      ),
    );
  }

  // ─── Ações do professor ───────────────────────────────────────────────────

  Future<void> _novaPasta() async {
    final nome = await _pedirNome(titulo: 'Nova pasta', rotulo: 'Criar');
    if (nome == null) return;

    final pastaId = _pastaAtualId;

    try {
      if (!await _nomeDisponivel(nome, pastaId)) {
        _aviso('Já existe um item chamado "$nome" nesta pasta.');
        return;
      }

      await _arquivosRef.add({
        'tipo': 'pasta',
        'nome': nome,
        'pastaId': pastaId,
        'autorUid': _uid,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      _aviso('Não foi possível criar a pasta.');
    }
  }

  Future<void> _renomear(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final dados = doc.data();
    final atual = dados['nome']?.toString() ?? '';
    final ehArquivo = dados['tipo'] != 'pasta';

    final novo = await _pedirNome(
      titulo: 'Renomear',
      rotulo: 'Renomear',
      inicial: atual,
      ehArquivo: ehArquivo,
    );

    if (novo == null || novo == atual) return;

    try {
      final pastaId = dados['pastaId']?.toString() ?? _raiz;

      if (!await _nomeDisponivel(novo, pastaId, ignorarId: doc.id)) {
        _aviso('Já existe um item chamado "$novo" nesta pasta.');
        return;
      }

      await doc.reference.update({'nome': novo});
    } catch (_) {
      _aviso('Não foi possível renomear.');
    }
  }

  Future<void> _enviarArquivos() async {
    final resultado = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true, // necessário para web
    );

    if (resultado == null || resultado.files.isEmpty) return;

    // Guarda a pasta de destino: o usuário pode navegar durante o envio
    final pastaDestino = _pastaAtualId;
    final arquivos = resultado.files;

    final existentes = await _nomesNaPasta(pastaDestino);

    var enviados = 0;
    final recusados = <String>[];

    for (var i = 0; i < arquivos.length; i++) {
      final arquivo = arquivos[i];

      if (arquivo.bytes == null) {
        recusados.add('${arquivo.name} (não foi possível ler)');
        continue;
      }

      if (arquivo.size > _limiteBytes) {
        recusados.add('${arquivo.name} (acima de 50 MB)');
        continue;
      }

      final nome = _nomeUnico(arquivo.name, existentes);
      existentes.add(nome.toLowerCase());

      if (!mounted) return;
      setState(() {
        _status = 'Enviando ${i + 1} de ${arquivos.length}: $nome';
        _progresso = 0;
      });

      try {
        final docRef = _arquivosRef.doc();
        final path = 'materiais/${widget.nomeTurma}/${docRef.id}/$nome';
        final ref = FirebaseStorage.instance.ref(path);

        final tarefa = ref.putData(
          arquivo.bytes!,
          SettableMetadata(contentType: _contentType(nome)),
        );

        tarefa.snapshotEvents.listen((evento) {
          if (mounted && evento.totalBytes > 0) {
            setState(() {
              _progresso = evento.bytesTransferred / evento.totalBytes;
            });
          }
        });

        await tarefa;
        final url = await ref.getDownloadURL();

        await docRef.set({
          'tipo': 'arquivo',
          'nome': nome,
          'pastaId': pastaDestino,
          'url': url,
          'storagePath': path,
          'tamanho': arquivo.size,
          'autorUid': _uid,
          'criadoEm': FieldValue.serverTimestamp(),
        });

        enviados++;
      } catch (_) {
        recusados.add('${arquivo.name} (erro no envio)');
      }
    }

    if (!mounted) return;

    setState(() {
      _status = null;
      _progresso = null;
    });

    final partes = <String>[];
    if (enviados > 0) {
      partes.add(
        enviados == 1 ? '1 arquivo enviado.' : '$enviados arquivos enviados.',
      );
    }
    if (recusados.isNotEmpty) {
      partes.add('Não enviados: ${recusados.join(', ')}.');
    }

    _aviso(partes.join(' '));
  }

  Future<void> _excluir(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final dados = doc.data();
    final ehPasta = dados['tipo'] == 'pasta';
    final nome = dados['nome']?.toString() ?? '';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(ehPasta ? 'Excluir pasta?' : 'Excluir arquivo?'),
        content: Text(
          ehPasta
              ? 'A pasta "$nome" e tudo que há dentro dela serão apagados.'
              : 'O arquivo "$nome" será apagado.',
        ),
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

    setState(() {
      _status = 'Excluindo "$nome"...';
      _progresso = null;
    });

    try {
      // Tudo que está dentro da pasta (o Firestore não apaga em cascata)
      final descendentes = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      if (ehPasta) await _coletarDescendentes(doc.id, descendentes);

      final todos = [...descendentes, doc];

      // Arquivos do Storage
      for (final item in todos) {
        final path = item.data()['storagePath']?.toString();
        if (path != null && path.isNotEmpty) {
          try {
            await FirebaseStorage.instance.ref(path).delete();
          } catch (_) {
            // Já removido ou inexistente: segue em frente
          }
        }
      }

      // Documentos, em lotes (limite de 500 operações por batch)
      final referencias = todos.map((d) => d.reference).toList();
      for (var i = 0; i < referencias.length; i += 400) {
        final batch = FirebaseFirestore.instance.batch();
        for (final ref in referencias.skip(i).take(400)) {
          batch.delete(ref);
        }
        await batch.commit();
      }
    } catch (_) {
      _aviso('Não foi possível excluir.');
    } finally {
      if (mounted) {
        setState(() {
          _status = null;
          _progresso = null;
        });
      }
    }
  }

  Future<void> _coletarDescendentes(
    String pastaId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> acumulador,
  ) async {
    final filhos =
        await _arquivosRef.where('pastaId', isEqualTo: pastaId).get();

    for (final filho in filhos.docs) {
      acumulador.add(filho);
      if (filho.data()['tipo'] == 'pasta') {
        await _coletarDescendentes(filho.id, acumulador);
      }
    }
  }

  // ─── Download ─────────────────────────────────────────────────────────────

  Future<void> _abrirArquivo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abriu) _aviso('Não foi possível abrir o arquivo.');
    } catch (_) {
      _aviso('Não foi possível abrir o arquivo.');
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // O botão voltar do sistema sobe uma pasta antes de sair da tela
      canPop: _caminho.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _subir();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        appBar: AppBarPadrao(
          nomeUsuario: widget.nomeUsuario,
          mostrarVoltar: true,
        ),
        body: Column(
          children: [
            _buildCabecalho(),
            _buildTitulo(),
            _buildCaminho(),
            if (_ehProfessor) _buildBarraAcoes(),
            if (_status != null) _buildBannerStatus(),
            Expanded(child: _buildLista()),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        children: [
          Text(
            widget.disciplina ?? widget.nomeTurma,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.nomeTurma,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildTitulo() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Text(
        'ARQUIVOS',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
    );
  }

  // Barra de endereço: botão "subir" + caminho clicável
  Widget _buildCaminho() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          IconButton(
            onPressed: _caminho.isEmpty ? null : _subir,
            icon: const Icon(Icons.arrow_upward, size: 20),
            color: _vinho,
            tooltip: 'Subir um nível',
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _caminhoScroll,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSegmento(
                    'Arquivos',
                    () => _voltarAteNivel(0),
                    atual: _caminho.isEmpty,
                  ),
                  for (var i = 0; i < _caminho.length; i++) ...[
                    Icon(Icons.chevron_right,
                        size: 18, color: cs.onSurfaceVariant),
                    _buildSegmento(
                      _caminho[i].nome,
                      () => _voltarAteNivel(i + 1),
                      atual: i == _caminho.length - 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmento(
    String texto,
    VoidCallback onTap, {
    required bool atual,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            fontWeight: atual ? FontWeight.w700 : FontWeight.w500,
            color: atual ? _vinho : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildBarraAcoes() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _ocupado ? null : _novaPasta,
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: const Text('Nova pasta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _vinho,
                side: const BorderSide(color: _vinho),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _ocupado ? null : _enviarArquivos,
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Enviar arquivo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _vinho,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStatus() {
    return Container(
      width: double.infinity,
      color: _vinho.withValues(alpha: 0.08),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _status!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _vinho,
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: _progresso,
            color: _vinho,
            backgroundColor: _vinho.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildMensagem(
            icone: Icons.error_outline,
            titulo: 'Não foi possível carregar os arquivos.',
          );
        }

        final itens = List.of(snapshot.data?.docs ?? []);

        // Pastas primeiro, depois ordem alfabética (como no Explorer)
        itens.sort((a, b) {
          final pastaA = a.data()['tipo'] == 'pasta';
          final pastaB = b.data()['tipo'] == 'pasta';
          if (pastaA != pastaB) return pastaA ? -1 : 1;

          final nomeA = (a.data()['nome']?.toString() ?? '').toLowerCase();
          final nomeB = (b.data()['nome']?.toString() ?? '').toLowerCase();
          return nomeA.compareTo(nomeB);
        });

        if (itens.isEmpty) {
          return _buildMensagem(
            icone: Icons.folder_open_outlined,
            titulo: 'Esta pasta está vazia',
            subtitulo: _ehProfessor
                ? 'Crie uma pasta ou envie arquivos para os alunos.'
                : 'O professor ainda não publicou materiais aqui.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 2, bottom: 24),
          itemCount: itens.length,
          itemBuilder: (context, index) => _buildItem(itens[index]),
        );
      },
    );
  }

  Widget _buildMensagem({
    required IconData icone,
    required String titulo,
    String? subtitulo,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 52, color: cs.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
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
      ),
    );
  }

  Widget _buildItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final cs = Theme.of(context).colorScheme;
    final dados = doc.data();

    final ehPasta = dados['tipo'] == 'pasta';
    final nome = dados['nome']?.toString() ?? 'Sem nome';
    final data = _formatarData(dados['criadoEm'] as Timestamp?);
    final tamanho = (dados['tamanho'] as num?)?.toInt() ?? 0;
    final url = dados['url']?.toString() ?? '';

    final subtitulo =
        ehPasta ? 'Pasta · $data' : '${_formatarTamanho(tamanho)} · $data';

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      color: cs.surface,
      child: InkWell(
        onTap: () {
          if (ehPasta) {
            _abrirPasta(doc.id, nome);
          } else {
            _abrirArquivo(url);
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ehPasta
                      ? _corPasta.withValues(alpha: 0.18)
                      : _vinho.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  ehPasta ? Icons.folder : _iconeArquivo(nome),
                  color: ehPasta ? _corPasta : _vinho,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_ehProfessor)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                  onSelected: (valor) {
                    if (valor == 'renomear') _renomear(doc);
                    if (valor == 'excluir') _excluir(doc);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'renomear', child: Text('Renomear')),
                    PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    ehPasta ? Icons.chevron_right : Icons.download_outlined,
                    color: ehPasta ? cs.onSurfaceVariant : _vinho,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatarData(Timestamp? ts) {
    if (ts == null) return 'agora';

    final d = ts.toDate();
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');

    return '$dia/$mes/${d.year}';
  }

  String _formatarTamanho(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _extensao(String nome) {
    return nome.contains('.') ? nome.split('.').last.toLowerCase() : '';
  }

  IconData _iconeArquivo(String nome) {
    return switch (_extensao(nome)) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'doc' || 'docx' || 'odt' || 'rtf' => Icons.description_outlined,
      'xls' || 'xlsx' || 'csv' || 'ods' => Icons.table_chart_outlined,
      'ppt' || 'pptx' || 'odp' => Icons.slideshow_outlined,
      'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' || 'svg' =>
        Icons.image_outlined,
      'zip' || 'rar' || '7z' || 'tar' || 'gz' => Icons.folder_zip_outlined,
      'mp4' || 'mov' || 'avi' || 'mkv' || 'webm' => Icons.movie_outlined,
      'mp3' || 'wav' || 'm4a' || 'ogg' => Icons.audiotrack_outlined,
      'txt' || 'md' => Icons.article_outlined,
      'dart' || 'java' || 'py' || 'js' || 'html' || 'css' || 'sql' || 'json' =>
        Icons.code,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  String _contentType(String nome) {
    return switch (_extensao(nome)) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'zip' => 'application/zip',
      'txt' => 'text/plain',
      'mp4' => 'video/mp4',
      'mp3' => 'audio/mpeg',
      _ => 'application/octet-stream',
    };
  }
}

// ─── Diálogo para nomear pasta / renomear item ────────────────────────────────

class _DialogNome extends StatefulWidget {
  final String titulo;
  final String rotulo;
  final String inicial;
  final bool ehArquivo;

  const _DialogNome({
    required this.titulo,
    required this.rotulo,
    required this.inicial,
    required this.ehArquivo,
  });

  @override
  State<_DialogNome> createState() => _DialogNomeState();
}

class _DialogNomeState extends State<_DialogNome> {
  late final TextEditingController _controller;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.inicial);
    final ponto = widget.inicial.lastIndexOf('.');
    final fim =
        (widget.ehArquivo && ponto > 0) ? ponto : widget.inicial.length;
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: fim);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    final nome = _controller.text.trim();

    if (nome.isEmpty) {
      setState(() => _erro = 'Informe um nome.');
      return;
    }

    // Mesmos caracteres proibidos do Windows
    if (RegExp(r'[\\/:*?"<>|]').hasMatch(nome)) {
      setState(() => _erro = 'O nome não pode conter \\ / : * ? " < > |');
      return;
    }

    Navigator.of(context).pop(nome);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) {
          if (_erro != null) setState(() => _erro = null);
        },
        onSubmitted: (_) => _confirmar(),
        decoration: InputDecoration(
          hintText: 'Nome',
          errorText: _erro,
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: _vinho, width: 1.5),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: _vinho,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.rotulo),
        ),
      ],
    );
  }
}
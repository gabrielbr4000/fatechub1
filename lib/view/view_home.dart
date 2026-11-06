
import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TelaHome extends StatelessWidget {
  final String nomeUsuario;

  const TelaHome({super.key, required this.nomeUsuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBarPadrao(nomeUsuario: nomeUsuario),
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _MuralCard(),
              const SizedBox(height: 16),
              _SecaoNoticias(),
              const SizedBox(height: 16),
              const _SecaoAcessoRapido(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Mural de Novidades ─────────────────────────────────────────────────────

class _MuralCard extends StatefulWidget {
  const _MuralCard();

  @override
  State<_MuralCard> createState() => _MuralCardState();
}

class _MuralCardState extends State<_MuralCard> {
  final PageController _pageController = PageController();
  final Set<String> _curtidasEmProcessamento = {};

  Timer? _timer;

  int _paginaAtual = 0;
  int _quantidadeSlides = 0;
  String? _perfil;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();

    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_pageController.hasClients) return;
      if (_quantidadeSlides <= 1) return;

      final proximaPagina = (_paginaAtual + 1) % _quantidadeSlides;

      _pageController.animateToPage(
        proximaPagina,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _carregarPerfil() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    try {
      final documento = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      if (!mounted) return;

      setState(() {
        _perfil = documento.data()?['perfil'] as String?;
      });
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _irPara(int pagina) {
    if (!_pageController.hasClients || _quantidadeSlides <= 1) return;

    final destino = (pagina + _quantidadeSlides) % _quantidadeSlides;

    _pageController.animateToPage(
      destino,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  String _formatarData(dynamic valor) {
    if (valor is! Timestamp) {
      return 'Data de publicação indisponível';
    }

    final data = valor.toDate();
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return 'Publicado em $dia/$mes/${data.year}';
  }

  // ─── Curtidas ───────────────────────────────────────────────────────────

  Future<void> _alternarCurtida(String idPublicacao) async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      _mostrarMensagem('Você precisa estar conectado para curtir.');
      return;
    }

    if (_curtidasEmProcessamento.contains(idPublicacao)) return;

    setState(() {
      _curtidasEmProcessamento.add(idPublicacao);
    });

    final referencia = FirebaseFirestore.instance
        .collection('mural_novidades')
        .doc(idPublicacao)
        .collection('curtidas')
        .doc(usuario.uid);

    try {
      await FirebaseFirestore.instance.runTransaction((transacao) async {
        final curtida = await transacao.get(referencia);

        if (curtida.exists) {
          transacao.delete(referencia);
        } else {
          transacao.set(referencia, {
            'usuarioUid': usuario.uid,
            'criadoEm': FieldValue.serverTimestamp(),
          });
        }
      });

      debugPrint('Curtida atualizada: $idPublicacao');
    } catch (e, stackTrace) {
      debugPrint('Erro ao atualizar curtida: $e');
      debugPrint('$stackTrace');

      if (mounted) {
        _mostrarMensagem('Não foi possível atualizar a curtida: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _curtidasEmProcessamento.remove(idPublicacao);
        });
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
  }

  // ─── Comentários ────────────────────────────────────────────────────────

  Future<void> _abrirComentarios(String idPublicacao) async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      _mostrarMensagem('Você precisa estar conectado para comentar.');
      return;
    }

    final comentariosRef = FirebaseFirestore.instance
        .collection('mural_novidades')
        .doc(idPublicacao)
        .collection('comentarios');

    final textoController = TextEditingController();

    String nomeAutor =
        usuario.displayName ?? usuario.email ?? 'Usuário';

    try {
      final usuarioDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      nomeAutor = usuarioDoc.data()?['nome'] as String? ??
          usuario.displayName ??
          usuario.email ??
          'Usuário';
    } catch (e) {
      debugPrint('Erro ao carregar nome do usuário: $e');
    }

    if (!mounted) {
      textoController.dispose();
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (contextSheet) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(contextSheet).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(contextSheet).size.height * 0.7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Comentários',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(contextSheet),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: comentariosRef
                        .orderBy('criadoEm', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        debugPrint(
                          'Erro ao carregar comentários: ${snapshot.error}',
                        );

                        return const Center(
                          child: Text('Erro ao carregar comentários.'),
                        );
                      }

                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final comentarios = snapshot.data?.docs ?? [];

                      if (comentarios.isEmpty) {
                        return const Center(
                          child: Text('Seja o primeiro a comentar!'),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: comentarios.length,
                        itemBuilder: (context, index) {
                          final comentario = comentarios[index];
                          final dados = comentario.data();

                          final autorUid =
                              dados['autorUid'] as String? ?? '';
                          final nome =
                              dados['nomeAutor'] as String? ?? 'Usuário';
                          final texto =
                              dados['texto'] as String? ?? '';

                          final comentarioDoUsuario =
                              autorUid == usuario.uid;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text(
                                nome.isNotEmpty
                                    ? nome[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(
                              nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(texto),
                            ),
                            trailing: comentarioDoUsuario
                                ? IconButton(
                                    tooltip: 'Apagar comentário',
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      try {
                                        await comentario.reference.delete();
                                      } catch (e) {
                                        debugPrint(
                                          'Erro ao apagar comentário: $e',
                                        );

                                        if (!contextSheet.mounted) return;

                                        ScaffoldMessenger.of(contextSheet)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Erro ao apagar comentário: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textoController,
                          maxLength: 500,
                          minLines: 1,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Escreva um comentário...',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Enviar comentário',
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final texto = textoController.text.trim();

                          if (texto.isEmpty) return;

                          try {
                            await comentariosRef.add({
                              'autorUid': usuario.uid,
                              'nomeAutor': nomeAutor,
                              'texto': texto,
                              'criadoEm': FieldValue.serverTimestamp(),
                            });

                            textoController.clear();
                          } catch (e) {
                            debugPrint('Erro ao enviar comentário: $e');

                            if (!contextSheet.mounted) return;

                            ScaffoldMessenger.of(contextSheet).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Não foi possível enviar: $e',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    textoController.dispose();
  }

  // ─── Nova publicação ────────────────────────────────────────────────────

  Future<void> _adicionarPublicacao() async {
    if (_perfil != 'coordenador') return;

    final tituloController = TextEditingController();
    final descricaoController = TextEditingController();

    Uint8List? imagemSelecionada;
    String? nomeImagem;

    _NovaPublicacao? dados;

    try {
      dados = await showDialog<_NovaPublicacao>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (contextDialogo, atualizarDialogo) {
              return AlertDialog(
                title: const Text('Nova publicação'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: tituloController,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descricaoController,
                        maxLines: 4,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final resultado =
                              await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );

                          if (resultado == null ||
                              resultado.files.isEmpty) {
                            return;
                          }

                          final arquivo = resultado.files.first;

                          if (arquivo.bytes == null) return;

                          atualizarDialogo(() {
                            imagemSelecionada = arquivo.bytes;
                            nomeImagem = arquivo.name;
                          });
                        },
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Selecionar imagem'),
                      ),
                      if (nomeImagem != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          nomeImagem!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final titulo = tituloController.text.trim();
                      final descricao = descricaoController.text.trim();

                      if (titulo.isEmpty ||
                          descricao.isEmpty ||
                          imagemSelecionada == null) {
                        ScaffoldMessenger.of(contextDialogo).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Preencha o título, a descrição e selecione uma imagem.',
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                        _NovaPublicacao(
                          titulo: titulo,
                          descricao: descricao,
                          imagem: imagemSelecionada!,
                          nomeImagem: nomeImagem!,
                        ),
                      );
                    },
                    child: const Text('Publicar'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      tituloController.dispose();
      descricaoController.dispose();
    }

    if (dados == null || !mounted) return;

    try {
      final usuario = FirebaseAuth.instance.currentUser;

      if (usuario == null) {
        throw Exception('Usuário não autenticado.');
      }

      final referencia = FirebaseFirestore.instance
          .collection('mural_novidades')
          .doc();

      final extensao = dados.nomeImagem.contains('.')
          ? dados.nomeImagem.split('.').last.toLowerCase()
          : 'jpg';

      final referenciaImagem = FirebaseStorage.instance
          .ref()
          .child('mural_novidades/${referencia.id}/imagem.$extensao');

      final tipoConteudo = switch (extensao) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        'bmp' => 'image/bmp',
        'heic' => 'image/heic',
        'heif' => 'image/heif',
        _ => 'image/jpeg',
      };

      await referenciaImagem.putData(
        dados.imagem,
        SettableMetadata(
          contentType: tipoConteudo,
          cacheControl: 'public,max-age=3600',
        ),
      );

      final urlImagem = await referenciaImagem.getDownloadURL();

      await referencia.set({
        'titulo': dados.titulo,
        'descricao': dados.descricao,
        'urlImagem': urlImagem,
        'autorUid': usuario.uid,
        'publicadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicação criada com sucesso!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível publicar: $e'),
        ),
      );
    }
  }

  // ─── Excluir publicação ─────────────────────────────────────────────────

  Future<void> _excluirPublicacao(
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) async {
    if (_perfil != 'coordenador') return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir publicação'),
        content: const Text(
          'Tem certeza de que deseja excluir esta publicação?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      final urlImagem = documento.data()['urlImagem'] as String?;

      if (urlImagem != null && urlImagem.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(urlImagem).delete();
        } on FirebaseException catch (e) {
          if (e.code != 'object-not-found') rethrow;
        }
      }

      await documento.reference.delete();

      if (!mounted) return;

      setState(() {
        _paginaAtual = 0;
      });

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicação excluída com sucesso!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível excluir: $e'),
        ),
      );
    }
  }

  // ─── Interface do mural ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = tema.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cores.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              color: const Color(0xFF8B0000),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mural de Novidades',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_perfil == 'coordenador')
                    IconButton(
                      tooltip: 'Nova publicação',
                      onPressed: _adicionarPublicacao,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('mural_novidades')
                  .orderBy('publicadoEm', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('Erro ao carregar mural: ${snapshot.error}');

                  return const SizedBox(
                    height: 240,
                    child: Center(
                      child: Text('Erro ao carregar o mural.'),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const SizedBox(
                    height: 240,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final publicacoes = snapshot.data?.docs ?? [];
                _quantidadeSlides = publicacoes.length;

                if (publicacoes.isEmpty) {
                  return SizedBox(
                    height: 240,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _perfil == 'coordenador'
                              ? 'Nenhuma publicação. Toque em + para adicionar uma novidade.'
                              : 'Nenhuma novidade publicada no momento.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cores.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 440,
                      child: Stack(
                        children: [
                          PageView.builder(
                            key: ValueKey(
                              publicacoes
                                  .map((documento) => documento.id)
                                  .join(','),
                            ),
                            controller: _pageController,
                            itemCount: publicacoes.length,
                            onPageChanged: (pagina) {
                              setState(() => _paginaAtual = pagina);
                            },
                            itemBuilder: (context, index) {
                              final documento = publicacoes[index];
                              final dados = documento.data();

                              final titulo =
                                  dados['titulo'] as String? ?? '';
                              final descricao =
                                  dados['descricao'] as String? ?? '';
                              final urlImagem =
                                  dados['urlImagem'] as String? ?? '';

                              final idPublicacao = documento.id;
                              final curtidaEmProcessamento =
                                  _curtidasEmProcessamento
                                      .contains(idPublicacao);

                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  8,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      titulo,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          tema.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatarData(dados['publicadoEm']),
                                      style:
                                          tema.textTheme.bodySmall?.copyWith(
                                        color: cores.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: urlImagem.isEmpty
                                            ? const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 48,
                                                ),
                                              )
                                            : Image.network(
                                                urlImagem,
                                                key: ValueKey(urlImagem),
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                filterQuality:
                                                    FilterQuality.medium,
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }

                                                  final total = loadingProgress
                                                      .expectedTotalBytes;
                                                  final carregado =
                                                      loadingProgress
                                                          .cumulativeBytesLoaded;

                                                  return Center(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const CircularProgressIndicator(),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          total == null
                                                              ? 'Carregando imagem...'
                                                              : 'Carregando ${(carregado / total * 100).toStringAsFixed(0)}%',
                                                          style: tema
                                                              .textTheme.bodySmall,
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  debugPrint(
                                                    'Erro ao carregar imagem: $error',
                                                  );

                                                  return Center(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .broken_image_outlined,
                                                          size: 48,
                                                          color: cores.error,
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          'Não foi possível carregar a imagem.',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: tema
                                                              .textTheme.bodySmall,
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      descricao,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: tema.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),

                                    // Curtidas e comentários
                                    Row(
                                      children: [
                                        StreamBuilder<
                                            QuerySnapshot<
                                                Map<String, dynamic>>>(
                                          stream: FirebaseFirestore.instance
                                              .collection('mural_novidades')
                                              .doc(idPublicacao)
                                              .collection('curtidas')
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasError) {
                                              debugPrint(
                                                'Erro ao carregar curtidas: ${snapshot.error}',
                                              );
                                            }

                                            final usuarioUid = FirebaseAuth
                                                .instance.currentUser?.uid;

                                            final curtidas =
                                                snapshot.data?.docs ?? [];

                                            final curtiu = usuarioUid != null &&
                                                curtidas.any(
                                                  (curtida) =>
                                                      curtida.id == usuarioUid,
                                                );

                                            return Row(
                                              children: [
                                                IconButton(
                                                  tooltip: curtiu
                                                      ? 'Remover curtida'
                                                      : 'Curtir',
                                                  onPressed:
                                                      curtidaEmProcessamento
                                                          ? null
                                                          : () =>
                                                              _alternarCurtida(
                                                                idPublicacao,
                                                              ),
                                                  icon: curtidaEmProcessamento
                                                      ? const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                        )
                                                      : Icon(
                                                          curtiu
                                                              ? Icons.favorite
                                                              : Icons
                                                                  .favorite_border,
                                                          color: curtiu
                                                              ? Colors.red
                                                              : cores.onSurface,
                                                          size: 22,
                                                        ),
                                                ),
                                                Text(
                                                  snapshot.hasError
                                                      ? '!'
                                                      : '${curtidas.length}',
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 12),
                                        StreamBuilder<
                                            QuerySnapshot<
                                                Map<String, dynamic>>>(
                                          stream: FirebaseFirestore.instance
                                              .collection('mural_novidades')
                                              .doc(idPublicacao)
                                              .collection('comentarios')
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasError) {
                                              debugPrint(
                                                'Erro ao carregar quantidade de comentários: ${snapshot.error}',
                                              );
                                            }

                                            final quantidade =
                                                snapshot.data?.docs.length ?? 0;

                                            return Row(
                                              children: [
                                                IconButton(
                                                  tooltip: 'Ver comentários',
                                                  onPressed: () =>
                                                      _abrirComentarios(
                                                    idPublicacao,
                                                  ),
                                                  icon: const Icon(
                                                    Icons.mode_comment_outlined,
                                                    size: 21,
                                                  ),
                                                ),
                                                Text(
                                                  snapshot.hasError
                                                      ? '!'
                                                      : '$quantidade',
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        const Spacer(),
                                        if (_perfil == 'coordenador')
                                          IconButton(
                                            tooltip: 'Excluir publicação',
                                            onPressed: () =>
                                                _excluirPublicacao(documento),
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: cores.error,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (publicacoes.length > 1)
                            Positioned(
                              left: 4,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton.filledTonal(
                                  tooltip: 'Publicação anterior',
                                  onPressed: () =>
                                      _irPara(_paginaAtual - 1),
                                  icon: const Icon(Icons.chevron_left),
                                ),
                              ),
                            ),
                          if (publicacoes.length > 1)
                            Positioned(
                              right: 4,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton.filledTonal(
                                  tooltip: 'Próxima publicação',
                                  onPressed: () =>
                                      _irPara(_paginaAtual + 1),
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (publicacoes.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(publicacoes.length, (index) {
                            final ativo = _paginaAtual == index;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              width: ativo ? 18 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: ativo
                                    ? cores.primary
                                    : cores.outlineVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NovaPublicacao {
  final String titulo;
  final String descricao;
  final Uint8List imagem;
  final String nomeImagem;

  const _NovaPublicacao({
    required this.titulo,
    required this.descricao,
    required this.imagem,
    required this.nomeImagem,
  });
}

// ─── Seção de Notícias / Avisos ──────────────────────────────────────────────

class _SecaoNoticias extends StatelessWidget {
  final List<_AvisoItem> avisos = const [
    _AvisoItem(
      titulo: 'Palestra: Mercado de TI',
      descricao:
          'Palestra sobre carreira e tendências no mercado de tecnologia.',
      data: 'Hoje',
      icone: Icons.mic_outlined,
    ),
    _AvisoItem(
      titulo: 'Ponto facultativo',
      descricao: 'Não haverá aula hoje devido ao feriado.',
      data: '02/06',
      icone: Icons.cancel_outlined,
    ),
    _AvisoItem(
      titulo: 'Code Wars',
      descricao: 'Inscrições abertas para a competição.',
      data: '30/05',
      icone: Icons.event_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Avisos Recentes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0.2,
            ),
          ),
        ),
        ...avisos.map((aviso) => _CardAviso(aviso: aviso)),
      ],
    );
  }
}

class _AvisoItem {
  final String titulo;
  final String descricao;
  final String data;
  final IconData icone;

  const _AvisoItem({
    required this.titulo,
    required this.descricao,
    required this.data,
    required this.icone,
  });
}

class _CardAviso extends StatelessWidget {
  final _AvisoItem aviso;

  const _CardAviso({required this.aviso});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
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
              color: const Color(0xFF8B0000).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              aviso.icone,
              color: const Color(0xFF8B0000),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aviso.titulo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  aviso.descricao,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            aviso.data,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface,
            size: 18,
          ),
        ],
      ),
    );
  }
}

// ─── Seção Acesso Rápido ────────────────────────────────────────────────────

class _SecaoAcessoRapido extends StatefulWidget {
  const _SecaoAcessoRapido();

  @override
  State<_SecaoAcessoRapido> createState() => _SecaoAcessoRapidoState();
}

class _SecaoAcessoRapidoState extends State<_SecaoAcessoRapido> {
  static const List<_AcessoItem> _itens = [
    _AcessoItem(
      icone: Icons.calendar_month_outlined,
      label: 'Calendário',
    ),
    _AcessoItem(
      icone: Icons.schedule_outlined,
      label: 'Horários',
    ),
    _AcessoItem(
      icone: Icons.language_outlined,
      label: 'Site',
    ),
    _AcessoItem(
      icone: Icons.school_outlined,
      label: 'SIGA',
    ),
    _AcessoItem(
      icone: Icons.local_library_outlined,
      label: 'Biblioteca',
    ),
    _AcessoItem(
      icone: Icons.work_outline,
      label: 'Estágio',
    ),
    _AcessoItem(
      icone: Icons.record_voice_over_outlined,
      label: 'Ouvidoria',
    ),
    _AcessoItem(
      icone: Icons.email_outlined,
      label: 'E-mail',
    ),
  ];

  String? _perfil;
  String? _urlCalendario;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    try {
      final usuarioDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      final calendarioDoc = await FirebaseFirestore.instance
          .collection('configuracoes')
          .doc('calendario')
          .get();

      if (!mounted) return;

      setState(() {
        _perfil = usuarioDoc.data()?['perfil'];
        _urlCalendario = calendarioDoc.data()?['url'];
      });
    } catch (e) {
      debugPrint('Erro ao carregar acesso rápido: $e');
    }
  }

  Future<void> _adicionarCalendario() async {
    if (_perfil != 'coordenador') return;

    try {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (resultado == null || resultado.files.isEmpty) return;

      final arquivo = resultado.files.first;
      final Uint8List? bytes = arquivo.bytes;

      if (bytes == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível ler o arquivo.'),
          ),
        );
        return;
      }

      final referencia = FirebaseStorage.instance
          .ref()
          .child('calendario')
          .child('calendario_letivo.pdf');

      await referencia.putData(
        bytes,
        SettableMetadata(contentType: 'application/pdf'),
      );

      final url = await referencia.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('configuracoes')
          .doc('calendario')
          .set({
        'url': url,
        'nomeArquivo': arquivo.name,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _urlCalendario = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calendário enviado com sucesso.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar o calendário: $e'),
        ),
      );
    }
  }

  Future<void> _apagarCalendario() async {
    if (_perfil != 'coordenador') return;

    try {
      final referencia = FirebaseStorage.instance
          .ref()
          .child('calendario')
          .child('calendario_letivo.pdf');

      try {
        await referencia.delete();
      } catch (_) {}

      await FirebaseFirestore.instance
          .collection('configuracoes')
          .doc('calendario')
          .delete();

      if (!mounted) return;

      setState(() {
        _urlCalendario = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calendário apagado com sucesso.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao apagar o calendário: $e'),
        ),
      );
    }
  }

  Future<void> _menuCalendario() async {
    if (_perfil != 'coordenador') return;

    final opcao = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Adicionar PDF'),
                onTap: () => Navigator.pop(context, 'adicionar'),
              ),
              if (_urlCalendario != null && _urlCalendario!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Apagar PDF atual'),
                  onTap: () => Navigator.pop(context, 'apagar'),
                ),
            ],
          ),
        );
      },
    );

    if (opcao == 'adicionar') {
      await _adicionarCalendario();
    } else if (opcao == 'apagar') {
      await _apagarCalendario();
    }
  }

  Future<void> _abrirCalendario() async {
    if (_urlCalendario == null || _urlCalendario!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O calendário ainda não foi disponibilizado.',
          ),
        ),
      );
      return;
    }

    await launchUrl(
      Uri.parse(_urlCalendario!),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Acesso Rápido',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0.2,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: _itens.map((item) {
            if (item.label == 'Calendário') {
              return _CardAcesso(
                item: item,
                onTap: _abrirCalendario,
                mostrarMais: _perfil == 'coordenador',
                onMaisTap: _menuCalendario,
              );
            }

            return _CardAcesso(item: item);
          }).toList(),
        ),
      ],
    );
  }
}

class _AcessoItem {
  final IconData icone;
  final String label;

  const _AcessoItem({
    required this.icone,
    required this.label,
  });
}

class _CardAcesso extends StatelessWidget {
  final _AcessoItem item;
  final VoidCallback? onTap;
  final bool mostrarMais;
  final VoidCallback? onMaisTap;

  const _CardAcesso({
    required this.item,
    this.onTap,
    this.mostrarMais = false,
    this.onMaisTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B0000).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icone,
                      color: const Color(0xFF8B0000),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (mostrarMais)
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onMaisTap,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B0000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

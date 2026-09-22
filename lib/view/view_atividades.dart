import 'package:flutter/material.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fatechub2/view/view_criar_atividade.dart';
import 'view_atividadeEntregar.dart';

class TelaAtividades extends StatefulWidget {
  final String nomeUsuario;
  final String nomeTurma;
  final String? disciplina;

  const TelaAtividades({
    super.key,
    required this.nomeUsuario,
    required this.nomeTurma,
    this.disciplina,
  });

  @override
  State<TelaAtividades> createState() => _TelaAtividadesState();
}

class _TelaAtividadesState extends State<TelaAtividades> {
  String? _perfil;
  bool _carregandoPerfil = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    try {
      final usuario = FirebaseAuth.instance.currentUser;

      if (usuario == null) {
        setState(() {
          _carregandoPerfil = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      if (doc.exists) {
        final dados = doc.data();

        setState(() {
          _perfil = dados?['perfil'] as String?;
          _carregandoPerfil = false;
        });
      } else {
        setState(() {
          _carregandoPerfil = false;
        });
      }
    } catch (e) {
      setState(() {
        _carregandoPerfil = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,

      appBar: AppBarPadrao(
        nomeUsuario: widget.nomeUsuario,
        mostrarVoltar: true,
      ),

      floatingActionButton:
          !_carregandoPerfil && _perfil == 'professor'
              ? FloatingActionButton(
                  backgroundColor: const Color(0xFF8B0000),
                  foregroundColor: Colors.white,
                  onPressed: _abrirNovaAtividade,
                  child: const Icon(Icons.add),
                )
              : null,

      body: Column(
        children: [
          _buildCabecalho(),
          _buildTitulo(),

          Expanded(
            child: _buildListaAtividades(),
          ),
        ],
      ),
    );
  }

  Widget _buildCabecalho() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      child: Column(
        children: [
          Text(
            widget.disciplina ?? widget.nomeTurma,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            widget.nomeTurma,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitulo() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Text(
        'ATIVIDADES',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildListaAtividades() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('turmas')
          .doc(widget.nomeTurma)
          .collection('atividades')
          .orderBy('dataEntrega')
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Não foi possível carregar as atividades.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        final documentos = snapshot.data?.docs ?? [];

        if (documentos.isEmpty) {
          return _buildSemAtividades();
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            top: 3,
            bottom: 90,
          ),
          itemCount: documentos.length,
          itemBuilder: (context, index) {
            final documento = documentos[index];

            final dados =
                documento.data() as Map<String, dynamic>;

            final String nome =
                dados['nome']?.toString() ?? 'Sem título';

            final String descricao =
                dados['descricao']?.toString() ?? '';

            final String dataEntrega =
                _formatarData(dados['dataEntrega']);

            final bool entregue =
                dados['entregue'] == true;

            return _buildAtividade(
              id: documento.id,
              nome: nome,
              dataEntrega: dataEntrega,
              entregue: entregue,
              descricao: descricao,
            );
          },
        );
      },
    );
  }

  Widget _buildSemAtividades() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 52,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),

            const SizedBox(height: 14),

            Text(
              'Nenhuma atividade publicada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              _perfil == 'professor'
                  ? 'Clique no botão + para publicar uma atividade.'
                  : 'Quando o professor publicar uma atividade, ela aparecerá aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtividade({
    required String id,
    required String nome,
    required String dataEntrega,
    required bool entregue,
    required String descricao,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 3,
      ),
      padding: const EdgeInsets.fromLTRB(
        12,
        11,
        12,
        11,
      ),
      color: Theme.of(context).colorScheme.surface,

      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TelaAtividade(
                nomeUsuario: widget.nomeUsuario,
                nomeTurma: widget.nomeTurma,
                atividadeId: id,
                nome: nome,
                dataEntrega: dataEntrega,
                descricao: descricao,
                disciplina: widget.disciplina,
                isProfessor: _perfil == 'professor',
              ),
            ),
          );
        },

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,

          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius:
                    BorderRadius.circular(6),
              ),

              child: const Icon(
                Icons.assignment_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    nome,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      Icon(
                        Icons
                            .calendar_today_outlined,
                        size: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        'Entrega: $dataEntrega',
                        style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            if (_perfil == 'professor')
              IconButton(
                onPressed: () {
                  _confirmarExclusao(
                    id: id,
                    nome: nome,
                  );
                },
                icon: const Icon(
                  Icons.delete_outline,
                  size: 22,
                ),
                color: const Color(0xFF8B0000),
                tooltip: 'Excluir atividade',
              )
            else
              _buildStatus(entregue),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(bool entregue) {
    return Column(
      children: [
        Icon(
          entregue
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          size: 23,
          color: entregue
              ? Colors.green
              : Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
        ),

        const SizedBox(height: 2),

        Text(
          entregue ? 'Entregue' : 'Pendente',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            color: entregue
                ? Colors.green
                : Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _mostrarDetalhes({
    required String id,
    required String nome,
    required String dataEntrega,
    required bool entregue,
    required String descricao,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(14),
        ),
      ),

      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            25,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                nome,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    'Data de entrega: $dataEntrega',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                descricao.isEmpty
                    ? 'Nenhuma descrição informada.'
                    : descricao,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),

              if (_perfil != 'professor') ...[
                const SizedBox(height: 16),

                Row(
                  children: [
                    Icon(
                      entregue
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: entregue
                          ? Colors.green
                          : Colors.grey,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      entregue
                          ? 'Atividade entregue'
                          : 'Atividade não entregue',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                        color: entregue
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmarExclusao({
    required String id,
    required String nome,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Excluir atividade?',
          ),

          content: Text(
            'Tem certeza que deseja excluir "$nome"?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Excluir',
                style: TextStyle(
                  color: Color(0xFF8B0000),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('turmas')
          .doc(widget.nomeTurma)
          .collection('atividades')
          .doc(id)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Atividade excluída com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível excluir a atividade.',
          ),
        ),
      );
    }
  }

  void _abrirNovaAtividade() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TelaCriarAtividade(
        nomeUsuario: widget.nomeUsuario,
        nomeTurma: widget.nomeTurma,
        disciplina: widget.disciplina,
      ),
    ),
  );
}

  String _formatarData(dynamic data) {
    if (data == null) {
      return 'Sem data';
    }

    if (data is Timestamp) {
      final date = data.toDate();

      final dia =
          date.day.toString().padLeft(2, '0');

      final mes =
          date.month.toString().padLeft(2, '0');

      final ano = date.year.toString();

      return '$dia/$mes/$ano';
    }

    return data.toString();
  }
}
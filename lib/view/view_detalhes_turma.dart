import 'package:flutter/material.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:fatechub2/view/view_atividades.dart';

class TelaDetalhesTurma extends StatefulWidget {
  final String nomeUsuario;
  final String nomeTurma;
  final String? disciplina;

  const TelaDetalhesTurma({
    super.key,
    required this.nomeUsuario,
    required this.nomeTurma,
    this.disciplina,
  });

  @override
  State<TelaDetalhesTurma> createState() => _TelaDetalhesTurmaState();
}

class _TelaDetalhesTurmaState extends State<TelaDetalhesTurma> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,

      appBar: AppBarPadrao(
  nomeUsuario: widget.nomeUsuario,
  mostrarVoltar: true,
),

      body: Column(
        children: [
          _buildCabecalhoTurma(),
          _buildBotoes(),
          _buildTituloMural(),
          Expanded(
            child: _buildMural(),
          ),
        ],
      ),
    );
  }

  Widget _buildCabecalhoTurma() {
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

  Widget _buildBotoes() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildBotao(
              texto: 'Atividades',
              icone: Icons.assignment_outlined,
              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TelaAtividades(
        nomeUsuario: widget.nomeUsuario,
        nomeTurma: widget.nomeTurma,
        disciplina: widget.disciplina,
      ),
    ),
  );
},
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildBotao(
              texto: 'Arquivos',
              icone: Icons.folder_outlined,
              onTap: () {
                // Vamos implementar depois.
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotao({
    required String texto,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B0000),
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 18,
            ),
            const SizedBox(width: 7),
            Text(
              texto,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTituloMural() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
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

  Widget _buildMural() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildPost(
          professor: 'Prof.',
          titulo: 'PRIMEIRO POST!',
          texto:
              'Texto teste de texto para o FatecHub hahaha, é assim que o projeto vai ser. '
              'Essa é uma publicação de exemplo.',
          curtidas: 10,
          comentarios: 03,
        ),
        _buildPost(
          professor: 'Prof.',
          titulo: 'SEGUNDO POST!',
          texto:
              'Texto teste de texto para o FatecHub hahaha, é assim que o projeto vai ser. '
              'Essa é uma publicação de exemplo.',
          curtidas: 09,
          comentarios: 02,
        ),
        _buildPost(
          professor: 'Prof.',
          titulo: 'TERCEIRO POST!',
          texto:
              'Texto teste de texto para o FatecHub hahaha, é assim que o projeto vai ser. '
              'Essa é uma publicação de exemplo.',
          curtidas: 12,
          comentarios: 04,
        ),
      ],
    );
  }

  Widget _buildPost({
    required String professor,
    required String titulo,
    required String texto,
    required int curtidas,
    required int comentarios,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 3,
      ),
      padding: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        7,
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: Colors.grey.shade300,
                child: Icon(
                  Icons.person,
                  size: 19,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            professor,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '18:23 14/09/2026',
                          style: TextStyle(
                            fontSize: 8,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      texto,
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.favorite_border,
                size: 15,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
              const SizedBox(width: 3),
              Text(
                '$curtidas',
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chat_bubble_outline,
                size: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
              const SizedBox(width: 3),
              Text(
                '$comentarios',
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
    );
  }
}
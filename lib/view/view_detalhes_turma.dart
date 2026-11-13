import 'package:flutter/material.dart';
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:fatechub2/widgets/mural_turma.dart';
import 'package:fatechub2/view/view_atividades.dart';
import 'package:fatechub2/view/view_arquivos.dart';

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

          // Mural da turma (a faixa "COMEÇO DO MURAL" já vem dentro dele)
          Expanded(
            child: SingleChildScrollView(
              child: MuralTurma(nomeTurma: widget.nomeTurma),
            ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TelaArquivos(
                      nomeUsuario: widget.nomeUsuario, 
                      nomeTurma: widget.nomeTurma
                    ),
                  ),
                );
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
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fatechub2/widgets/app_bar.dart';

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
  State<TelaCriarAtividade> createState() =>
      _TelaCriarAtividadeState();
}

class _TelaCriarAtividadeState
    extends State<TelaCriarAtividade> {
  final TextEditingController _tituloController =
      TextEditingController();

  final TextEditingController _prazoController =
      TextEditingController();

  final TextEditingController _descricaoController =
      TextEditingController();

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  bool _postando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _prazoController.dispose();
    _descricaoController.dispose();
    super.dispose();
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

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            30,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              _buildTituloPagina(),

              const SizedBox(height: 24),

              _buildCampoTitulo(),

              const SizedBox(height: 18),

              _buildCampoPrazo(),

              const SizedBox(height: 18),

              _buildCampoDescricao(),

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
        color: Theme.of(context)
            .colorScheme
            .onSurface,
      ),
    ),
  );
}

  Widget _buildCampoTitulo() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          'Título',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context)
                .colorScheme
                .onSurface,
          ),
        ),

        const SizedBox(height: 7),

        TextFormField(
          controller: _tituloController,

          textCapitalization:
              TextCapitalization.sentences,

          decoration: _decoracaoCampo(
            hint: 'Digite o título da atividade',
          ),

          validator: (valor) {
            if (valor == null ||
                valor.trim().isEmpty) {
              return 'Informe o título da atividade.';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCampoPrazo() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          'Prazo',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context)
                .colorScheme
                .onSurface,
          ),
        ),

        const SizedBox(height: 7),

        TextFormField(
          controller: _prazoController,

          keyboardType:
              TextInputType.datetime,

          decoration: _decoracaoCampo(
            hint: 'Digite o prazo da atividade',
          ),

          validator: (valor) {
            if (valor == null ||
                valor.trim().isEmpty) {
              return 'Informe o prazo da atividade.';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCampoDescricao() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          'Descrição',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context)
                .colorScheme
                .onSurface,
          ),
        ),

        const SizedBox(height: 7),

        TextFormField(
          controller: _descricaoController,

          textCapitalization:
              TextCapitalization.sentences,

          maxLines: 6,

          decoration: _decoracaoCampo(
            hint: 'Digite a descrição da atividade',
          ),
        ),
      ],
    );
  }

  InputDecoration _decoracaoCampo({
    required String hint,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: TextStyle(
        fontSize: 11,
        color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant,
      ),

      filled: true,

      fillColor: Theme.of(context)
          .colorScheme
          .surface,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(7),

        borderSide: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(7),

        borderSide: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(7),

        borderSide: const BorderSide(
          color: Color(0xFF8B0000),
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(7),

        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(7),

        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

Widget _buildBotoes() {
  return Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            // Botão apenas visual por enquanto.
          },

          icon: const Icon(
            Icons.attach_file,
            size: 19,
          ),

          label: const Text(
            'Anexar',
          ),

          style: ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF8B0000),

            foregroundColor:
                Colors.white,

            padding:
                const EdgeInsets.symmetric(
              vertical: 13,
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(7),
            ),
          ),
        ),
      ),

      const SizedBox(width: 10),

      Expanded(
        child: ElevatedButton.icon(
          onPressed:
              _postando ? null : _postar,

          icon: _postando
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.subdirectory_arrow_right,
                  size: 19,
                ),

          label: Text(
            _postando
                ? 'Postando...'
                : 'Postar',
          ),

          style: ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF8B0000),

            foregroundColor:
                Colors.white,

            disabledBackgroundColor:
                Colors.grey,

            padding:
                const EdgeInsets.symmetric(
              vertical: 13,
            ),

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(7),
            ),
          ),
        ),
      ),
    ],
  );
}

  Future<void> _postar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _postando = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('turmas')
          .doc(widget.nomeTurma)
          .collection('atividades')
          .add({
        'nome': _tituloController.text.trim(),

        'dataEntrega':
            _prazoController.text.trim(),

        'descricao':
            _descricaoController.text.trim(),

        'entregue': false,

        'disciplina':
            widget.disciplina ?? widget.nomeTurma,

        'turma':
            widget.nomeTurma,

        'criadoEm':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Atividade publicada com sucesso!',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível publicar a atividade.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _postando = false;
        });
      }
    }
  }
}
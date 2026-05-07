import 'package:fatechub2/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class TelaTurmas extends StatefulWidget {
  const TelaTurmas({super.key});

  @override
  State<TelaTurmas> createState() => _TelaTurmasState();
}

// Mixin adicionado para manter a tela salva
class _TelaTurmasState extends State<TelaTurmas> 
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _buscaController = TextEditingController();
  String _filtro = 'Todos';
  String _busca = '';

  //  Interar com a API futuramente
  final String _turmaAtual = 'Análise-e-Desenvolvimento-de-Sistemas-4-Semestre-Manhã-2';
  //  Interar com a API futuramente
  final List<Map<String, dynamic>> _disciplinas = [
    {'nome': 'Engenharia de Software III', 'ativo': true},
    {'nome': 'Programação Orientada...', 'ativo': true},
    {'nome': 'Banco de Dados', 'ativo': true},
    {'nome': 'Sistemas Operacionais II', 'ativo': true},
    {'nome': 'English IV', 'ativo': true},
    {'nome': 'Programação para Disp...', 'ativo': true},
  ];

List<Map<String, dynamic>> get _disciplinasFiltradas {
  return _disciplinas.where((d) {
    // Filtro ativo/inativo
    final passaFiltro = switch (_filtro) {
      'Ativos'   => d['ativo'] == true,
      'Inativos' => d['ativo'] == false,
      _          => true, // 'Todos'
    };

    // Filtro de busca
    final passaBusca = _busca.isEmpty ||
        (d['nome'] as String).toLowerCase().contains(_busca.toLowerCase());

    return passaFiltro && passaBusca;
  }).toList();
}

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
 
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: const AppBarPadrao(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNomeTurma(),
          _buildBarraFiltros(),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  Widget _buildNomeTurma() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        _turmaAtual,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF212121),
        ),
      ),
    );
  }

  Widget _buildBarraFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          // Dropdown Todos
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFBDBDBD)),
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filtro,
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF424242),
                ),
                items: ['Todos', 'Ativos', 'Inativos']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _filtro = value!),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Campo de busca
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _buscaController,
                onChanged: (value) => setState(() => _busca = value),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                        color: Color(0xFF8B0000), width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Botão ordenar
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFBDBDBD)),
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
            ),
            child: const Center(
              child: Text(
                'Ordenar por',
                style: TextStyle(fontSize: 12, color: Color(0xFF424242)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final disciplinas = _disciplinasFiltradas;

    if (disciplinas.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma disciplina encontrada.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: disciplinas.length,
      itemBuilder: (context, index) =>
          _buildCardDisciplina(disciplinas[index]),
    );
  }

  Widget _buildCardDisciplina(Map<String, dynamic> disciplina) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Área da imagem/thumbnail   (Adicionar opção para professor fazer upload de uma imagem futuramente)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Center(
                  child: Icon(
                    Icons.image_outlined,         
                    color: Colors.grey[400],
                    size: 36,
                  ),
                ),
              ),
            ),

            // Nome da disciplina
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                disciplina['nome'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF212121),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:fatechub2/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'view_detalhes_turma.dart';
import 'view_todas_atividades.dart';

class TelaTurmas extends StatefulWidget {
  final String nomeUsuario;

  const TelaTurmas({
    super.key,
    required this.nomeUsuario,
  });

  @override
  State<TelaTurmas> createState() => _TelaTurmasState();
}

class _TelaTurmasState extends State<TelaTurmas>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _buscaController =
      TextEditingController();

  String _filtro = 'Todos';
  String _busca = '';

  int? _semestreAluno;
  String? _turnoAluno;
  String? _disciplinaProfessor;
  String? _perfil;

  bool _carregando = true;

  // ─── Disciplinas por semestre (aluno) ─────────────────────────────────────

  final List<Map<String, dynamic>> _disciplinasPrimeiroSemestre = [
    {'nome': 'Engenharia de Software I', 'ativo': true},
    {'nome': 'Sistemas Operacionais', 'ativo': true},
    {'nome': 'Comunicação e Expressão', 'ativo': true},
    {'nome': 'Inglês I', 'ativo': true},
    {'nome': 'PI ADS I', 'ativo': true},
    {'nome': 'Algoritmos e Lógica de Programação', 'ativo': true},
    {'nome': 'Arquitetura e Organização de Computadores', 'ativo': true},
  ];

  final List<Map<String, dynamic>> _disciplinasSegundoSemestre = [
    {'nome': 'Cibersegurança e Segurança da Informação', 'ativo': true},
    {'nome': 'Linguagem de Programação I', 'ativo': true},
    {'nome': 'Inglês II', 'ativo': true},
    {'nome': 'Engenharia de Software II', 'ativo': true},
    {'nome': 'PI ADS II', 'ativo': true},
    {'nome': 'Banco de Dados I', 'ativo': true},
    {'nome': 'Desenvolvimento Web', 'ativo': true},
  ];

  // ─── Mapa disciplina -> código da turma ───────────────────────────────────

  static const Map<String, String> _codigoTurma = {
    'Engenharia de Software I': 'ENG-SOFT-I',
    'Sistemas Operacionais': 'SO',
    'Comunicação e Expressão': 'COM-EXP',
    'Inglês I': 'INGLES-I',
    'PI ADS I': 'PI-ADS-I',
    'Algoritmos e Lógica de Programação': 'ALG-L-P',
    'Arquitetura e Organização de Computadores': 'A-O-COMP',
    'Cibersegurança e Segurança da Informação': 'C-SEG-INF',
    'Linguagem de Programação I': 'LING-PROG-I',
    'Inglês II': 'INGLES-II',
    'Engenharia de Software II': 'ENG-SOFT-II',
    'PI ADS II': 'PI-ADS-II',
    'Banco de Dados I': 'BD-I',
    'Desenvolvimento Web': 'DES-WEB',

    'ENG SOFT I': 'ENG-SOFT-I',
    'SO': 'SO',
    'COM EXP': 'COM-EXP',
    'INGLES I': 'INGLES-I',
    'ALG L P': 'ALG-L-P',
    'A O COMP': 'A-O-COMP',
    'C SEG INF': 'C-SEG-INF',
    'LING PROG I': 'LING-PROG-I',
    'INGLES II': 'INGLES-II',
    'ENG SOFT II': 'ENG-SOFT-II',
    'BD I': 'BD-I',
    'DES WEB': 'DES-WEB',
  };

  // ─── Mapa disciplina -> nome completo ─────────────────────────────────────

  static const Map<String, String> _nomeCompleto = {
    'Engenharia de Software I': 'Engenharia de Software I',
    'Sistemas Operacionais': 'Sistemas Operacionais',
    'Comunicação e Expressão': 'Comunicação e Expressão',
    'Inglês I': 'Inglês I',
    'PI ADS I': 'PI ADS I',
    'Algoritmos e Lógica de Programação':
        'Algoritmos e Lógica de Programação',
    'Arquitetura e Organização de Computadores':
        'Arquitetura e Organização de Computadores',
    'Cibersegurança e Segurança da Informação':
        'Cibersegurança e Segurança da Informação',
    'Linguagem de Programação I': 'Linguagem de Programação I',
    'Inglês II': 'Inglês II',
    'Engenharia de Software II': 'Engenharia de Software II',
    'PI ADS II': 'PI ADS II',
    'Banco de Dados I': 'Banco de Dados I',
    'Desenvolvimento Web': 'Desenvolvimento Web',

    'ENG SOFT I': 'Engenharia de Software I',
    'SO': 'Sistemas Operacionais',
    'COM EXP': 'Comunicação e Expressão',
    'INGLES I': 'Inglês I',
    'ALG L P': 'Algoritmos e Lógica de Programação',
    'A O COMP': 'Arquitetura e Organização de Computadores',
    'C SEG INF': 'Cibersegurança e Segurança da Informação',
    'LING PROG I': 'Linguagem de Programação I',
    'INGLES II': 'Inglês II',
    'ENG SOFT II': 'Engenharia de Software II',
    'BD I': 'Banco de Dados I',
    'DES WEB': 'Desenvolvimento Web',
  };

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    try {
      final usuario = FirebaseAuth.instance.currentUser;

      if (usuario == null) {
        setState(() => _carregando = false);
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
          _semestreAluno = dados?['semestre'] as int?;
          _turnoAluno =
              (dados?['turno'] as String?)?.trim();
          _disciplinaProfessor =
              (dados?['disciplina'] as String?)?.trim();
          _carregando = false;
        });
      } else {
        setState(() => _carregando = false);
      }
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  // ─── Turmas do professor ─────────────────────────────────────────────────

  List<Map<String, dynamic>> get _turmasProfessor {
    if (_disciplinaProfessor == null) return [];

    final codigo =
        _codigoTurma[_disciplinaProfessor] ??
            _disciplinaProfessor!;

    return [
      {'nome': '$codigo-MANHA', 'ativo': true},
      {'nome': '$codigo-NOITE', 'ativo': true},
    ];
  }

  // ─── Disciplinas do aluno ─────────────────────────────────────────────────

  List<Map<String, dynamic>> get _disciplinas {
    switch (_semestreAluno) {
      case 1:
        return _disciplinasPrimeiroSemestre;
      case 2:
        return _disciplinasSegundoSemestre;
      default:
        return [];
    }
  }

  // ─── Lista filtrada ───────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _listaFiltrada {
    final lista =
        _perfil == 'professor'
            ? _turmasProfessor
            : _disciplinas;

    return lista.where((d) {
      final passaFiltro = switch (_filtro) {
        'Ativos' => d['ativo'] == true,
        'Inativos' => d['ativo'] == false,
        _ => true,
      };

      final passaBusca = _busca.isEmpty ||
          (d['nome'] as String)
              .toLowerCase()
              .contains(_busca.toLowerCase());

      return passaFiltro && passaBusca;
    }).toList();
  }

  String get _tituloCabecalho {
    if (_perfil == 'professor') {
      return _nomeCompleto[_disciplinaProfessor?.trim()] ??
          _disciplinaProfessor ??
          '';
    }

    return 'Análise e Desenvolvimento de Sistemas - ${_semestreAluno}º Semestre';
  }

  // ─── Botão de atividades do aluno ────────────────────────────────────────


Widget _buildBotaoAtividades() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
    child: SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: () {
          if (_semestreAluno == null ||
              _turnoAluno == null ||
              _turnoAluno!.isEmpty) {
            return;
          }

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TelaTodasAtividadesAluno(
                nomeUsuario: widget.nomeUsuario,
                semestre: _semestreAluno!,
                turno: _turnoAluno!,
              ),
            ),
          );
        },
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
          children: const [
            Icon(
              Icons.assignment_outlined,
              size: 18,
            ),
            SizedBox(width: 7),
            Text(
              'Atividades',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
      backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBarPadrao(
        nomeUsuario: widget.nomeUsuario,
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _perfil == 'professor'
              ? _disciplinaProfessor == null
                  ? _buildErro(
                      'Disciplina não encontrada.',
                    )
                  : Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildCabecalho(
                          _tituloCabecalho,
                        ),
                        _buildBarraFiltros(),
                        Expanded(
                          child: _buildGrid(),
                        ),
                      ],
                    )
              : _semestreAluno == null
                  ? _buildErro(
                      'Não foi possível identificar o semestre.',
                    )
                  : Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildCabecalho(
                          _tituloCabecalho,
                        ),
                        _buildBarraFiltros(),

                        // Só aparece para alunos.
                        _buildBotaoAtividades(),

                        Expanded(
                          child: _buildGrid(),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildErro(String mensagem) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          mensagem,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildCabecalho(String texto) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color:
              Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildBarraFiltros() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12,
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface,
              ),
              borderRadius: BorderRadius.circular(6),
              color: Theme.of(context)
                  .colorScheme
                  .surface,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filtro,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface,
                ),
                items: [
                  'Todos',
                  'Ativos',
                  'Inativos',
                ]
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _filtro = value!;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _buscaController,
                onChanged: (value) {
                  setState(() {
                    _busca = value;
                  });
                },
                style: const TextStyle(
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar',
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface,
                    fontSize: 13,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(6),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                  focusedBorder:
                      const OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(6),
                    ),
                    borderSide: BorderSide(
                      color: Color(0xFF8B0000),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
              borderRadius: BorderRadius.circular(6),
              color: Theme.of(context)
                  .colorScheme
                  .surface,
            ),
            child: Center(
              child: Text(
                'Ordenar por',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final lista = _listaFiltrada;

    if (lista.isEmpty) {
      return Center(
        child: Text(
          _perfil == 'professor'
              ? 'Nenhuma turma encontrada.'
              : 'Nenhuma disciplina encontrada.',
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: lista.length,
      itemBuilder: (context, index) =>
          _buildCard(lista[index]),
    );
  }

  Widget _buildCard(
    Map<String, dynamic> item,
  ) {
    final String nomeItem =
        item['nome'] as String;

    final String nomeDisciplina =
        _nomeCompleto[nomeItem] ??
            _nomeCompleto[
                _disciplinaProfessor?.trim()
            ] ??
            nomeItem;

    final String codigoBase =
        _codigoTurma[nomeItem] ?? nomeItem;

    final String codigoTurma =
        _perfil == 'professor'
            ? nomeItem
            : (_turnoAluno == null ||
                    _turnoAluno!.isEmpty
                ? codigoBase
                : '$codigoBase-$_turnoAluno');

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TelaDetalhesTurma(
              nomeUsuario: widget.nomeUsuario,
              nomeTurma: codigoTurma,
              disciplina: nomeDisciplina,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.surface,
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFEEEEEE),
                  borderRadius:
                      BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.grey,
                    size: 36,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Text(
                nomeItem,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fatechub2/widgets/app_bar.dart';

class TelaTodasAtividadesAluno extends StatefulWidget {
  final String nomeUsuario;
  final int semestre;
  final String turno;

  const TelaTodasAtividadesAluno({
    super.key,
    required this.nomeUsuario,
    required this.semestre,
    required this.turno,
  });

  @override
  State<TelaTodasAtividadesAluno> createState() =>
      _TelaTodasAtividadesAlunoState();
}

class _TelaTodasAtividadesAlunoState
    extends State<TelaTodasAtividadesAluno> {
  bool _carregando = true;

  List<Map<String, dynamic>> _atividades = [];

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
  };

  static const List<String> _primeiroSemestre = [
    'Engenharia de Software I',
    'Sistemas Operacionais',
    'Comunicação e Expressão',
    'Inglês I',
    'PI ADS I',
    'Algoritmos e Lógica de Programação',
    'Arquitetura e Organização de Computadores',
  ];

  static const List<String> _segundoSemestre = [
    'Cibersegurança e Segurança da Informação',
    'Linguagem de Programação I',
    'Inglês II',
    'Engenharia de Software II',
    'PI ADS II',
    'Banco de Dados I',
    'Desenvolvimento Web',
  ];

  @override
  void initState() {
    super.initState();
    _carregarAtividades();
  }

  Future<void> _carregarAtividades() async {
    try {
      final disciplinas = widget.semestre == 1
          ? _primeiroSemestre
          : _segundoSemestre;

      final List<Map<String, dynamic>> atividades = [];

      for (final disciplina in disciplinas) {
        final codigo = _codigoTurma[disciplina];

        if (codigo == null) continue;

        final turma = '$codigo-${widget.turno}';

        final snapshot = await FirebaseFirestore.instance
            .collection('turmas')
            .doc(turma)
            .collection('atividades')
            .get();

        for (final documento in snapshot.docs) {
          final dados = documento.data();

          atividades.add({
            'id': documento.id,
            'nome': dados['nome']?.toString() ?? 'Sem título',
            'descricao': dados['descricao']?.toString() ?? '',
            'dataEntrega': dados['dataEntrega'],
            'entregue': dados['entregue'] == true,
            'disciplina':
                dados['disciplina']?.toString() ?? disciplina,
            'turma': turma,
          });
        }
      }

      atividades.sort((a, b) {
        final dataA = _dataParaOrdenacao(a['dataEntrega']);
        final dataB = _dataParaOrdenacao(b['dataEntrega']);

        return dataA.compareTo(dataB);
      });

      if (!mounted) return;

      setState(() {
        _atividades = atividades;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
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
      body: Column(
        children: [
          _buildCabecalho(),
          _buildTitulo(),
          Expanded(
            child: _carregando
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _atividades.isEmpty
                    ? _buildSemAtividades()
                    : _buildListaAtividades(),
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
            'ATIVIDADES',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Todas as atividades das suas disciplinas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitulo() {
    return Container(
      width: double.infinity,
      color:
          Theme.of(context).colorScheme.surfaceContainerHighest,
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
    return ListView.builder(
      padding: const EdgeInsets.only(
        top: 3,
        bottom: 20,
      ),
      itemCount: _atividades.length,
      itemBuilder: (context, index) {
        return _buildAtividade(
          _atividades[index],
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
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              'Nenhuma atividade publicada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color:
                    Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Quando o professor publicar uma atividade, ela aparecerá aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color:
                    Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtividade(
    Map<String, dynamic> atividade,
  ) {
    final String nome = atividade['nome'].toString();

    final String dataEntrega =
        _formatarData(atividade['dataEntrega']);

    final bool entregue =
        atividade['entregue'] == true;

    final String descricao =
        atividade['descricao'].toString();

    final String disciplina =
        atividade['disciplina'].toString();

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
          _mostrarDetalhes(
            nome: nome,
            dataEntrega: dataEntrega,
            entregue: entregue,
            descricao: descricao,
            disciplina: disciplina,
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
                borderRadius: BorderRadius.circular(6),
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
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Entrega: $dataEntrega',
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    disciplina,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
    required String nome,
    required String dataEntrega,
    required bool entregue,
    required String descricao,
    required String disciplina,
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
              const SizedBox(height: 8),
              Text(
                disciplina,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                  fontWeight: FontWeight.w500,
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    entregue
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color:
                        entregue ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entregue
                        ? 'Atividade entregue'
                        : 'Atividade não entregue',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          entregue ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

  DateTime _dataParaOrdenacao(dynamic data) {
    if (data is Timestamp) {
      return data.toDate();
    }

    if (data is String) {
      final partes = data.split('/');

      if (partes.length == 3) {
        final dia = int.tryParse(partes[0]);
        final mes = int.tryParse(partes[1]);
        final ano = int.tryParse(partes[2]);

        if (dia != null && mes != null && ano != null) {
          return DateTime(ano, mes, dia);
        }
      }
    }

    return DateTime(9999);
  }
}


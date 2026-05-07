import 'package:flutter/material.dart';
import 'package:fatechub2/widgets/app_bar.dart';


class TelaHome extends StatelessWidget {
  const TelaHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      appBar: const AppBarPadrao(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MuralCard(),
            const SizedBox(height: 16),
            _SecaoNoticias(),
            const SizedBox(height: 16),
            _SecaoAcessoRapido(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Mural Card (Carrossel) ───────────────────────────────────────────────────

class _MuralCard extends StatefulWidget {
  @override
  State<_MuralCard> createState() => _MuralCardState();
}

class _MuralCardState extends State<_MuralCard> {
  final PageController _pageController = PageController();
  int _paginaAtual = 0;

  final List<_MuralSlide> _slides = const [
    _MuralSlide(icone: Icons.campaign_outlined, texto: 'Bem-vindo ao Mural de Novidades!'),
    _MuralSlide(icone: Icons.flight_outlined, texto: 'Intercâmbio internacional de 1 semestre acadêmico — Para alunos FATEC'),
    _MuralSlide(icone: Icons.work_outline, texto: 'As inscrições para o programa de estágio já estão abertas!'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _irPara(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
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
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _paginaAtual = i),
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Container(
                  color: const Color(0xFFF5F5F5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(slide.icone, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            slide.texto,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000).withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Text(
                  'Mural de Novidades',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            if (_paginaAtual > 0)
              Positioned(
                left: 4, top: 0, bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _irPara(_paginaAtual - 1),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),

            if (_paginaAtual < _slides.length - 1)
              Positioned(
                right: 4, top: 0, bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _irPara(_paginaAtual + 1),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 10, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final bool ativo = index == _paginaAtual;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: ativo ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: ativo ? const Color(0xFF8B0000) : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MuralSlide {
  final IconData icone;
  final String texto;
  const _MuralSlide({required this.icone, required this.texto});
}

// ─── Seção de Notícias / Avisos ───────────────────────────────────────────────

class _SecaoNoticias extends StatelessWidget {
  final List<_AvisoItem> avisos = const [
    _AvisoItem(
      titulo: 'Palestra: Mercado de TI',
      descricao: 'Palestra sobre carreira e tendências no mercado de tecnologia.',
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
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Avisos Recentes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
              letterSpacing: 0.2,
            ),
          ),
        ),
        ...avisos.map(
          (aviso) => ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 100), // tamanho mínimo
            child: _CardAviso(aviso: aviso),
          ),
        ),
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
        color: Colors.white,
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
            child: Icon(aviso.icone, color: const Color(0xFF8B0000), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aviso.titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  aviso.descricao,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            aviso.data,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
        ],
      ),
    );
  }
}

// ─── Seção Acesso Rápido ──────────────────────────────────────────────────────

class _SecaoAcessoRapido extends StatelessWidget {
  static const List<_AcessoItem> _itens = [
    _AcessoItem(icone: Icons.calendar_month_outlined,    label: 'Calendário'),
    _AcessoItem(icone: Icons.schedule_outlined,          label: 'Horários'),
    _AcessoItem(icone: Icons.language_outlined,          label: 'Site'),
    _AcessoItem(icone: Icons.school_outlined,            label: 'SIGA'),
    _AcessoItem(icone: Icons.local_library_outlined,     label: 'Biblioteca'),
    _AcessoItem(icone: Icons.work_outline,               label: 'Estágio'),
    _AcessoItem(icone: Icons.record_voice_over_outlined, label: 'Ouvidoria'),
    _AcessoItem(icone: Icons.email_outlined,             label: 'E-mail'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Acesso Rápido',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
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
          children: _itens.map((item) => _CardAcesso(item: item)).toList(),
        ),
      ],
    );
  }
}

class _AcessoItem {
  final IconData icone;
  final String label;
  const _AcessoItem({required this.icone, required this.label});
}

class _CardAcesso extends StatelessWidget {
  final _AcessoItem item;

  const _CardAcesso({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
                child: Icon(item.icone, color: const Color(0xFF8B0000), size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
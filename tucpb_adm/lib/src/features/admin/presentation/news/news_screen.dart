import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tucpb_adm/src/features/admin/data/news_model.dart';
import 'package:tucpb_adm/src/features/admin/data/news_repository.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';
import 'news_form_screen.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F1EA),
        appBar: AppBar(
          backgroundColor: AdminTheme.surface,
          elevation: 0,
          title: Text('CENTRAL DE NOTÍCIAS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AdminTheme.primary)),
          bottom: TabBar(
            labelColor: AdminTheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AdminTheme.primary,
            tabs: const [
              Tab(text: 'TUCPB NEWS'),
              Tab(text: 'GERENCIAMENTO'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Newspaper View
            ref.watch(newsStreamProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (noticias) => _NewspaperLayout(noticias: noticias),
            ),
            // Tab 2: Management Table
            ref.watch(newsAdminStreamProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (noticias) => _ManagementTable(noticias: noticias),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewsFormScreen()),
          ),
          backgroundColor: Colors.black,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nova Edição', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class _ManagementTable extends ConsumerWidget {
  final List<Noticia> noticias;
  const _ManagementTable({required this.noticias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GESTÃO DE PUBLICAÇÕES', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Visualize, edite e controle o status de todas as notícias do sistema.'),
            const SizedBox(height: 32),
            
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3), // Titulo
                1: FixedColumnWidth(120), // Categoria
                2: FixedColumnWidth(150), // Data
                3: FixedColumnWidth(120), // Status
                4: FixedColumnWidth(150), // Ações
              },
              border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200)),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade50),
                  children: [
                    _headerCell('Título'),
                    _headerCell('Categoria'),
                    _headerCell('Data'),
                    _headerCell('Status'),
                    _headerCell('Ações'),
                  ],
                ),
                ...noticias.map((n) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(n.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(n.categoria.label),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(DateFormat('dd/MM/yyyy').format(n.dataCriacao)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _StatusBadge(noticia: n),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsFormScreen(noticia: n))),
                          ),
                          IconButton(
                            icon: Icon(n.isArquivada ? Icons.unarchive_outlined : Icons.archive_outlined, size: 20, color: Colors.orange),
                            onPressed: () => _toggleArchive(ref, n),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            onPressed: () => _deletar(ref, n),
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String label) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
    );
  }

  void _toggleArchive(WidgetRef ref, Noticia n) {
    ref.read(newsRepositoryProvider).atualizarNoticia(n.id, {'isArquivada': !n.isArquivada});
  }

  void _deletar(WidgetRef ref, Noticia n) {
    ref.read(newsRepositoryProvider).deletarNoticia(n.id);
  }
}

class _StatusBadge extends StatelessWidget {
  final Noticia noticia;
  const _StatusBadge({required this.noticia});

  @override
  Widget build(BuildContext context) {
    String label = 'RASCUNHO';
    Color color = Colors.grey;

    if (noticia.isArquivada) {
      label = 'ARQUIVADA';
      color = Colors.brown;
    } else if (noticia.isPublicada) {
      label = 'PUBLICADO';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _NewspaperLayout extends StatelessWidget {
  final List<Noticia> noticias;
  const _NewspaperLayout({required this.noticias});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://www.transparenttextures.com/patterns/paper-fibers.png'),
          repeat: ImageRepeat.repeat,
          opacity: 0.2,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                // Título Gigante "TUCPB NEWS"
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'TUCPB NEWS',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                    ),
                  ),
                ),
                
                const Divider(color: Colors.black, thickness: 3, height: 10),
                const Divider(color: Colors.black, thickness: 1, height: 10),
                const SizedBox(height: 30),

                // Grid de Notícias estilo jornal
                if (noticias.isEmpty)
                  Text('Nenhuma notícia para exibir hoje.', style: GoogleFonts.libreBaskerville(fontSize: 20)),
                
                if (noticias.isNotEmpty)
                  _buildNewsGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsGrid(BuildContext context) {
    // Vamos dividir as notícias em seções para simular o layout complexo
    final principal = noticias.first;
    final secundarias = noticias.skip(1).take(2).toList();
    final resto = noticias.skip(3).toList();

    return Column(
      children: [
        // Primeira Linha: Manchete Principal + Destaque
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Manchete principal (Coluna larga na esquerda)
              Expanded(
                flex: 2,
                child: _MainArticle(noticia: principal),
              ),
              const VerticalDivider(color: Colors.black, thickness: 1, width: 40),
              // Coluna lateral (Texto bold ou secundárias)
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    if (secundarias.isNotEmpty)
                      ...secundarias.map((n) => _SideArticle(noticia: n)).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const Divider(color: Colors.black, thickness: 1, height: 60),

        // Linha Inferior: Grid de 3 colunas
        if (resto.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 30,
              mainAxisSpacing: 40,
              childAspectRatio: 0.7,
            ),
            itemCount: resto.length,
            itemBuilder: (_, i) => _BottomArticle(noticia: resto[i]),
          ),
      ],
    );
  }
}

class _MainArticle extends StatelessWidget {
  final Noticia noticia;
  const _MainArticle({required this.noticia});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          noticia.titulo,
          style: GoogleFonts.playfairDisplay(fontSize: 48, fontWeight: FontWeight.bold, height: 1.1),
        ),
        const SizedBox(height: 12),
        Text(
          DateFormat('d MMMM yyyy', 'pt_BR').format(noticia.dataCriacao),
          style: GoogleFonts.libreBaskerville(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (noticia.imagemUrl != null) ...[
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
              child: Image.network(noticia.imagemUrl!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          noticia.conteudo,
          style: GoogleFonts.libreBaskerville(fontSize: 16, height: 1.6),
          maxLines: 15,
          overflow: TextOverflow.ellipsis,
        ),
        _buildReadMore(context),
      ],
    );
  }

  Widget _buildReadMore(BuildContext context) {
    return TextButton(
      onPressed: () => _editar(context),
      child: Text('EDITAR CONTEÚDO →', style: GoogleFonts.libreBaskerville(color: Colors.black, fontWeight: FontWeight.bold)),
    );
  }

  void _editar(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => NewsFormScreen(noticia: noticia)));
  }
}

class _SideArticle extends StatelessWidget {
  final Noticia noticia;
  const _SideArticle({required this.noticia});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '“${noticia.titulo}”',
          style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 8),
        Text(
          noticia.conteudo,
          style: GoogleFonts.libreBaskerville(fontSize: 14, height: 1.5),
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
        ),
        const Divider(color: Colors.black, height: 32),
      ],
    );
  }
}

class _BottomArticle extends StatelessWidget {
  final Noticia noticia;
  const _BottomArticle({required this.noticia});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (noticia.imagemUrl != null) ...[
          AspectRatio(
            aspectRatio: 1.5,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
              child: Image.network(noticia.imagemUrl!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          noticia.titulo.toUpperCase(),
          style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Text(
            noticia.conteudo,
            style: GoogleFonts.libreBaskerville(fontSize: 13, height: 1.5),
            overflow: TextOverflow.ellipsis,
            maxLines: 8,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsFormScreen(noticia: noticia))),
          child: const Text('LER MAIS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
      ],
    );
  }
}

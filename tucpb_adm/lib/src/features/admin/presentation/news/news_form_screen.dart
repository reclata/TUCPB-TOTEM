import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tucpb_adm/src/features/admin/data/news_model.dart';
import 'package:tucpb_adm/src/features/admin/data/news_repository.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class NewsFormScreen extends ConsumerStatefulWidget {
  final Noticia? noticia;
  const NewsFormScreen({super.key, this.noticia});

  @override
  ConsumerState<NewsFormScreen> createState() => _NewsFormScreenState();
}

class _NewsFormScreenState extends ConsumerState<NewsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _assuntoController;
  late TextEditingController _conteudoController;
  late TextEditingController _imagemController;
  late TextEditingController _videoController;
  late TextEditingController _pdfController;
  
  CategoriaNoticia _categoria = CategoriaNoticia.informacoes;
  VisibilidadeNoticia _visibilidade = VisibilidadeNoticia.todos;
  final List<String> _perfisSelecionados = [];
  bool _isDestaque = false;
  bool _isPublicada = false;
  bool _isArquivada = false;
  bool _salvando = false;

  final List<String> _opcoesPerfis = ['Médium', 'Assistência', 'Cambono', 'Dirigente', 'Financeiro'];

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.noticia?.titulo);
    _assuntoController = TextEditingController(text: widget.noticia?.assunto);
    _conteudoController = TextEditingController(text: widget.noticia?.conteudo);
    _imagemController = TextEditingController(text: widget.noticia?.imagemUrl);
    _videoController = TextEditingController(text: widget.noticia?.videoUrl);
    _pdfController = TextEditingController(text: widget.noticia?.pdfUrl);
    
    if (widget.noticia != null) {
      _categoria = widget.noticia!.categoria;
      _visibilidade = widget.noticia!.visibilidade;
      _perfisSelecionados.addAll(widget.noticia!.perfisPermitidos);
      _isDestaque = widget.noticia!.isDestaque;
      _isPublicada = widget.noticia!.isPublicada;
      _isArquivada = widget.noticia!.isArquivada;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _assuntoController.dispose();
    _conteudoController.dispose();
    _imagemController.dispose();
    _videoController.dispose();
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _salvando = true);
    
    try {
      final repo = ref.read(newsRepositoryProvider);
      
      final noticia = Noticia(
        id: widget.noticia?.id ?? '',
        titulo: _tituloController.text.trim(),
        assunto: _assuntoController.text.trim(),
        conteudo: _conteudoController.text.trim(),
        categoria: _categoria,
        imagemUrl: _imagemController.text.trim().isEmpty ? null : _imagemController.text.trim(),
        videoUrl: _videoController.text.trim().isEmpty ? null : _videoController.text.trim(),
        pdfUrl: _pdfController.text.trim().isEmpty ? null : _pdfController.text.trim(),
        visibilidade: _visibilidade,
        perfisPermitidos: _visibilidade == VisibilidadeNoticia.perfis ? _perfisSelecionados : [],
        isDestaque: _isDestaque,
        isPublicada: _isPublicada,
        isArquivada: _isArquivada,
        dataCriacao: widget.noticia?.dataCriacao ?? DateTime.now(),
        autorId: 'admin', // Placeholder
        autorNome: 'Administração', // Placeholder
      );

      if (widget.noticia == null) {
        await repo.criarNoticia(noticia);
      } else {
        await repo.atualizarNoticia(widget.noticia!.id, noticia.toMap());
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publicação salva com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      appBar: AppBar(
        title: Text(widget.noticia == null ? 'Nova Notícia' : 'Editar Notícia',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: AdminTheme.surface,
        foregroundColor: AdminTheme.textPrimary,
        elevation: 0,
        actions: [
          if (widget.noticia != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmarExclusao(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: 'Conteúdo da Publicação',
                    children: [
                      TextFormField(
                        controller: _tituloController,
                        decoration: const InputDecoration(labelText: 'Título da Notícia *', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _assuntoController,
                        decoration: const InputDecoration(labelText: 'Assunto / Subtítulo', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<CategoriaNoticia>(
                              value: _categoria,
                              decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
                              items: CategoriaNoticia.values.map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.label),
                              )).toList(),
                              onChanged: (v) => setState(() => _categoria = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('Destaque na Newsletter'),
                              subtitle: const Text('Exibir na coluna lateral'),
                              value: _isDestaque,
                              activeColor: AdminTheme.primary,
                              onChanged: (v) => setState(() => _isDestaque = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _conteudoController,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          labelText: 'Conteúdo (Texto) *',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildSectionCard(
                    title: 'Anexos e Mídia',
                    children: [
                      TextFormField(
                        controller: _imagemController,
                        decoration: const InputDecoration(
                          labelText: 'URL da Imagem Principal',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.image),
                          hintText: 'https://exemplo.com/imagem.jpg',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _videoController,
                        decoration: const InputDecoration(
                          labelText: 'URL do Vídeo (Youtube/Vimeo)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.play_circle),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pdfController,
                        decoration: const InputDecoration(
                          labelText: 'URL do Documento PDF',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.picture_as_pdf),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _buildSectionCard(
                    title: 'Visibilidade e Público',
                    children: [
                      Row(
                        children: [
                          _buildVisibilidadeOption(VisibilidadeNoticia.todos, 'Visível a todos', Icons.public),
                          const SizedBox(width: 12),
                          _buildVisibilidadeOption(VisibilidadeNoticia.perfis, 'Por perfil', Icons.group),
                          const SizedBox(width: 12),
                          _buildVisibilidadeOption(VisibilidadeNoticia.nenhum, 'Invisível', Icons.visibility_off),
                        ],
                      ),
                      if (_visibilidade == VisibilidadeNoticia.perfis) ...[
                        const SizedBox(height: 16),
                        const Text('Selecione os perfis que podem visualizar:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          children: _opcoesPerfis.map((p) => FilterChip(
                            label: Text(p),
                            selected: _perfisSelecionados.contains(p),
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _perfisSelecionados.add(p);
                                } else {
                                  _perfisSelecionados.remove(p);
                                }
                              });
                            },
                          )).toList(),
                        ),
                      ],
                    ],
                  ),

                  _buildSectionCard(
                    title: 'Status da Publicação',
                    children: [
                      SwitchListTile(
                        title: const Text('Publicar Oficialmente'),
                        subtitle: const Text('Se desativado, ficará salvo como rascunho apenas para os administradores.'),
                        value: _isPublicada,
                        activeColor: Colors.green,
                        onChanged: (v) => setState(() => _isPublicada = v),
                        secondary: Icon(Icons.cloud_upload, color: _isPublicada ? Colors.green : Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _salvando 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Salvar Publicação', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilidadeOption(VisibilidadeNoticia val, String label, IconData icon) {
    bool selected = _visibilidade == val;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _visibilidade = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AdminTheme.primary.withOpacity(0.1) : Colors.white,
            border: Border.all(color: selected ? AdminTheme.primary : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AdminTheme.primary : Colors.grey),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AdminTheme.primary : Colors.grey,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Notícia?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (ok == true && mounted) {
      await ref.read(newsRepositoryProvider).deletarNoticia(widget.noticia!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

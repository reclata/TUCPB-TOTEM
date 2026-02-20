import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tucpb_adm/src/features/admin/data/estoque_model.dart';
import 'package:tucpb_adm/src/features/admin/data/estoque_repository.dart';
import 'package:tucpb_adm/src/features/admin/presentation/estoque/tabs/aba_categoria_estoque.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class AbaChecklistEstoque extends ConsumerStatefulWidget {
  const AbaChecklistEstoque({super.key});

  @override
  ConsumerState<AbaChecklistEstoque> createState() => _AbaChecklistEstoqueState();
}

class _AbaChecklistEstoqueState extends ConsumerState<AbaChecklistEstoque> {
  final Set<String> _selecionadosEstoque = {};
  final Set<String> _selecionadosManual = {};
  bool _mostrandoNovoManual = false;
  final TextEditingController _novoItemController = TextEditingController();
  CategoriaEstoque _categoriaNovoItem = CategoriaEstoque.espiritual;

  @override
  void dispose() {
    _novoItemController.dispose();
    super.dispose();
  }

  Future<void> _salvarCompras(Map<String, List<dynamic>> data) async {
    final repo = ref.read(estoqueRepositoryProvider);
    final itensEstoque = data['estoque'] as List<ItemEstoque>;
    final itensManual = data['manual'] as List<ChecklistManualItem>;

    int total = _selecionadosEstoque.length + _selecionadosManual.length;
    if (total == 0) return;

    // Processar itens manuais (simples: marca como comprado)
    for (final id in _selecionadosManual) {
      await repo.marcarManualComoComprado(id);
    }

    // Processar itens de estoque
    // Para itens de estoque, precisamos de uma quantidade.
    // Se o usuário só deu check, vamos perguntar um por um ou abrir os modais?
    // Vou abrir uma sequência de diálogos rápidos.
    
    final selecionados = itensEstoque.where((i) => _selecionadosEstoque.contains(i.id)).toList();
    
    setState(() {
      _selecionadosEstoque.clear();
      _selecionadosManual.clear();
    });

    if (selecionados.isNotEmpty && mounted) {
      for (final item in selecionados) {
        if (!mounted) break;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => EntradaModal(
            categoria: item.categoria,
            itemPreSelecionado: item,
            tituloOverride: 'Confirmar compra: ${item.nome}',
          ),
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$total item(ns) processados!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _adicionarManual() async {
    final nome = _novoItemController.text.trim();
    if (nome.isEmpty) return;

    await ref.read(estoqueRepositoryProvider).criarItemManualChecklist(nome, _categoriaNovoItem);
    
    setState(() {
      _novoItemController.clear();
      _mostrandoNovoManual = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final checklistAsync = ref.watch(checklistStreamProvider);

    return checklistAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (data) {
        final itensEstoque = data['estoque'] as List<ItemEstoque>;
        final itensManual = data['manual'] as List<ChecklistManualItem>;

        if (itensEstoque.isEmpty && itensManual.isEmpty && !_mostrandoNovoManual) {
          return _EmptyChecklist(onAddManual: () => setState(() => _mostrandoNovoManual = true));
        }

        return Column(
          children: [
            // Banner / Header de Ações
            _HeaderAcoes(
              countTotal: itensEstoque.length + itensManual.length,
              countSelecionados: _selecionadosEstoque.length + _selecionadosManual.length,
              onSalvar: () => _salvarCompras(data),
              onNovoManual: () => setState(() => _mostrandoNovoManual = true),
            ),

            if (_mostrandoNovoManual)
              _NovoManualCard(
                controller: _novoItemController,
                categoria: _categoriaNovoItem,
                onChangedCat: (c) => setState(() => _categoriaNovoItem = c!),
                onCancelar: () => setState(() => _mostrandoNovoManual = false),
                onConfirmar: _adicionarManual,
              ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (itensManual.isNotEmpty) ...[
                    _SeccaoHeader(titulo: 'Compras Extras (Manual)', icone: Icons.playlist_add_check, cor: Colors.indigo),
                    ...itensManual.map((item) => _ManualItemTile(
                      item: item,
                      selecionado: _selecionadosManual.contains(item.id),
                      onToggle: (v) => setState(() => v! ? _selecionadosManual.add(item.id) : _selecionadosManual.remove(item.id)),
                    )),
                    const SizedBox(height: 16),
                  ],

                  if (itensEstoque.isNotEmpty) ...[
                    _SeccaoHeader(titulo: 'Reposição de Estoque (Automático)', icone: Icons.autorenew, cor: Colors.red),
                    ...itensEstoque.map((item) => _EstoqueItemTile(
                      item: item,
                      selecionado: _selecionadosEstoque.contains(item.id),
                      onToggle: (v) => setState(() => v! ? _selecionadosEstoque.add(item.id) : _selecionadosEstoque.remove(item.id)),
                    )),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyChecklist extends StatelessWidget {
  final VoidCallback onAddManual;
  const _EmptyChecklist({required this.onAddManual});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green[200]),
          const SizedBox(height: 16),
          Text('Tudo em dia! 🎉', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 8),
          const Text('Nenhum item pendente no checklist.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddManual,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar compra manual'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAcoes extends StatelessWidget {
  final int countTotal, countSelecionados;
  final VoidCallback onSalvar, onNovoManual;
  const _HeaderAcoes({required this.countTotal, required this.countSelecionados, required this.onSalvar, required this.onNovoManual});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$countTotal itens na lista', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('$countSelecionados selecionados para salvar', style: TextStyle(fontSize: 12, color: countSelecionados > 0 ? Colors.green : Colors.grey)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onNovoManual,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Novo manual'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.indigo),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: countSelecionados > 0 ? onSalvar : null,
            icon: const Icon(Icons.save),
            label: const Text('Salvar Compras'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccaoHeader extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final Color cor;
  const _SeccaoHeader({required this.titulo, required this.icone, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 18),
          const SizedBox(width: 8),
          Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 13)),
          const Expanded(child: Divider(indent: 12)),
        ],
      ),
    );
  }
}

class _ManualItemTile extends StatelessWidget {
  final ChecklistManualItem item;
  final bool selecionado;
  final ValueChanged<bool?> onToggle;
  const _ManualItemTile({required this.item, required this.selecionado, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 4),
      color: selecionado ? Colors.green[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selecionado ? Colors.green.shade200 : Colors.grey.shade200),
      ),
      child: CheckboxListTile(
        value: selecionado,
        onChanged: onToggle,
        title: Text(item.item_nome_com_categoria, style: const TextStyle(fontWeight: FontWeight.w500)),
        secondary: CircleAvatar(
          radius: 14,
          backgroundColor: item.categoria.color.withOpacity(0.1),
          child: Icon(item.categoria.icon, color: item.categoria.color, size: 14),
        ),
        activeColor: Colors.green,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}

extension on ChecklistManualItem {
  String get item_nome_com_categoria => nome;
}

class _EstoqueItemTile extends StatelessWidget {
  final ItemEstoque item;
  final bool selecionado;
  final ValueChanged<bool?> onToggle;
  const _EstoqueItemTile({required this.item, required this.selecionado, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final zerado = item.zerado;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 4),
      color: selecionado ? Colors.green[50] : (zerado ? Colors.red[50] : Colors.orange[50]),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selecionado ? Colors.green.shade200 : (zerado ? Colors.red.shade200 : Colors.orange.shade200)),
      ),
      child: CheckboxListTile(
        value: selecionado,
        onChanged: onToggle,
        title: Text(item.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          zerado ? '⛔ SEM ESTOQUE' : '⚠️ Apenas ${item.quantidadeAtual} ${item.unidade}',
          style: TextStyle(fontSize: 12, color: zerado ? Colors.red : Colors.orange.shade800),
        ),
        secondary: CircleAvatar(
          radius: 14,
          backgroundColor: item.categoria.color.withOpacity(0.1),
          child: Icon(item.categoria.icon, color: item.categoria.color, size: 14),
        ),
        activeColor: Colors.green,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}

class _NovoManualCard extends StatelessWidget {
  final TextEditingController controller;
  final CategoriaEstoque categoria;
  final ValueChanged<CategoriaEstoque?> onChangedCat;
  final VoidCallback onCancelar, onConfirmar;

  const _NovoManualCard({
    required this.controller, required this.categoria, required this.onChangedCat,
    required this.onCancelar, required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        border: Border(bottom: BorderSide(color: Colors.indigo.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Adicionar Item Manual', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Nome do item (ex: Gelo, Copo...)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => onConfirmar(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey)),
                child: DropdownButton<CategoriaEstoque>(
                  value: categoria,
                  underline: const SizedBox(),
                  onChanged: onChangedCat,
                  items: CategoriaEstoque.values.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.labelCurto),
                  )).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onCancelar, child: const Text('Cancelar')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onConfirmar,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: const Text('Adicionar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

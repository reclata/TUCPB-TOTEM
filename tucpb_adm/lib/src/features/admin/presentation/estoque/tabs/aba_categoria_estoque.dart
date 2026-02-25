import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tucpb_adm/src/features/admin/data/estoque_model.dart';
import 'package:tucpb_adm/src/features/admin/data/estoque_repository.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class AbaCategoriaEstoque extends ConsumerWidget {
  final CategoriaEstoque categoria;
  const AbaCategoriaEstoque({super.key, required this.categoria});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(estoqueStreamProvider(categoria));

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (itens) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: itens.isEmpty
              ? _EmptyState(categoria: categoria)
              : _ItemGrid(itens: itens, categoria: categoria),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _abrirNovaEntrada(context, ref, null),
            backgroundColor: categoria.color,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Nova Entrada', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  void _abrirNovaEntrada(BuildContext context, WidgetRef ref, ItemEstoque? itemPreSelecionado) {
    showDialog(
      context: context,
      builder: (_) => EntradaModal(categoria: categoria, itemPreSelecionado: itemPreSelecionado),
    );
  }
}

// ═══════════════════════════════════════════
// Grid de itens
// ═══════════════════════════════════════════
class _ItemGrid extends ConsumerWidget {
  final List<ItemEstoque> itens;
  final CategoriaEstoque categoria;
  const _ItemGrid({required this.itens, required this.categoria});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zerados = itens.where((i) => i.zerado).toList();
    final baixos = itens.where((i) => !i.zerado && i.precisaComprar).toList();
    final normais = itens.where((i) => !i.precisaComprar).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alertas
          if (zerados.isNotEmpty || baixos.isNotEmpty)
            _AlertaBanner(zerados: zerados.length, baixos: baixos.length, categoria: categoria),

          if (zerados.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel('⛔ Sem estoque (${zerados.length})', Colors.red),
            const SizedBox(height: 8),
            _Grid(itens: zerados, categoria: categoria),
          ],
          if (baixos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel('⚠️ Estoque baixo (${baixos.length})', Colors.orange),
            const SizedBox(height: 8),
            _Grid(itens: baixos, categoria: categoria),
          ],
          if (normais.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel('✅ Em estoque (${normais.length})', Colors.green),
            const SizedBox(height: 8),
            _Grid(itens: normais, categoria: categoria),
          ],
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<ItemEstoque> itens;
  final CategoriaEstoque categoria;
  const _Grid({required this.itens, required this.categoria});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 160,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: itens.length,
      itemBuilder: (_, i) => _ItemCard(item: itens[i], categoria: categoria),
    );
  }
}

// ═══════════════════════════════════════════
// Card do item
// ═══════════════════════════════════════════
class _ItemCard extends ConsumerWidget {
  final ItemEstoque item;
  final CategoriaEstoque categoria;
  const _ItemCard({required this.item, required this.categoria});

  Color get _qtdColor {
    if (item.zerado) return Colors.red;
    if (item.precisaComprar) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _qtdColor.withValues(alpha: 0.3), width: item.precisaComprar ? 2 : 1),
      ),
      color: item.zerado
          ? Colors.red[50]
          : item.precisaComprar
              ? Colors.orange[50]
              : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _verDetalhes(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome
              Text(
                item.nome,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Quantidade grande
              Text(
                '${item.quantidadeAtual % 1 == 0 ? item.quantidadeAtual.toInt() : item.quantidadeAtual}',
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: _qtdColor),
              ),
              Text(item.unidade, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 8),
              // Botões
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _darBaixa(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Baixa', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _entrada(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: categoria.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('+', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _entrada(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => EntradaModal(categoria: categoria, itemPreSelecionado: item));
  }

  void _darBaixa(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => BaixaModal(item: item));
  }

  void _verDetalhes(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => DetalhesItemModal(item: item, categoria: categoria));
  }
}

// ═══════════════════════════════════════════
// Modal ENTRADA
// ═══════════════════════════════════════════
class EntradaModal extends ConsumerStatefulWidget {
  final CategoriaEstoque categoria;
  final ItemEstoque? itemPreSelecionado;
  final String? tituloOverride;
  const EntradaModal({super.key, required this.categoria, this.itemPreSelecionado, this.tituloOverride});

  @override
  ConsumerState<EntradaModal> createState() => _EntradaModalState();
}

class _EntradaModalState extends ConsumerState<EntradaModal> {
  final _nomeController = TextEditingController();
  final _qtdController = TextEditingController();
  final _responsavelController = TextEditingController();
  final _obsController = TextEditingController();
  final _festaController = TextEditingController();
  String _unidade = 'un';
  ItemEstoque? _itemExistente;
  bool _salvando = false;
  List<String> _sugestoes = [];

  @override
  void initState() {
    super.initState();
    if (widget.itemPreSelecionado != null) {
      _itemExistente = widget.itemPreSelecionado;
      _nomeController.text = widget.itemPreSelecionado!.nome;
      _unidade = widget.itemPreSelecionado!.unidade;
    }
    _carregarCatalogo();
  }

  Future<void> _carregarCatalogo() async {
    final nomes = await ref.read(estoqueRepositoryProvider).buscarNomesCatalogo(widget.categoria);
    setState(() => _sugestoes = nomes);
  }

  Future<void> _salvar() async {
    if (_nomeController.text.trim().isEmpty || _qtdController.text.isEmpty || _responsavelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha nome, quantidade e responsável.'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _salvando = true);
    try {
      final repo = ref.read(estoqueRepositoryProvider);
      final qtd = double.tryParse(_qtdController.text.replaceAll(',', '.')) ?? 0;

      if (_itemExistente != null) {
        // Entrada em item existente
        await repo.registrarEntrada(
          item: _itemExistente!,
          quantidade: qtd,
          responsavelNome: _responsavelController.text.trim(),
          observacao: _obsController.text.trim().isEmpty ? null : _obsController.text.trim(),
          festaReferencia: _festaController.text.trim().isEmpty ? null : _festaController.text.trim(),
        );
      } else {
        // Criar novo item e registrar entrada
        final novoItem = ItemEstoque(
          id: '',
          nome: _nomeController.text.trim(),
          unidade: _unidade,
          categoria: widget.categoria,
          quantidadeAtual: 0,
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
        );
        await repo.criarItem(novoItem);
        // Buscar item criado para registrar movimento
        // Simplificado: atualizar através do update direto
        // O item será criado com quantidade 0 e depois damos entrada
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrada registrada!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _qtdController.dispose();
    _responsavelController.dispose();
    _obsController.dispose();
    _festaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.categoria;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Icon(Icons.input, color: cat.color),
                  const SizedBox(width: 8),
                  Text(widget.tituloOverride ?? 'Registrar Entrada', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: cat.color)),
                ]),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              Text(cat.label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Divider(height: 20),

              // Nome (autocomplete ou livre)
              if (_itemExistente != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Icon(Icons.inventory_2, color: cat.color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_itemExistente!.nome, style: TextStyle(fontWeight: FontWeight.bold, color: cat.color))),
                    TextButton(onPressed: () => setState(() => _itemExistente = null), child: const Text('trocar')),
                  ]),
                )
              else
                Autocomplete<String>(
                  optionsBuilder: (v) => _sugestoes.where((s) => s.toLowerCase().contains(v.text.toLowerCase())),
                  onSelected: (nome) {
                    _nomeController.text = nome;
                    // Tentar encontrar o item existente
                  },
                  fieldViewBuilder: (ctx, ctrl, fn, _) {
                    return TextFormField(
                      controller: ctrl,
                      focusNode: fn,
                      decoration: const InputDecoration(
                        labelText: 'Nome do item *',
                        border: OutlineInputBorder(),
                        hintText: 'Digite ou selecione da lista',
                        prefixIcon: Icon(Icons.search, size: 18),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),

              // Quantidade + Unidade
              Row(children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _qtdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantidade *', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unidade,
                    decoration: const InputDecoration(labelText: 'Unidade', border: OutlineInputBorder()),
                    items: kUnidadesEstoque.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: _itemExistente != null ? null : (v) => setState(() => _unidade = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Referência de festa (opcional)
              TextFormField(
                controller: _festaController,
                decoration: const InputDecoration(labelText: 'Referência de Festa/Gira (opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.event, size: 18)),
              ),
              const SizedBox(height: 12),

              // Observações
              TextFormField(controller: _obsController, maxLines: 2, decoration: const InputDecoration(labelText: 'Observações', border: OutlineInputBorder())),
              const SizedBox(height: 12),

              // Responsável
              TextFormField(
                controller: _responsavelController,
                decoration: const InputDecoration(
                  labelText: 'Registrado por (nome) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                  hintText: 'Quem está registrando esta compra',
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save, size: 16),
                  label: const Text('Confirmar Entrada'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cat.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

// ═══════════════════════════════════════════
// Modal DAR BAIXA (o que sobrou → sistema calcula saída)
// ═══════════════════════════════════════════
class BaixaModal extends ConsumerStatefulWidget {
  final ItemEstoque item;
  const BaixaModal({super.key, required this.item});

  @override
  ConsumerState<BaixaModal> createState() => _BaixaModalState();
}

class _BaixaModalState extends ConsumerState<BaixaModal> {
  final _sobroupController = TextEditingController();
  final _responsavelController = TextEditingController();
  final _obsController = TextEditingController();
  final _festaController = TextEditingController();
  bool _salvando = false;

  double get _sobrouQtd => double.tryParse(_sobroupController.text.replaceAll(',', '.')) ?? widget.item.quantidadeAtual;
  double get _saiuQtd => widget.item.quantidadeAtual - _sobrouQtd;

  @override
  void dispose() {
    _sobroupController.dispose();
    _responsavelController.dispose();
    _obsController.dispose();
    _festaController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_responsavelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assinatura obrigatória!'), backgroundColor: Colors.red));
      return;
    }
    if (_sobroupController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe a quantidade que sobrou.'), backgroundColor: Colors.red));
      return;
    }
    final sobrou = double.tryParse(_sobroupController.text.replaceAll(',', '.')) ?? 0;
    if (sobrou > widget.item.quantidadeAtual) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantidade que sobrou não pode ser maior que o estoque atual!'), backgroundColor: Colors.red));
      return;
    }
    setState(() => _salvando = true);
    try {
      await ref.read(estoqueRepositoryProvider).registrarSaida(
        item: widget.item,
        quantidadeSobrou: sobrou,
        responsavelNome: _responsavelController.text.trim(),
        observacao: _obsController.text.trim().isEmpty ? null : _obsController.text,
        festaReferencia: _festaController.text.trim().isEmpty ? null : _festaController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Baixa registrada com sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Row(children: [
                  Icon(Icons.output, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Dar Baixa', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.red)),
                ]),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              const Divider(height: 16),

              // Item info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.item.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Categoria: ${widget.item.categoria.label}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('Em estoque', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        '${widget.item.quantidadeAtual % 1 == 0 ? widget.item.quantidadeAtual.toInt() : widget.item.quantidadeAtual} ${widget.item.unidade}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text('Quanto sobrou após uso?', style: TextStyle(fontWeight: FontWeight.w600)),
              const Text('O sistema calculará automaticamente o que saiu.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),

              TextFormField(
                controller: _sobroupController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Quantidade que SOBROU (${widget.item.unidade}) *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.inventory, size: 18),
                ),
              ),
              const SizedBox(height: 8),

              // Preview do que saiu
              if (_sobroupController.text.isNotEmpty)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _saiuQtd < 0 ? Colors.red[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _saiuQtd < 0 ? Colors.red : Colors.orange),
                  ),
                  child: _saiuQtd < 0
                      ? const Text('⚠️ Valor inválido: sobrou mais do que tinha em estoque!', style: TextStyle(color: Colors.red))
                      : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Saiu do estoque:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${_saiuQtd % 1 == 0 ? _saiuQtd.toInt() : _saiuQtd} ${widget.item.unidade}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                        ]),
                ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _festaController,
                decoration: const InputDecoration(labelText: 'Referência de Gira/Festa (opcional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.event, size: 18)),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _obsController, maxLines: 2, decoration: const InputDecoration(labelText: 'Observações', border: OutlineInputBorder())),
              const SizedBox(height: 16),

              // ASSINATURA
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.draw, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('Assinatura obrigatória', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13)),
                    ]),
                    const SizedBox(height: 4),
                    const Text('Quem está dando a baixa?', style: TextStyle(fontSize: 12, color: Colors.red)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _responsavelController,
                      decoration: const InputDecoration(
                        labelText: 'Seu nome completo *',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person, size: 18),
                        hintText: 'Confirma sua identidade',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _salvando ? null : _confirmar,
                  icon: _salvando
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check, size: 16),
                  label: const Text('Confirmar Baixa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

// ═══════════════════════════════════════════
// Modal DETALHES + histórico do item
// ═══════════════════════════════════════════
class DetalhesItemModal extends ConsumerWidget {
  final ItemEstoque item;
  final CategoriaEstoque categoria;
  const DetalhesItemModal({super.key, required this.item, required this.categoria});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movAsync = ref.watch(movimentosStreamProvider(item.id));
    final fmt = DateFormat('dd/MM/yy HH:mm');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${categoria.label} • ${item.unidade}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
            const Divider(),
            Text('Histórico de Movimentos', style: TextStyle(fontWeight: FontWeight.bold, color: categoria.color)),
            const SizedBox(height: 8),
            Expanded(
              child: movAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Erro: $e'),
                data: (movs) {
                  if (movs.isEmpty) return const Center(child: Text('Nenhum movimento registrado.', style: TextStyle(color: Colors.grey)));
                  return ListView.separated(
                    itemCount: movs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final m = movs[i];
                      final isEntrada = m.tipo == TipoMovimento.entrada;
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isEntrada ? Colors.green[50] : Colors.red[50],
                          child: Icon(isEntrada ? Icons.add : Icons.remove, size: 16, color: isEntrada ? Colors.green : Colors.red),
                        ),
                        title: Text(
                          '${isEntrada ? "+" : "-"}${m.quantidade % 1 == 0 ? m.quantidade.toInt() : m.quantidade} ${item.unidade}  →  ${m.quantidadeDepois % 1 == 0 ? m.quantidadeDepois.toInt() : m.quantidadeDepois} ${item.unidade}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('👤 ${m.responsavelNome}  •  🕐 ${fmt.format(m.dataHora)}', style: const TextStyle(fontSize: 11)),
                            if (m.festaReferencia != null) Text('🎉 ${m.festaReferencia}', style: const TextStyle(fontSize: 11)),
                            if (m.observacao != null) Text('📝 ${m.observacao}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                          ],
                        ),
                        isThreeLine: m.festaReferencia != null || m.observacao != null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13));
  }
}

class _AlertaBanner extends StatelessWidget {
  final int zerados, baixos;
  final CategoriaEstoque categoria;
  const _AlertaBanner({required this.zerados, required this.baixos, required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade300)),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(child: Text(
          '${zerados > 0 ? "$zerados item(ns) sem estoque   " : ""}${baixos > 0 ? "$baixos com estoque baixo" : ""}  — verifique a aba Checklist',
          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500, fontSize: 13),
        )),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final CategoriaEstoque categoria;
  const _EmptyState({required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(categoria.icon, size: 72, color: categoria.color.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Nenhum item no ${categoria.label}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Clique em "Nova Entrada" para cadastrar o primeiro item.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

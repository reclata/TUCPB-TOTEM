import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tucpb_adm/src/features/admin/data/estoque_model.dart';
import 'package:tucpb_adm/src/features/admin/data/estoque_repository.dart';
import 'package:tucpb_adm/src/features/admin/presentation/estoque/tabs/aba_categoria_estoque.dart';
import 'package:tucpb_adm/src/features/admin/presentation/estoque/tabs/aba_checklist_estoque.dart';
import 'package:tucpb_adm/src/features/admin/presentation/estoque/tabs/aba_importacao_estoque.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class EstoqueScreen extends ConsumerStatefulWidget {
  const EstoqueScreen({super.key});

  @override
  ConsumerState<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends ConsumerState<EstoqueScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _abaAtual = 0;

  final List<CategoriaEstoque> _categorias = CategoriaEstoque.values;

  @override
  void initState() {
    super.initState();
    // 4 categorias + Importação + Checklist
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() => _abaAtual = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checklistAsync = ref.watch(checklistStreamProvider);
    final checklistCount = checklistAsync.maybeWhen(data: (l) => l.length, orElse: () => 0);

    Color activeColor() {
      if (_abaAtual == 0) return Colors.red; // Checklist (primeiro agora)
      if (_abaAtual == 5) return Colors.indigo; // Importação (último agora)
      // Categorias são índices 1 a 4
      return _categorias[_abaAtual - 1].color;
    }

    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(
        children: [
          // ═══ Header ═══
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            color: AdminTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estoque',
                            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                        Text('Controle de entradas, saídas e checklist de compras',
                            style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                    const Spacer(),
                    // Badge checklist
                    if (checklistCount > 0)
                      _AlertaBadge(count: checklistCount, onTap: () {
                        _tabController.animateTo(0);
                        setState(() => _abaAtual = 0);
                      }),
                  ],
                ),
                const SizedBox(height: 16),
                // Tab bar
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: activeColor(),
                  unselectedLabelColor: AdminTheme.textSecondary,
                  indicatorColor: activeColor(),
                  indicatorWeight: 3,
                  tabs: [
                    // 1. Checklist com badge
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Checklist'),
                          if (checklistCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                              child: Text('$checklistCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 2-5. As 4 categorias
                    ..._categorias.map((cat) => Tab(text: cat.labelCurto)),

                    // 6. Importação
                    const Tab(text: 'Importação'),
                  ],
                ),
              ],
            ),
          ),

          // ═══ Conteúdo ═══
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const AbaChecklistEstoque(),
                AbaCategoriaEstoque(categoria: CategoriaEstoque.espiritual),
                AbaCategoriaEstoque(categoria: CategoriaEstoque.cozinha),
                AbaCategoriaEstoque(categoria: CategoriaEstoque.limpeza),
                AbaCategoriaEstoque(categoria: CategoriaEstoque.shop),
                const AbaImportacaoEstoque(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertaBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _AlertaBadge({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.red),
            const SizedBox(width: 6),
            Text('$count item(ns) para comprar',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'estoque_model.dart';

final estoqueRepositoryProvider = Provider<EstoqueRepository>((ref) {
  return EstoqueRepository(FirebaseFirestore.instance);
});

// Stream por categoria
final estoqueStreamProvider = StreamProvider.family<List<ItemEstoque>, CategoriaEstoque>((ref, categoria) {
  return ref.watch(estoqueRepositoryProvider).streamPorCategoria(categoria);
});

// Stream do checklist (todos que precisam comprar)
final checklistStreamProvider = StreamProvider<Map<String, List<dynamic>>>((ref) {
  return ref.watch(estoqueRepositoryProvider).streamChecklistUnificado();
});

// Stream de itens manuais do checklist
final checklistManualStreamProvider = StreamProvider<List<ChecklistManualItem>>((ref) {
  return ref.watch(estoqueRepositoryProvider).streamChecklistManual();
});

// Stream de movimentos por item
final movimentosStreamProvider = StreamProvider.family<List<MovimentoEstoque>, String>((ref, itemId) {
  return ref.watch(estoqueRepositoryProvider).streamMovimentos(itemId);
});

// Catalogo de nomes (autocomplete)
final catalogoNomesProvider = FutureProvider.family<List<String>, CategoriaEstoque>((ref, categoria) {
  return ref.watch(estoqueRepositoryProvider).buscarNomesCatalogo(categoria);
});

class EstoqueRepository {
  final FirebaseFirestore _db;
  static const _itens = 'estoque_itens';
  static const _movimentos = 'estoque_movimentos';
  static const _checklistManual = 'estoque_checklist_manual';

  EstoqueRepository(this._db);

  // ═══ Items ═══

  Stream<List<ItemEstoque>> streamPorCategoria(CategoriaEstoque cat) {
    return _db
        .collection(_itens)
        .snapshots()
        .map((s) {
          final lista = s.docs
              .map(ItemEstoque.fromFirestore)
              .where((i) => i.categoria == cat)
              .toList();
          lista.sort((a, b) => a.nome.compareTo(b.nome));
          return lista;
        });
  }

  Stream<List<ItemEstoque>> streamChecklist() {
    return _db
        .collection(_itens)
        .orderBy('nome')
        .snapshots()
        .map((s) => s.docs
            .map(ItemEstoque.fromFirestore)
            .where((i) => i.precisaComprar)
            .toList());
  }

  Stream<List<ChecklistManualItem>> streamChecklistManual() {
    return _db
        .collection(_checklistManual)
        .where('comprado', isEqualTo: false)
        .snapshots()
        .map((s) {
          final items = s.docs.map(ChecklistManualItem.fromFirestore).toList();
          items.sort((a, b) => (b.dataCriacao ?? DateTime(0)).compareTo(a.dataCriacao ?? DateTime(0)));
          return items;
        });
  }

  /// Retorna um Map com itens de estoque e itens manuais que precisam ser comprados
  Stream<Map<String, List<dynamic>>> streamChecklistUnificado() {
    return Rx.combineLatest2<List<ItemEstoque>, List<ChecklistManualItem>, Map<String, List<dynamic>>>(
      streamChecklist(),
      streamChecklistManual(),
      (estoque, manual) => {
        'estoque': estoque,
        'manual': manual,
      },
    );
  }

  Future<void> criarItemManualChecklist(String nome, CategoriaEstoque categoria) async {
    await _db.collection(_checklistManual).add({
      'nome': nome,
      'categoria': categoria.key,
      'comprado': false,
      'dataCriacao': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> marcarManualComoComprado(String id) async {
    await _db.collection(_checklistManual).doc(id).update({'comprado': true});
  }

  Future<void> criarItem(ItemEstoque item) async {
    await _db.collection(_itens).add(item.toMap());
  }

  Future<void> atualizarItem(String id, Map<String, dynamic> dados) async {
    dados['dataAtualizacao'] = Timestamp.fromDate(DateTime.now());
    await _db.collection(_itens).doc(id).update(dados);
  }

  Future<void> deletarItem(String id) async {
    await _db.collection(_itens).doc(id).delete();
  }

  Future<List<String>> buscarNomesCatalogo(CategoriaEstoque cat) async {
    final snap = await _db
        .collection(_itens)
        .where('categoria', isEqualTo: cat.key)
        .get();
    final nomes = snap.docs.map((d) => d.data()['nome'] as String? ?? '').toSet().toList();
    nomes.sort();
    return nomes;
  }

  // ═══ Movimentos ═══

  Stream<List<MovimentoEstoque>> streamMovimentos(String itemId) {
    return _db
        .collection(_movimentos)
        .where('itemId', isEqualTo: itemId)
        .orderBy('dataHora', descending: true)
        .snapshots()
        .map((s) => s.docs.map(MovimentoEstoque.fromFirestore).toList());
  }

  /// Registra ENTRADA: soma quantidade ao item atual
  Future<void> registrarEntrada({
    required ItemEstoque item,
    required double quantidade,
    required String responsavelNome,
    String? observacao,
    String? festaReferencia,
  }) async {
    final antes = item.quantidadeAtual;
    final depois = antes + quantidade;

    final batch = _db.batch();

    // Atualizar item
    batch.update(_db.collection(_itens).doc(item.id), {
      'quantidadeAtual': depois,
      'dataAtualizacao': Timestamp.fromDate(DateTime.now()),
    });

    // Registrar movimento
    final movRef = _db.collection(_movimentos).doc();
    batch.set(movRef, MovimentoEstoque(
      id: movRef.id,
      itemId: item.id,
      itemNome: item.nome,
      categoria: item.categoria.key,
      tipo: TipoMovimento.entrada,
      quantidade: quantidade,
      quantidadeAntes: antes,
      quantidadeDepois: depois,
      responsavelNome: responsavelNome,
      dataHora: DateTime.now(),
      observacao: observacao,
      festaReferencia: festaReferencia,
    ).toMap());

    await batch.commit();
  }

  /// Registra SAÍDA: a pessoa informa o que SOBrou, sistema calcula o que saiu
  Future<void> registrarSaida({
    required ItemEstoque item,
    required double quantidadeSobrou,
    required String responsavelNome,
    String? observacao,
    String? festaReferencia,
  }) async {
    final antes = item.quantidadeAtual;
    final saiu = antes - quantidadeSobrou;
    final depois = quantidadeSobrou;

    final batch = _db.batch();

    batch.update(_db.collection(_itens).doc(item.id), {
      'quantidadeAtual': depois,
      'dataAtualizacao': Timestamp.fromDate(DateTime.now()),
    });

    final movRef = _db.collection(_movimentos).doc();
    batch.set(movRef, MovimentoEstoque(
      id: movRef.id,
      itemId: item.id,
      itemNome: item.nome,
      categoria: item.categoria.key,
      tipo: TipoMovimento.saida,
      quantidade: saiu < 0 ? 0 : saiu,
      quantidadeAntes: antes,
      quantidadeDepois: depois,
      responsavelNome: responsavelNome,
      dataHora: DateTime.now(),
      observacao: observacao,
      festaReferencia: festaReferencia,
    ).toMap());

    await batch.commit();
  }
}

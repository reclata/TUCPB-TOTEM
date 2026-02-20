import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ═══ Categorias ═══
enum CategoriaEstoque { espiritual, cozinha, limpeza, shop }

extension CategoriaEstoqueExt on CategoriaEstoque {
  String get key {
    switch (this) {
      case CategoriaEstoque.espiritual: return 'espiritual';
      case CategoriaEstoque.cozinha:    return 'cozinha';
      case CategoriaEstoque.limpeza:    return 'limpeza';
      case CategoriaEstoque.shop:       return 'shop';
    }
  }

  String get label {
    switch (this) {
      case CategoriaEstoque.espiritual: return 'Espiritual';
      case CategoriaEstoque.cozinha:    return 'Cozinha';
      case CategoriaEstoque.limpeza:    return 'Limpeza / Higiene / Bazar';
      case CategoriaEstoque.shop:       return 'TUCPB Shop';
    }
  }

  String get labelCurto {
    switch (this) {
      case CategoriaEstoque.espiritual: return 'Espiritual';
      case CategoriaEstoque.cozinha:    return 'Cozinha';
      case CategoriaEstoque.limpeza:    return 'HLB';
      case CategoriaEstoque.shop:       return 'Shop';
    }
  }

  IconData get icon {
    switch (this) {
      case CategoriaEstoque.espiritual: return Icons.auto_fix_high;
      case CategoriaEstoque.cozinha:    return Icons.restaurant;
      case CategoriaEstoque.limpeza:    return Icons.cleaning_services;
      case CategoriaEstoque.shop:       return Icons.shopping_bag;
    }
  }

  Color get color {
    switch (this) {
      case CategoriaEstoque.espiritual: return const Color(0xFF6A1B9A);
      case CategoriaEstoque.cozinha:    return const Color(0xFFE65100);
      case CategoriaEstoque.limpeza:    return const Color(0xFF00838F);
      case CategoriaEstoque.shop:       return const Color(0xFF1565C0);
    }
  }

  static CategoriaEstoque fromKey(String? key) {
    switch (key) {
      case 'cozinha':    return CategoriaEstoque.cozinha;
      case 'limpeza':    return CategoriaEstoque.limpeza;
      case 'shop':       return CategoriaEstoque.shop;
      default:           return CategoriaEstoque.espiritual;
    }
  }
}

// ═══ Unidades ═══
const kUnidadesEstoque = ['un', 'kg', 'g', 'L', 'mL', 'cx', 'pct', 'fd', 'par', 'rolo'];

// ═══ Item do Estoque ═══
class ItemEstoque {
  final String id;
  final String nome;
  final String unidade;
  final CategoriaEstoque categoria;
  final double quantidadeAtual;
  final double quantidadeMinima; // alerta checklist
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;

  const ItemEstoque({
    required this.id,
    required this.nome,
    required this.unidade,
    required this.categoria,
    required this.quantidadeAtual,
    this.quantidadeMinima = 1,
    required this.dataCriacao,
    required this.dataAtualizacao,
  });

  bool get precisaComprar => quantidadeAtual <= quantidadeMinima;
  bool get zerado => quantidadeAtual <= 0;

  factory ItemEstoque.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ItemEstoque(
      id: doc.id,
      nome: d['nome'] ?? '',
      unidade: d['unidade'] ?? 'un',
      categoria: CategoriaEstoqueExt.fromKey(d['categoria']),
      quantidadeAtual: (d['quantidadeAtual'] as num?)?.toDouble() ?? 0,
      quantidadeMinima: (d['quantidadeMinima'] as num?)?.toDouble() ?? 1,
      dataCriacao: (d['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataAtualizacao: (d['dataAtualizacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'unidade': unidade,
    'categoria': categoria.key,
    'quantidadeAtual': quantidadeAtual,
    'quantidadeMinima': quantidadeMinima,
    'dataCriacao': Timestamp.fromDate(dataCriacao),
    'dataAtualizacao': Timestamp.fromDate(dataAtualizacao),
  };
}

// ═══ Movimento (Entrada / Saída) ═══
enum TipoMovimento { entrada, saida }

class MovimentoEstoque {
  final String id;
  final String itemId;
  final String itemNome;
  final String categoria;
  final TipoMovimento tipo;
  final double quantidade;
  final double quantidadeAntes;
  final double quantidadeDepois;
  final String responsavelNome;  // assinatura
  final DateTime dataHora;
  final String? observacao;
  final String? festaReferencia;

  const MovimentoEstoque({
    required this.id,
    required this.itemId,
    required this.itemNome,
    required this.categoria,
    required this.tipo,
    required this.quantidade,
    required this.quantidadeAntes,
    required this.quantidadeDepois,
    required this.responsavelNome,
    required this.dataHora,
    this.observacao,
    this.festaReferencia,
  });

  factory MovimentoEstoque.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MovimentoEstoque(
      id: doc.id,
      itemId: d['itemId'] ?? '',
      itemNome: d['itemNome'] ?? '',
      categoria: d['categoria'] ?? '',
      tipo: d['tipo'] == 'entrada' ? TipoMovimento.entrada : TipoMovimento.saida,
      quantidade: (d['quantidade'] as num?)?.toDouble() ?? 0,
      quantidadeAntes: (d['quantidadeAntes'] as num?)?.toDouble() ?? 0,
      quantidadeDepois: (d['quantidadeDepois'] as num?)?.toDouble() ?? 0,
      responsavelNome: d['responsavelNome'] ?? '',
      dataHora: (d['dataHora'] as Timestamp?)?.toDate() ?? DateTime.now(),
      observacao: d['observacao'],
      festaReferencia: d['festaReferencia'],
    );
  }

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'itemNome': itemNome,
    'categoria': categoria,
    'tipo': tipo == TipoMovimento.entrada ? 'entrada' : 'saida',
    'quantidade': quantidade,
    'quantidadeAntes': quantidadeAntes,
    'quantidadeDepois': quantidadeDepois,
    'responsavelNome': responsavelNome,
    'dataHora': Timestamp.fromDate(dataHora),
    if (observacao != null) 'observacao': observacao,
    if (festaReferencia != null) 'festaReferencia': festaReferencia,
  };
}
// ═══ Item Manual de Checklist (Compras extras) ═══
class ChecklistManualItem {
  final String id;
  final String nome;
  final CategoriaEstoque categoria;
  final bool comprado;
  final DateTime dataCriacao;

  const ChecklistManualItem({
    required this.id,
    required this.nome,
    required this.categoria,
    this.comprado = false,
    required this.dataCriacao,
  });

  factory ChecklistManualItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChecklistManualItem(
      id: doc.id,
      nome: d['nome'] ?? '',
      categoria: CategoriaEstoqueExt.fromKey(d['categoria']),
      comprado: d['comprado'] ?? false,
      dataCriacao: (d['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'categoria': categoria.key,
    'comprado': comprado,
    'dataCriacao': Timestamp.fromDate(dataCriacao),
  };
}

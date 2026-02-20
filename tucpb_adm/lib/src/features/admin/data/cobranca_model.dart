import 'package:cloud_firestore/cloud_firestore.dart';

// Status das cobranças
enum StatusCobranca { pago, emAndamento, naoIniciado, atrasado }

extension StatusCobrancaExt on StatusCobranca {
  String get label {
    switch (this) {
      case StatusCobranca.pago: return 'Pago';
      case StatusCobranca.emAndamento: return 'Em Andamento';
      case StatusCobranca.naoIniciado: return 'Não Iniciado';
      case StatusCobranca.atrasado: return 'Atrasado';
    }
  }
  String get key {
    switch (this) {
      case StatusCobranca.pago: return 'pago';
      case StatusCobranca.emAndamento: return 'em_andamento';
      case StatusCobranca.naoIniciado: return 'nao_iniciado';
      case StatusCobranca.atrasado: return 'atrasado';
    }
  }
  static StatusCobranca fromKey(String? key) {
    switch (key) {
      case 'pago': return StatusCobranca.pago;
      case 'em_andamento': return StatusCobranca.emAndamento;
      case 'atrasado': return StatusCobranca.atrasado;
      default: return StatusCobranca.naoIniciado;
    }
  }
}

// Tipos de cobrança avulsa
const kTiposAvulso = ['Festa', 'Ervas', 'Contribuição', 'Obrigação', 'Outros'];

// Origens
enum OrigemCobranca { avulso, asaas }

class CobrancaModel {
  final String id;
  final String tipo;         // Festa, Ervas, Contribuição...
  final double valor;
  final StatusCobranca status;
  final String usuarioId;    // uid ou doc id
  final String usuarioNome;
  final String usuarioEmail;
  final OrigemCobranca origem; // avulso | asaas
  final DateTime dataCriacao;
  final DateTime? dataPagamento;
  final DateTime? dataVencimento;
  final String? descricao;
  final String? asaasId;     // ID da cobrança no ASAAS
  final String? pixCopiaECola;
  final String? linkPagamento;

  CobrancaModel({
    required this.id,
    required this.tipo,
    required this.valor,
    required this.status,
    required this.usuarioId,
    required this.usuarioNome,
    required this.usuarioEmail,
    required this.origem,
    required this.dataCriacao,
    this.dataPagamento,
    this.dataVencimento,
    this.descricao,
    this.asaasId,
    this.pixCopiaECola,
    this.linkPagamento,
  });

  factory CobrancaModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CobrancaModel(
      id: doc.id,
      tipo: d['tipo'] ?? 'Outros',
      valor: (d['valor'] as num?)?.toDouble() ?? 0.0,
      status: StatusCobrancaExt.fromKey(d['status']),
      usuarioId: d['usuarioId'] ?? '',
      usuarioNome: d['usuarioNome'] ?? '',
      usuarioEmail: d['usuarioEmail'] ?? '',
      origem: d['origem'] == 'asaas' ? OrigemCobranca.asaas : OrigemCobranca.avulso,
      dataCriacao: (d['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataPagamento: (d['dataPagamento'] as Timestamp?)?.toDate(),
      dataVencimento: (d['dataVencimento'] as Timestamp?)?.toDate(),
      descricao: d['descricao'],
      asaasId: d['asaasId'],
      pixCopiaECola: d['pixCopiaECola'],
      linkPagamento: d['linkPagamento'],
    );
  }

  Map<String, dynamic> toMap() => {
    'tipo': tipo,
    'valor': valor,
    'status': status.key,
    'usuarioId': usuarioId,
    'usuarioNome': usuarioNome,
    'usuarioEmail': usuarioEmail,
    'origem': origem == OrigemCobranca.asaas ? 'asaas' : 'avulso',
    'dataCriacao': Timestamp.fromDate(dataCriacao),
    if (dataPagamento != null) 'dataPagamento': Timestamp.fromDate(dataPagamento!),
    if (dataVencimento != null) 'dataVencimento': Timestamp.fromDate(dataVencimento!),
    'descricao': descricao,
    if (asaasId != null) 'asaasId': asaasId,
    if (pixCopiaECola != null) 'pixCopiaECola': pixCopiaECola,
    if (linkPagamento != null) 'linkPagamento': linkPagamento,
  };
}

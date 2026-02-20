import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de uma Gira - compartilhado entre ADM e TOTEM via Firestore
class GiraModel {
  final String id;
  final String nome;
  final DateTime data;
  final String horarioInicio;
  final String horarioFim;
  final bool ativo;
  final String? descricao;
  final String tipo; // 'gira', 'culto', 'evento', 'reuniao'
  final String? cor; // Cor para visualização no calendário
  final String? mediumId; // Caso seja limpeza
  final String? mediumNome; // Nome do médium escalado
  final bool visivelAssistencia; // Se é visível para o público/assistência
  
  // Histórico (preenchido pelo TOTEM após a gira)
  final HistoricoGira? historico;

  GiraModel({
    required this.id,
    required this.nome,
    required this.data,
    required this.horarioInicio,
    required this.horarioFim,
    required this.ativo,
    this.descricao,
    required this.tipo,
    this.cor,
    this.mediumId,
    this.mediumNome,
    this.visivelAssistencia = true,
    this.historico,
  });

  factory GiraModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return GiraModel(
      id: doc.id,
      nome: map['nome'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
      horarioInicio: map['horarioInicio'] ?? '',
      horarioFim: map['horarioFim'] ?? '',
      ativo: map['ativo'] ?? true,
      descricao: map['descricao'],
      tipo: map['tipo'] ?? 'gira',
      cor: map['cor'],
      mediumId: map['mediumId'],
      mediumNome: map['mediumNome'],
      visivelAssistencia: map['visivelAssistencia'] ?? true,
      historico: map['historico'] != null
          ? HistoricoGira.fromMap(map['historico'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'data': Timestamp.fromDate(data),
        'horarioInicio': horarioInicio,
        'horarioFim': horarioFim,
        'ativo': ativo,
        'descricao': descricao,
        'tipo': tipo,
        'cor': cor ?? defaultCor(tipo),
        'mediumId': mediumId,
        'mediumNome': mediumNome,
        'visivelAssistencia': visivelAssistencia,
        'dataCriacao': FieldValue.serverTimestamp(),
        // 'historico' é preenchido pelo TOTEM
      };

  static String defaultCor(String tipo) {
    switch (tipo) {
      case 'gira':    return '#1565C0'; // Azul
      case 'limpeza': return '#00838F'; // Teal
      case 'festa':   return '#AD1457'; // Rosa
      case 'evento':  return '#2E7D32'; // Verde
      case 'entrega': return '#FF9800'; // Laranja
      case 'comemorativa': return '#795548'; // Marrom
      default:        return '#1565C0';
    }
  }
}

class HistoricoGira {
  final int totalSenhas;
  final int totalMediums;
  final int totalAtendimentos;
  final Map<String, int> atendimentosPorMedium;
  final String? horarioInicioReal;
  final String? horarioFimReal;

  HistoricoGira({
    required this.totalSenhas,
    required this.totalMediums,
    required this.totalAtendimentos,
    required this.atendimentosPorMedium,
    this.horarioInicioReal,
    this.horarioFimReal,
  });

  factory HistoricoGira.fromMap(Map<String, dynamic> map) {
    return HistoricoGira(
      totalSenhas: (map['totalSenhas'] ?? 0) as int,
      totalMediums: (map['totalMediums'] ?? 0) as int,
      totalAtendimentos: (map['totalAtendimentos'] ?? 0) as int,
      atendimentosPorMedium: Map<String, int>.from(map['atendimentosPorMedium'] ?? {}),
      horarioInicioReal: map['horarioInicioReal'],
      horarioFimReal: map['horarioFimReal'],
    );
  }
}

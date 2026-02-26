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
  final String linha; // Grupo espiritual (ex: ESQUERDA, CABOCLO)
  final String tema;  // Nome completo (ex: Gira de Pretos Velhos)
  final String? cor; // Cor para visualização no calendário
  final String? mediumId; // Caso seja limpeza
  final String? mediumNome; // Nome do médium escalado
  final bool visivelAssistencia; // Se é visível para o público/assistência
  final List<String> mediumsParticipantes;
  final List<String> entidadesParticipantes;
  final Map<String, bool> presencas;
  // Configurações do Kiosk (Totem)
  final String horarioKiosk;
  final String? horarioEncerramentoKiosk;
  final bool encerramentoKioskAtivo;
  
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
    this.linha = '',
    this.tema = '',
    this.cor,
    this.mediumId,
    this.mediumNome,
    this.visivelAssistencia = true,
    this.horarioKiosk = '18:00',
    this.horarioEncerramentoKiosk,
    this.encerramentoKioskAtivo = false,
    this.mediumsParticipantes = const [],
    this.entidadesParticipantes = const [],
    this.presencas = const {},
    this.historico,
  });

  factory GiraModel.fromFirestore(DocumentSnapshot doc) {
    final rawData = doc.data();
    if (rawData == null) throw Exception("Documento ${doc.id} sem dados");
    final map = Map<String, dynamic>.from(rawData as Map);
    return GiraModel(
      id: doc.id,
      nome: (map['nome'] ?? '').toString(),
      data: (map['data'] as Timestamp).toDate(),
      horarioInicio: map['horarioInicio'] ?? '',
      horarioFim: map['horarioFim'] ?? '',
      ativo: map['ativo'] ?? true,
      descricao: map['descricao'],
      tipo: map['tipo'] ?? 'gira',
      linha: map['linha'] ?? '',
      tema: map['tema'] ?? map['nome'] ?? '',
      cor: map['cor'],
      mediumId: map['mediumId'],
      mediumNome: map['mediumNome'],
      visivelAssistencia: map['visivelAssistencia'] ?? true,
      horarioKiosk: map['horarioKiosk'] ?? '18:00',
      horarioEncerramentoKiosk: map['horarioEncerramentoKiosk'],
      encerramentoKioskAtivo: map['encerramentoKioskAtivo'] ?? false,
      mediumsParticipantes: List<String>.from(map['mediumsParticipantes'] ?? map['mediums_participantes'] ?? []),
      entidadesParticipantes: List<String>.from(map['entidadesParticipantes'] ?? map['entidades_participantes'] ?? []),
      presencas: Map<String, bool>.from(map['presencas'] ?? map['presences'] ?? {}),
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
        'linha': linha,
        'tema': tema,
        'cor': cor ?? defaultCor(tipo),
        'mediumId': mediumId,
        'mediumNome': mediumNome,
        'visivelAssistencia': visivelAssistencia,
        'horarioKiosk': horarioKiosk,
        'horarioEncerramentoKiosk': horarioEncerramentoKiosk,
        'encerramentoKioskAtivo': encerramentoKioskAtivo,
        'mediumsParticipantes': mediumsParticipantes,
        'entidadesParticipantes': entidadesParticipantes,
        'presencas': presencas,
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

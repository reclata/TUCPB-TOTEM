import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'models.g.dart';

// Firestore timestamp converter for generic handling
class TimestampConverter implements JsonConverter<DateTime, Object> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object json) {
    if (json is Timestamp) return json.toDate();
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return DateTime.parse(json as String);
  }

  @override
  Object toJson(DateTime object) => Timestamp.fromDate(object);
}

@JsonSerializable()
class Gira {
  final String id;
  final String terreiroId;
  final String linha;
  final String tema;
  @TimestampConverter()
  final DateTime data;
  final String status; // aberta, encerrada, agendada
  final String horarioInicio; // e.g. "19:00"
  final String horarioKiosk; // horário de liberação do kiosk
  final String? horarioEncerramentoKiosk; // horário encerramento (opcional)
  final bool encerramentoKioskAtivo; // flag para ativar encerramento automático
  final List<String> mediumsParticipantes; // IDs dos médiuns participantes

  final Map<String, bool> presencas; // mediumId -> presente (true/false)

  const Gira({
    required this.id,
    required this.terreiroId,
    required this.linha,
    required this.tema,
    required this.data,
    required this.status,
    this.horarioInicio = '',
    this.horarioKiosk = '',
    this.horarioEncerramentoKiosk,
    this.encerramentoKioskAtivo = false,
    this.mediumsParticipantes = const [],
    this.presencas = const {},
  });

  factory Gira.fromJson(Map<String, dynamic> json) => _$GiraFromJson(json);
  Map<String, dynamic> toJson() => _$GiraToJson(this);
}

@JsonSerializable()
class Entidade {
  final String id;
  final String terreiroId;
  final String nome;
  final String linha; // e.g. Caboclos, Pretos Velhos, Baianos
  final String tipo; // e.g. Caboclo, Preto Velho

  const Entidade({
    required this.id,
    required this.terreiroId,
    required this.nome,
    required this.linha,
    required this.tipo,
  });

  factory Entidade.fromJson(Map<String, dynamic> json) => _$EntidadeFromJson(json);
  Map<String, dynamic> toJson() => _$EntidadeToJson(this);
}

@JsonSerializable()
class MediumEntidade {
  final String entidadeId;
  final String entidadeNome; // Denormalized for easier display
  final String linha; // Spiritual line
  final String tipo; // Entity type
  final String status; // 'ativo', 'pausado', 'desativado'

  const MediumEntidade({
    required this.entidadeId,
    required this.entidadeNome,
    required this.linha,
    required this.tipo,
    required this.status,
  });

  factory MediumEntidade.fromJson(Map<String, dynamic> json) => _$MediumEntidadeFromJson(json);
  Map<String, dynamic> toJson() => _$MediumEntidadeToJson(this);
}

@JsonSerializable()
class Medium {
  final String id;
  final String terreiroId;
  final String nome;
  final bool ativo; // General status of the medium
  final List<MediumEntidade> entidades; // List of entities they channel
  
  // Stats
  final int girasParticipadas;
  final int atendimentosRealizados;
  final int faltas;

  const Medium({
    required this.id,
    required this.terreiroId,
    required this.nome,
    required this.ativo,
    this.entidades = const [],
    this.girasParticipadas = 0,
    this.atendimentosRealizados = 0,
    this.faltas = 0,
  });

  factory Medium.fromJson(Map<String, dynamic> json) => _$MediumFromJson(json);
  Map<String, dynamic> toJson() => _$MediumToJson(this);
}

@JsonSerializable()
class Ticket {
  final String id;
  final String terreiroId;
  final String giraId;
  final String entidadeId;
  final String mediumId;
  final String codigoSenha; // SL0001
  final int sequencial; // 1
  final String dataRef; // YYYY-MM-DD
  final String status; // emitida, chamada, atendida, nao_compareceu, encerrada
  final int ordemFila; // Order number
  @TimestampConverter()
  final DateTime dataHoraEmissao;
  @TimestampConverter()
  final DateTime? dataHoraChamada;
  @TimestampConverter()
  final DateTime? dataHoraAtendida;
  final int chamadaCount;

  const Ticket({
    required this.id,
    required this.terreiroId,
    required this.giraId,
    required this.entidadeId,
    required this.mediumId,
    required this.codigoSenha,
    required this.sequencial,
    required this.dataRef,
    required this.status,
    required this.ordemFila,
    required this.dataHoraEmissao,
    this.dataHoraChamada,
    this.dataHoraAtendida,
    this.chamadaCount = 0,
  });


  factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);
  Map<String, dynamic> toJson() => _$TicketToJson(this);
}

@JsonSerializable()
class Usuario {
  final String id;
  final String terreiroId;
  final String nomeCompleto;
  final String login;
  final String senha; // In production, this should be hashed
  final String perfilAcesso; // 'admin', 'operador', 'visualizador'
  final bool ativo;

  const Usuario({
    required this.id,
    required this.terreiroId,
    required this.nomeCompleto,
    required this.login,
    required this.senha,
    required this.perfilAcesso,
    this.ativo = true,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => _$UsuarioFromJson(json);
  Map<String, dynamic> toJson() => _$UsuarioToJson(this);
}

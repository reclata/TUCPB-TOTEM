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

@JsonSerializable(explicitToJson: true)
class Gira {
  final String id;
  final String? terreiroId;
  final String linha;
  @JsonKey(readValue: _readGiraTema)
  final String tema;
  
  static Object? _readGiraTema(Map json, String key) => 
      (json['nome'] ?? json['tema'] ?? '').toString();
  @TimestampConverter()
  final DateTime data;
  @JsonKey(defaultValue: 'agendada')
  final String status; // aberta, encerrada, agendada
  final bool? ativo; // vindo do tucpb_adm
  final String horarioInicio; // e.g. "19:00"
  final String horarioKiosk; // horário de liberação do kiosk
  final String? horarioEncerramentoKiosk; // horário encerramento (opcional)
  final bool encerramentoKioskAtivo; // flag para ativar encerramento automático
  @JsonKey(readValue: _readMediumsParticipantes)
  final List<String> mediumsParticipantes; // IDs dos médiuns participantes
  @JsonKey(readValue: _readEntidadesParticipantes)
  final List<String> entidadesParticipantes; // IDs das entidades específicas selecionadas

  @JsonKey(readValue: _readPresencas)
  final Map<String, bool> presencas; // mediumId -> presente (true/false)

  static Object? _readMediumsParticipantes(Map json, String key) => 
      List<dynamic>.from(json['mediumsParticipantes'] ?? json['mediums_participantes'] ?? []);
  static Object? _readEntidadesParticipantes(Map json, String key) => 
      List<dynamic>.from(json['entidadesParticipantes'] ?? json['entidades_participantes'] ?? []);
  static Object? _readPresencas(Map json, String key) => 
      Map<String, dynamic>.from(json['presencas'] ?? json['presences'] ?? <String, dynamic>{});

  const Gira({
    required this.id,
    this.terreiroId,
    this.linha = '',
    this.tema = '',
    required this.data,
    this.status = 'agendada',
    this.ativo,
    this.horarioInicio = '',
    this.horarioKiosk = '',
    this.horarioEncerramentoKiosk,
    this.encerramentoKioskAtivo = false,
    this.mediumsParticipantes = const [],
    this.entidadesParticipantes = const [],
    this.presencas = const {},
  });

  // Getter de compatibilidade: se status não estiver setado ou for vazio, tenta usar o 'ativo'
  bool get isAberta => status == 'aberta' || (ativo == true);
  
  // Getter de compatibilidade para tema (no ADM é apenas 'nome')
  String get nomeExibicao => tema.isNotEmpty ? tema : linha;

  factory Gira.fromJson(Map<String, dynamic> json) => _$GiraFromJson(json);
  Map<String, dynamic> toJson() => _$GiraToJson(this);
}

@JsonSerializable(explicitToJson: true)
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

@JsonSerializable(explicitToJson: true)
class MediumEntidade {
  @JsonKey(defaultValue: '')
  final String entidadeId;
  @JsonKey(name: 'nome', defaultValue: '', readValue: _readEntidadeNome)
  final String entidadeNome; // Denormalized for easier display
  
  static Object? _readEntidadeNome(Map json, String key) => 
      (json['nome'] ?? json['entidadeNome'] ?? '').toString();
  @JsonKey(defaultValue: '')
  final String linha; // Spiritual line
  @JsonKey(defaultValue: '')
  final String tipo; // Entity type
  @JsonKey(defaultValue: 'ativo')
  final String status; // 'ativo', 'pausado', 'desativado'

  const MediumEntidade({
    required this.entidadeId,
    this.entidadeNome = '',
    this.linha = '',
    this.tipo = '',
    this.status = 'ativo',
  });

  factory MediumEntidade.fromJson(Map<String, dynamic> json) => _$MediumEntidadeFromJson(json);
  Map<String, dynamic> toJson() => _$MediumEntidadeToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Medium {
  final String id;
  final String? terreiroId;
  final String nome;
  final bool ativo; // General status of the medium
  final List<MediumEntidade> entidades; // List of entities they channel
  
  // Stats
  final int girasParticipadas;
  final int atendimentosRealizados;
  final int faltas;
  
  // Settings
  final int maxFichas;
  final String cargo;
  final String fotoUrl;
  @JsonKey(name: 'observacao', defaultValue: '')
  final String observacoes;
  final String ultimaGira;
  @JsonKey(name: 'perfil', defaultValue: 'medium')
  final String tipoAcesso;

  const Medium({
    required this.id,
    this.terreiroId,
    this.nome = '',
    this.ativo = true,
    this.entidades = const [],
    this.girasParticipadas = 0,
    this.atendimentosRealizados = 0,
    this.faltas = 0,
    this.maxFichas = 0,
    this.cargo = '',
    this.fotoUrl = '',
    this.observacoes = '',
    this.ultimaGira = '',
    this.tipoAcesso = 'medium',
  });

  factory Medium.fromJson(Map<String, dynamic> json) => _$MediumFromJson(json);
  Map<String, dynamic> toJson() => _$MediumToJson(this);
}


@JsonSerializable(explicitToJson: true)
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
  final bool isRedistributed;

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
    this.isRedistributed = false,
  });


  factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);
  Map<String, dynamic> toJson() => _$TicketToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Usuario {
  final String id;
  final String terreiroId;
  final String nomeCompleto;
  final String login;
  final String senha; // In production, this should be hashed
  final String perfilAcesso; // 'admin', 'operador', 'visualizador'
  final List<String> permissoes; // Lista de funcionalidades permitidas
  final bool ativo;

  const Usuario({
    required this.id,
    required this.terreiroId,
    required this.nomeCompleto,
    required this.login,
    required this.senha,
    required this.perfilAcesso,
    this.permissoes = const [],
    this.ativo = true,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => _$UsuarioFromJson(json);
  Map<String, dynamic> toJson() => _$UsuarioToJson(this);
}

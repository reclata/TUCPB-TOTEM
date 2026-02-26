// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Gira _$GiraFromJson(Map<String, dynamic> json) => Gira(
  id: json['id'] as String,
  terreiroId: json['terreiroId'] as String?,
  linha: json['linha'] as String? ?? '',
  tema: Gira._readGiraTema(json, 'tema') as String? ?? '',
  data: const TimestampConverter().fromJson(json['data'] as Object),
  status: json['status'] as String? ?? 'agendada',
  ativo: json['ativo'] as bool?,
  horarioInicio: json['horarioInicio'] as String? ?? '',
  horarioKiosk: json['horarioKiosk'] as String? ?? '',
  horarioEncerramentoKiosk: json['horarioEncerramentoKiosk'] as String?,
  encerramentoKioskAtivo: json['encerramentoKioskAtivo'] as bool? ?? false,
  mediumsParticipantes:
      (Gira._readMediumsParticipantes(json, 'mediumsParticipantes')
              as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  entidadesParticipantes:
      (Gira._readEntidadesParticipantes(json, 'entidadesParticipantes')
              as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  presencas:
      (Gira._readPresencas(json, 'presencas') as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as bool),
      ) ??
      const {},
);

Map<String, dynamic> _$GiraToJson(Gira instance) => <String, dynamic>{
  'id': instance.id,
  'terreiroId': instance.terreiroId,
  'linha': instance.linha,
  'tema': instance.tema,
  'data': const TimestampConverter().toJson(instance.data),
  'status': instance.status,
  'ativo': instance.ativo,
  'horarioInicio': instance.horarioInicio,
  'horarioKiosk': instance.horarioKiosk,
  'horarioEncerramentoKiosk': instance.horarioEncerramentoKiosk,
  'encerramentoKioskAtivo': instance.encerramentoKioskAtivo,
  'mediumsParticipantes': instance.mediumsParticipantes,
  'entidadesParticipantes': instance.entidadesParticipantes,
  'presencas': instance.presencas,
};

Entidade _$EntidadeFromJson(Map<String, dynamic> json) => Entidade(
  id: json['id'] as String,
  terreiroId: json['terreiroId'] as String,
  nome: json['nome'] as String,
  linha: json['linha'] as String,
  tipo: json['tipo'] as String,
);

Map<String, dynamic> _$EntidadeToJson(Entidade instance) => <String, dynamic>{
  'id': instance.id,
  'terreiroId': instance.terreiroId,
  'nome': instance.nome,
  'linha': instance.linha,
  'tipo': instance.tipo,
};

MediumEntidade _$MediumEntidadeFromJson(Map<String, dynamic> json) =>
    MediumEntidade(
      entidadeId: json['entidadeId'] as String? ?? '',
      entidadeNome:
          MediumEntidade._readEntidadeNome(json, 'nome') as String? ?? '',
      linha: json['linha'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      status: json['status'] as String? ?? 'ativo',
    );

Map<String, dynamic> _$MediumEntidadeToJson(MediumEntidade instance) =>
    <String, dynamic>{
      'entidadeId': instance.entidadeId,
      'nome': instance.entidadeNome,
      'linha': instance.linha,
      'tipo': instance.tipo,
      'status': instance.status,
    };

Medium _$MediumFromJson(Map<String, dynamic> json) => Medium(
  id: json['id'] as String,
  terreiroId: json['terreiroId'] as String?,
  nome: json['nome'] as String? ?? '',
  ativo: json['ativo'] as bool? ?? true,
  entidades: (Medium._readMediumEntidades(json, 'entidades') as List<dynamic>?)
          ?.map((e) => MediumEntidade.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  girasParticipadas: (json['girasParticipadas'] as num?)?.toInt() ?? 0,
  atendimentosRealizados:
      (json['atendimentosRealizados'] as num?)?.toInt() ?? 0,
  faltas: (json['faltas'] as num?)?.toInt() ?? 0,
  maxFichas: (json['maxFichas'] as num?)?.toInt() ?? 0,
  cargo: json['cargo'] as String? ?? '',
  fotoUrl: json['fotoUrl'] as String? ?? '',
  observacoes: json['observacao'] as String? ?? '',
  ultimaGira: json['ultimaGira'] as String? ?? '',
  tipoAcesso: json['perfil'] as String? ?? 'medium',
);

Map<String, dynamic> _$MediumToJson(Medium instance) => <String, dynamic>{
  'id': instance.id,
  'terreiroId': instance.terreiroId,
  'nome': instance.nome,
  'ativo': instance.ativo,
  'entidades': instance.entidades.map((e) => e.toJson()).toList(),
  'girasParticipadas': instance.girasParticipadas,
  'atendimentosRealizados': instance.atendimentosRealizados,
  'faltas': instance.faltas,
  'maxFichas': instance.maxFichas,
  'cargo': instance.cargo,
  'fotoUrl': instance.fotoUrl,
  'observacao': instance.observacoes,
  'ultimaGira': instance.ultimaGira,
  'perfil': instance.tipoAcesso,
};

Ticket _$TicketFromJson(Map<String, dynamic> json) => Ticket(
  id: json['id'] as String,
  terreiroId: json['terreiroId'] as String,
  giraId: json['giraId'] as String,
  entidadeId: json['entidadeId'] as String,
  mediumId: json['mediumId'] as String,
  codigoSenha: json['codigoSenha'] as String,
  sequencial: (json['sequencial'] as num).toInt(),
  dataRef: json['dataRef'] as String,
  status: json['status'] as String,
  ordemFila: (json['ordemFila'] as num).toInt(),
  dataHoraEmissao: const TimestampConverter().fromJson(
    json['dataHoraEmissao'] as Object,
  ),
  dataHoraChamada: _$JsonConverterFromJson<Object, DateTime>(
    json['dataHoraChamada'],
    const TimestampConverter().fromJson,
  ),
  dataHoraAtendida: _$JsonConverterFromJson<Object, DateTime>(
    json['dataHoraAtendida'],
    const TimestampConverter().fromJson,
  ),
  chamadaCount: (json['chamadaCount'] as num?)?.toInt() ?? 0,
  isRedistributed: json['isRedistributed'] as bool? ?? false,
);

Map<String, dynamic> _$TicketToJson(Ticket instance) => <String, dynamic>{
  'id': instance.id,
  'terreiroId': instance.terreiroId,
  'giraId': instance.giraId,
  'entidadeId': instance.entidadeId,
  'mediumId': instance.mediumId,
  'codigoSenha': instance.codigoSenha,
  'sequencial': instance.sequencial,
  'dataRef': instance.dataRef,
  'status': instance.status,
  'ordemFila': instance.ordemFila,
  'dataHoraEmissao': const TimestampConverter().toJson(
    instance.dataHoraEmissao,
  ),
  'dataHoraChamada': _$JsonConverterToJson<Object, DateTime>(
    instance.dataHoraChamada,
    const TimestampConverter().toJson,
  ),
  'dataHoraAtendida': _$JsonConverterToJson<Object, DateTime>(
    instance.dataHoraAtendida,
    const TimestampConverter().toJson,
  ),
  'chamadaCount': instance.chamadaCount,
  'isRedistributed': instance.isRedistributed,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

Usuario _$UsuarioFromJson(Map<String, dynamic> json) => Usuario(
  id: json['id'] as String,
  terreiroId: json['terreiroId'] as String,
  nomeCompleto: json['nomeCompleto'] as String,
  login: json['login'] as String,
  senha: json['senha'] as String,
  perfilAcesso: json['perfilAcesso'] as String,
  permissoes:
      (json['permissoes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  ativo: json['ativo'] as bool? ?? true,
);

Map<String, dynamic> _$UsuarioToJson(Usuario instance) => <String, dynamic>{
  'id': instance.id,
  'terreiroId': instance.terreiroId,
  'nomeCompleto': instance.nomeCompleto,
  'login': instance.login,
  'senha': instance.senha,
  'perfilAcesso': instance.perfilAcesso,
  'permissoes': instance.permissoes,
  'ativo': instance.ativo,
};

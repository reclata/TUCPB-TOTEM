// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Gira _$GiraFromJson(Map<String, dynamic> json) => Gira(
  id: json['id'] as String,
  terreiroId: json['terreiroId'] as String,
  linha: json['linha'] as String,
  tema: json['tema'] as String,
  data: const TimestampConverter().fromJson(json['data'] as Object),
  status: json['status'] as String,
  horarioInicio: json['horarioInicio'] as String? ?? '',
  horarioKiosk: json['horarioKiosk'] as String? ?? '',
  horarioEncerramentoKiosk: json['horarioEncerramentoKiosk'] as String?,
  encerramentoKioskAtivo: json['encerramentoKioskAtivo'] as bool? ?? false,
  mediumsParticipantes:
      (json['mediumsParticipantes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  presencas:
      (json['presencas'] as Map<String, dynamic>?)?.map(
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
  'horarioInicio': instance.horarioInicio,
  'horarioKiosk': instance.horarioKiosk,
  'horarioEncerramentoKiosk': instance.horarioEncerramentoKiosk,
  'encerramentoKioskAtivo': instance.encerramentoKioskAtivo,
  'mediumsParticipantes': instance.mediumsParticipantes,
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
      entidadeId: json['entidadeId'] as String,
      entidadeNome: json['entidadeNome'] as String,
      linha: json['linha'] as String,
      tipo: json['tipo'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$MediumEntidadeToJson(MediumEntidade instance) =>
    <String, dynamic>{
      'entidadeId': instance.entidadeId,
      'entidadeNome': instance.entidadeNome,
      'linha': instance.linha,
      'tipo': instance.tipo,
      'status': instance.status,
    };

Medium _$MediumFromJson(Map<String, dynamic> json) => Medium(
  id: json['id'] as String,
  terreiroId: json['terreiroId'] as String,
  nome: json['nome'] as String,
  ativo: json['ativo'] as bool,
  entidades:
      (json['entidades'] as List<dynamic>?)
          ?.map((e) => MediumEntidade.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  girasParticipadas: (json['girasParticipadas'] as num?)?.toInt() ?? 0,
  atendimentosRealizados:
      (json['atendimentosRealizados'] as num?)?.toInt() ?? 0,
  faltas: (json['faltas'] as num?)?.toInt() ?? 0,
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
  ativo: json['ativo'] as bool? ?? true,
);

Map<String, dynamic> _$UsuarioToJson(Usuario instance) => <String, dynamic>{
  'id': instance.id,
  'terreiroId': instance.terreiroId,
  'nomeCompleto': instance.nomeCompleto,
  'login': instance.login,
  'senha': instance.senha,
  'perfilAcesso': instance.perfilAcesso,
  'ativo': instance.ativo,
};

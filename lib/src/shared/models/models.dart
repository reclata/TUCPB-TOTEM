import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'models.freezed.dart';
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

@freezed
class Gira with _$Gira {
  const factory Gira({
    required String id,
    required String terreiroId,
    required String tema, // e.g., Caboclo
    @TimestampConverter() required DateTime data,
    required String status, // aberta, encerrada
  }) = _Gira;

  factory Gira.fromJson(Map<String, dynamic> json) => _$GiraFromJson(json);
}

@freezed
class Entidade with _$Entidade {
  const factory Entidade({
    required String id,
    required String terreiroId,
    required String nome,
    required String tipo, // e.g. Caboclo, Preto Velho
  }) = _Entidade;

  factory Entidade.fromJson(Map<String, dynamic> json) =>
      _$EntidadeFromJson(json);
}

@freezed
class Medium with _$Medium {
  const factory Medium({
    required String id,
    required String terreiroId,
    required String nome,
    required String iniciais, // SL
    required String entidadeId, // Linked Entity
    required bool ativo,
  }) = _Medium;

  factory Medium.fromJson(Map<String, dynamic> json) => _$MediumFromJson(json);
}

@freezed
class Ticket with _$Ticket {
  const factory Ticket({
    required String id,
    required String terreiroId,
    required String giraId,
    required String entidadeId,
    required String mediumId,
    required String codigoSenha, // SL0001
    required int sequencial, // 1
    required String dataRef, // YYYY-MM-DD
    required String status, // emitida, chamada, atendida, nao_compareceu, encerrada
    required int ordemFila, // Order number
    @TimestampConverter() required DateTime dataHoraEmissao,
    @TimestampConverter() DateTime? dataHoraChamada,
    @TimestampConverter() DateTime? dataHoraAtendida,
    @Default(0) int chamadaCount,
  }) = _Ticket;

  factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);
}

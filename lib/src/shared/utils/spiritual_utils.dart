import 'package:terreiro_queue_system/src/shared/models/models.dart';

const Map<String, List<String>> GIRA_THEME_MAPPING = {
  'Gira de Caboclo': ['CABOCLO', 'CABOCLA'],
  'Gira de Esquerda': ['EXÚ', 'POMBA GIRA', 'POMBO GIRO', 'EXÚ - MIRIM', 'EXÚ - MIRIM MENINO', 'EXÚ - MIRIM MENINA', 'FEITICEIRO', 'FEITICEIRA'],
  'Gira de Boiadeiro': ['BOIADEIRO', 'VAQUEIRO', 'MARINHEIRO', 'MALANDRO', 'MALANDRA', 'CAPOEIRA'],
  'Gira de Preto Velho': ['PRETO VELHO', 'PRETA VELHA', 'FEITICEIRO', 'FEITICEIRA'],
  'Gira de Erês': ['ERÊ', 'ERÊ MENINO', 'ERÊ MENINA', 'CRIANÇA', 'MENINO', 'MENINA'],
  'Gira de Baiano': ['BAIANO', 'BAIANA'],
  'Gira de Cigano': ['CIGANO', 'CIGANA'],
  'Gira de Feiticeiro': ['FEITICEIRO', 'FEITICEIRA'],
};

const Map<String, List<String>> LINE_GROUPS = {
  'BOIADEIRO': ['BOIADEIRO', 'VAQUEIRO', 'MARINHEIRO', 'MALANDRO', 'MALANDRA', 'CAPOEIRA'],
  'ESQUERDA': ['EXÚ', 'POMBA GIRA', 'POMBO GIRO', 'EXÚ - MIRIM', 'FEITICEIRO', 'FEITICEIRA'],
  'PRETO VELHO': ['PRETO VELHO', 'PRETA VELHA', 'FEITICEIRO', 'FEITICEIRA'],
  'CABOCLO': ['CABOCLO', 'CABOCLA'],
  'ERÊS': ['ERÊ', 'ERÊ MENINO', 'ERÊ MENINA', 'CRIANÇA', 'MENINO', 'MENINA'],
  'ERES': ['ERÊ', 'ERÊ MENINO', 'ERÊ MENINA', 'CRIANÇA', 'MENINO', 'MENINA'],
  'BAIANO': ['BAIANO', 'BAIANA'],
  'CIGANO': ['CIGANO', 'CIGANA'],
  'FEITICEIRO': ['FEITICEIRO', 'FEITICEIRA'],
};

const List<String> ALLOWED_TABLET_USERS = [
  'THÁBATA',
  'THAYENI',
  'SANDRA',
  'EDUARDO',
  'ROBSON',
  'JUCINEIDE',
  'PEDRO',
  'DENIS ALBERTO',
  'LUCIANO',
];

String normalizeSpiritualLine(String? s) {
  if (s == null || s.trim().isEmpty) return '';
  final u = s.toUpperCase().trim();
  if (u == 'EXU' || u == 'EXÚ') return 'EXÚ';
  if (u == 'POMBAGIRA' || u == 'POMBA GIRA') return 'POMBA GIRA';
  if (u == 'POMBOGIRO' || u == 'POMBO GIRO') return 'POMBO GIRO';
  if (u == 'EXU MIRIM' || u == 'EXÚ MIRIM' || u == 'EXÚ - MIRIM') return 'EXÚ - MIRIM';
  if (u == 'ERÊS' || u == 'ERES') return 'ERÊS';
  return u;
}

MediumEntidade getEntityOfDay(Gira gira, Medium medium) {
  if (medium.entidades.isEmpty) {
    return const MediumEntidade(entidadeId: '', entidadeNome: 'Sem guia', linha: '', tipo: '', status: '');
  }

  // 1. Prioridade absoluta: Seleção granular no Admin
  final participandoIds = gira.entidadesParticipantes;
  for (var ent in medium.entidades) {
    if (participandoIds.contains(ent.entidadeId)) {
      return ent;
    }
  }

  // 2. Segunda prioridade: Guia compatível com a linha da Gira
  final giraLineNorm = normalizeSpiritualLine(gira.linha);
  final allowedLines = LINE_GROUPS[giraLineNorm] ?? [giraLineNorm];
  final allowedLinesNorm = allowedLines.map((l) => normalizeSpiritualLine(l)).toList();

  for (var ent in medium.entidades) {
    if (ent.status == 'ativo') {
      final entLinha = normalizeSpiritualLine(ent.linha);
      final entTipo = normalizeSpiritualLine(ent.tipo);
      if (allowedLinesNorm.contains(entLinha) || allowedLinesNorm.contains(entTipo)) {
        return ent;
      }
    }
  }

  // 3. Fallback final: Primeiro guia ativo
  return medium.entidades.firstWhere((e) => e.status == 'ativo', orElse: () => medium.entidades.first);
}

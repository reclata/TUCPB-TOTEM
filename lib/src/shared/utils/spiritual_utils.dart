import 'package:terreiro_queue_system/src/shared/models/models.dart';

const Map<String, List<String>> GIRA_THEME_MAPPING = {
  'Gira de Caboclo': ['CABOCLO', 'CABOCLA'],
  'Gira de Esquerda': ['EXÚ', 'POMBA GIRA', 'POMBO GIRO', 'EXÚ - MIRIM', 'EXÚ - MIRIM MENINO', 'EXÚ - MIRIM MENINA', 'FEITICEIRO', 'FEITICEIRA'],
  'Gira de Boiadeiro': ['BOIADEIRO', 'VAQUEIRO', 'MARINHEIRO', 'MALANDRO', 'MALANDRA', 'CAPOEIRA'],
  'Gira de Preto Velho': ['PRETO VELHO', 'PRETA VELHA'],
  'Gira de Erês': ['ERÊ', 'ERÊ MENINO', 'ERÊ MENINA', 'CRIANÇA', 'MENINO', 'MENINA'],
  'Gira de Baiano': ['BAIANO', 'BAIANA'],
  'Gira de Cigano': ['CIGANO', 'CIGANA'],
  'Gira de Feiticeiro': ['FEITICEIRO', 'FEITICEIRA'],
};

const Map<String, List<String>> LINE_GROUPS = {
  'PRETO VELHO': ['PRETO VELHO', 'PRETA VELHA'],
  'CABOCLO': ['CABOCLO', 'CABOCLA'],
  'ESQUERDA': ['EXÚ', 'POMBA GIRA', 'POMBO GIRO', 'EXÚ - MIRIM'],
  'ERÊS': ['ERÊS'],
  'BAIANO': ['BAIANO', 'BAIANA'],
  'BOIADEIRO': ['BOIADEIRO', 'VAQUEIRO'],
  'CIGANO': ['CIGANO', 'CIGANA'],
  'FEITICEIRO': ['FEITICEIRO', 'FEITICEIRA'],
};

const List<String> ALLOWED_TABLET_USERS = [
  'THÁBATA',
  'THABATA',
  'THAYENI',
  'THAYNI',
  'SANDRA',
  'EDUARDO',
  'ROBSON',
  'JUCINEIDE',
  'JUINEIDE',
  'PEDRO',
  'DENIS ALBERTO',
  'LUCIANO',
];

String normalizeSpiritualLine(String? s) {
  if (s == null || s.trim().isEmpty) return '';
  final u = s.toUpperCase().trim()
    .replaceAll(' ', '')
    .replaceAll('-', '')
    .replaceAll('Ó', 'O')
    .replaceAll('Ú', 'U')
    .replaceAll('Ê', 'E')
    .replaceAll('Á', 'A')
    .replaceAll('Í', 'I');

  if (u.contains('PRETOVELHO') || u.contains('PRETOVELHA') || u.contains('PRETOSVELHOS') || u.contains('PRETAVELHA')) return 'PRETO VELHO';
  if (u.contains('CABOCLO') || u.contains('CABOCLA')) return 'CABOCLO';
  if (u.contains('EXU') || u.contains('POMBAGIRA') || u.contains('POMBOGIRO')) return 'EXÚ';
  if (u.contains('ERE') || u.contains('CRIANCA')) return 'ERÊS';
  if (u.contains('BAIANO') || u.contains('BAIANA')) return 'BAIANO';
  if (u.contains('BOIADEIRO') || u.contains('VAQUEIRO')) return 'BOIADEIRO';
  if (u.contains('MARINHEIRO')) return 'MARINHEIRO';
  if (u.contains('MALANDRO') || u.contains('MALANDRA')) return 'MALANDRO';
  if (u.contains('CIGANO') || u.contains('CIGANA')) return 'CIGANO';
  if (u.contains('FEITICEIRO') || u.contains('FEITICEIRA')) return 'FEITICEIRO';
  
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
String getMajorLine(String? line) {
  final norm = normalizeSpiritualLine(line);
  if (norm == 'PRETO VELHO' || norm == 'PRETA VELHA') return 'PRETO VELHO';
  if (norm == 'CABOCLO') return 'CABOCLO';
  if (norm == 'EXÚ' || norm == 'POMBA GIRA' || norm == 'POMBO GIRO' || norm == 'EXÚ - MIRIM') return 'ESQUERDA';
  if (norm == 'ERÊS') return 'ERÊS';
  if (norm == 'BAIANO') return 'BAIANO';
  if (norm == 'BOIADEIRO') return 'BOIADEIRO';
  if (norm == 'MARINHEIRO') return 'MARINHEIRO';
  if (norm == 'MALANDRO') return 'MALANDRO';
  if (norm == 'CIGANO') return 'CIGANO';
  if (norm == 'FEITICEIRO') return 'FEITICEIRO';
  return norm;
}

bool isCompatibleWithGroup(String? entityLine, String? entityType, String groupName) {
  final group = LINE_GROUPS[groupName.toUpperCase()] ?? [groupName.toUpperCase()];
  final entLinhaNorm = normalizeSpiritualLine(entityLine);
  final entTipoNorm = normalizeSpiritualLine(entityType);
  
  return group.contains(entLinhaNorm) || group.contains(entTipoNorm);
}
String formatMediumName(String? name) {
  if (name == null || name.trim().isEmpty) return '';
  final nameTrimmed = name.trim();
  final lower = nameTrimmed.toLowerCase();
  
  if (lower.contains('greco')) {
    print('[DEBUG-NAME] Formatando: "$name" -> Encontrou "greco"');
  }

  // Exceções específicas solicitadas
  if (lower.contains('greco') && (lower.contains('maria') || lower.contains('elcidia') || lower.contains('elcídia'))) return 'Elcídia Greco';
  if (lower.contains('silvania paula') || lower.contains('paula duran') || lower.contains('silvania duran')) return 'Paula Duran';
  if (lower.contains('vitoria souza') || lower.contains('vitoria sousa') || lower.contains('maria vitória') || lower.contains('maria vitoria') || lower.contains('maria souza')) {
    return 'Vitória Souza';
  }

  final parts = nameTrimmed.split(' ').where((s) => s.isNotEmpty).toList();
  if (parts.length >= 2) {
    return '${parts.first} ${parts.last}';
  }
  return nameTrimmed;
}

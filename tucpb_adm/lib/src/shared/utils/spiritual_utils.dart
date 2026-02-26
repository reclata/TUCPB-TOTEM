
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

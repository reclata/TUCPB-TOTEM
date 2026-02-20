import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CadastroFormData extends ChangeNotifier {
  // Aba 1: Perfil
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController emailController = TextEditingController(); // Login field
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController senhaController = TextEditingController(text: "TUCPB");
  String perfilAcesso = "Medium";
  bool ativo = true;
  final TextEditingController observacaoController = TextEditingController();
  String? fotoUrl; // URL da foto após upload

  // Aba 2: Pessoal
  final TextEditingController dtNascimentoController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController cepController = TextEditingController();
  final TextEditingController ruaController = TextEditingController();
  final TextEditingController numeroController = TextEditingController();
  final TextEditingController complementoController = TextEditingController();
  final TextEditingController bairroController = TextEditingController();
  final TextEditingController cidadeController = TextEditingController();
  String estadoCivil = "Solteiro";
  bool temFilhos = false;
  int qtdFilhos = 1;
  List<TextEditingController> nomesFilhosControllers = [];
  bool restricaoSaude = false;
  final TextEditingController qualRestricaoController = TextEditingController();
  bool alergias = false;
  final TextEditingController quaisAlergiasController = TextEditingController();
  final TextEditingController contatoEmergenciaNome = TextEditingController();
  final TextEditingController contatoEmergenciaParentesco = TextEditingController();
  final TextEditingController contatoEmergenciaTel = TextEditingController();

  // Aba 3: Imagem
  final Map<String, bool> usoImagem = {
    "Redes Sociais": false,
    "Materiais Institucionais": false,
    "Site Institucional": false,
    "Apresentações Internas": false,
    "Não Autorizo": false,
  };

  // Aba 4: Espiritual
  final List<String> paisCabecaPai = [];
  final List<String> paisCabecaMae = [];
  final TextEditingController entradaTerreiroController = TextEditingController();
  final List<ObrigacaoItem> obrigacoes = [];
  bool batizadoCatolica = false;
  bool batizadoTucpb = false;
  final TextEditingController dataBatismoController = TextEditingController();
  final TextEditingController padrinhoBatismoController = TextEditingController();
  final TextEditingController madrinhaBatismoController = TextEditingController();
  bool crismadoTucpb = false;
  final TextEditingController dataCrismaController = TextEditingController();
  final TextEditingController padrinhoCrismaController = TextEditingController();
  final TextEditingController madrinhaCrismaController = TextEditingController();

  // Aba 5: Entidades
  final List<EntidadeItem> entidades = [];

  // Logic
  bool get isAssistencia => perfilAcesso == "Assistencia";
  bool get imageAuthDenied => usoImagem["Não Autorizo"] == true;

  void updatePerfil(String val) {
    perfilAcesso = val;
    notifyListeners();
  }

  void updateFilhos(bool val) {
     temFilhos = val;
     if (!val) {
       nomesFilhosControllers.clear();
       qtdFilhos = 1;
     } else {
       if (nomesFilhosControllers.isEmpty) _adjustFilhosCount(1);
     }
     notifyListeners();
  }

  void setQtdFilhos(int val) {
    qtdFilhos = val;
    _adjustFilhosCount(val);
    notifyListeners();
  }

  void _adjustFilhosCount(int count) {
    while (nomesFilhosControllers.length < count) {
      nomesFilhosControllers.add(TextEditingController());
    }
    while (nomesFilhosControllers.length > count) {
      nomesFilhosControllers.removeLast();
    }
  }

  void toggleImagemAuth(String key) {
    if (key == "Não Autorizo") {
      usoImagem["Não Autorizo"] = !usoImagem["Não Autorizo"]!;
      if (usoImagem["Não Autorizo"]!) {
        // Desmarcar outros?
        usoImagem.forEach((k, v) { if (k != "Não Autorizo") usoImagem[k] = false; });
      }
    } else {
      usoImagem[key] = !usoImagem[key]!;
      if (usoImagem[key]!) {
        usoImagem["Não Autorizo"] = false;
      }
    }
    notifyListeners();
  }

  void togglePaiHeader(String nome, bool isPai) {
    final list = isPai ? paisCabecaPai : paisCabecaMae;
    if (list.contains(nome)) {
      list.remove(nome);
    } else {
      list.add(nome);
    }
    notifyListeners();
  }

  void addObrigacao() {
    obrigacoes.add(ObrigacaoItem());
    notifyListeners();
  }

  void removeObrigacao(int index) {
    obrigacoes.removeAt(index);
    notifyListeners();
  }

  void addEntidade() {
    entidades.add(EntidadeItem());
    notifyListeners();
  }
  
  void removeEntidade(int index) {
      entidades.removeAt(index);
      notifyListeners();
  }

  Map<String, dynamic> toMap() {
    return {
      // Perfil
      'nome': nomeController.text,
      'email': emailController.text,
      'telefone': telefoneController.text,
      'perfil': perfilAcesso,
      'ativo': ativo,
      'senhaInicial': senhaController.text,
      if (fotoUrl != null) 'fotoUrl': fotoUrl!,
      
      // Pessoal
      if (!isAssistencia) ...{
        'dadosPessoais': {
            'dtNascimento': dtNascimentoController.text,
            'cpf': cpfController.text,
            'endereco': {
                'cep': cepController.text,
                'rua': ruaController.text,
                'numero': numeroController.text,
                'bairro': bairroController.text,
                'cidade': cidadeController.text,
            },
            'estadoCivil': estadoCivil,
            'filhos': temFilhos ? nomesFilhosControllers.map((e) => e.text).toList() : [],
            'restricoes': restricaoSaude ? qualRestricaoController.text : null,
            'alergias': alergias ? quaisAlergiasController.text : null,
            'emergencia': {
                'nome': contatoEmergenciaNome.text,
                'parentesco': contatoEmergenciaParentesco.text,
                'telefone': contatoEmergenciaTel.text,
            }
        },
      },
      
      // Imagem
      'usoImagem': usoImagem,
      
      // Espiritual
      'espiritual': {
          'pais': paisCabecaPai,
          'maes': paisCabecaMae,
          'entrada': entradaTerreiroController.text,
          'obrigacoes': obrigacoes.map((e) => {'tipo': e.tipo, 'data': e.dataController.text}).toList(),
          'batizadoCatolica': batizadoCatolica,
          'batizadoTucpb': batizadoTucpb ? {
              'data': dataBatismoController.text,
              'padrinho': padrinhoBatismoController.text,
              'madrinha': madrinhaBatismoController.text,
          } : null,
          'crismadoTucpb': crismadoTucpb ? {
              'data': dataCrismaController.text,
              'padrinho': padrinhoCrismaController.text,
              'madrinha': madrinhaCrismaController.text,
          } : null,
      },
      
      // Entidades
      'entidades': entidades.map((e) => {'linha': e.linha, 'tipo': e.tipo, 'nome': e.nomeController.text}).toList(),
      
      'observacao': observacaoController.text,
      'dataCriacao': FieldValue.serverTimestamp(),
    };
  }

  void fromMap(Map<String, dynamic> map) {
    nomeController.text = map['nome'] ?? '';
    emailController.text = map['email'] ?? '';
    telefoneController.text = map['telefone'] ?? '';
    perfilAcesso = map['perfil'] ?? 'Medium';
    ativo = map['ativo'] ?? true;
    fotoUrl = map['fotoUrl'];
    observacaoController.text = map['observacao'] ?? '';

    final dp = map['dadosPessoais'] as Map<String, dynamic>?;
    if (dp != null) {
      dtNascimentoController.text = dp['dtNascimento'] ?? '';
      cpfController.text = dp['cpf'] ?? '';
      estadoCivil = dp['estadoCivil'] ?? 'Solteiro';
      final filhos = dp['filhos'] as List<dynamic>?;
      if (filhos != null && filhos.isNotEmpty) {
        temFilhos = true;
        qtdFilhos = filhos.length;
        _adjustFilhosCount(qtdFilhos);
        for (int i = 0; i < filhos.length; i++) {
          nomesFilhosControllers[i].text = filhos[i];
        }
      }
      final end = dp['endereco'] as Map<String, dynamic>?;
      if (end != null) {
        cepController.text = end['cep'] ?? '';
        ruaController.text = end['rua'] ?? '';
        numeroController.text = end['numero'] ?? '';
        bairroController.text = end['bairro'] ?? '';
        cidadeController.text = end['cidade'] ?? '';
      }
      restricaoSaude = dp['restricoes'] != null;
      qualRestricaoController.text = dp['restricoes'] ?? '';
      alergias = dp['alergias'] != null;
      quaisAlergiasController.text = dp['alergias'] ?? '';
      final em = dp['emergencia'] as Map<String, dynamic>?;
      if (em != null) {
        contatoEmergenciaNome.text = em['nome'] ?? '';
        contatoEmergenciaParentesco.text = em['parentesco'] ?? '';
        contatoEmergenciaTel.text = em['telefone'] ?? '';
      }
    }

    final ui = map['usoImagem'] as Map<String, dynamic>?;
    if (ui != null) {
      ui.forEach((k, v) => usoImagem[k] = v);
    }

    final esp = map['espiritual'] as Map<String, dynamic>?;
    if (esp != null) {
      paisCabecaPai.clear();
      paisCabecaPai.addAll(List<String>.from(esp['pais'] ?? []));
      paisCabecaMae.clear();
      paisCabecaMae.addAll(List<String>.from(esp['maes'] ?? []));
      entradaTerreiroController.text = esp['entrada'] ?? '';
      
      obrigacoes.clear();
      final obs = esp['obrigacoes'] as List<dynamic>?;
      if (obs != null) {
        for (final o in obs) {
          final item = ObrigacaoItem();
          item.tipo = o['tipo'] ?? 'Macifi';
          item.dataController.text = o['data'] ?? '';
          obrigacoes.add(item);
        }
      }

      batizadoCatolica = esp['batizadoCatolica'] ?? false;
      final bt = esp['batizadoTucpb'] as Map<String, dynamic>?;
      if (bt != null) {
        batizadoTucpb = true;
        dataBatismoController.text = bt['data'] ?? '';
        padrinhoBatismoController.text = bt['padrinho'] ?? '';
        madrinhaBatismoController.text = bt['madrinha'] ?? '';
      }
      final ct = esp['crismadoTucpb'] as Map<String, dynamic>?;
      if (ct != null) {
        crismadoTucpb = true;
        dataCrismaController.text = ct['data'] ?? '';
        padrinhoCrismaController.text = ct['padrinho'] ?? '';
        madrinhaCrismaController.text = ct['madrinha'] ?? '';
      }
    }

    final ents = map['ententities'] as List<dynamic>? ?? map['entidades'] as List<dynamic>?;
    if (ents != null) {
      entidades.clear();
      for (final e in ents) {
        final item = EntidadeItem();
        item.linha = e['linha'] ?? 'CABOCLO';
        item.tipo = e['tipo'] ?? 'CABOCLO';
        item.nomeController.text = e['nome'] ?? '';
        entidades.add(item);
      }
    }

    notifyListeners();
  }
  
  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    nomesFilhosControllers.forEach((c) => c.dispose());
    obrigacoes.forEach((o) => o.dataController.dispose());
    entidades.forEach((e) => e.nomeController.dispose());
    super.dispose();
  }
}

class ObrigacaoItem {
  String tipo = "Macifi";
  final TextEditingController dataController = TextEditingController();
}

class EntidadeItem {
  String linha = "CABOCLO";
  String tipo = "CABOCLO";
  final TextEditingController nomeController = TextEditingController();
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terreiro_queue_system/src/shared/models/models.dart';
import 'package:terreiro_queue_system/src/shared/utils/spiritual_utils.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository(FirebaseFirestore.instance));

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository(this._firestore);

  // --- Gira Management ---
  Future<void> createGira(Gira gira) async {
    final Map<String, bool> finalPresencas = Map.from(gira.presencas);

    // Se não houver presenças pré-selecionadas (ex: via UI), tenta preencher automaticamente
    if (finalPresencas.isEmpty) {
      final mediumsSnap = await _firestore.collection('usuarios')
          .where('ativo', isEqualTo: true)
          .get();

      final allowedLinesNorm = (LINE_GROUPS[normalizeSpiritualLine(gira.linha)] ?? [normalizeSpiritualLine(gira.linha)])
          .map((l) => normalizeSpiritualLine(l)).toList();

      for (var doc in mediumsSnap.docs) {
        final data = doc.data();
        final entidades = (data['entidades'] as List?) ?? <dynamic>[];
        final hasCompatibleEntity = entidades.any((e) {
          final entLinha = normalizeSpiritualLine(e['linha'] ?? '');
          final entTipo = normalizeSpiritualLine(e['tipo'] ?? '');
          return allowedLinesNorm.contains(entLinha) || allowedLinesNorm.contains(entTipo);
        });
        
        if (hasCompatibleEntity) {
          finalPresencas[doc.id] = true;
        }
      }
    }

    final giraData = gira.toJson();
    giraData['presencas'] = finalPresencas;
    
    await _firestore.collection('giras').doc(gira.id).set(giraData);
  }

  Future<void> updateGiraPresence(String giraId, Map<String, bool> presencas) async {
    await _firestore.collection('giras').doc(giraId).update({'presencas': presencas});
  }

  Future<void> updateGira(Gira gira) async {
    await _firestore.collection('giras').doc(gira.id).update(gira.toJson());
  }

  Future<void> deleteGira(String giraId) async {
    await _firestore.collection('giras').doc(giraId).delete();
  }

  Future<void> closeGira(String giraId) async {
    await _firestore.collection('giras').doc(giraId).update({'status': 'encerrada'});
  }

  Future<void> openGira(String giraId) async {
    await _firestore.collection('giras').doc(giraId).update({'status': 'aberta'});
  }

  Stream<List<Gira>> streamGiras(String terreiroId) {
    return _firestore
        .collection('giras')
        // Removido filtro de terreiroId para compatibilidade com tucpb_adm
        .orderBy('data', descending: true)
        .snapshots()
        .map((snap) {
          final List<Gira> result = [];
          for (final doc in snap.docs) {
            try {
              final rawData = doc.data();
              if (rawData == null) continue;
              final data = Map<String, dynamic>.from(rawData);
              
              data['id'] = doc.id;
              // Compatibilidade: campo 'nome' do tucpb_adm -> 'tema' do Totem
              data['tema'] = (data['tema'] ?? data['nome'] ?? '').toString();
              // Compatibilidade: 'linha' pode não existir no tucpb_adm
              data['linha'] = (data['linha'] ?? '').toString();
              // Compatibilidade: 'horarioInicio' pode vir como vazio
              data['horarioInicio'] = (data['horarioInicio'] ?? data['horarioFim'] ?? '').toString();
              // Compatibilidade: 'horarioKiosk' pode não existir
              data['horarioKiosk'] = (data['horarioKiosk'] ?? '').toString();
              // Compatibilidade: 'encerramentoKioskAtivo' pode não existir ou vir como outro tipo
              data['encerramentoKioskAtivo'] = data['encerramentoKioskAtivo'] == true;
              
              // Explicit type conversion for Lists (String only)
              final List rawMediums = (data['mediumsParticipantes'] ?? data['mediums_participantes'] ?? <dynamic>[]) as List;
              data['mediumsParticipantes'] = rawMediums.map((e) => e.toString()).toList();
              
              final List rawEntidadesPart = (data['entidadesParticipantes'] ?? data['entidades_participantes'] ?? <dynamic>[]) as List;
              data['entidadesParticipantes'] = rawEntidadesPart.map((e) => e.toString()).toList();
              
              final List rawLinhasPart = (data['linhasParticipantes'] ?? data['linhas_participantes'] ?? <dynamic>[]) as List;
              data['linhasParticipantes'] = rawLinhasPart.map((e) => e.toString()).toList();
              
              // Explicit type conversion for Map (String -> bool)
              final rawPresencas = data['presencas'] ?? data['presences'] ?? {};
              final Map<String, bool> presencasMap = {};
              if (rawPresencas is Map) {
                rawPresencas.forEach((k, v) {
                  presencasMap[k.toString()] = v == true;
                });
              }
              data['presencas'] = presencasMap;
              
              // Compatibilidade: 'status' pode não existir (tucpb_adm usa 'ativo')
              if (!data.containsKey('status') || data['status'] == null) {
                data['status'] = (data['ativo'] == true) ? 'aberta' : 'agendada';
              }
              result.add(Gira.fromJson(data));
            } catch (e) {
              debugPrint('[KIOSK_DEBUG] Erro ao parsear Gira ${doc.id}: $e');
            }
          }
          return result;
        });
    }


  // --- Entity Management ---
  Future<void> addEntity(Entidade entity) async {
    await _firestore.collection('entidades').doc(entity.id).set(entity.toJson());
  }

  Future<void> updateEntity(Entidade entity) async {
    await _firestore.collection('entidades').doc(entity.id).update(entity.toJson());
  }

  Future<void> deleteEntity(String entityId) async {
    await _firestore.collection('entidades').doc(entityId).delete();
  }

  Stream<List<Entidade>> streamEntities(String terreiroId) {
    return _firestore
        .collection('entidades')
        .snapshots()
        .map((snap) {
          final List<Entidade> result = [];
          for (final doc in snap.docs) {
            try {
              final rawData = doc.data();
              if (rawData == null) continue;
              final data = Map<String, dynamic>.from(rawData as Map);
              data['id'] = doc.id;
              
              // Robustness for missing fields
              data['terreiroId'] = (data['terreiroId'] ?? '').toString();
              data['nome'] = (data['nome'] ?? '').toString();
              data['linha'] = (data['linha'] ?? '').toString();
              data['tipo'] = (data['tipo'] ?? '').toString();
              
              result.add(Entidade.fromJson(data));
            } catch (e) {
              debugPrint('[KIOSK_DEBUG] Erro ao parsear Entidade ${doc.id}: $e');
            }
          }
          return result;
        });
    }

  // --- Medium Management ---
  Future<void> addMedium(Medium medium) async {
    // Save the medium
    final data = medium.toJson();
    data['entidades'] = medium.entidades.map((e) => e.toJson()).toList();
    await _firestore.collection('usuarios').doc(medium.id).set(data);
    
    // Auto-create entities that don't exist yet
    for (var medEnt in medium.entidades) {
      final entDoc = await _firestore.collection('entidades').doc(medEnt.entidadeId).get();
      if (!entDoc.exists) {
        await _firestore.collection('entidades').doc(medEnt.entidadeId).set({
          'id': medEnt.entidadeId,
          'terreiroId': medium.terreiroId,
          'nome': medEnt.entidadeNome,
          'linha': medEnt.linha,
          'tipo': medEnt.tipo,
        });
      }
    }
  }

  Future<void> updateMedium(Medium medium) async {
    // Update the medium
    final data = medium.toJson();
    data['entidades'] = medium.entidades.map((e) => e.toJson()).toList();
    await _firestore.collection('usuarios').doc(medium.id).update(data);
    
    // Auto-create new entities
    for (var medEnt in medium.entidades) {
      final entDoc = await _firestore.collection('entidades').doc(medEnt.entidadeId).get();
      if (!entDoc.exists) {
        await _firestore.collection('entidades').doc(medEnt.entidadeId).set({
          'id': medEnt.entidadeId,
          'terreiroId': medium.terreiroId,
          'nome': medEnt.entidadeNome,
          'linha': medEnt.linha,
          'tipo': medEnt.tipo,
        });
      }
    }
  }

  Future<void> deleteMedium(String mediumId) async {
    await _firestore.collection('usuarios').doc(mediumId).delete();
  }

  Stream<List<Medium>> streamMediums(String terreiroId) {
    return _firestore
        .collection('usuarios')
        .snapshots()
        .map((snap) {
          final List<Medium> result = [];
          for (final doc in snap.docs) {
            try {
              final rawData = doc.data();
              if (rawData == null) continue;
              final data = Map<String, dynamic>.from(rawData);
              
              data['id'] = doc.id;
              // Compatibilidade: campo 'nome' pode não existir
              data['nome'] = (data['nome'] ?? data['nomeCompleto'] ?? '').toString();
              // Compatibilidade: campo 'ativo' pode não existir (padrão: true)
              data['ativo'] = data['ativo'] ?? true;
              // Compatibilidade: 'cargo' pode não existir
              data['cargo'] = (data['cargo'] ?? '').toString();
              // Compatibilidade: 'fotoUrl' pode não existir
              data['fotoUrl'] = (data['fotoUrl'] ?? '').toString();
              // Compatibilidade: 'ultimaGira' pode não existir
              data['ultimaGira'] = (data['ultimaGira'] ?? '').toString();
              
              // Compatibilidade: 'entidades' pode não existir
              final rawEntidades = data['entidades'] ?? <dynamic>[];
              final List<Map<String, dynamic>> entidadesList = [];
              if (rawEntidades is List) {
                for (final e in rawEntidades) {
                  final entMap = Map<String, dynamic>.from(e is Map ? e : {});
                  // 'entidadeId' pode não existir no tucpb_adm
                  entMap['entidadeId'] = (entMap['entidadeId'] ?? entMap['id'] ?? '').toString();
                  // 'status' pode não existir — padrão: 'ativo'
                  entMap['status'] = (entMap['status'] ?? 'ativo').toString();
                  entMap['linha'] = (entMap['linha'] ?? '').toString();
                  entMap['tipo'] = (entMap['tipo'] ?? '').toString();
                  entMap['nome'] = (entMap['nome'] ?? entMap['entidadeNome'] ?? '').toString();
                  entidadesList.add(entMap);
                }
              }
              data['entidades'] = entidadesList;
              result.add(Medium.fromJson(data));
            } catch (e) {
              debugPrint('[KIOSK_DEBUG] Erro ao parsear Medium ${doc.id}: $e');
            }
          }
          return result;
        });
    }
  
  // Toggle Medium Status (Active/Inactive for today's Gira)
  Future<void> toggleMediumStatus(String mediumId, bool isActive) async {
    await _firestore.collection('usuarios').doc(mediumId).update({'ativo': isActive});
  }

  // --- Usuario Management ---
  Future<void> addUsuario(Usuario usuario) async {
    await _firestore.collection('usuarios').doc(usuario.id).set(usuario.toJson());
  }

  Future<void> updateUsuario(Usuario usuario) async {
    await _firestore.collection('usuarios').doc(usuario.id).update(usuario.toJson());
  }

  Future<void> deleteUsuario(String usuarioId) async {
    await _firestore.collection('usuarios').doc(usuarioId).delete();
  }

  Stream<List<Usuario>> streamUsuarios(String terreiroId) {
    return _firestore
        .collection('usuarios')
        .snapshots()
        .map((snap) {
          final List<Usuario> result = [];
          for (final doc in snap.docs) {
            try {
              final rawData = doc.data();
              if (rawData == null) continue;
              final data = Map<String, dynamic>.from(rawData as Map);
              data['id'] = doc.id;
              
              // Map tucpb_adm fields to Usuario model
              data['nomeCompleto'] = (data['nomeCompleto'] ?? data['nome'] ?? 'Sem nome').toString();
              data['login'] = (data['login'] ?? data['email'] ?? '').toString();
              data['perfilAcesso'] = (data['perfilAcesso'] ?? data['perfil'] ?? 'medium').toString().toLowerCase();
              data['terreiroId'] = (data['terreiroId'] ?? terreiroId).toString();
              data['senha'] = (data['senha'] ?? data['senhaInicial'] ?? '').toString();
              data['permissoes'] = List<String>.from(data['permissoes'] ?? <String>[]);
              data['ativo'] = data['ativo'] ?? true;

              result.add(Usuario.fromJson(data));
            } catch (e) {
              debugPrint('[KIOSK_DEBUG] Erro ao parsear Usuario ${doc.id}: $e');
            }
          }
          return result;
        });
  }

  // --- Ticket Management ---
  Stream<List<Ticket>> streamTickets(String terreiroId) {
    return _firestore
        .collection('tickets')
        .snapshots()
        .map((snap) {
          final List<Ticket> result = [];
          for (final doc in snap.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              
              // Robustness for missing fields
              data['terreiroId'] ??= '';
              data['giraId'] ??= '';
              data['entidadeId'] ??= '';
              data['mediumId'] ??= '';
              data['codigoSenha'] ??= '';
              data['sequencial'] ??= 0;
              data['dataRef'] ??= '';
              data['status'] ??= 'emitida';
              data['ordemFila'] ??= 0;
              data['chamadaCount'] ??= 0;
              data['isRedistributed'] ??= false;
              
              // Handle dataHoraEmissao if missing (shouldn't happen but let's be safe)
              data['dataHoraEmissao'] ??= Timestamp.now();
              
              result.add(Ticket.fromJson(data));
            } catch (e) {
              debugPrint('[KIOSK_DEBUG] Erro ao parsear Ticket ${doc.id}: $e');
            }
          }
          return result;
        });
    }

  // --- Seed Data for Testing ---
  Future<void> generateSeedData(String terreiroId) async {
    // 1. Create some Entities
    final entityNames = [
      'Caboclo das Sete Encruzilhadas',
      'Preto Velho Pai Joaquim',
      'Ere Formiguinha',
      'Baiano Zé do Coco',
      'Marinheiro Capitão Gancho',
      'Pomba Gira Maria Padilha',
      'Exu Caveira',
    ];

    final entities = entityNames.map((name) {
      String linha = 'Caboclo';
      if (name.contains('Preto Velho')) linha = 'Preto Velho';
      if (name.contains('Ere')) linha = 'Erê';
      if (name.contains('Baiano')) linha = 'Baiano';
      if (name.contains('Marinheiro')) linha = 'Marinheiro';
      if (name.contains('Pomba Gira') || name.contains('Exu')) linha = 'Esquerda';

      return Entidade(
        id: name.toLowerCase().replaceAll(' ', '-'),
        terreiroId: terreiroId,
        nome: name,
        linha: linha,
        tipo: linha,
      );
    }).toList();

    for (var e in entities) {
      await addEntity(e);
    }

    // 2. Create some Mediums and link to entities
    final mediumNames = ['João Silva', 'Maria Santos', 'Pedro Oliveira', 'Ana Costa'];
    for (var i = 0; i < mediumNames.length; i++) {
        final mId = 'medium-$i';
        final linkedEntities = [
            MediumEntidade(
                entidadeId: entities[i % entities.length].id,
                entidadeNome: entities[i % entities.length].nome,
                linha: entities[i % entities.length].linha,
                tipo: entities[i % entities.length].tipo,
                status: 'ativo',
            ),
            if (i + 1 < entities.length)
             MediumEntidade(
                entidadeId: entities[(i + 1) % entities.length].id,
                entidadeNome: entities[(i + 1) % entities.length].nome,
                linha: entities[(i + 1) % entities.length].linha,
                tipo: entities[(i + 1) % entities.length].tipo,
                status: 'ativo',
            ),
        ];

        final medium = Medium(
            id: mId,
            terreiroId: terreiroId,
            nome: mediumNames[i],
            ativo: true,
            entidades: linkedEntities,
        );
        await addMedium(medium);
    }

    // 3. Create an active Gira
    final gira = Gira(
        id: 'gira-teste-hoje',
        terreiroId: terreiroId,
        linha: 'Caboclo',
        tema: 'Gira de Teste - Caboclo',
        data: DateTime.now(),
        status: 'aberta',
    );
    await createGira(gira);
  }
}

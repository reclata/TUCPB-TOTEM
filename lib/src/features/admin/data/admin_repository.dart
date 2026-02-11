
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terreiro_queue_system/src/shared/models/models.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository(FirebaseFirestore.instance));

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository(this._firestore);

  // --- Gira Management ---
  Future<void> createGira(Gira gira) async {
    // Buscar médiuns para pré-popular presenças
    final mediumsSnap = await _firestore.collection('mediuns')
        .where('terreiroId', isEqualTo: gira.terreiroId)
        .where('ativo', isEqualTo: true)
        .get();

    final Map<String, bool> initialPresencas = {};
    
    // Grupos de linhagem (replicando a lógica do totem)
    final Map<String, List<String>> lineGroups = {
      'Boiadeiro': ['Boiadeiro', 'Marinheiro', 'Malandro'],
      'Esquerda': ['Esquerda'],
    };
    final allowedLines = lineGroups[gira.linha] ?? [gira.linha];

    for (var doc in mediumsSnap.docs) {
      final data = doc.data();
      final entidades = (data['entidades'] as List?) ?? [];
      final hasCompatibleEntity = entidades.any((e) => allowedLines.contains(e['linha']));
      
      if (hasCompatibleEntity) {
        initialPresencas[doc.id] = true;
      }
    }

    final giraData = gira.toJson();
    giraData['presencas'] = initialPresencas;
    
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
        .where('terreiroId', isEqualTo: terreiroId)
        .orderBy('data', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Gira.fromJson(doc.data())).toList());
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
        .where('terreiroId', isEqualTo: terreiroId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Entidade.fromJson(doc.data())).toList());
  }

  // --- Medium Management ---
  Future<void> addMedium(Medium medium) async {
    // Save the medium
    await _firestore.collection('mediuns').doc(medium.id).set(medium.toJson());
    
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
    await _firestore.collection('mediuns').doc(medium.id).update(medium.toJson());
    
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
    await _firestore.collection('mediuns').doc(mediumId).delete();
  }

  Stream<List<Medium>> streamMediums(String terreiroId) {
    return _firestore
        .collection('mediuns')
        .where('terreiroId', isEqualTo: terreiroId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Medium.fromJson(doc.data())).toList());
  }
  
  // Toggle Medium Status (Active/Inactive for today's Gira)
  Future<void> toggleMediumStatus(String mediumId, bool isActive) async {
    await _firestore.collection('mediuns').doc(mediumId).update({'ativo': isActive});
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
        .where('terreiroId', isEqualTo: terreiroId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Usuario.fromJson(doc.data())).toList());
  }

  // --- Ticket Management ---
  Stream<List<Ticket>> streamTickets(String terreiroId) {
    return _firestore
        .collection('tickets')
        .where('terreiroId', isEqualTo: terreiroId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Ticket.fromJson(doc.data())).toList());
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


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/models.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository(FirebaseFirestore.instance));

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository(this._firestore);

  // --- Gira Management ---
  Future<void> createGira(Gira gira) async {
    await _firestore.collection('giras').doc(gira.id).set(gira.toJson());
  }

  Future<void> closeGira(String giraId) async {
    await _firestore.collection('giras').doc(giraId).update({'status': 'encerrada'});
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
  Future<void> addEntity(Entidade entidade) async {
    await _firestore.collection('entidades').doc(entidade.id).set(entidade.toJson());
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
    await _firestore.collection('mediuns').doc(medium.id).set(medium.toJson());
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
}

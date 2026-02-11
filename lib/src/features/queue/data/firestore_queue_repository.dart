
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terreiro_queue_system/src/shared/models/models.dart';

final queueRepositoryProvider = Provider((ref) => FirestoreQueueRepository(FirebaseFirestore.instance));

class FirestoreQueueRepository {
  final FirebaseFirestore _firestore;

  FirestoreQueueRepository(this._firestore);

  // Stream tickets for a specific Gira and Entity, ordered by 'ordemFila'
  Stream<List<Ticket>> streamQueue(String giraId, String entidadeId) {
    return _firestore
        .collection('tickets')
        .where('giraId', isEqualTo: giraId)
        .where('entidadeId', isEqualTo: entidadeId)
        .where('status', whereIn: ['emitida', 'chamada']) // Only active ones
        .orderBy('ordemFila', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Ticket.fromJson(doc.data()))
            .toList());
  }

  Future<Ticket> issueTicket({
    required String terreiroId,
    required String giraId,
    required String entidadeId,
    required Medium medium,
  }) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    
    try {
      debugPrint("DEBUG: Issuing real ticket for entity: $entidadeId");
      
      // 1. Get Current Sequence for Medium
      final counterRef = _firestore.collection('counters').doc('${medium.id}_$today');
      final counterSnap = await counterRef.get();
      int nextSeq = 1;
      if (counterSnap.exists) {
        nextSeq = (counterSnap.data()?['seq'] as int? ?? 0) + 1;
      }

      // 2. Get Current Queue Order for Entity
      final queueRef = _firestore.collection('queue_counters').doc('${entidadeId}_$today');
      final queueSnap = await queueRef.get();
      int nextOrder = 1;
      if (queueSnap.exists) {
        nextOrder = (queueSnap.data()?['order'] as int? ?? 0) + 1;
      }

      // 3. Generate initials (3 letters if possible)
      String initials;
      final parts = medium.nome.split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 3) {
        initials = (parts[0][0] + parts[1][0] + parts[2][0]).toUpperCase();
      } else if (parts.length == 2) {
        initials = (parts[0].substring(0, parts[0].length >= 2 ? 2 : 1) + parts[1][0]).toUpperCase();
      } else if (parts.isNotEmpty) {
        initials = parts[0].substring(0, parts[0].length >= 3 ? 3 : parts[0].length).toUpperCase();
      } else {
        initials = 'MED';
      }
      
      final code = '$initials${nextSeq.toString().padLeft(3, '0')}';
      final newTicketRef = _firestore.collection('tickets').doc();
      
      final ticket = Ticket(
        id: newTicketRef.id,
        terreiroId: terreiroId,
        giraId: giraId,
        entidadeId: entidadeId,
        mediumId: medium.id,
        codigoSenha: code,
        sequencial: nextSeq,
        dataRef: today,
        status: 'emitida',
        ordemFila: nextOrder,
        dataHoraEmissao: DateTime.now(),
        chamadaCount: 0,
      );

      // Perform all writes in a batch for atomic-like behavior on Web
      final batch = _firestore.batch();
      batch.set(newTicketRef, ticket.toJson());
      batch.set(counterRef, {'seq': nextSeq}, SetOptions(merge: true));
      batch.set(queueRef, {'order': nextOrder}, SetOptions(merge: true));
      
      await batch.commit();
      
      debugPrint("DEBUG: Ticket $code saved successfully via Batch");
      return ticket;
    } catch (e, stack) {
      debugPrint("DEBUG SAVE ERROR: $e");
      debugPrint("DEBUG STACK: $stack");
      rethrow;
    }
  }

  // Call next ticket
  Future<void> callTicket(String ticketId) async {
    await _firestore.collection('tickets').doc(ticketId).update({
      'status': 'chamada',
      'dataHoraChamada': FieldValue.serverTimestamp(),
      'chamadaCount': FieldValue.increment(1),
    });
  }

  // Mark as attended
  Future<void> markAttended(String ticketId) async {
    await _firestore.collection('tickets').doc(ticketId).update({
      'status': 'atendida',
      'dataHoraAtendida': FieldValue.serverTimestamp(),
    });
  }

  // Mark as absent (Re-queue to end)
  Future<void> markAbsentAndRequeue(String ticketId, String entityId) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    
    await _firestore.runTransaction((transaction) async {
       // Get new max order
       final queueRef = _firestore.collection('queue_counters').doc('${entityId}_$today');
       final queueSnap = await transaction.get(queueRef);
       
       int nextOrder = 1;
         if (queueSnap.exists) {
         nextOrder = (queueSnap.data()!['order'] as int) + 1;
         transaction.update(queueRef, {'order': nextOrder});
       } else {
         transaction.set(queueRef, {'order': nextOrder});
       }

       // Update ticket
       final ticketRef = _firestore.collection('tickets').doc(ticketId);
       transaction.update(ticketRef, {
         'status': 'emitida', // Back to queue
         'ordemFila': nextOrder, // Moved to end
         // effectively "nao_compareceu" logic handled by moving it. 
         // Could add a log field here if needed.
       });
    });
  }
}

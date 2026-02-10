
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Issue a new ticket
  Future<Ticket> issueTicket({
    required String terreiroId,
    required String giraId,
    required String entidadeId,
    required Medium medium,
  }) async {
    final today = DateTime.now().toIso8601String().split('T').first; // YYYY-MM-DD
    
    // Transaction to ensure sequential integrity
    return _firestore.runTransaction((transaction) async {
       // Get strict sequence from a counter document
       final counterRef = _firestore.collection('counters').doc('${medium.id}_$today');
       final counterSnap = await transaction.get(counterRef);
       
       int nextSeq = 1;
       if (counterSnap.exists) {
         nextSeq = (counterSnap.data()!['seq'] as int) + 1;
         transaction.update(counterRef, {'seq': nextSeq});
       } else {
         transaction.set(counterRef, {'seq': nextSeq});
       }

       // Get current max queue order for global queue appending
       // This might be expensive if many docs, but usually manageable per day/entity
       // Alternatively keep a 'queue_tail' counter per entity
       final queueRef = _firestore.collection('queue_counters').doc('${entidadeId}_$today');
       final queueSnap = await transaction.get(queueRef);
       int nextOrder = 1;
       if (queueSnap.exists) {
         nextOrder = (queueSnap.data()!['order'] as int) + 1;
         transaction.update(queueRef, {'order': nextOrder});
       } else {
         transaction.set(queueRef, {'order': nextOrder});
       }

        // Generate initials from medium name (3 letters)
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
        
        final code = '$initials${nextSeq.toString().padLeft(4, '0')}';
       
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
       
       transaction.set(newTicketRef, ticket.toJson());
       return ticket;
    });
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

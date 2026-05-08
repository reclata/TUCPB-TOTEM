import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:terreiro_queue_system/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('--- CHECKING DATA ---');
  
  try {
    final giras = await FirebaseFirestore.instance.collection('giras').get();
    print('Giras found: ${giras.docs.length}');
    for (final doc in giras.docs) {
      print('- Gira: ${doc.id} | Status: ${doc.data()['status']}');
    }
  } catch (e) {
    print('Error loading giras: $e');
  }

  try {
    final tickets = await FirebaseFirestore.instance.collection('tickets').get();
    print('Tickets found: ${tickets.docs.length}');
    for (final doc in tickets.docs) {
      print('- Ticket: ${doc.id} | Gira: ${doc.data()['giraId']}');
    }
  } catch (e) {
    print('Error loading tickets: $e');
  }
  
  print('---------------------');
}

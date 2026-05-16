import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:terreiro_queue_system/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('--- LISTANDO MÉDIUNS NO BANCO ---');
  
  try {
    final snap = await FirebaseFirestore.instance.collection('mediums').get();
    print('Total de médiuns encontrados: ${snap.docs.length}');
    for (final doc in snap.docs) {
      print('- ID: ${doc.id} | Nome: "${doc.data()['nome']}" | MaxFichas: ${doc.data()['maxFichas']}');
    }
  } catch (e) {
    print('❌ Erro ao listar médiuns: $e');
  }
  
  print('---------------------');
}

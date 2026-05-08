import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:terreiro_queue_system/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('--- FORÇANDO TV PARA O CARROSSEL ---');
  try {
    await FirebaseFirestore.instance
        .collection('tvPanels')
        .doc('tv-painel-1')
        .update({'senhaAtual': null});
    print('✅ TV Resetada com sucesso (senhaAtual definida como null).');
  } catch (e) {
    print('❌ Erro ao resetar TV: $e');
  }
  print('--- OPERAÇÃO CONCLUÍDA ---');
}

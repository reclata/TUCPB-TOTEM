import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:terreiro_queue_system/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('--- CONFIGURANDO MÉDIUNS PRIORITÁRIOS ---');

  final names = ['Sandra', 'Robson', 'Eduardo', 'Jucineide'];
  
  for (final name in names) {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('mediums')
          .where('nome', isEqualTo: name)
          .get();
          
      if (snap.docs.isEmpty) {
        // Se não existir, cria com 25 fichas
        await FirebaseFirestore.instance.collection('mediums').add({
          'nome': name,
          'maxFichas': 25,
        });
        print('✅ Criado médium "$name" com 25 fichas.');
      } else {
        // Se existir, atualiza para 25 fichas
        for (final doc in snap.docs) {
          await doc.reference.update({'maxFichas': 25});
          print('✅ Atualizado médium "$name" para 25 fichas.');
        }
      }
    } catch (e) {
      print('❌ Erro ao processar $name: $e');
    }
  }
  
  print('--- OPERAÇÃO CONCLUÍDA ---');
}

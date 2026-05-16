import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:terreiro_queue_system/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('--- CONFIGURANDO MÉDIUNS COM NOMES COMPLETOS ---');

  final names = [
    'Sandra Heloisa Alves Delfino da Luz',
    'Eduardo Rodrigues de Camargo',
    'Robson Rodrigues de Camargo',
    'Jucineide santos Gonçalves'
  ];
  
  for (final name in names) {
    try {
      // Tenta buscar por 'nome' ou 'nomeCompleto' na coleção 'usuarios'
      var snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('nome', isEqualTo: name)
          .get();
          
      if (snap.docs.isEmpty) {
        snap = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('nomeCompleto', isEqualTo: name)
            .get();
      }
      
      if (snap.docs.isEmpty) {
        print('⚠️ Médium "$name" não encontrado no banco.');
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:terreiro_queue_system/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('--- LIMPANDO BANCO DE DADOS (RESET TOTAL) ---');
  
  try {
    // 1. Deletar todos os tickets
    final tickets = await FirebaseFirestore.instance.collection('tickets').get();
    print('Tickets encontrados para deletar: ${tickets.docs.length}');
    for (final doc in tickets.docs) {
      await doc.reference.delete();
    }
    print('✅ Todos os tickets foram deletados.');
  } catch (e) {
    print('❌ Erro ao deletar tickets: $e');
  }

  try {
    // 2. Deletar todas as giras
    final giras = await FirebaseFirestore.instance.collection('giras').get();
    print('Giras encontradas para deletar: ${giras.docs.length}');
    for (final doc in giras.docs) {
      await doc.reference.delete();
    }
    print('✅ Todas as giras foram deletadas.');
  } catch (e) {
    print('❌ Erro ao deletar giras: $e');
  }

  try {
    // 3. Resetar o painel da TV
    await FirebaseFirestore.instance
        .collection('tvPanels')
        .doc('tv-painel-1')
        .update({
          'senhaAtual': null,
          'giraId': '',
        });
    print('✅ Painel da TV resetado (giraId vazio e senhaAtual null).');
  } catch (e) {
    print('❌ Erro ao resetar painel da TV: $e');
  }
  
  print('--- OPERAÇÃO CONCLUÍDA ---');
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:terreiro_queue_system/firebase_options.dart';

const _terreiroId = 'demo-terreiro';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  print('--- RECRIANDO COLLECTION tvPanels ---');

  String giraId = '';
  try {
    final girasSnap = await firestore
        .collection('giras')
        .where('status', isEqualTo: 'aberta')
        .limit(5)
        .get();

    if (girasSnap.docs.isNotEmpty) {
      giraId = girasSnap.docs.first.id;
      print('Gira ativa encontrada: $giraId');
    } else {
      print('Nenhuma gira aberta - giraId vazio.');
    }
  } catch (e) {
    print('Aviso ao buscar gira ativa: $e');
  }

  final now = Timestamp.now();
  final panels = <String, Map<String, dynamic>>{
    'tv-painel-1': {
      'id': 'tv-painel-1',
      'terreiroId': _terreiroId,
      'nomePainel': 'Painel TV 1',
      'status': 'ativo',
      'modo': 'geral',
      'giraId': giraId,
      'ultimaAtualizacao': now,
    },
    'tv-painel-2': {
      'id': 'tv-painel-2',
      'terreiroId': _terreiroId,
      'nomePainel': 'Painel TV 2',
      'status': 'ativo',
      'modo': 'geral',
      'giraId': giraId,
      'ultimaAtualizacao': now,
    },
  };

  for (final entry in panels.entries) {
    try {
      await firestore.collection('tvPanels').doc(entry.key).set(entry.value);
      print('OK: documento ${entry.key} criado.');
    } catch (e) {
      print('ERRO ${entry.key}: $e');
    }
  }

  print('--- CONCLUIDO ---');
}
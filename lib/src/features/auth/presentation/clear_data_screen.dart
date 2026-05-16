import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ClearDataScreen extends StatefulWidget {
  const ClearDataScreen({super.key});

  @override
  State<ClearDataScreen> createState() => _ClearDataScreenState();
}

class _ClearDataScreenState extends State<ClearDataScreen> {
  String _status = 'Aguardando ação...';
  bool _loading = false;

  Future<void> _clearData() async {
    setState(() {
      _loading = true;
      _status = 'Iniciando limpeza...';
    });

    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // 1. Apagar senhas do dia
      final ticketsSnap = await FirebaseFirestore.instance
          .collection('tickets')
          .where('dataRef', isEqualTo: todayStr)
          .get();
          
      int ticketsDeleted = 0;
      for (var doc in ticketsSnap.docs) {
        await doc.reference.delete();
        ticketsDeleted++;
      }

      // 2. Apagar todas as giras
      final girasSnap = await FirebaseFirestore.instance.collection('giras').get();
      int girasDeleted = 0;
      for (var doc in girasSnap.docs) {
        await doc.reference.delete();
        girasDeleted++;
      }

      // 3. Apagar contadores do dia (para resetar a numeração das senhas)
      final countersSnap = await FirebaseFirestore.instance.collection('counters').get();
      int countersDeleted = 0;
      for (var doc in countersSnap.docs) {
        if (doc.id.endsWith(todayStr)) {
          await doc.reference.delete();
          countersDeleted++;
        }
      }

      final queueCountersSnap = await FirebaseFirestore.instance.collection('queue_counters').get();
      int queueCountersDeleted = 0;
      for (var doc in queueCountersSnap.docs) {
        if (doc.id.endsWith(todayStr)) {
          await doc.reference.delete();
          queueCountersDeleted++;
        }
      }

      setState(() {
        _loading = false;
        _status = 'FIM: $ticketsDeleted senhas, $girasDeleted giras e contadores resetados!';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _status = 'Erro: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Limpar Dados')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            if (_loading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _clearData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Apagar Senhas de Hoje e Giras', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}

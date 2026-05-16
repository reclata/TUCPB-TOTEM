import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FixAdminScreen extends StatefulWidget {
  const FixAdminScreen({super.key});

  @override
  State<FixAdminScreen> createState() => _FixAdminScreenState();
}

class _FixAdminScreenState extends State<FixAdminScreen> {
  String _status = 'Aguardando ação...';
  bool _loading = false;

  Future<void> _makeAdmins() async {
    setState(() {
      _loading = true;
      _status = 'Buscando usuários...';
    });

    try {
      final allowedNames = [
        'SANDRA', 'EDUARDO', 'ROBSON', 'JUINEIDE', 'THAYNI', 
        'THABATA', 'PEDRO', 'LUCIANO', 'DENIS ALBERTO'
      ];

      final usersSnap = await FirebaseFirestore.instance.collection('usuarios').get();
      
      int updatedCount = 0;

      for (var doc in usersSnap.docs) {
        final nome = (doc.data()['nome'] ?? '').toString().toUpperCase();
        
        bool match = false;
        for (var allowed in allowedNames) {
          if (nome.contains(allowed)) {
            match = true;
            break;
          }
        }

        if (match) {
          setState(() => _status = 'Atualizando $nome...');
          await doc.reference.update({'perfilAcesso': 'admin'});
          updatedCount++;
        }
      }

      setState(() {
        _loading = false;
        _status = 'FIM: $updatedCount usuários atualizados!';
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
      appBar: AppBar(title: const Text('Fix Admin Access')),
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
                onPressed: _makeAdmins,
                child: const Text('Tornar Usuários Admin'),
              ),
          ],
        ),
      ),
    );
  }
}

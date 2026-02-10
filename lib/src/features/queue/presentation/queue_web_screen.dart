
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QueueWebScreen extends ConsumerWidget {
  final String terreiroId;
  const QueueWebScreen({super.key, required this.terreiroId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Fila')),
      body: Center(child: Text('User Queue View for $terreiroId')),
    ); // Simple user view
  }
}

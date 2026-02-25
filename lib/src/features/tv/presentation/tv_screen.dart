
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:terreiro_queue_system/src/shared/models/models.dart';

// Provider para buscar tickets chamados/atendidos
final tvCallsProvider = StreamProvider.family<List<Ticket>, String>((ref, terreiroId) {
  return FirebaseFirestore.instance
      .collection('tickets')
      .where('terreiroId', isEqualTo: terreiroId)
      .where('status', whereIn: ['chamada', 'atendida'])
      .orderBy('dataHoraChamada', descending: true)
      .limit(6)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Ticket.fromJson(d.data())).toList());
});

// Provider para nome da entidade — evita FutureBuilder recriado a cada rebuild
final _entityNameProvider = FutureProvider.family<String, String>((ref, entityId) async {
  if (entityId.isEmpty) return '';
  final doc = await FirebaseFirestore.instance.collection('entidades').doc(entityId).get();
  final data = doc.data();
  if (data == null) return '';
  return (data['nome'] as String? ?? '').toUpperCase();
});

class TvScreen extends ConsumerWidget {
  final String terreiroId;
  const TvScreen({super.key, required this.terreiroId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callsAsync = ref.watch(tvCallsProvider(terreiroId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: callsAsync.when(
        data: (calls) {
          if (calls.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.tv, size: 80, color: Colors.white24),
                  const SizedBox(height: 24),
                  Text(
                    'AGUARDANDO CHAMADAS...',
                    style: GoogleFonts.outfit(fontSize: 36, color: Colors.white24),
                  ),
                ],
              ),
            );
          }

          final currentCall = calls.first;
          final history = calls.skip(1).toList();

          return Row(
            children: [
              // Painel principal — senha chamada
              Expanded(
                flex: 2,
                child: Container(
                  color: const Color(0xFF1A1A2E),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Label
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'SENHA CHAMADA',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Código da senha em destaque
                      Text(
                        currentCall.codigoSenha,
                        style: GoogleFonts.outfit(
                          fontSize: 200,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Entidade
                      Text(
                        'ENTIDADE',
                        style: GoogleFonts.outfit(fontSize: 22, color: Colors.white38, letterSpacing: 3),
                      ),
                      const SizedBox(height: 8),
                      _EntityName(entityId: currentCall.entidadeId),

                      const SizedBox(height: 12),

                      // Horário da chamada
                      if (currentCall.dataHoraChamada != null)
                        Text(
                          DateFormat('HH:mm').format(currentCall.dataHoraChamada!),
                          style: GoogleFonts.outfit(fontSize: 28, color: Colors.white38),
                        ),
                    ],
                  ),
                ),
              ),

              // Sidebar — histórico
              Expanded(
                flex: 1,
                child: Container(
                  color: const Color(0xFF0F0F1A),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      ClipOval(
                        child: Image.asset('assets/images/logo.png', height: 100),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'ÚLTIMAS CHAMADAS',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          color: Colors.white38,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: history.map((t) => _HistoryItem(ticket: t)).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (e, s) => Center(
          child: Text('Erro: $e', style: const TextStyle(color: Colors.red, fontSize: 24)),
        ),
      ),
    );
  }
}

// Widget de nome da entidade usando Riverpod provider — sem piscar
class _EntityName extends ConsumerWidget {
  final String entityId;
  const _EntityName({required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameAsync = ref.watch(_entityNameProvider(entityId));
    return nameAsync.when(
      data: (name) => Text(
        name.isEmpty ? '—' : name,
        style: GoogleFonts.outfit(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.amber,
        ),
        textAlign: TextAlign.center,
      ),
      loading: () => const SizedBox(height: 36),
      error: (_, __) => const Text('—', style: TextStyle(color: Colors.amber, fontSize: 36)),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Ticket ticket;
  const _HistoryItem({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Text(
            ticket.codigoSenha,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white60,
            ),
          ),
          const Spacer(),
          Text(
            ticket.dataHoraChamada != null
                ? DateFormat('HH:mm').format(ticket.dataHoraChamada!)
                : '--:--',
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.white30),
          ),
        ],
      ),
    );
  }
}

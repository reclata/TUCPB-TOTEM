
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:terreiro_queue_system/src/shared/models/models.dart';

// Specific provider for TV to get calls
final tvCallsProvider = StreamProvider.family<List<Ticket>, String>((ref, terreiroId) {
  // Get today's calls, ordered by time called descending
  // Status: 'chamada' or 'atendida' (if we want to show recently attended too? Usually just called)
  // Let's show 'chamada' (blinking?) and 'atendida' as history?
  // "Conteúdo do painel TV: SENHA ATUAL CHAMADA ... Últimas 3 a 5 chamadas"
  // So we fetch last 5 tickets with status 'chamada' or 'atendida'?
  // If 'chamada' means "Calling Now", then we only have 1?
  // Or multiple stations calling? System supports multiple entities.
  // We should show the "Latest Call".
  
  return FirebaseFirestore.instance
      .collection('tickets')
      .where('terreiroId', isEqualTo: terreiroId)
      //.where('dataRef', isEqualTo: DateTime.now().toIso8601String().split('T').first) // Filter locally or composite index
      // Simpler: fetch last 10 changed tickets?
      // Better: where('status', whereIn: ['chamada', 'atendida'])
      // But we need to order by dataHoraChamada desc.
      // This requires an index. I'll assume index exists or create it.
      .where('status', whereIn: ['chamada', 'atendida'])
      .orderBy('dataHoraChamada', descending: true)
      .limit(6) 
      .snapshots()
      .map((snap) => snap.docs.map((d) => Ticket.fromJson(d.data())).toList());
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
              child: Text(
                'AGUARDANDO CHAMADAS...',
                style: GoogleFonts.outfit(fontSize: 48, color: Colors.white24),
              ),
            );
          }

          // First one is the Main Call
          final currentCall = calls.first;
          // Rest are history
          final history = calls.skip(1).toList();

          return Row(
            children: [
              // Main Panel (Left/Center)
              Expanded(
                flex: 2,
                child: Container(
                  color: const Color(0xFF1E1E1E),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("SENHA CHAMADA", style: GoogleFonts.outfit(fontSize: 32, color: Colors.amber)),
                      const SizedBox(height: 20),
                      Text(
                        currentCall.codigoSenha,
                        style: GoogleFonts.outfit(fontSize: 180, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        // We need the Entity Name. Ticket has 'entidadeId'.
                        // We could fetch Entity name or just show ID/Code?
                        // Ideally we pre-fetch or join.
                        // For now, let's use a FutureBuilder or just show "GUICHÊ / MESA" placeholder logic
                        // But the prompt says "ENTIDADE (ex: Cabocla Indaçema)".
                        // Fetching entity generic name might be slow per tick.
                        // Ideally Ticket should store Entity Name denormalized?
                        // Or we use a provider to look it up.
                        "ENTIDADE / MÉDIUM", // Placeholder until we lookup
                        style: GoogleFonts.outfit(fontSize: 32, color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      // Since we don't have the Entity Name readily available without lookup,
                      // We can use a widget that looks it up.
                      _EntityNameWidget(entityId: currentCall.entidadeId),
                    ],
                  ),
                ),
              ),
              
              // Sidebar (History)
              Expanded(
                flex: 1,
                child: Container(
                  color: const Color(0xFF121212),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Image.asset('assets/images/logo.jpg', height: 120)),
                      const SizedBox(height: 40),
                      Text("ÚLTIMAS CHAMADAS", style: GoogleFonts.outfit(fontSize: 24, color: Colors.white54)),
                      const SizedBox(height: 20),
                      ...history.map((t) => _HistoryItem(ticket: t)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erro: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Ticket ticket;
  const _HistoryItem({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            ticket.codigoSenha,
            style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const Spacer(),
          Text(
            DateFormat('HH:mm').format(ticket.dataHoraChamada ?? DateTime.now()),
            style: GoogleFonts.outfit(fontSize: 20, color: Colors.white30),
          ),
        ],
      ),
    );
  }
}

// Widget to fetch and display Entity Name
class _EntityNameWidget extends ConsumerWidget {
  final String entityId;
  const _EntityNameWidget({required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can access the global entity list if loaded, or fetch single
    // Assuming terreiroId is needed for fetching list, but here we only have entityId.
    // We can assume we entered via TvScreen which has terreiroId.
    // I'll leave it simple for now or fetch the document directly.
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('entidades').doc(entityId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const Text("...");
        return Text(
          (data['nome'] as String).toUpperCase(),
           style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.amber),
           textAlign: TextAlign.center,
        );
      },
    );
  }
}

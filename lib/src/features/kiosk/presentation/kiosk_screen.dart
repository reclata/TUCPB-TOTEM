
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/models.dart';
import '../../../shared/providers/global_providers.dart';
import '../../../shared/services/printer_service.dart';
import '../../queue/data/firestore_queue_repository.dart';

class KioskScreen extends ConsumerWidget {
  const KioskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Retrieve from local storage/secure storage
    const terreiroId = 'demo-terreiro';
    final activeGiraAsync = ref.watch(activeGiraProvider(terreiroId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E003E), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          Center(
            child: activeGiraAsync.when(
              data: (activeGira) {
                if (activeGira == null) {
                  return _buildClosedState();
                }
                return _buildOpenState(context, ref, terreiroId, activeGira);
              },
              loading: () => const CircularProgressIndicator(color: Colors.amber),
              error: (err, stack) => Text('Erro ao carregar: $err', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_clock, size: 80, color: Colors.white24),
        const SizedBox(height: 20),
        Text("TERREIRO FECHADO", style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white54)),
        Text("Aguarde a abertura da Gira.", style: GoogleFonts.outfit(fontSize: 24, color: Colors.white24)),
      ],
    );
  }

  Widget _buildOpenState(BuildContext context, WidgetRef ref, String terreiroId, Gira gira) {
    final activeMediumsAsync = ref.watch(activeMediumsProvider(terreiroId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Axé e Bem-Vindo", style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white70)),
          Text("TERREIRO EXEMPLO", style: GoogleFonts.outfit(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 60),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                Text("GIRA DE HOJE:", style: GoogleFonts.outfit(fontSize: 24, color: Colors.white70)),
                Text(gira.tema.toUpperCase(), style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.amber)),
              ],
            ),
          ),

          const SizedBox(height: 60),

          activeMediumsAsync.when(
            data: (mediums) {
              if (mediums.isEmpty) {
                return Text("Nenhuma entidade disponível no momento.", style: GoogleFonts.outfit(fontSize: 24, color: Colors.white38));
              }
              // Deduplicate by Entity Name if needed, but for now show all active mediums
              // If multiple mediums incorporate the same entity, the user might want to choose the specific medium?
              // The prompt says "Selecionar ENTIDADE".
              // Let's group by Entity Name to simulate selecting Entity.
              // If multiple mediums exist for an entity, we auto-assign via round-robin? Or just pick first?
              // For simplicity: Show Buttons for Entity Names.
              // Logic: Map<EntityName, List<Medium>>
              final Map<String, List<Medium>> entityMap = {};
              for (var pair in mediums) {
                entityMap.putIfAbsent(pair.entity.nome, () => []).add(pair.medium);
              }

              return Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: entityMap.keys.map((entityName) {
                   // Pick the first one for now or handle random selection
                   final targetMedium = entityMap[entityName]!.first; 
                   return _buildEntityButton(context, ref, terreiroId, gira, entityName, targetMedium);
                }).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text("Erro: $e", style: const TextStyle(color: Colors.red)),
          ),

          const SizedBox(height: 80),
          Text("Toque na entidade desejada para retirar sua senha.", style: GoogleFonts.outfit(fontSize: 18, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildEntityButton(BuildContext context, WidgetRef ref, String terreiroId, Gira gira, String entityName, Medium medium) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showConfirmationDialog(context, ref, terreiroId, gira, entityName, medium);
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 300,
          height: 180,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_pin_circle_outlined, size: 48, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                entityName,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, WidgetRef ref, String terreiroId, Gira gira, String entityName, Medium medium) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Confirmar Senha", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Deseja retirar senha para:", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Text(entityName, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(height: 20),
            Text("Médium: ${medium.nome}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _processTicket(context, ref, terreiroId, gira, entityName, medium);
            },
            child: const Text("CONFIRMAR E IMPRIMIR"),
          ),
        ],
      ),
    );
  }

  Future<void> _processTicket(BuildContext context, WidgetRef ref, String terreiroId, Gira gira, String entityName, Medium medium) async {
    // Show loading overlay?
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Imprimindo senha..."), backgroundColor: Colors.blue, duration: Duration(seconds: 2)),
    );

    try {
      final repo = ref.read(queueRepositoryProvider);
      final ticket = await repo.issueTicket(
        terreiroId: terreiroId, 
        giraId: gira.id, 
        entidadeId: medium.entidadeId, 
        medium: medium
      );

      // Print
      final printer = ref.read(printerServiceProvider);
      await printer.printTicket(
        terreiroName: "TERREIRO EXEMPLO", // Hardcoded or fetched
        giraName: gira.tema,
        entityName: entityName,
        mediumName: medium.nome,
        mediumInitials: medium.iniciais,
        ticketCode: ticket.codigoSenha,
        pixKey: "12345678900", // Configurable
        date: ticket.dataHoraEmissao,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Senha ${ticket.codigoSenha} emitida!"), backgroundColor: Colors.green, duration: const Duration(seconds: 3)),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao emitir: $e"), backgroundColor: Colors.red),
      );
    }
  }
}

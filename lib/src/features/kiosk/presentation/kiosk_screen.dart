
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:terreiro_queue_system/src/shared/models/models.dart';
import '../../../shared/providers/global_providers.dart';
import '../../../shared/services/printer_service.dart';
import '../../queue/data/firestore_queue_repository.dart';

final Map<String, IconData> _lineIcons = {
  'Caboclo': Icons.person_outline,
  'Erê': Icons.child_care_outlined,
  'Exu': Icons.face_retouching_natural_outlined,
  'Preto Velho': Icons.elderly_outlined,
  'Cigano': Icons.auto_awesome_outlined,
  'Pombo gira': Icons.face_3_outlined,
  'Boiadeiro': Icons.directions_boat_outlined, // Placeholder icon
  'Baiano': Icons.emoji_nature_outlined,
  'Marinheiro': Icons.anchor_outlined,
  'Malandro': Icons.person_search_outlined,
  'Feiticeiro': Icons.star_outline_sharp,
  'Pombo Giro': Icons.face_2_outlined,
};

final Map<String, List<String>> _giraLineGroups = {
  'Boiadeiro': ['Boiadeiro', 'Marinheiro', 'Malandro'],
  'Esquerda': ['Esquerda'],
  // Outras linhas são 1 para 1 por padrão
};

class KioskScreen extends ConsumerStatefulWidget {
  const KioskScreen({super.key});

  @override
  ConsumerState<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends ConsumerState<KioskScreen> {
  bool _showEntitySelection = false;
  String? _selectedLine;

  @override
  Widget build(BuildContext context) {
    // TODO: Retrieve from local storage/secure storage
    const terreiroId = 'demo-terreiro';
    final activeGiraAsync = ref.watch(activeGiraProvider(terreiroId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/wood_background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          Center(
            child: activeGiraAsync.when(
              data: (activeGira) {
                if (activeGira == null) {
                  return _buildClosedState();
                }
                if (!_showEntitySelection) {
                  return _buildLandingState();
                }
                return _buildOpenState(activeGira);
              },
              loading: () => const CircularProgressIndicator(color: Colors.amber),
              error: (err, stack) => Text('Erro ao carregar: $err', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Bem vindos",
          style: GoogleFonts.outfit(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 40),
        Image.asset('assets/images/logo.jpg', height: 450),
        const SizedBox(height: 60),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _showEntitySelection = true;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.9),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 10,
            shadowColor: Colors.black54,
          ),
          child: Text(
            "Senha",
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClosedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/logo.jpg', height: 120),
        const SizedBox(height: 20),
        Text("T.U.C.P.B.", style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
        Text("Token System", style: GoogleFonts.outfit(fontSize: 24, color: Colors.white70, letterSpacing: 2)),
        const SizedBox(height: 40),
        Icon(Icons.lock_clock, size: 80, color: Colors.white24),
        const SizedBox(height: 20),
        Text("TERREIRO FECHADO", style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white54)),
        Text("Aguarde a abertura da Gira.", style: GoogleFonts.outfit(fontSize: 24, color: Colors.white24)),
      ],
    );
  }

  Widget _buildOpenState(Gira gira) {
    const terreiroId = 'demo-terreiro';
    final activeMediumsAsync = ref.watch(activeMediumsProvider(terreiroId));

    return Column(
      children: [
        // Top Bar con Botón Volver y Título
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 40),
                onPressed: () {
                  if (_selectedLine != null) {
                    setState(() => _selectedLine = null);
                  } else {
                    setState(() => _showEntitySelection = false);
                  }
                },
              ),
              const SizedBox(width: 20),
              Text(
                _selectedLine == null ? "Escolha a linha para seu atendimento:" : "Escolha o guia para seu atendimento:",
                style: GoogleFonts.outfit(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: activeMediumsAsync.when(
              data: (mediums) {
                if (mediums.isEmpty) {
                  return Center(child: Text("Nenhuma entidade disponível no momento.", style: GoogleFonts.outfit(fontSize: 24, color: Colors.white38)));
                }

                if (_selectedLine == null) {
                  // Filtrar as linhas permitidas para esta Gira
                  final allowedLines = _giraLineGroups[gira.linha] ?? [gira.linha];
                  
                  final lines = mediums
                    .map((m) => m.entity.linha)
                    .where((linha) => allowedLines.contains(linha))
                    .toSet()
                    .toList();
                  lines.sort();
                  
                  if (lines.isEmpty) {
                    return Center(child: Text("Nenhuma entidade da linha ${gira.linha} disponível.", style: GoogleFonts.outfit(fontSize: 24, color: Colors.white38)));
                  }

                  return Wrap(
                    spacing: 30,
                    runSpacing: 30,
                    alignment: WrapAlignment.center,
                    children: lines.map((line) => _buildLineButton(line)).toList(),
                  );
                } else {
                  // Mostrar Grid de ENTIDADES daquela linha
                  final filteredMediums = mediums.where((m) => m.entity.linha == _selectedLine).toList();
                  
                  Map<String, List<({Medium medium, Entidade entity})>> entityMap = {};
                  for (var pair in filteredMediums) {
                    entityMap.putIfAbsent(pair.entity.nome, () => []).add(pair);
                  }

                  return Wrap(
                    spacing: 30,
                    runSpacing: 30,
                    alignment: WrapAlignment.center,
                    children: entityMap.entries.map((entry) {
                       final entityName = entry.key;
                       final pairs = entry.value;
                       final firstPair = pairs.first;
                       return _buildEntityButton(context, ref, terreiroId, gira, entityName, firstPair.entity.id, firstPair.medium);
                    }).toList(),
                  );
                }
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
              error: (e, s) => Center(child: Text("Erro: $e", style: const TextStyle(color: Colors.red))),
            ),
          ),
        ),
        
        // Rodapé com nome do Terreiro
        Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 10),
          child: Column(
            children: [
               Container(
                 width: 400,
                 height: 4,
                 decoration: BoxDecoration(
                   color: Colors.blue[300],
                   borderRadius: BorderRadius.circular(2)
                 ),
               ),
               const SizedBox(height: 10),
               Text(
                 "Tenda de Umbanda",
                 style: GoogleFonts.outfit(color: Colors.white38, fontSize: 24),
               ),
               Text(
                 "Caboclo Pena Branca e Tupi, Ogum Rompe Mato e Beira Mar & Mãe Maria da Guia",
                 style: GoogleFonts.outfit(color: Colors.white24, fontSize: 18),
               ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLineButton(String line) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedLine = line),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 280,
          height: 350,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_lineIcons[line] ?? Icons.person_outline, size: 180, color: Colors.grey[700]),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400]!.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                ),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntityButton(BuildContext context, WidgetRef ref, String terreiroId, Gira gira, String entityName, String entityId, Medium medium) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
          child: Text(
            medium.nome,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _showConfirmationDialog(context, ref, terreiroId, gira, entityName, entityId, medium);
            },
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 320,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.black87, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Text(
                entityName.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4A2C2A), // Cor marrom escura da foto
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog(BuildContext context, WidgetRef ref, String terreiroId, Gira gira, String entityName, String entityId, Medium medium) {
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
              await _processTicket(context, ref, terreiroId, gira, entityName, entityId, medium);
            },
            child: const Text("CONFIRMAR E IMPRIMIR"),
          ),
        ],
      ),
    );
  }

  Future<void> _processTicket(BuildContext context, WidgetRef ref, String terreiroId, Gira gira, String entityName, String entityId, Medium medium) async {
    // Show loading overlay?
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Imprimindo senha..."), backgroundColor: Colors.blue, duration: Duration(seconds: 2)),
    );

    try {
      final repo = ref.read(queueRepositoryProvider);
      final ticket = await repo.issueTicket(
        terreiroId: terreiroId, 
        giraId: gira.id, 
        entidadeId: entityId, 
        medium: medium
      );

      // Print
      final printer = ref.read(printerServiceProvider);
      final mediumInitials = medium.nome.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase();
      await printer.printTicket(
        terreiroName: "T.U.C.P.B. Token", // Hardcoded or fetched
        giraName: gira.tema,
        entityName: entityName,
        mediumName: medium.nome,
        mediumInitials: mediumInitials,
        ticketCode: ticket.codigoSenha,
        pixKey: "12345678900", // Configurable
        date: ticket.dataHoraEmissao,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Senha ${ticket.codigoSenha} emitida!"), backgroundColor: Colors.green, duration: const Duration(seconds: 3)),
      );

      // Voltar para a tela inicial ou tela de seleção após um tempo
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _selectedLine = null;
            _showEntitySelection = false;
          });
        }
      });

    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao emitir: $e"), backgroundColor: Colors.red),
      );
    }
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:terreiro_queue_system/src/shared/models/models.dart';
import 'package:terreiro_queue_system/src/shared/providers/global_providers.dart';
import 'package:terreiro_queue_system/src/shared/services/printer_service.dart';
import 'package:terreiro_queue_system/src/features/queue/data/firestore_queue_repository.dart';

final Map<String, IconData> _lineIcons = {
  'Caboclo': Icons.person_outline,
  'Erê': Icons.child_care_outlined,
  'Exu': Icons.face_retouching_natural_outlined,
  'Preto Velho': Icons.elderly_outlined,
  'Cigano': Icons.auto_awesome_outlined,
  'Pombo gira': Icons.face_3_outlined,
  'Boiadeiro': Icons.directions_boat_outlined,
  'Baiano': Icons.emoji_nature_outlined,
  'Marinheiro': Icons.anchor_outlined,
  'Malandro': Icons.person_search_outlined,
  'Feiticeiro': Icons.star_outline_sharp,
  'Pomba Gira': Icons.face_2_outlined,
};

// Mapeamento de imagens para cada linha (devem ser colocadas em assets/images/linhas/)
final Map<String, String> _lineImages = {
  'Caboclo': 'assets/images/linhas/caboclo.jpg',
  'Erê': 'assets/images/linhas/ere.jpg',
  'Preto Velho': 'assets/images/linhas/preto_velho.jpg',
  'Boiadeiro': 'assets/images/linhas/boiadeiro.jpg',
  'Marinheiro': 'assets/images/linhas/marinheiro.jpg',
  'Baiano': 'assets/images/linhas/baiano.jpg',
  'Cigano': 'assets/images/linhas/cigano.jpg',
  'Malandro': 'assets/images/linhas/malandro.jpg',
  'Exu': 'assets/images/linhas/exu.jpg',
  'Pomba Gira': 'assets/images/linhas/pombo_gira.jpg',
  'Esquerda': 'assets/images/linhas/exu.jpg', // Fallback para Esquerda
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
  String? _selectedTipo;
  Ticket? _lastIssuedTicket;
  String? _lastIssuedEntityName;
  Gira? _lastIssuedGira;

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
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  (_showEntitySelection || _lastIssuedTicket != null)
                      ? 'assets/images/kiosk_bg_selection.jpg'
                      : 'assets/images/wood_background.jpg',
                ),
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
                if (_lastIssuedTicket != null) {
                  return _buildTicketSuccessState(_lastIssuedTicket!, _lastIssuedGira!, _lastIssuedEntityName!);
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
        Image.asset('assets/images/logo.png', height: 450),
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
        Image.asset('assets/images/logo.png', height: 120),
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
                icon: const Icon(Icons.arrow_back, color: Colors.black, size: 40),
                onPressed: () {
                  if (_selectedTipo != null) {
                    setState(() => _selectedTipo = null);
                  } else if (_selectedLine != null) {
                    setState(() => _selectedLine = null);
                  } else {
                    setState(() => _showEntitySelection = false);
                  }
                },
              ),
              const SizedBox(width: 20),
              Text(
                _selectedLine == null 
                    ? "Escolha a linha para seu atendimento:" 
                    : (_selectedTipo == null 
                        ? "Escolha para qual parte da Gira é a senha:" 
                        : "Escolha o guia para seu atendimento:"),
                style: GoogleFonts.outfit(fontSize: 48, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: activeMediumsAsync.when(
              data: (mediums) {
                if (mediums.isEmpty) {
                  return Center(child: Text("Nenhuma entidade disponível no momento.", style: GoogleFonts.outfit(fontSize: 24, color: Colors.white38)));
                }

                if (_selectedLine == null) {
                  // Usar a lógica de grupos de linhas para filtrar o que deve aparecer
                  final allowedGiraLines = _giraLineGroups[gira.linha] ?? [gira.linha];
                  
                  // Buscar todas as linhas disponíveis dos médiuns presentes que pertencem ao grupo da Gira
                  final lines = mediums
                    .map((m) => m.entity.linha)
                    .where((linha) => allowedGiraLines.contains(linha))
                    .toSet()
                    .toList();
                  lines.sort();
                  
                  // Se a linha da gira tem médiuns, pode ir direto para entidades
                  if (lines.length == 1) {
                    // Apenas uma linha disponível, pular seleção de linha
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _selectedLine == null) {
                        setState(() => _selectedLine = lines.first);
                      }
                    });
                    return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  }
                  
                  if (lines.isEmpty) {
                    final allLines = mediums.map((m) => m.entity.linha).toSet().toList()..sort();
                    // Nenhum médium da linha da gira está presente
                    // Mostrar todas as linhas disponíveis como fallback
                    if (allLines.isEmpty) {
                      return Center(child: Text("Nenhuma entidade disponível para a linha '${gira.linha}'.", style: GoogleFonts.outfit(fontSize: 24, color: Colors.white38)));
                    }
                    return Wrap(
                      spacing: 30,
                      runSpacing: 30,
                      alignment: WrapAlignment.center,
                      children: allLines.map((line) => _buildLineButton(line)).toList(),
                    );
                  }

                  return Wrap(
                    spacing: 30,
                    runSpacing: 30,
                    alignment: WrapAlignment.center,
                    children: lines.map((line) => _buildLineButton(line)).toList(),
                  );
                } else if (_selectedTipo == null) {
                  // Verificar se esta linha EXIGE a escolha de Tipo (apenas Esquerda e Boiadeiro)
                  final bool mustChooseTipo = _selectedLine == 'Esquerda' || _selectedLine == 'Boiadeiro';
                  
                  final filteredByLine = mediums.where((m) => m.entity.linha == _selectedLine).toList();
                  final availableTipos = filteredByLine.map((m) => m.entity.tipo).toSet().toList();
                  availableTipos.sort();

                  if (!mustChooseTipo || availableTipos.length <= 1) {
                    // Se não exige escolha de tipo OU só tem um tipo, pula direto para entidades
                    final singleTipo = availableTipos.isNotEmpty ? availableTipos.first : '';
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _selectedTipo == null) {
                        setState(() => _selectedTipo = singleTipo.isEmpty ? 'ALL' : singleTipo);
                      }
                    });
                    return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  }

                  return Wrap(
                    spacing: 30,
                    runSpacing: 30,
                    alignment: WrapAlignment.center,
                    children: availableTipos.map((tipo) => _buildTipoButton(tipo)).toList(),
                  );
                } else {
                  // Mostrar Grid de ENTIDADES daquela linha
                  // Se o tipo for 'ALL', mostramos todos da linha
                  final filteredMediums = mediums.where((m) => 
                     m.entity.linha == _selectedLine && 
                     (_selectedTipo == 'ALL' || m.entity.tipo == _selectedTipo)
                  ).toList();
                  
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
                   color: const Color(0xFFFFD700), // Dourado
                   borderRadius: BorderRadius.circular(2)
                 ),
               ),
               const SizedBox(height: 10),
               Text(
                 "Tenda de Umbanda",
                 style: GoogleFonts.outfit(color: Colors.black.withOpacity(0.7), fontSize: 24, fontWeight: FontWeight.bold),
               ),
               Text(
                 "Caboclo Pena Branca e Tupi, Ogum Rompe Mato e Beira Mar & Mãe Maria da Guia",
                 style: GoogleFonts.outfit(color: Colors.black.withOpacity(0.6), fontSize: 18),
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
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _lineImages.containsKey(line)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          _lineImages[line]!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(_lineIcons[line] ?? Icons.person_outline, size: 180, color: Colors.grey[700]),
                        ),
                      )
                    : Icon(_lineIcons[line] ?? Icons.person_outline, size: 180, color: Colors.grey[700]),
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

  Widget _buildTipoButton(String tipo) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedTipo = tipo),
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
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _lineImages.containsKey(tipo)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          _lineImages[tipo]!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(_lineIcons[tipo] ?? Icons.person_outline, size: 180, color: Colors.grey[700]),
                        ),
                      )
                    : Icon(_lineIcons[tipo] ?? Icons.person_outline, size: 180, color: Colors.grey[700]),
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
                  tipo,
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
    debugPrint("DEBUG AUTH: User is ${FirebaseAuth.instance.currentUser?.email ?? 'NOT LOGGED IN'}");
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

      if (!context.mounted) return;

      debugPrint("Ticket issued: ${ticket.codigoSenha}");

      setState(() {
        _lastIssuedTicket = ticket;
        _lastIssuedEntityName = entityName;
        _lastIssuedGira = gira;
      });

      // Show success briefly even if printer fails
      debugPrint("Starting print process...");

      // Print
      final printer = ref.read(printerServiceProvider);
      final mediumInitials = medium.nome.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase();
      await printer.printTicket(
        terreiroName: "T.U.C.P.B. Token",
        giraName: gira.tema,
        entityName: entityName,
        mediumName: medium.nome,
        mediumInitials: mediumInitials,
        ticketCode: ticket.codigoSenha,
        pixKey: "12345678900",
        date: ticket.dataHoraEmissao,
      );

      debugPrint("Print process completed.");

      // Voltar para a tela inicial após 15 segundos (um pouco mais de tempo)
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted) {
          setState(() {
            _lastIssuedTicket = null;
            _lastIssuedEntityName = null;
            _lastIssuedGira = null;
            _selectedLine = null;
            _selectedTipo = null;
            _showEntitySelection = false;
          });
        }
      });

    } catch (e, stack) {
      debugPrint("ERROR issuing ticket: $e");
      debugPrint("STACK TRACE: $stack");
      if (!context.mounted) return;
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erro', style: TextStyle(color: Colors.red)),
          content: Text('Falha ao gerar senha:\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTicketSuccessState(Ticket ticket, Gira gira, String entityName) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Retire sua senha!",
              style: GoogleFonts.outfit(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),
            
            // Ticket Card
            Container(
              width: 600,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    "Gira de ${gira.tema}", // Usar tema em vez de linha para ser mais específico
                    style: GoogleFonts.outfit(fontSize: 24, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    entityName,
                    style: GoogleFonts.outfit(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    DateFormat('dd/MM/yyyy').format(ticket.dataHoraEmissao),
                    style: GoogleFonts.outfit(fontSize: 22, color: Colors.black54),
                  ),
                  Text(
                    DateFormat('HH:mm').format(ticket.dataHoraEmissao),
                    style: GoogleFonts.outfit(fontSize: 22, color: Colors.black54),
                  ),
                  const SizedBox(height: 60),
                  Text(
                    ticket.codigoSenha,
                    style: GoogleFonts.outfit(
                      fontSize: 140,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: -5,
                    ),
                  ),
                  const SizedBox(height: 60),
                  Text(
                    "Tenda de umbanda Caboclo Pena Branca e Tupi, Sr Ogum Rompe Mato e Beira Mar & Mãe Maria da Guia",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.black45),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 60),
            Text(
              "Agradecemos sua presença!",
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Axé!",
              style: GoogleFonts.outfit(
                fontSize: 56,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

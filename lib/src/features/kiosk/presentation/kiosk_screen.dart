
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:terreiro_queue_system/src/shared/models/models.dart';
import 'package:terreiro_queue_system/src/shared/providers/global_providers.dart';
import 'package:terreiro_queue_system/src/shared/services/printer_service.dart';
import 'package:terreiro_queue_system/src/features/queue/data/firestore_queue_repository.dart';
import 'package:terreiro_queue_system/src/shared/utils/spiritual_utils.dart';

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

// Mapeamento normalizado para MAIÚSCULAS para evitar problemas de case-sensitivity
final Map<String, String> _lineImages = {
  'CABOCLO': 'assets/images/linhas/caboclo.jpg',
  'ERE': 'assets/images/linhas/ere.jpg',
  'PRETO VELHO': 'assets/images/linhas/preto_velho.jpg',
  'BOIADEIRO': 'assets/images/linhas/boiadeiro.jpg',
  'MARINHEIRO': 'assets/images/linhas/marinheiro.jpg',
  'BAIANO': 'assets/images/linhas/baiano.jpg',
  'CIGANO': 'assets/images/linhas/cigano.jpg',
  'MALANDRO': 'assets/images/linhas/malandro.jpg',
  'EXU': 'assets/images/linhas/exu.jpg',
  'POMBA GIRA': 'assets/images/linhas/pombo_gira.jpg',
  'POMBO GIRA': 'assets/images/linhas/pombo_gira.jpg',
  'ESQUERDA': 'assets/images/linhas/exu.jpg',
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
  bool _showReprintScreen = false;
  String? _selectedLine;
  String? _selectedTipo;
  Ticket? _lastIssuedTicket;
  String? _lastIssuedEntityName;
  Gira? _lastIssuedGira;

  @override
  Widget build(BuildContext context) {
    // Sincronizado com global_providers.dart: 'demo-terreiro'
    final terreiroId = ref.watch(selectedTerreiroIdProvider) ?? 'demo-terreiro'; 
    final activeGiraAsync = ref.watch(activeGiraProvider(terreiroId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  (_showEntitySelection || _showReprintScreen || _lastIssuedTicket != null)
                      ? 'assets/images/kiosk_bg_selection.jpg'
                      : 'assets/images/wood_background.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
            child: activeGiraAsync.when(
              data: (activeGira) {
                // Prioridade 1: Tela de Sucesso após emitir ticket
                if (_lastIssuedTicket != null) {
                  return _buildTicketSuccessState(_lastIssuedTicket!, _lastIssuedGira!, _lastIssuedEntityName!);
                }
                
                // Prioridade 1.5: Reimpressão
                if (_showReprintScreen) {
                  return _buildReprintState(terreiroId);
                }

                // Prioridade 2: Seleção de Entidades (Fluxo interno)
                // Funciona com gira real OU com fallback caso Firestore retorne null
                if (_showEntitySelection) {
                  final giraParaUsar = activeGira ?? _fallbackGira;
                  return _buildOpenState(giraParaUsar);
                }

                // Prioridade 3: Tela Inicial (Bem-vindos) - SEMPRE VISÍVEL
                return _buildLandingState(activeGira);
              },
              loading: () => const CircularProgressIndicator(color: Colors.brown),
              error: (err, stack) => Text('Erro ao carregar: $err', style: const TextStyle(color: Colors.red)),
            ),
           ),
          ),
        ],
      ),
    );
  }

  /// Gira de fallback usada quando o Firestore não retorna giras
  Gira get _fallbackGira => Gira(
    id: 'kiosk-fallback',
    terreiroId: 'demo-terreiro',
    tema: 'Gira',
    linha: '',
    data: DateTime.now(),
    status: 'aberta',
    horarioInicio: '18:00',
    horarioKiosk: '18:00',
    encerramentoKioskAtivo: false,
    mediumsParticipantes: const [],
    presencas: const {},
  );

  bool _isKioskOpen(Gira? gira) {
    if (gira == null) {
      debugPrint('[KIOSK_DEBUG] Gira é NULA');
      return false;
    }
    
    debugPrint('[KIOSK_DEBUG] Validando Gira: ${gira.tema}');
    debugPrint('[KIOSK_DEBUG] Status: ${gira.status} | Ativo: ${gira.ativo}');
    debugPrint('[KIOSK_DEBUG] Horário Kiosk: ${gira.horarioKiosk}');

    // Se o usuário já abriu a gira MANUALMENTE no Admin, o Kiosk libera imediatamente.
    if (gira.isAberta) {
      debugPrint('[KIOSK_DEBUG] Gira está ABERTA ou ATIVA. Liberando...');
      return true;
    }

    // Regra de Horário: Se ainda não foi aberta manualmente, respeitamos o horário programado.
    try {
      if (gira.horarioKiosk.isEmpty) {
        debugPrint('[KIOSK_DEBUG] Horário Kiosk VAZIO.');
        return false;
      }
      
      final now = DateTime.now();
      final timeParts = gira.horarioKiosk.split(':');
      if (timeParts.length != 2) return false;
      
      final openTime = DateTime(
        now.year, now.month, now.day, 
        int.parse(timeParts[0]), 
        int.parse(timeParts[1])
      );
      
      final isOpen = now.isAfter(openTime);
      debugPrint('[KIOSK_DEBUG] Hora Atual: $now | Hora Abertura: $openTime');
      debugPrint('[KIOSK_DEBUG] Resultado Horário: $isOpen');
      
      return isOpen;
    } catch (e) {
      debugPrint('[KIOSK_DEBUG] ERRO no parse de horário: $e');
      return false;
    }
  }

  Widget _buildLandingState(Gira? gira) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Bem-Vindos",
          style: TextStyle(fontFamily: "Roboto", 
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Container(
          height: 450,
          width: 450,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: GestureDetector(
            onDoubleTap: () {
              setState(() {
                _showReprintScreen = true;
              });
            },
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF0F0F0), // Fundo Cinza Claro como solicitado
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 60),
        _AnimatedSenhaButton(
          onTap: () {
            setState(() {
              _showEntitySelection = true;
            });
          },
        ),
      ],
    );
  }
}

class _AnimatedSenhaButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedSenhaButton({required this.onTap});

  @override
  State<_AnimatedSenhaButton> createState() => _AnimatedSenhaButtonState();
}

class _AnimatedSenhaButtonState extends State<_AnimatedSenhaButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ElevatedButton(
          onPressed: null, // Controlado pelo GestureDetector para efeito imediato
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.9),
            disabledBackgroundColor: Colors.white.withOpacity(0.9),
            foregroundColor: Colors.black,
            disabledForegroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 10,
            shadowColor: Colors.black54,
          ),
          child: const Text(
            "Senha",
            style: TextStyle(
              fontFamily: "Roboto",
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Extensão do _KioskScreenState para fechar o widget original e adicionar os novos métodos se necessário
extension _KioskScreenStateUI on _KioskScreenState {

  String _formatMediumName(String fullName) {
    if (fullName.isEmpty) return fullName;
    final parts = fullName.trim().split(' ');
    if (parts.length > 1) {
      return '${parts.first} ${parts.last}';
    }
    return fullName;
  }

  Widget _buildReprintState(String terreiroId) {
    final ticketsAsync = ref.watch(ticketListProvider(terreiroId));
    final girasAsync = ref.watch(giraListProvider(terreiroId));
    final entitiesAsync = ref.watch(entityListProvider(terreiroId));
    final mediumsAsync = ref.watch(mediumListProvider(terreiroId));

    if (ticketsAsync.isLoading || girasAsync.isLoading || entitiesAsync.isLoading || mediumsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }

    final today = DateTime.now();
    final tickets = (ticketsAsync.value ?? <Ticket>[]).where((t) {
      return t.dataHoraEmissao.year == today.year &&
             t.dataHoraEmissao.month == today.month &&
             t.dataHoraEmissao.day == today.day;
    }).toList()..sort((a, b) => b.dataHoraEmissao.compareTo(a.dataHoraEmissao)); // Mais recentes primeiro

    final giras = girasAsync.value ?? <Gira>[];
    final entities = entitiesAsync.value ?? <Entidade>[];
    final mediums = mediumsAsync.value ?? <Medium>[];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black, size: 40),
                onPressed: () => setState(() => _showReprintScreen = false),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "Reimpressão de Senhas (Hoje)",
                  style: TextStyle(fontFamily: "Roboto", fontSize: 28, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: tickets.isEmpty 
            ? Center(child: Text("Nenhuma senha gerada hoje.", style: TextStyle(fontFamily: "Roboto", fontSize: 24, color: Colors.brown[900])))
            : ListView.builder(
             padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
             itemCount: tickets.length,
             itemBuilder: (context, index) {
               final ticket = tickets[index];
               final gira = giras.cast<Gira?>().firstWhere((g) => g?.id == ticket.giraId, orElse: () => null) ?? _fallbackGira;
               final medium = mediums.cast<Medium?>().firstWhere((m) => m?.id == ticket.mediumId, orElse: () => null) ?? Medium(id: '', nome: 'Aberto');
               final entity = entities.cast<Entidade?>().firstWhere((e) => e?.id == ticket.entidadeId, orElse: () => null) ?? Entidade(id: '', terreiroId: '', nome: '?', linha: '', tipo: '');

               String resolvedEntityName = entity.nome;
               if (resolvedEntityName == '?' && medium.id.isNotEmpty) {
                 try {
                   final medEnt = medium.entidades.firstWhere((e) => e.entidadeId == ticket.entidadeId);
                   resolvedEntityName = medEnt.entidadeNome;
                   if (resolvedEntityName.isEmpty) resolvedEntityName = '?';
                 } catch (_) {}
               }

               return Card(
                 margin: const EdgeInsets.only(bottom: 20),
                 elevation: 5,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                 child: InkWell(
                   onTap: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text("Reimprimindo senha ${ticket.codigoSenha}..."), backgroundColor: Colors.blue, duration: const Duration(seconds: 2)),
                     );
                     try {
                       final printer = ref.read(printerServiceProvider);
                       final mediumInitials = medium.nome.split(' ').where((n) => n.isNotEmpty).map((n) => n[0]).take(2).join().toUpperCase();
                       printer.printTicket(
                         terreiroName: "T.U.C.P.B.",
                         giraName: gira.tema,
                         entityName: resolvedEntityName,
                         mediumName: _formatMediumName(medium.nome),
                         mediumInitials: mediumInitials,
                         ticketCode: ticket.codigoSenha,
                         pixKey: "12345678900",
                         date: ticket.dataHoraEmissao,
                       );
                     } catch (e) {
                       debugPrint("Erro impressao: $e");
                     }
                   },
                   borderRadius: BorderRadius.circular(20),
                   child: Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       crossAxisAlignment: CrossAxisAlignment.center,
                       children: [
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text('$resolvedEntityName', style: TextStyle(fontFamily: "Roboto", fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown[900])),
                               const SizedBox(height: 8),
                               Text('Médium: ${_formatMediumName(medium.nome)}', style: TextStyle(fontFamily: "Roboto", fontSize: 20, color: Colors.black87)),
                               const SizedBox(height: 8),
                               Text('Emitida às: ${DateFormat('HH:mm').format(ticket.dataHoraEmissao)}', style: TextStyle(fontFamily: "Roboto", fontSize: 18, color: Colors.grey[700])),
                             ],
                           ),
                         ),
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.end,
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Text('SENHA', style: TextStyle(fontFamily: "Roboto", fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[400], letterSpacing: 2)),
                             Text(ticket.codigoSenha, style: TextStyle(fontFamily: "Roboto", fontSize: 46, fontWeight: FontWeight.w900, color: Colors.brown[900])),
                           ],
                         ),
                       ],
                     ),
                   ),
                 ),
               );
             }
          )
        ),
      ]
    );
  }

  Widget _buildClosedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipOval(
          child: Image.asset('assets/images/logo.png', height: 120),
        ),
        const SizedBox(height: 20),
        Text("T.U.C.P.B.", style: TextStyle(fontFamily: "Roboto", fontSize: 48, fontWeight: FontWeight.bold, color: Colors.brown[900])),
        Text("Token System", style: TextStyle(fontFamily: "Roboto", fontSize: 24, color: Colors.brown[600], letterSpacing: 2)),
        const SizedBox(height: 40),
        Icon(Icons.lock_clock, size: 80, color: Colors.brown[200]),
        const SizedBox(height: 20),
        Text("TERREIRO FECHADO", style: TextStyle(fontFamily: "Roboto", fontSize: 40, fontWeight: FontWeight.bold, color: Colors.brown[900])),
        Text("Aguarde a abertura da Gira.", style: TextStyle(fontFamily: "Roboto", fontSize: 24, color: Colors.brown[400])),
      ],
    );
  }

  Widget _buildOpenState(Gira gira) {
    final terreiroId = ref.watch(selectedTerreiroIdProvider) ?? 'demo-terreiro';
    final activeMediumsAsync = ref.watch(activeMediumsProvider(terreiroId));

    return Column(
      children: [
        // Top Bar con Botón Volver y Título
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
                onPressed: () {
                  if (_selectedLine != null) {
                    setState(() {
                      _selectedLine = null;
                      _selectedTipo = null;
                    });
                  } else {
                    setState(() => _showEntitySelection = false);
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedLine == null 
                      ? "Escolha a linha:" 
                      : (_selectedTipo == null 
                          ? "Escolha a parte da Gira:" 
                          : "Escolha o guia:"),
                  style: TextStyle(fontFamily: "Roboto", fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                  child: Center(
                    child: activeMediumsAsync.when(
              data: (mediums) {
                if (mediums.isEmpty) {
                  return Center(child: Text("Nenhuma entidade disponível no momento.", style: TextStyle(fontFamily: "Roboto", fontSize: 20, color: Colors.brown[900])));
                }

                if (_selectedLine == null) {
                  // ETAPA 1: Mostrar seleção de linha baseada nas entidades disponíveis (já filtradas pelo provider)
                  var lines = mediums
                      .map((m) => m.entity.linha)
                      .where((l) => l.isNotEmpty)
                      .map((l) => normalizeSpiritualLine(l))
                      .where((l) => l.toUpperCase() == 'EXU') // Filtro temporário para a gira de hoje
                      .toSet()
                      .toList()
                    ..sort();

                  if (lines.isEmpty) {
                    // Fallback: mostrar todas as linhas disponíveis
                    lines = mediums.map((m) => m.entity.linha).where((l) => l.isNotEmpty).toSet().toList()..sort();
                  }

                  if (lines.isEmpty) {
                    return Center(child: Text("Nenhuma linha disponível no momento.", style: TextStyle(fontFamily: "Roboto", fontSize: 20, color: Colors.brown[900])));
                  }

                  return Wrap(
                    spacing: 30,
                    runSpacing: 30,
                    alignment: WrapAlignment.center,
                    children: lines.map((line) => _buildLineButton(line)).toList(),
                  );

                } else if (_selectedTipo == null) {
                  // ETAPA 2 (automática): Definir tipo como ALL e ir para entidades
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _selectedTipo == null) {
                      setState(() => _selectedTipo = 'ALL');
                    }
                  });
                  return const Center(child: CircularProgressIndicator(color: Colors.amber));

                } else {
                  // ETAPA 3: Mostrar entidades da linha selecionada
                  final filteredMediums = mediums.where((m) =>
                    m.entity.linha.toUpperCase() == (_selectedLine ?? '').toUpperCase()
                  ).toList();

                  Map<String, List<({Medium medium, Entidade entity})>> entityMap = {};
                  for (var pair in filteredMediums) {
                    entityMap.putIfAbsent(pair.entity.nome, () => []).add(pair);
                  }

                  if (entityMap.isEmpty) {
                    return Center(child: Text("Nenhum guia disponível para '${_selectedLine}'.", style: TextStyle(fontFamily: "Roboto", fontSize: 20, color: Colors.brown[900])));
                  }

                  // Converter o map para lista e aplicar a ordenação solicitada
                  final sortedEntries = entityMap.entries.toList();
                  sortedEntries.sort((a, b) {
                    final mediumA = a.value.first.medium.nome.toUpperCase();
                    final mediumB = b.value.first.medium.nome.toUpperCase();

                    int getPriority(String name) {
                      if (name.startsWith('SANDRA')) return 1;
                      if (name.startsWith('EDUARDO')) return 2;
                      if (name.startsWith('ROBSON')) return 3;
                      if (name.startsWith('JUCINEIDE')) return 4;
                      return 5;
                    }

                    final priorityA = getPriority(mediumA);
                    final priorityB = getPriority(mediumB);

                    if (priorityA != priorityB) {
                      return priorityA.compareTo(priorityB);
                    }
                    return mediumA.compareTo(mediumB); // Ordem alfabética para os demais (priority = 5)
                  });

                  bool isMany = sortedEntries.length > 5;
                  return Wrap(
                    spacing: isMany ? 20 : 30,
                    runSpacing: isMany ? 15 : 30,
                    alignment: WrapAlignment.center,
                    direction: isMany ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: sortedEntries.map((entry) {
                       final entityName = entry.key;
                       final pairs = entry.value;
                       final firstPair = pairs.first;
                       return _buildEntityButton(context, ref, terreiroId, gira, entityName, firstPair.entity.id, firstPair.medium, isCompact: isMany);
                    }).toList(),
                  );
                }
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
              error: (e, s) => Center(child: Text("Erro ao carregar: $e", style: const TextStyle(color: Colors.red))),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Rodapé com nome do Terreiro
        Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 10),
          child: Column(
            children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Container(width: 100, height: 1.5, color: const Color(0xFFFFD700)),
                   const SizedBox(width: 12),
                   Transform.rotate(
                     angle: 0.785398,
                     child: Container(width: 6, height: 6, color: const Color(0xFFFFD700)),
                   ),
                   const SizedBox(width: 6),
                   Transform.rotate(
                     angle: 0.785398,
                     child: Container(width: 10, height: 10, color: const Color(0xFFFFD700)),
                   ),
                   const SizedBox(width: 6),
                   Transform.rotate(
                     angle: 0.785398,
                     child: Container(width: 6, height: 6, color: const Color(0xFFFFD700)),
                   ),
                   const SizedBox(width: 12),
                   Container(width: 100, height: 1.5, color: const Color(0xFFFFD700)),
                 ],
               ),
               const SizedBox(height: 15),
               Text(
                 "T.U.C.P.B.",
                 textAlign: TextAlign.center,
                 style: TextStyle(fontFamily: "Roboto", color: Colors.black.withOpacity(0.8), fontSize: 28, fontWeight: FontWeight.bold),
               ),
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
                 child: Text(
                   "Tenda de Umbanda Caboclo Pena Branca e Tupi, Ogum Rompe Mato e Beira Mar & Mãe Maria da Cuia",
                   textAlign: TextAlign.center,
                   style: TextStyle(fontFamily: "Roboto", color: Colors.black.withOpacity(0.6), fontSize: 18),
                 ),
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
                  child: () {
                    final normalizedKey = line.toUpperCase()
                        .replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U')
                        .replaceAll('Â', 'A').replaceAll('Ê', 'E').replaceAll('Î', 'I').replaceAll('Ô', 'O').replaceAll('Û', 'U')
                        .replaceAll('Ã', 'A').replaceAll('Õ', 'O').replaceAll('Ç', 'C');
                    
                    if (_lineImages.containsKey(normalizedKey)) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          _lineImages[normalizedKey]!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(_lineIcons[line] ?? Icons.person_outline, size: 180, color: Colors.grey[700]),
                        ),
                      );
                    }
                    return Icon(_lineIcons[line] ?? Icons.person_outline, size: 180, color: Colors.grey[700]);
                  }(),
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
                  style: TextStyle(fontFamily: "Roboto", fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black87),
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
                  style: TextStyle(fontFamily: "Roboto", fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntityButton(BuildContext context, WidgetRef ref, String terreiroId, Gira gira, String entityName, String entityId, Medium medium, {bool isCompact = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 12.0, bottom: isCompact ? 2.0 : 4.0),
          child: Text(
            _formatMediumName(medium.nome),
            style: TextStyle(fontFamily: "Roboto", 
              fontSize: isCompact ? 18 : 20,
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
              width: isCompact ? 300 : 340,
              padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 20),
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
                style: TextStyle(fontFamily: "Roboto", 
                  fontSize: isCompact ? 20 : 24,
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Confirmar Senha", style: TextStyle(color: Colors.brown[900], fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Deseja retirar senha para:", style: TextStyle(color: Colors.brown[700])),
            const SizedBox(height: 10),
            Text(entityName, style: TextStyle(fontFamily: "Roboto", fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown[900])),
            const SizedBox(height: 20),
            Text("Médium: ${_formatMediumName(medium.nome)}", style: TextStyle(color: Colors.brown[400], fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("CANCELAR", style: TextStyle(color: Colors.brown[300])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[900],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext); // Fecha o diálogo usando o contexto do diálogo
              // Usa o contexto ORIGINAL da KioskScreen para processar o ticket
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

      debugPrint("[KIOSK] Ticket issued logic START for ${ticket.codigoSenha}");

      if (!context.mounted) {
        debugPrint("[KIOSK] Context NOT mounted after issueTicket");
        return;
      }

      setState(() {
        _lastIssuedTicket = ticket;
        _lastIssuedEntityName = entityName;
        _lastIssuedGira = gira;
      });

      debugPrint("[KIOSK] State updated. Starting print process...");

      // Print
      try {
        final printer = ref.read(printerServiceProvider);
        final mediumInitials = medium.nome.split(' ').where((n) => n.isNotEmpty).map((n) => n[0]).take(2).join().toUpperCase();
        
        debugPrint("[KIOSK] Calling printer.printTicket for ${ticket.codigoSenha}...");
        
        await printer.printTicket(
          terreiroName: "T.U.C.P.B.",
          giraName: gira.tema,
          entityName: entityName,
          mediumName: _formatMediumName(medium.nome),
          mediumInitials: mediumInitials,
          ticketCode: ticket.codigoSenha,
          pixKey: "12345678900",
          date: ticket.dataHoraEmissao,
        );
        debugPrint("[KIOSK] printer.printTicket call FINISHED.");
      } catch (printErr) {
        debugPrint("[KIOSK] EXCEPTION during print scan: $printErr");
      }

      debugPrint("[KIOSK] Final step of _processTicket reached.");

      // Voltar para a tela inicial após 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Sua senha é:",
            style: TextStyle(
              fontFamily: "Roboto",
              fontSize: 48,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            ticket.codigoSenha,
            style: TextStyle(
              fontFamily: "Roboto",
              fontSize: 70, // 50% menor que os 140 originais
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 60),
          Text(
            "Aguarde a impressão total!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "Roboto",
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.brown[900],
            ),
          ),
        ],
      ),
    );
  }
}

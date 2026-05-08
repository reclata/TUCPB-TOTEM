import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:terreiro_queue_system/src/shared/models/models.dart';

// Provider to stream the TV Panel
final tvPanelProvider = StreamProvider.family<TvPanel?, String>((ref, panelId) {
  return FirebaseFirestore.instance
      .collection('tvPanels')
      .doc(panelId)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return null;
    final data = snap.data()!;
    data['id'] = snap.id;
    return TvPanel.fromJson(data);
  });
});

// Provider para buscar a Gira ativa diretamente (Status: aberta)
final activeGiraProvider = StreamProvider<Gira?>((ref) {
  return FirebaseFirestore.instance
      .collection('giras')
      .where('status', isEqualTo: 'aberta')
      .limit(1)
      .snapshots()
      .map((snap) {
        if (snap.docs.isEmpty) return null;
        final data = snap.docs.first.data();
        data['id'] = snap.docs.first.id;
        return Gira.fromJson(data);
      });
});

// Provider to stream the history for this panel, filtered by Gira
final tvHistoryProvider = StreamProvider.family<List<Ticket>, String>((ref, arg) {
  final parts = arg.split('_');
  final panelId = parts[0];
  final giraId = parts.length > 1 ? parts[1] : '';
  
  var query = FirebaseFirestore.instance
      .collection('tickets')
      .where('panelId', isEqualTo: panelId);
      
  if (giraId.isEmpty) {
    return Stream.value([]); // Se não tem gira ativa, não mostra histórico
  }
  
  query = query.where('giraId', isEqualTo: giraId);
  
  return query
      .where('status', whereIn: ['chamada', 'atendida', 'nao_compareceu'])
      .orderBy('dataHoraChamada', descending: true)
      .limit(6)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Ticket.fromJson(d.data())).toList());
});

class TvScreen extends ConsumerWidget {
  final String panelId;
  const TvScreen({super.key, required this.panelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final panelAsync = ref.watch(tvPanelProvider(panelId));
    final activeGiraAsync = ref.watch(activeGiraProvider);
    
    // Pega o ID da Gira ativa diretamente (ignora o do painel que pode estar desatualizado)
    final activeGira = activeGiraAsync.value;
    final giraId = activeGira?.id ?? '';
    
    final historyAsync = ref.watch(tvHistoryProvider("${panelId}_$giraId"));

    return Scaffold(
      backgroundColor: Colors.black,
      body: panelAsync.when(
        data: (panel) {
          if (panel == null) {
            return const Center(
              child: Text(
                'PAINEL NÃO ENCONTRADO',
                style: TextStyle(color: Colors.red, fontSize: 36),
              ),
            );
          }

          final currentSenha = panel.senhaAtual;

          return Column(
            children: [
              // Tarja Superior
              const _TickerBanner(text: "FAÇA SUA CONTRIBUIÇÃO - PIX: (11) 992584595", isBottom: false),
              
              Expanded(
                child: historyAsync.when(
                  data: (history) {
                    // Filtra o histórico para não mostrar a senha atual de novo se ela estiver no topo
                    final filteredHistory = history.where((t) => currentSenha == null || t.id != currentSenha.senhaId).take(5).toList();
                    
                    final bool hasActiveGira = activeGira != null;
                    final bool showSidebar = currentSenha != null;
                    
                    if (!hasActiveGira || !showSidebar) {
                      // Se não tem gira ativa OU não tem nenhuma senha chamada AGORA, mostra o carrossel em TELA CHEIA
                      return const _IdleCarousel();
                    }
                    
                    // Se tem senhas, mostra a tela dividida
                    return Row(
                      children: [
                        // Painel principal — senha chamada
                        Expanded(
                          flex: 2,
                          child: Container(
                            color: Colors.brown[900],
                            child: currentSenha == null
                                ? const _IdleCarousel() // Fallback se tiver histórico mas nenhuma chamada agora
                                : _buildCurrentSenhaPanel(currentSenha),
                          ),
                        ),

                        // Sidebar — histórico
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: const Color(0xFF2E1C15),
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 24),
                                ClipOval(
                                  child: Image.asset('assets/images/logo.png', height: 120),
                                ),
                                const SizedBox(height: 48),
                                Text(
                                  'ÚLTIMAS CHAMADAS',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white38,
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: filteredHistory.length,
                                    itemBuilder: (context, index) {
                                      return _HistoryItem(ticket: filteredHistory[index]);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Aguarde sua senha ser chamada',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    color: Colors.white24,
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
                  error: (e, s) {
                    if (currentSenha == null) {
                      return const _IdleCarousel();
                    }
                    return Container(
                      color: Colors.brown[900],
                      child: _buildCurrentSenhaPanel(currentSenha),
                    );
                  },
                ),
              ),
              // Tarja Inferior
              const _TickerBanner(text: "AXÉ", isBottom: true),
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

  // Widget auxiliar para construir o painel da senha atual
  Widget _buildCurrentSenhaPanel(TvPanelSenhaAtual currentSenha) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Header: Terreiro / Gira
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            children: [
              Text(
                'T.U.C.P.B.',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  color: Colors.white54,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentSenha.giraNome.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
        
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Text(
            'SENHA CHAMADA',
            style: GoogleFonts.outfit(
              fontSize: 36,
              color: Colors.amber,
              fontWeight: FontWeight.w600,
              letterSpacing: 6,
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Código da senha em destaque
        Text(
          currentSenha.codigoSenha,
          style: GoogleFonts.outfit(
            fontSize: 240,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 40),

        // Entidade e Médium
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text(
                currentSenha.entidadeNome.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 48, 
                  fontWeight: FontWeight.bold,
                  color: Colors.amber, 
                  letterSpacing: 2
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'MÉDIUM: ${currentSenha.mediumNome.toUpperCase()}',
                style: GoogleFonts.outfit(
                  fontSize: 28, 
                  color: Colors.white70,
                  letterSpacing: 2
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
        // Mensagem
        Text(
          'DIRIJA-SE AO ATENDIMENTO',
          style: GoogleFonts.outfit(
            fontSize: 32, 
            color: Colors.greenAccent,
            fontWeight: FontWeight.w500,
            letterSpacing: 2
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Text(
            ticket.codigoSenha,
            style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white60,
            ),
          ),
          const Spacer(),
          Text(
            ticket.dataHoraChamada != null
                ? DateFormat('HH:mm').format(ticket.dataHoraChamada!)
                : '--:--',
            style: GoogleFonts.outfit(fontSize: 24, color: Colors.white30),
          ),
        ],
      ),
    );
  }
}

class _TickerBanner extends StatefulWidget {
  final String text;
  final bool isBottom;
  const _TickerBanner({required this.text, required this.isBottom});

  @override
  State<_TickerBanner> createState() => _TickerBannerState();
}

class _TickerBannerState extends State<_TickerBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _textWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final textSpan = TextSpan(
      text: '${widget.text}   ✦   ',
      style: GoogleFonts.outfit(
        fontSize: 28, 
        color: Colors.amber, 
        fontWeight: FontWeight.bold, 
        letterSpacing: 6
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: Directionality.of(context),
    );
    textPainter.layout();
    _textWidth = textPainter.width;

    if (_textWidth > 0) {
      _controller.duration = Duration(milliseconds: (_textWidth / 100 * 1000).toInt());
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final int repeatCount = _textWidth > 0 ? (screenWidth / _textWidth).ceil() + 3 : 10;
    final fullText = List.generate(repeatCount, (_) => '${widget.text}   ✦   ').join('');

    return Container(
      height: 60,
      width: double.infinity,
      color: widget.isBottom ? Colors.brown[900] : Colors.brown[800],
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(-_textWidth * _controller.value, 0),
            child: child,
          );
        },
        child: OverflowBox(
          maxWidth: double.infinity,
          alignment: Alignment.centerLeft,
          child: Text(
            fullText,
            style: GoogleFonts.outfit(
              fontSize: 28, 
              color: Colors.amber, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 6
            ),
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );
  }
}

class _IdleCarousel extends StatefulWidget {
  const _IdleCarousel();
  @override
  State<_IdleCarousel> createState() => _IdleCarouselState();
}

class _IdleCarouselState extends State<_IdleCarousel> {
  int _currentIndex = 0;
  late Timer _timer;

  final List<String> _images = [
    "assets/images/TUCPB 1.png",
    "assets/images/TUCPB 2.png",
    "assets/images/TUCPB 3.png",
    "assets/images/TUCPB 4.png",
    "assets/images/TUCPB 5.png",
    "assets/images/TUCPB 6.png",
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() => _currentIndex = (_currentIndex + 1) % _images.length);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.brown[900],
      child: AnimatedSwitcher(
        duration: const Duration(seconds: 2),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: Image.asset(
          _images[_currentIndex],
          key: ValueKey(_currentIndex),
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

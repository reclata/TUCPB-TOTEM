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

// Provider to stream the history for this panel
final tvHistoryProvider = StreamProvider.family<List<Ticket>, String>((ref, panelId) {
  return FirebaseFirestore.instance
      .collection('tickets')
      .where('panelId', isEqualTo: panelId)
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
    final historyAsync = ref.watch(tvHistoryProvider(panelId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: panelAsync.when(
        data: (panel) {
          if (panel == null) {
            return const Center(
              child: Text(
                'PAINEL NÃƒO ENCONTRADO',
                style: TextStyle(color: Colors.red, fontSize: 36),
              ),
            );
          }

          final currentSenha = panel.senhaAtual;

          return Column(
            children: [
              // Tarja Superior
              const _TickerBanner(text: "FAÃ‡A SUA CONTRIBUIÃ‡ÃƒO - PIX: (11) 992584595", isBottom: false),
              
              Expanded(
                child: Row(
                  children: [
                    // Painel principal â€” senha chamada
                    Expanded(
                      flex: 2,
                      child: Container(
                  color: Colors.brown[900],
                  child: currentSenha == null
                      ? const _IdleCarousel()
                      : Column(
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

                            // CÃ³digo da senha em destaque
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

                            // Entidade e MÃ©dium
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
                                    'MÃ‰DIUM: ${currentSenha.mediumNome.toUpperCase()}',
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
                        ),
                ),
              ),

              // Sidebar â€” histÃ³rico
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
                        'ÃšLTIMAS CHAMADAS',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          color: Colors.white38,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: historyAsync.when(
                          data: (history) {
                            // Filtra o histÃ³rico para nÃ£o mostrar a senha atual de novo se ela estiver no topo
                            final filteredHistory = history.where((t) => currentSenha == null || t.id != currentSenha.senhaId).take(5).toList();
                            if (filteredHistory.isEmpty) {
                              return Center(
                                child: Text('Nenhum histÃ³rico', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 18)),
                              );
                            }
                            return ListView.builder(
                              itemCount: filteredHistory.length,
                              itemBuilder: (context, index) {
                                return _HistoryItem(ticket: filteredHistory[index]);
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
                          error: (_, __) => const Center(child: Text('Erro ao carregar histÃ³rico', style: TextStyle(color: Colors.red))),
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
                ),
              ),
              // Tarja Inferior
              const _TickerBanner(text: "AXÃ‰", isBottom: true),
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


// =============================================================================
// TICKER BANNER (Tarja que se movimenta)
// =============================================================================
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
    
    // Measure the width of one block of text
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

    // Set duration based on width so speed is constant (e.g. 100 pixels per second)
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
    // Repeat enough times to cover screen width plus extra for the loop
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

// =============================================================================
// IDLE CAROUSEL (Mensagens quando vazio)
// =============================================================================
class _IdleCarousel extends StatefulWidget {
  const _IdleCarousel();
  @override
  State<_IdleCarousel> createState() => _IdleCarouselState();
}

class _IdleCarouselState extends State<_IdleCarousel> {
  int _currentIndex = 0;
  late Timer _timer;

  final List<String> _messages = [
    "BEM-VINDOS AO T.U.C.P.B.\nSinta-se em casa!",
    "PONTOS DA GIRA\nAguarde o início dos trabalhos e prepare sua vibração.",
    "CURIOSIDADE\nA Umbanda é paz, amor e caridade.",
    "MANTENHA O SILÊNCIO\nDesligue o celular e concentre-se nas preces.",
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (mounted) {
        setState(() => _currentIndex = (_currentIndex + 1) % _messages.length);
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
    return Padding(
      padding: const EdgeInsets.all(60.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/images/logo.png", 
            height: 250, 
            color: Colors.white12, 
            colorBlendMode: BlendMode.srcIn
          ),
          const SizedBox(height: 80),
          AnimatedSwitcher(
            duration: const Duration(seconds: 2),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: Text(
              _messages[_currentIndex],
              key: ValueKey(_currentIndex),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.amber[100],
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


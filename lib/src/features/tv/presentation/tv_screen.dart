import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:terreiro_queue_system/src/features/admin/data/admin_repository.dart';
import 'package:terreiro_queue_system/src/shared/models/models.dart';
import 'package:terreiro_queue_system/src/shared/utils/spiritual_utils.dart';

import 'package:terreiro_queue_system/src/shared/providers/global_providers.dart';
import 'package:terreiro_queue_system/src/shared/services/call_sound_service.dart';

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

class TvScreen extends ConsumerStatefulWidget {
  final String panelId;
  const TvScreen({super.key, required this.panelId});

  @override
  ConsumerState<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends ConsumerState<TvScreen> {
  String? _lastSoundKey;
  bool _soundEnabled = false;
  Timer? _closeTimer;

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _enableSound() {
    if (_soundEnabled) return;
    CallSoundService.instance.unlockFromGesture();
    setState(() => _soundEnabled = true);
  }

  void _onPanelUpdate(TvPanel? panel, String giraId) {
    if (panel == null || panel.giraId != giraId) {
      _closeTimer?.cancel();
      _closeTimer = null;
      return;
    }
    final senha = panel.senhaAtual;
    if (senha == null) {
      _closeTimer?.cancel();
      _closeTimer = null;
      return;
    }

    final key =
        '${senha.senhaId}_${senha.chamadaCount}_${senha.dataHoraChamada.millisecondsSinceEpoch}';
    if (_lastSoundKey == key) return;
    _lastSoundKey = key;
    CallSoundService.instance.playCallSound();

    _closeTimer?.cancel();
    _closeTimer = null;

    if (senha.isLastTicket) {
      debugPrint('[TV_SCREEN] Última senha detectada chamada no painel. Aguardando 15 min para encerrar a Gira.');
      _closeTimer = Timer(const Duration(minutes: 15), () async {
        if (!mounted) return;
        try {
          debugPrint('[TV_SCREEN] Encerrando a Gira $giraId automaticamente após 15 minutos do último chamado.');
          await ref.read(adminRepositoryProvider).closeGira(giraId);
        } catch (e) {
          debugPrint('[TV_SCREEN] Erro ao encerrar Gira $giraId automaticamente: $e');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const terreiroId = 'demo-terreiro';
    final panelAsync = ref.watch(tvPanelProvider(widget.panelId));
    final activeGiraAsync = ref.watch(activeGiraProvider(terreiroId));

    final activeGira = activeGiraAsync.value;
    final giraId = activeGira?.id ?? '';

    ref.listen<AsyncValue<TvPanel?>>(tvPanelProvider(widget.panelId), (prev, next) {
      final currentGiraId = ref.read(activeGiraProvider(terreiroId)).valueOrNull?.id ?? '';
      _onPanelUpdate(next.valueOrNull, currentGiraId);
    });

    final historyAsync = ref.watch(tvHistoryProvider("${widget.panelId}_$giraId"));

    final screenHeight = MediaQuery.of(context).size.height;
    final scale = screenHeight / 1080;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          panelAsync.when(
        data: (panel) {
          if (panel == null) {
            return const Center(
              child: Text(
                'PAINEL NÃO ENCONTRADO',
                style: TextStyle(color: Colors.red, fontSize: 36),
              ),
            );
          }

          // Mostrar a senha atual do painel (callPassword sempre atualiza o giraId corretamente)
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
                      return _IdleCarousel(images: panel.carouselImages);
                    }
                    
                    // Se tem senhas, mostra a tela dividida
                    return Row(
                      children: [
                        // Painel principal — senha chamada
                        Expanded(
                          flex: 2,
                          child: Container(
                            color: Colors.brown[900],
                            child: _buildCurrentSenhaPanel(currentSenha, scale),
                          ),
                        ),

                        // Sidebar — histórico
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: const Color(0xFF2E1C15),
                            padding: EdgeInsets.all(32 * scale),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: 24 * scale),
                                ClipOval(
                                  child: Image.asset('assets/images/logo.png', height: 120 * scale),
                                ),
                                SizedBox(height: 48 * scale),
                                Text(
                                  'ÚLTIMAS CHAMADAS',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white38,
                                    fontSize: 16 * scale,
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 32 * scale),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: filteredHistory.length,
                                    itemBuilder: (context, index) {
                                      return _HistoryItem(ticket: filteredHistory[index]);
                                    },
                                  ),
                                ),
                                SizedBox(height: 24 * scale),
                                Text(
                                  'Aguarde sua senha ser chamada',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18 * scale,
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
                      return _IdleCarousel(images: panel.carouselImages);
                    }
                    return Container(
                      color: Colors.brown[900],
                      child: _buildCurrentSenhaPanel(currentSenha, scale),
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
          if (!_soundEnabled)
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (_) => _enableSound(),
                child: ColoredBox(
                  color: Colors.black26,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 80 * scale),
                      child: Material(
                        color: Colors.brown[900],
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24 * scale,
                            vertical: 16 * scale,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.volume_up, color: Colors.amber, size: 32 * scale),
                              SizedBox(width: 12 * scale),
                              Flexible(
                                child: Text(
                                  'TOQUE EM QUALQUER LUGAR DA TELA PARA ATIVAR O SOM',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: Colors.amber,
                                    fontSize: 18 * scale,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentSenhaPanel(TvPanelSenhaAtual currentSenha, double scale) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Header: Terreiro / Gira
        Padding(
          padding: EdgeInsets.only(bottom: 40 * scale),
          child: Column(
            children: [
              Text(
                'T.U.C.P.B.',
                style: GoogleFonts.outfit(
                  fontSize: 24 * scale,
                  color: Colors.white54,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentSenha.giraNome.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 32 * scale,
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
          padding: EdgeInsets.symmetric(horizontal: 40 * scale, vertical: 12 * scale),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Text(
            'SENHA CHAMADA',
            style: GoogleFonts.outfit(
              fontSize: 36 * scale,
              color: Colors.amber,
              fontWeight: FontWeight.w600,
              letterSpacing: 6,
            ),
          ),
        ),
        SizedBox(height: 40 * scale),

        // Código da senha em destaque
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            currentSenha.codigoSenha,
            style: GoogleFonts.outfit(
              fontSize: 240 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        SizedBox(height: 40 * scale),

        // Entidade e Médium
        Container(
          padding: EdgeInsets.all(32 * scale),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text(
                'MÉDIUM: ${formatMediumName(currentSenha.mediumNome).toUpperCase()}',
                style: GoogleFonts.outfit(
                  fontSize: 32 * scale, 
                  color: Colors.white70,
                  letterSpacing: 2
                ),
              ),
              SizedBox(height: 16 * scale),
              Text(
                currentSenha.entidadeNome.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 56 * scale, 
                  fontWeight: FontWeight.bold,
                  color: Colors.amber, 
                  letterSpacing: 2
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 40 * scale),
        // Mensagem
        Text(
          'DIRIJA-SE AO ATENDIMENTO',
          style: GoogleFonts.outfit(
            fontSize: 32 * scale, 
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
    final scale = MediaQuery.of(context).size.height / 1080;

    return Container(
      margin: EdgeInsets.only(bottom: 16 * scale),
      padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 20 * scale),
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
              fontSize: 36 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.white60,
            ),
          ),
          const Spacer(),
          Text(
            ticket.dataHoraChamada != null
                ? DateFormat('HH:mm').format(ticket.dataHoraChamada!)
                : '--:--',
            style: GoogleFonts.outfit(fontSize: 24 * scale, color: Colors.white30),
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
    
    final scale = MediaQuery.of(context).size.height / 1080;
    final textSpan = TextSpan(
      text: '${widget.text}   ✦   ',
      style: GoogleFonts.outfit(
        fontSize: 28 * scale, 
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
    final scale = MediaQuery.of(context).size.height / 1080;
    final int repeatCount = _textWidth > 0 ? (screenWidth / _textWidth).ceil() + 3 : 10;
    final fullText = List.generate(repeatCount, (_) => '${widget.text}   ✦   ').join('');

    return Container(
      height: 60 * scale,
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
              fontSize: 28 * scale, 
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
  final List<String>? images;
  const _IdleCarousel({this.images});

  @override
  State<_IdleCarousel> createState() => _IdleCarouselState();
}

class _IdleCarouselState extends State<_IdleCarousel> {
  int _currentIndex = 0;
  late Timer _timer;

  final List<String> _defaultImages = [
    "assets/images/TUCPB 1.png",
    "assets/images/TUCPB 2.png",
    "assets/images/TUCPB 3.png",
    "assets/images/TUCPB 4.png",
    "assets/images/TUCPB 5.png",
    "assets/images/TUCPB 8.png",
    "assets/images/TUCPB 7.png",
  ];

  List<String> get _images => (widget.images == null || widget.images!.isEmpty)
      ? _defaultImages
      : widget.images!;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          if (_images.isNotEmpty) {
            _currentIndex = (_currentIndex + 1) % _images.length;
          } else {
            _currentIndex = 0;
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _IdleCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentIndex >= _images.length) {
      _currentIndex = 0;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.brown[900],
        child: const Center(
          child: Icon(Icons.photo, color: Colors.white24, size: 64),
        ),
      );
    }

    final imagePath = _images[_currentIndex];

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.brown[900],
      child: AnimatedSwitcher(
        duration: const Duration(seconds: 2),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _buildImage(imagePath),
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    if (imagePath.startsWith('data:image/')) {
      try {
        final base64String = imagePath.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          key: ValueKey(imagePath.hashCode),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, color: Colors.white24, size: 64),
            );
          },
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.white24, size: 64),
        );
      }
    } else if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        key: ValueKey(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.white24, size: 64),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        },
      );
    } else {
      return Image.asset(
        imagePath,
        key: ValueKey(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.white24, size: 64),
          );
        },
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tabs/aba_asaas.dart';
import 'tabs/aba_avulsos.dart';
import 'tabs/aba_geral_financeiro.dart';
import 'tabs/aba_pagamentos.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';
import 'package:tucpb_adm/src/features/auth/presentation/auth_user_provider.dart';

class FinanceiroScreen extends ConsumerStatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  ConsumerState<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends ConsumerState<FinanceiroScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Valor inicial do length, será recriado no build se necessário or handled differently
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider).asData?.value;
    final perfil = (userData?['perfil'] ?? '').toString().toLowerCase();
    
    final isAdmin = ['admin', 'suporte', 'administrador', 'dirigente'].contains(perfil);
    final isMedium = perfil.contains('medium') || perfil.contains('médium') || perfil.contains('cambone') || perfil.contains('cambono');
    final isAssistencia = perfil.contains('assistencia') || perfil == 'público' || perfil == 'visitante';

    // Configuração de abas baseada no perfil
    List<Widget> tabWidgets = [];
    List<Widget> contentWidgets = [];

    if (isAdmin) {
      tabWidgets = const [
        Tab(icon: Icon(Icons.dashboard, size: 16), text: 'Geral'),
        Tab(icon: Icon(Icons.credit_card, size: 16), text: 'ASAAS'),
        Tab(icon: Icon(Icons.receipt_long, size: 16), text: 'Avulsos'),
        Tab(icon: Icon(Icons.payment, size: 16), text: 'Pagamentos'),
      ];
      contentWidgets = const [AbaGeral(), AbaAsaas(), AbaAvulsos(), AbaPagamentos()];
    } else if (isMedium) {
      tabWidgets = const [
        Tab(icon: Icon(Icons.history, size: 16), text: 'Meu Histórico'),
        Tab(icon: Icon(Icons.receipt_long, size: 16), text: 'Contribuir (Avulso)'),
      ];
      contentWidgets = const [AbaGeral(), AbaAvulsos()];
    } else if (isAssistencia) {
      tabWidgets = const [
        Tab(icon: Icon(Icons.receipt_long, size: 16), text: 'Contribuir (PIX/Cartão)'),
      ];
      contentWidgets = const [AbaAvulsos()];
    } else {
      // Default / Desconhecido
      tabWidgets = const [Tab(icon: Icon(Icons.receipt_long, size: 16), text: 'Avulsos')];
      contentWidgets = const [AbaAvulsos()];
    }

    // Recria o TabController se o tamanho mudar (raro em tempo real, mas seguro)
    if (_tabController.length != tabWidgets.length) {
      _tabController.dispose();
      _tabController = TabController(length: tabWidgets.length, vsync: this);
    }

    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(
        children: [
          // ═══ Header ═══
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            color: AdminTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Financeiro',
                            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                        Text(isAdmin ? 'Gestão completa do financeiro' : 'Sua área financeira',
                            style: TextStyle(color: AdminTheme.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.link, size: 14, color: Colors.blue),
                            SizedBox(width: 4),
                            Text('ASAAS + PagSeguro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AdminTheme.primary,
                  unselectedLabelColor: AdminTheme.textSecondary,
                  indicatorColor: AdminTheme.primary,
                  indicatorWeight: 3,
                  isScrollable: !isAdmin,
                  tabs: tabWidgets,
                ),
              ],
            ),
          ),

          // ═══ Conteúdo das abas ═══
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: contentWidgets,
            ),
          ),
        ],
      ),
    );
  }
}

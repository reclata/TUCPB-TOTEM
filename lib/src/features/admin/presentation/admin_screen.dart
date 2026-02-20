
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:terreiro_queue_system/src/shared/models/models.dart';
import '../data/admin_repository.dart';
import 'package:terreiro_queue_system/src/shared/providers/global_providers.dart';
import 'package:terreiro_queue_system/src/features/queue/data/firestore_queue_repository.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'usuarios_section.dart';
import 'senhas_screen.dart';

const List<String> LINHA_OPTIONS = [
  'Caboclo',
  'Erê',
  'Preto Velho',
  'Boiadeiro',
  'Marinheiro',
  'Malandro',
  'Baiano',
  'Cigano',
  'Esquerda',
  'Feiticeiro',
];

const List<String> TIPO_OPTIONS = [
  'Caboclo',
  'Cabocla',
  'Menino',
  'Menina',
  'Preta Velha',
  'Preto Velho',
  'Boiadeiro',
  'Vaqueiro',
  'Marinheiro',
  'Malandro',
  'Malandra',
  'Baiana',
  'Baiano',
  'Cigano',
  'Cigana',
  'Exu',
  'Pomba Gira',
  'Pombo Giro',
  'Exu Mirim',
  'Feiticeiro',
  'Feiticeira',
];

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Off-white
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.brown[900],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                )
              ],
            ),
            child: Column(
              children: [
                // Logo & Title
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.temple_buddhist, size: 60, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'T.U.C.P.B.',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Token System',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 20),
                
                // Menu Items
                if (user?.perfilAcesso == 'admin' || (user?.permissoes.contains('dashboard') ?? false))
                  _buildMenuItem(Icons.dashboard_outlined, 'Dashboard', 0),
                if (user?.perfilAcesso == 'admin' || (user?.permissoes.contains('cadastros') ?? false))
                  _buildMenuItem(Icons.folder_shared_outlined, 'Cadastros', 1),
                if (user?.perfilAcesso == 'admin' || (user?.permissoes.contains('calendario') ?? false))
                  _buildMenuItem(Icons.calendar_month_outlined, 'Calendário', 2),
                if (user?.perfilAcesso == 'admin' || (user?.permissoes.contains('senhas') ?? false))
                  _buildMenuItem(Icons.confirmation_number_outlined, 'Senhas', 3),
                if (user?.perfilAcesso == 'admin' || (user?.permissoes.contains('usuarios') ?? false))
                  _buildMenuItem(Icons.people_outline, 'Usuários', 4),
                
                const Spacer(),
                
                // Quick Actions
                const Divider(color: Colors.white24, height: 1),
                ListTile(
                  leading: const Icon(Icons.tv, color: Colors.white70, size: 20),
                  title: Text('Painel TV', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                  onTap: () => context.push('/tv/demo-terreiro'),
                ),
                ListTile(
                  leading: const Icon(Icons.monitor, color: Colors.white70, size: 20),
                  title: Text('Totem', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                  onTap: () => context.push('/kiosk'),
                ),
                
                if (user?.perfilAcesso == 'admin')
                  const Divider(color: Colors.white24, height: 1),
                if (user?.perfilAcesso == 'admin')
                  _buildMenuItem(Icons.settings_outlined, 'Configurações', 5),
                
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70, size: 20),
                  title: Text('Sair', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                  onTap: () => context.go('/login'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 85,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getTitle(),
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[800],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.notifications_outlined, color: Colors.brown[700]),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 24),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.brown[100],
                            radius: 18,
                            child: Icon(Icons.person, color: Colors.brown[700], size: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ref.watch(currentUserProvider)?.nomeCompleto ?? 'Usuário',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[900],
                            ),
                          ),
                          Text(
                            _getPerfilLabel(ref.watch(currentUserProvider)?.perfilAcesso ?? ''),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Colors.brown[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Body
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPerfilLabel(String perfil) {
    switch (perfil) {
      case 'admin':
        return 'Administrador';
      case 'operador':
        return 'Operador';
      case 'visualizador':
        return 'Visualizador';
      default:
        return perfil;
    }
  }

  Widget _buildMenuItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.brown[700] : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: 22,
        ),
        title: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Cadastros';
      case 2:
        return 'Calendário de Giras';
      case 3:
        return 'Senhas';
      case 4:
        return 'Usuários';
      case 5:
        return 'Configurações de Acesso';
      default:
        return 'T.U.C.P.B. Token';
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _DashboardScreen(onNavigate: (index) => setState(() => _selectedIndex = index));
      case 1:
        return _CadastrosScreen();
      case 2:
        return _AdminDashboard();
      case 3:
        return const SenhasScreen();
      case 4:
        return const UsuariosScreen();
      case 5:
        return _ConfiguracoesScreen();
      default:
        return const Center(child: Text('Em construção'));
    }
  }
}

// =============================================================================
// DASHBOARD INICIAL
// =============================================================================
class _DashboardScreen extends ConsumerWidget {
  final Function(int) onNavigate;

  const _DashboardScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const terreiroId = 'demo-terreiro';
    final girasAsync = ref.watch(giraListProvider(terreiroId));
    final mediumsAsync = ref.watch(mediumListProvider(terreiroId));
    final ticketsAsync = ref.watch(ticketListProvider(terreiroId));
    final activeGiraAsync = ref.watch(activeGiraProvider(terreiroId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown[700]!, Colors.brown[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bem-vindo de volta!',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gerencie as giras, médiuns e atendimentos',
                        style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.stacked_line_chart, size: 80, color: Colors.white.withOpacity(0.3)),
                const SizedBox(width: 16),
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => onNavigate(3), // Navigate to Senhas index
                        icon: const Icon(Icons.campaign),
                        label: const Text('CHAMAR SENHAS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.brown[700],
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () async {
                          try {
                            await ref.read(adminRepositoryProvider).generateSeedData(terreiroId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Dados de teste gerados com sucesso!')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao gerar dados: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.auto_fix_high, size: 16),
                        label: const Text('GERAR DADOS', style: TextStyle(fontSize: 10)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Porteiro Metrics Header
          activeGiraAsync.when(
            data: (activeGira) {
              if (activeGira == null) {
                return _buildStatCard(
                  'Gira',
                  'Nenhuma aberta',
                  Icons.event_busy,
                  Colors.grey,
                );
              }
              
              final presentMediumsCount = activeGira.presencas.values.where((p) => p).length;
              final todayTickets = ticketsAsync.value?.where((t) => t.giraId == activeGira.id).toList() ?? [];
              final assistanceCount = todayTickets.length;
              final calledCount = todayTickets.where((t) => t.status != 'emitida').length;

              return Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      int crossAxisCount = 4;
                      if (width < 600) crossAxisCount = 1;
                      else if (width < 900) crossAxisCount = 2;
                      
                      final double gap = 16.0;
                      final double cardWidth = (width - (gap * (crossAxisCount - 1))) / crossAxisCount;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              'Médiuns na Gira',
                              presentMediumsCount.toString(),
                              Icons.people,
                              Colors.brown,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              'Assistência do Dia',
                              assistanceCount.toString(),
                              Icons.confirmation_number,
                              Colors.amber[800]!,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              'Senhas Chamadas',
                              calledCount.toString(),
                              Icons.campaign,
                              Colors.green,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _buildStatCard(
                              'Transferências do Dia',
                              todayTickets.where((t) => t.isRedistributed).length.toString(),
                              Icons.swap_horiz,
                              Colors.purple,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Real-time Table
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Visualização Geral das Senhas',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[800],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.sync, size: 14, color: Colors.green[700]),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tempo Real',
                                    style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2),
                          },
                          border: TableBorder(
                            horizontalInside: BorderSide(color: Colors.grey[200]!, width: 1),
                          ),
                          children: [
                            TableRow(
                              children: [
                                _tableHeader('NOME DO MÉDIUM'),
                                _tableHeader('SENHAS EMITIDAS'),
                                _tableHeader('SENHAS CHAMADAS'),
                              ],
                            ),
                            ...mediumsAsync.when(
                              data: (mediums) {
                                final presentMediums = mediums.where((m) => activeGira.presencas[m.id] ?? false).toList();
                                presentMediums.sort((a, b) => a.nome.compareTo(b.nome));
                                
                                return presentMediums.map((m) {
                                  final mTickets = todayTickets.where((t) => t.mediumId == m.id).toList();
                                  final mIssued = mTickets.length;
                                  final mCalled = mTickets.where((t) => t.status != 'emitida').length;
                                  
                                  return TableRow(
                                    children: [
                                      _tableCell(m.nome, isBold: true),
                                      _tableCell('$mIssued', alignment: Alignment.center),
                                      _tableCell('$mCalled', alignment: Alignment.center, color: Colors.green[700]),
                                    ],
                                  );
                                }).toList();
                              },
                              loading: () => [TableRow(children: [const Text('...'), const Text('...'), const Text('...')])],
                              error: (_, __) => [TableRow(children: [const Text('Erro'), const Text('Erro'), const Text('Erro')])],
                            ),
                          ],
                        ),
                        if (activeGira.presencas.values.every((p) => !p))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'Nenhum médium com presença marcada nesta gira.',
                                style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text('Erro ao carregar métricas: $e'),
          ),
          
          const SizedBox(height: 32),
          
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Médiuns',
                  mediumsAsync.value?.length.toString() ?? '...',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Atendimentos',
                  ticketsAsync.value?.where((t) => t.status == 'atendida').length.toString() ?? '...',
                  Icons.poll,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Giras Abertas',
                  girasAsync.value?.where((g) => g.status == 'aberta').length.toString() ?? '...',
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total de Giras',
                  girasAsync.value?.length.toString() ?? '...',
                  Icons.event_note,
                  Colors.purple,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Charts Row
          ticketsAsync.when(
            data: (tickets) {
              final giras = girasAsync.value ?? [];
              final mediums = mediumsAsync.value ?? [];
              
              // Calcs for Charts
              final completedTickets = tickets.where((t) => t.status == 'atendida' || t.dataHoraAtendida != null).toList();
              
              // 1. Atendimentos por Gira
              final Map<String, int> attendanceByGira = {};
              for (var t in completedTickets) {
                final gira = giras.cast<Gira?>().firstWhere((g) => g?.id == t.giraId, orElse: () => null);
                final giraLabel = gira != null ? gira.tema : 'Gira Antiga';
                attendanceByGira[giraLabel] = (attendanceByGira[giraLabel] ?? 0) + 1;
              }
              
              // 2. Atendimentos por Médium
              final Map<String, int> attendanceByMedium = {};
              for (var t in completedTickets) {
                final medium = mediums.cast<Medium?>().firstWhere((m) => m?.id == t.mediumId, orElse: () => null);
                final mediumLabel = medium != null ? medium.nome : 'Ex-Médium';
                attendanceByMedium[mediumLabel] = (attendanceByMedium[mediumLabel] ?? 0) + 1;
              }

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gira Chart
                      Expanded(
                        child: _buildChartContainer(
                          title: 'Atendimentos por Gira',
                          child: _BarChartWidget(
                            data: attendanceByGira,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Medium Chart
                      Expanded(
                        child: _buildChartContainer(
                          title: 'Atendimentos por Médium',
                          child: _BarChartWidget(
                            data: attendanceByMedium,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Erro ao carregar dados dos gráficos: $e')),
          ),
          
          const SizedBox(height: 32),

          // Próximas Giras (Recuperado do antigo layout)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Próximas Giras',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
              const SizedBox(height: 16),
              girasAsync.when(
                data: (giras) {
                  if (giras.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text('Nenhuma gira agendada', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final today = DateTime.now();
                  final upcomingGiras = giras.where((g) => g.data.isAfter(today.subtract(const Duration(days: 1)))).take(5).toList();
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: upcomingGiras.length,
                    itemBuilder: (ctx, index) {
                      final gira = upcomingGiras[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: gira.status == 'aberta' ? Colors.green : Colors.brown[200],
                            child: Icon(
                              gira.status == 'aberta' ? Icons.radio_button_checked : Icons.schedule,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(gira.tema, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(DateFormat('dd/MM/yyyy - HH:mm').format(gira.data), style: const TextStyle(fontSize: 12)),
                          trailing: gira.status == 'aberta' 
                            ? const Chip(
                                label: Text('ATIVA', style: TextStyle(fontSize: 10)),
                                backgroundColor: Colors.green,
                                labelStyle: TextStyle(color: Colors.white),
                                padding: EdgeInsets.symmetric(horizontal: 8),
                              )
                            : null,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Erro: $e'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.brown[400],
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _tableCell(String value, {bool isBold = false, Alignment alignment = Alignment.centerLeft, Color? color}) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Text(
        value,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: color ?? Colors.brown[900],
        ),
      ),
    );
  }

  Widget _buildChartContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final Map<String, int> data;
  final Color color;

  const _BarChartWidget({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Sem dados para exibir',
          style: GoogleFonts.outfit(color: Colors.grey[400]),
        ),
      );
    }

    // Ordenar por valor (decrescente) e pegar top 5
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final displayEntries = sortedEntries.take(5).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (displayEntries.map((e) => e.value).fold(0, (prev, curr) => curr > prev ? curr : prev).toDouble() * 1.5).clamp(5, 1000),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.brown[800]!,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${displayEntries[groupIndex].key}\n',
                GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                children: [
                  TextSpan(
                    text: '${rod.toY.toInt()} atendimentos',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= displayEntries.length) return const SizedBox();
                final label = displayEntries[index].key;
                final shortLabel = label.length > 8 ? '${label.substring(0, 7)}.' : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(shortLabel, style: GoogleFonts.outfit(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0) return const SizedBox();
                return Text(value.toInt().toString(), style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[400]));
              },
              reservedSize: 28,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[100], strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(displayEntries.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: displayEntries[i].value.toDouble(),
                color: color,
                width: 22,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (displayEntries.map((e) => e.value).fold(0, (prev, curr) => curr > prev ? curr : prev).toDouble() * 1.5).clamp(5, 1000),
                  color: color.withOpacity(0.05),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// =============================================================================
// CALENDAR WIDGET
// =============================================================================
class _CalendarWidget extends ConsumerStatefulWidget {
  final List<Gira> giras;
  const _CalendarWidget({required this.giras});

  @override
  ConsumerState<_CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<_CalendarWidget> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Calendar Grid
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    return Column(
      children: [
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
              .map((day) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        
        // Calendar days
        ...List.generate((daysInMonth + firstWeekday) ~/ 7 + 1, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox(width: 40, height: 40);
                }

                final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
                final girasOnDate = widget.giras.where((g) =>
                    g.data.year == date.year &&
                    g.data.month == date.month &&
                    g.data.day == date.day).toList();
                
                final hasGira = girasOnDate.isNotEmpty;
                final isToday = date.day == DateTime.now().day &&
                    date.month == DateTime.now().month &&
                    date.year == DateTime.now().year;

                return GestureDetector(
                  onTap: () => _onDateTap(date, girasOnDate),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hasGira
                          ? Colors.brown[100]
                          : isToday
                              ? Colors.brown[50]
                              : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: Colors.brown, width: 2)
                          : hasGira
                              ? Border.all(color: Colors.brown[300]!, width: 1.5)
                              : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            color: hasGira ? Colors.brown[900] : Colors.black87,
                            fontWeight: hasGira ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (hasGira)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: girasOnDate.any((g) => g.status == 'aberta')
                                    ? Colors.green
                                    : Colors.brown,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  void _onDateTap(DateTime date, List<Gira> girasOnDate) {
    if (girasOnDate.isEmpty) {
      // No gira on this date - offer to create one
      _showCreateGiraDialog(date);
    } else {
      // Has gira(s) - show options
      _showGiraOptionsDialog(date, girasOnDate);
    }
  }

  void _showCreateGiraDialog(DateTime date) {
    final temaCtrl = TextEditingController();
    String? selectedLinha;
    
    // Buscar linhas dos médiuns cadastrados
    final linhasAsync = ref.read(linhasFromMediumsProvider('demo-terreiro'));
    final linhasOptions = linhasAsync.value ?? LINHA_OPTIONS;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Nova Gira - ${DateFormat('dd/MM/yyyy').format(date)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Linha Principal",
                  border: OutlineInputBorder(),
                ),
                value: selectedLinha,
                items: (linhasOptions.isEmpty ? LINHA_OPTIONS : linhasOptions).map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (val) => setDialogState(() => selectedLinha = val),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: temaCtrl,
                decoration: const InputDecoration(
                  labelText: "Tema da Gira",
                  hintText: "Ex: Gira de Encerramento",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (selectedLinha == null) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selecione a linha da gira')),
                  );
                  return;
                }
                final newGira = Gira(
                  id: const Uuid().v4(),
                  terreiroId: 'demo-terreiro',
                  linha: selectedLinha!,
                  tema: temaCtrl.text.isEmpty ? selectedLinha! : temaCtrl.text,
                  data: date,
                  status: 'agendada',
                );
                ref.read(adminRepositoryProvider).createGira(newGira);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gira cadastrada com sucesso!')),
                );
              },
              child: const Text("CRIAR GIRA"),
            )
          ],
        ),
      ),
    );
  }

  void _showPresenceDialog(BuildContext context, WidgetRef ref, Gira gira) {
    final mediumsAsync = ref.read(mediumListProvider('demo-terreiro'));
    Map<String, bool> currentPresencas = Map.from(gira.presencas);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Presenças - ${gira.tema}'),
          content: SizedBox(
            width: 400,
            height: 500,
            child: mediumsAsync.when(
              data: (mediums) {
                // Grupos de linhagem (replicando a lógica do totem)
                final Map<String, List<String>> lineGroups = {
                  'Boiadeiro': ['Boiadeiro', 'Marinheiro', 'Malandro'],
                  'Esquerda': ['Esquerda'],
                };
                final allowedLines = lineGroups[gira.linha] ?? [gira.linha];

                // Filtrar apenas médiuns que têm entidades compatíveis com esta gira
                final compatibleMediums = mediums.where((m) {
                  return m.entidades.any((e) => allowedLines.contains(e.linha));
                }).toList();

                if (compatibleMediums.isEmpty) {
                  return const Center(child: Text("Nenhum médium compatível encontrado para esta linha."));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: compatibleMediums.length,
                  itemBuilder: (context, index) {
                    final medium = compatibleMediums[index];
                    final isPresent = currentPresencas[medium.id] ?? false;
                    
                    return SwitchListTile(
                      title: Text(medium.nome),
                      subtitle: Text(medium.entidades
                        .where((e) => allowedLines.contains(e.linha))
                        .map((e) => e.entidadeNome).join(', ')),
                      value: isPresent,
                      onChanged: (val) {
                        setDialogState(() => currentPresencas[medium.id] = val);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text("Erro: $e"),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
              onPressed: () async {
                await ref.read(adminRepositoryProvider).updateGiraPresence(gira.id, currentPresencas);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Presenças atualizadas!')),
                );
              },
              child: const Text("SALVAR"),
            ),
          ],
        ),
      ),
    );
  }

  void _showGiraOptionsDialog(DateTime date, List<Gira> giras) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Giras - ${DateFormat('dd/MM/yyyy').format(date)}'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: giras.map((gira) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: gira.status == 'aberta' ? Colors.green : Colors.brown[200],
                          child: Icon(
                            gira.status == 'aberta' ? Icons.radio_button_checked : Icons.event,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(gira.tema, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${gira.linha} - ${gira.status.toUpperCase()}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (gira.status != 'aberta' && gira.status != 'encerrada')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                onPressed: () {
                                  ref.read(adminRepositoryProvider).openGira(gira.id);
                                  Navigator.pop(context);
                                },
                                child: const Text('ABRIR'),
                              ),
                            if (gira.status == 'aberta')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400], foregroundColor: Colors.white),
                                onPressed: () {
                                  ref.read(adminRepositoryProvider).closeGira(gira.id);
                                  Navigator.pop(context);
                                },
                                child: const Text('FECHAR GIRA'),
                              ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showPresenceDialog(context, ref, gira),
                              icon: const Icon(Icons.people, size: 20),
                              label: const Text("GERENCIAR PRESENÇAS"),
                            ),
                            Text(
                              "${gira.presencas.values.where((v) => v).length} presentes",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("FECHAR"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCreateGiraDialog(date);
            },
            child: Text("NOVA GIRA", style: TextStyle(color: Colors.brown[700])),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sub-screen with Tabs for Cadastros
// =============================================================================
class _CadastrosScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Colors.brown,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.brown,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Médiuns', icon: Icon(Icons.people)),
                Tab(text: 'Entidades', icon: Icon(Icons.groups_3)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MediumsList(),
                _EntitiesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB: CALENDÁRIO (Giras)
// -----------------------------------------------------------------------------
class _AdminDashboard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<_AdminDashboard> {
  late DateTime _currentMonth;
  
  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  @override
  Widget build(BuildContext context) {
    const terreiroId = 'demo-terreiro';
    final girasListAsync = ref.watch(giraListProvider(terreiroId));
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header do calendário - Navegação de meses
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.brown[800],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                          });
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
                          });
                        },
                        child: Column(
                          children: [
                            Text(
                              _monthName(_currentMonth.month),
                              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              '${_currentMonth.year}',
                              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                        onPressed: () {
                          setState(() {
                            _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Dias da semana
                Row(
                  children: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'].map((day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.brown[600],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                // Grid do calendário
                Expanded(
                  child: girasListAsync.when(
                    data: (giras) => _buildCalendarGrid(giras, terreiroId),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Erro: $err')),
                  ),
                ),

                // Legenda
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegend(Colors.green, 'Aberta'),
                    const SizedBox(width: 20),
                    _buildLegend(Colors.blue, 'Agendada'),
                    const SizedBox(width: 20),
                    _buildLegend(Colors.grey, 'Encerrada'),
                  ],
                ),
              ],
            ),
          ),
        ),
        // FAB para criar nova gira
        Positioned(
          right: 24,
          bottom: 24,
          child: FloatingActionButton.extended(
            onPressed: () => _showCreateGiraDialog(DateTime.now(), terreiroId),
            backgroundColor: Colors.brown[700],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Nova Gira'),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCalendarGrid(List<Gira> giras, String terreiroId) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Domingo
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    // Mapear giras por data (dia)
    final girasByDate = <String, List<Gira>>{};
    for (var gira in giras) {
      final key = '${gira.data.year}-${gira.data.month}-${gira.data.day}';
      girasByDate.putIfAbsent(key, () => []).add(gira);
    }

    final today = DateTime.now();

    return Column(
      children: List.generate(rows, (row) {
        return Expanded(
          child: Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNumber = cellIndex - firstWeekday + 1;
              
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                // Célula vazia
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }

              final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              final dateKey = '${date.year}-${date.month}-${date.day}';
              final dayGiras = girasByDate[dateKey] ?? [];
              final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
              final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
              final hasGira = dayGiras.isNotEmpty;
              final statusColor = hasGira ? _statusColor(dayGiras.first.status) : null;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!hasGira) {
                      _showCreateGiraDialog(date, terreiroId);
                    } else {
                      _showEditGiraDialog(dayGiras.first, terreiroId);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: hasGira ? statusColor : (isToday ? Colors.brown[50] : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday ? Colors.brown : Colors.grey[200]!,
                        width: isToday ? 2 : 1,
                      ),
                      boxShadow: hasGira ? [
                        BoxShadow(
                          color: statusColor!.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ] : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Número do dia
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 6),
                          child: Text(
                            '$dayNumber',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: (isToday || hasGira) ? FontWeight.bold : FontWeight.w500,
                              color: hasGira 
                                ? Colors.white 
                                : (isPast && dayGiras.isEmpty ? Colors.grey[400] : Colors.brown[800]),
                            ),
                          ),
                        ),
                        // Indicadores de gira (Título no centro)
                        if (hasGira)
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  dayGiras.first.linha,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      const Shadow(
                                        blurRadius: 2,
                                        color: Colors.black26,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        
                        // Pequeno indicador se houver mais de uma gira no mesmo dia (raro)
                        if (dayGiras.length > 1)
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '+${dayGiras.length - 1}',
                                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'aberta': return Colors.green;
      case 'agendada': return Colors.blue;
      case 'encerrada': return Colors.grey;
      default: return Colors.brown;
    }
  }

  String _monthName(int month) {
    const months = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month];
  }

  void _showCreateGiraDialog(DateTime date, String terreiroId) {
    final temaCtrl = TextEditingController();
    final horarioInicioCtrl = TextEditingController(text: '19:00');
    final horarioKioskCtrl = TextEditingController(text: '18:00');
    final horarioEncerramentoCtrl = TextEditingController(text: '20:00');
    final linhaCtrl = TextEditingController();
    String? selectedLinha;
    DateTime selectedDate = date;
    bool encerramentoAtivo = false;
    Map<String, bool> mediumsSelected = {};
    
    final linhasAsync = ref.read(linhasFromMediumsProvider(terreiroId));
    final registeredLinhas = linhasAsync.value ?? [];
    // Unificar LINHA_OPTIONS com as linhas já registradas nos médiuns
    final dropdownItems = {
      ...LINHA_OPTIONS,
      ...registeredLinhas,
    }.toList();
    dropdownItems.sort();
    
    // Buscar todos os médiuns
    final mediumsAsync = ref.read(mediumListProvider(terreiroId));
    final allMediums = mediumsAsync.value ?? [];
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Quando a linha muda, pré-selecionar médiuns da linha
          void _onLinhaChanged(String? val) {
            selectedLinha = val;
            mediumsSelected.clear();
            if (val != null) {
              for (var m in allMediums.where((m) => m.ativo)) {
                final hasLinha = m.entidades.any((e) => e.linha == val);
                mediumsSelected[m.id] = hasLinha;
              }
            }
            setDialogState(() {});
          }
          
          final activeMediums = allMediums.where((m) => m.ativo).toList();
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.brown[700]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Nova Gira',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              height: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Data
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Data da Gira",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.calendar_month),
                          suffixIcon: const Icon(Icons.edit, size: 18),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy - EEEE', 'pt_BR').format(selectedDate)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Linha Principal - Autocomplete editável
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) return dropdownItems;
                        return dropdownItems.where((l) =>
                          l.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (val) => _onLinhaChanged(val),
                      fieldViewBuilder: (ctx2, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: "Linha Principal",
                            hintText: "Selecione ou digite",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.auto_awesome),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty) {
                              _onLinhaChanged(val);
                            }
                          },
                          onSubmitted: (_) => onFieldSubmitted(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nome da Gira
                    TextField(
                      controller: temaCtrl,
                      decoration: InputDecoration(
                        labelText: "Nome da Gira",
                        hintText: "Ex: Gira de Caboclo",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.subject),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Horários em Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: horarioInicioCtrl,
                            decoration: InputDecoration(
                              labelText: "Horário Início",
                              hintText: "19:00",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.schedule, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: horarioKioskCtrl,
                            decoration: InputDecoration(
                              labelText: "Liberação Kiosk",
                              hintText: "18:00",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.tablet_android, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Encerramento Kiosk com Flag
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        color: encerramentoAtivo ? Colors.orange[50] : Colors.grey[50],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer_off, size: 20, color: Colors.orange),
                              const SizedBox(width: 8),
                              const Expanded(child: Text("Encerramento automático do Kiosk")),
                              Switch(
                                value: encerramentoAtivo,
                                activeColor: Colors.orange,
                                onChanged: (val) => setDialogState(() => encerramentoAtivo = val),
                              ),
                            ],
                          ),
                          if (encerramentoAtivo) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: horarioEncerramentoCtrl,
                              decoration: InputDecoration(
                                labelText: "Horário Encerramento",
                                hintText: "20:00",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.lock_clock, size: 20),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Médiuns Participantes
                    Text("Médiuns Participantes",
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.brown[700]),
                    ),
                    const SizedBox(height: 8),
                    if (activeMediums.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("Nenhum médium ativo cadastrado.", style: TextStyle(color: Colors.grey)),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: activeMediums.map((m) {
                            final isSelected = mediumsSelected[m.id] ?? false;
                            final linhas = m.entidades.map((e) => e.linha).toSet().join(', ');
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              title: Text(m.nome, style: const TextStyle(fontSize: 14)),
                              subtitle: Text(linhas, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              value: isSelected,
                              activeColor: Colors.brown,
                              onChanged: (val) {
                                setDialogState(() => mediumsSelected[m.id] = val ?? false);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("CANCELAR"),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (selectedLinha == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Selecione a linha da gira')),
                    );
                    return;
                  }
                  final participantes = mediumsSelected.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();

                  // Criar presenças a partir dos participantes
                  final presencas = <String, bool>{};
                  for (var id in participantes) {
                    presencas[id] = true;
                  }
                  
                  final newGira = Gira(
                    id: const Uuid().v4(),
                    terreiroId: terreiroId,
                    data: selectedDate,
                    tema: temaCtrl.text.isEmpty ? 'Gira de ${selectedLinha!}' : temaCtrl.text,
                    linha: selectedLinha!,
                    status: 'agendada',
                    horarioInicio: horarioInicioCtrl.text,
                    horarioKiosk: horarioKioskCtrl.text,
                    horarioEncerramentoKiosk: encerramentoAtivo ? horarioEncerramentoCtrl.text : null,
                    encerramentoKioskAtivo: encerramentoAtivo,
                    mediumsParticipantes: participantes,
                    presencas: presencas,
                  );
                  try {
                    await ref.read(adminRepositoryProvider).createGira(newGira);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gira criada com sucesso!'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                label: const Text("CRIAR GIRA"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditGiraDialog(Gira gira, String terreiroId) {
    final temaCtrl = TextEditingController(text: gira.tema);
    final horarioInicioCtrl = TextEditingController(text: gira.horarioInicio);
    final horarioKioskCtrl = TextEditingController(text: gira.horarioKiosk);
    final horarioEncerramentoCtrl = TextEditingController(text: gira.horarioEncerramentoKiosk ?? '20:00');
    final linhaCtrl = TextEditingController();
    String selectedLinha = gira.linha;
    String selectedStatus = gira.status;
    DateTime selectedDate = gira.data;
    bool encerramentoAtivo = gira.encerramentoKioskAtivo;
    Map<String, bool> mediumsSelected = {};
    
    final linhasAsync = ref.read(linhasFromMediumsProvider(terreiroId));
    final registeredLinhas = linhasAsync.value ?? [];
    // Unificar LINHA_OPTIONS com as linhas já registradas nos médiuns
    final dropdownItems = {
      ...LINHA_OPTIONS,
      ...registeredLinhas,
    }.toList();
    dropdownItems.sort();
    
    // Buscar todos os médiuns
    final mediumsAsync = ref.read(mediumListProvider(terreiroId));
    final allMediums = mediumsAsync.value ?? [];
    
    // Inicializar seleção com os participantes atuais
    for (var m in allMediums.where((m) => m.ativo)) {
      mediumsSelected[m.id] = gira.mediumsParticipantes.contains(m.id) || (gira.presencas[m.id] ?? false);
    }
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final activeMediums = allMediums.where((m) => m.ativo).toList();

          void _onLinhaChanged(String? val) {
            if (val != null) {
              setDialogState(() {
                selectedLinha = val;
                // Pré-selecionar médiuns da nova linha
                for (var m in activeMediums) {
                  final hasLinha = m.entidades.any((e) => e.linha == val);
                  if (hasLinha) mediumsSelected[m.id] = true;
                }
              });
            }
          }
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.edit_calendar, color: Colors.brown[700]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Editar Gira',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              height: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Data
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Data da Gira",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.calendar_month),
                          suffixIcon: const Icon(Icons.edit, size: 18),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy - EEEE', 'pt_BR').format(selectedDate)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Status",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.flag),
                      ),
                      value: selectedStatus,
                      items: ['agendada', 'aberta', 'encerrada'].map((s) => DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(color: _statusColor(s), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text(s[0].toUpperCase() + s.substring(1)),
                          ],
                        ),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedStatus = val!),
                    ),
                    const SizedBox(height: 16),

                    // Linha Principal - Autocomplete editável
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: selectedLinha),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) return dropdownItems;
                        return dropdownItems.where((l) =>
                          l.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (val) => _onLinhaChanged(val),
                      fieldViewBuilder: (ctx2, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: "Linha Principal",
                            hintText: "Selecione ou digite",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.auto_awesome),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty) {
                              _onLinhaChanged(val);
                            }
                          },
                          onSubmitted: (_) => onFieldSubmitted(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nome da Gira
                    TextField(
                      controller: temaCtrl,
                      decoration: InputDecoration(
                        labelText: "Nome da Gira",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.subject),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Horários
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: horarioInicioCtrl,
                            decoration: InputDecoration(
                              labelText: "Horário Início",
                              hintText: "19:00",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.schedule, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: horarioKioskCtrl,
                            decoration: InputDecoration(
                              labelText: "Liberação Kiosk",
                              hintText: "18:00",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.tablet_android, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Encerramento Kiosk com Flag
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        color: encerramentoAtivo ? Colors.orange[50] : Colors.grey[50],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer_off, size: 20, color: Colors.orange),
                              const SizedBox(width: 8),
                              const Expanded(child: Text("Encerramento automático do Kiosk")),
                              Switch(
                                value: encerramentoAtivo,
                                activeColor: Colors.orange,
                                onChanged: (val) => setDialogState(() => encerramentoAtivo = val),
                              ),
                            ],
                          ),
                          if (encerramentoAtivo) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: horarioEncerramentoCtrl,
                              decoration: InputDecoration(
                                labelText: "Horário Encerramento",
                                hintText: "20:00",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.lock_clock, size: 20),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Médiuns Participantes
                    Text("Médiuns Participantes",
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.brown[700]),
                    ),
                    const SizedBox(height: 8),
                    if (activeMediums.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("Nenhum médium ativo.", style: TextStyle(color: Colors.grey)),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: activeMediums.map((m) {
                            final isSelected = mediumsSelected[m.id] ?? false;
                            final linhas = m.entidades.map((e) => e.linha).toSet().join(', ');
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              title: Text(m.nome, style: const TextStyle(fontSize: 14)),
                              subtitle: Text(linhas, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              value: isSelected,
                              activeColor: Colors.brown,
                              onChanged: (val) {
                                setDialogState(() => mediumsSelected[m.id] = val ?? false);
                              },
                            );
                          }).toList(),
                        ),
                      ),

                    const SizedBox(height: 20),
                    
                    // Botão Sincronizar com Kiosk
                    OutlinedButton.icon(
                      icon: const Icon(Icons.sync, color: Colors.blue),
                      label: const Text("Sincronizar com Kiosk", style: TextStyle(color: Colors.blue)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        // Atualizar participantes e presenças imediatamente
                        final participantes = mediumsSelected.entries
                          .where((e) => e.value)
                          .map((e) => e.key)
                          .toList();
                        final presencas = <String, bool>{};
                        for (var id in participantes) {
                          presencas[id] = true;
                        }
                        try {
                          final updatedGira = Gira(
                            id: gira.id,
                            terreiroId: gira.terreiroId,
                            data: selectedDate,
                            tema: temaCtrl.text.isEmpty ? 'Gira de $selectedLinha' : temaCtrl.text,
                            linha: selectedLinha,
                            status: selectedStatus,
                            horarioInicio: horarioInicioCtrl.text,
                            horarioKiosk: horarioKioskCtrl.text,
                            horarioEncerramentoKiosk: encerramentoAtivo ? horarioEncerramentoCtrl.text : null,
                            encerramentoKioskAtivo: encerramentoAtivo,
                            mediumsParticipantes: participantes,
                            presencas: presencas,
                          );
                          await ref.read(adminRepositoryProvider).updateGira(updatedGira);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Kiosk sincronizado!'), backgroundColor: Colors.blue, duration: Duration(seconds: 2)),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // Botão excluir
              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                label: const Text("EXCLUIR", style: TextStyle(color: Colors.red)),
                onPressed: () {
                  showDialog(
                    context: ctx,
                    builder: (confirmCtx) => AlertDialog(
                      title: const Text('Confirmar exclusão'),
                      content: Text('Deseja excluir a gira "${gira.tema}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(confirmCtx), child: const Text('CANCELAR')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: () async {
                            await ref.read(adminRepositoryProvider).deleteGira(gira.id);
                            if (confirmCtx.mounted) Navigator.pop(confirmCtx);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gira excluída'), backgroundColor: Colors.orange),
                              );
                            }
                          },
                          child: const Text('EXCLUIR'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("CANCELAR"),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final participantes = mediumsSelected.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();
                  final presencas = <String, bool>{};
                  for (var id in participantes) {
                    presencas[id] = gira.presencas[id] ?? true;
                  }
                  
                  final updatedGira = Gira(
                    id: gira.id,
                    terreiroId: gira.terreiroId,
                    data: selectedDate,
                    tema: temaCtrl.text.isEmpty ? 'Gira de $selectedLinha' : temaCtrl.text,
                    linha: selectedLinha,
                    status: selectedStatus,
                    horarioInicio: horarioInicioCtrl.text,
                    horarioKiosk: horarioKioskCtrl.text,
                    horarioEncerramentoKiosk: encerramentoAtivo ? horarioEncerramentoCtrl.text : null,
                    encerramentoKioskAtivo: encerramentoAtivo,
                    mediumsParticipantes: participantes,
                    presencas: presencas,
                  );
                  try {
                    await ref.read(adminRepositoryProvider).updateGira(updatedGira);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gira atualizada!'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                label: const Text("SALVAR"),
              ),
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB: MÉDIUNS
// -----------------------------------------------------------------------------
class _MediumsList extends ConsumerStatefulWidget {
  @override
  _MediumsListState createState() => _MediumsListState();
}

class _MediumsListState extends ConsumerState<_MediumsList> {
  String _searchQuery = '';
  String? _filterLinha;
  String? _filterEntidade;

  @override
  Widget build(BuildContext context) {
    const terreiroId = 'demo-terreiro';
    final mediumsAsync = ref.watch(mediumListProvider(terreiroId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        onPressed: () => _addMediumDialog(context, ref, terreiroId),
        icon: const Icon(Icons.person_add),
        label: const Text("NOVO MÉDIUM"),
      ),
      body: Column(
        children: [
          // FILTROS
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Buscar por Nome",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterLinha,
                        decoration: const InputDecoration(labelText: "Filtrar por Linha", border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(value: null, child: Text("Todas")),
                          ...LINHA_OPTIONS.map((l) => DropdownMenuItem(value: l, child: Text(l))),
                        ],
                        onChanged: (val) => setState(() => _filterLinha = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: "Filtrar por Entidade",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => setState(() => _filterEntidade = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: mediumsAsync.when(
                data: (mediums) {
                  // FILTERING LOGIC
                  final filteredMediums = mediums.where((m) {
                    final matchesName = m.nome.toLowerCase().contains(_searchQuery.toLowerCase());
                    
                    bool matchesLinha = true;
                    if (_filterLinha != null) {
                      matchesLinha = m.entidades.any((e) => e.linha == _filterLinha);
                    }

                    bool matchesEntidade = true;
                    if (_filterEntidade != null && _filterEntidade!.isNotEmpty) {
                      matchesEntidade = m.entidades.any((e) => e.entidadeNome.toLowerCase().contains(_filterEntidade!.toLowerCase()));
                    }

                    return matchesName && matchesLinha && matchesEntidade;
                  }).toList();

                  if (filteredMediums.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('Nenhum médium cadastrado', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredMediums.length,
                    itemBuilder: (context, index) {
                      final medium = filteredMediums[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () => _editMediumDialog(context, ref, terreiroId, medium),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: medium.ativo ? Colors.brown : Colors.grey,
                                      radius: 24,
                                      child: Text(
                                        medium.nome.isNotEmpty ? medium.nome.substring(0, 1).toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            medium.nome,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${medium.entidades.length} entidade(s) cadastrada(s)',
                                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 16,
                                            runSpacing: 8,
                                            children: [
                                              _buildStatChip(Icons.event_available, "${medium.girasParticipadas} Giras", Colors.blue[100]!, Colors.blue[900]!),
                                              _buildStatChip(Icons.emoji_people, "${medium.atendimentosRealizados} Atend.", Colors.green[100]!, Colors.green[900]!),
                                              _buildStatChip(Icons.event_busy, "${medium.faltas} Faltas", Colors.red[100]!, Colors.red[900]!),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.brown, size: 20),
                                              onPressed: () => _editMediumDialog(context, ref, terreiroId, medium),
                                              tooltip: 'Editar Médium',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                              onPressed: () => _confirmDeleteMedium(context, ref, medium),
                                              tooltip: 'Excluir Médium',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          medium.ativo ? 'ATIVO' : 'INATIVO',
                                          style: TextStyle(
                                            color: medium.ativo ? Colors.green : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Switch(
                                          activeColor: Colors.brown,
                                          value: medium.ativo,
                                          onChanged: (val) {
                                            ref.read(adminRepositoryProvider).toggleMediumStatus(medium.id, val);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                // Entidades List
                                if (medium.entidades.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Entidades:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: medium.entidades.map((medEnt) {
                                      Color chipColor;
                                      IconData chipIcon;
                                      switch (medEnt.status) {
                                        case 'ativo':
                                          chipColor = Colors.green;
                                          chipIcon = Icons.check_circle;
                                          break;
                                        case 'pausado':
                                          chipColor = Colors.orange;
                                          chipIcon = Icons.pause_circle;
                                          break;
                                        case 'desativado':
                                          chipColor = Colors.red;
                                          chipIcon = Icons.cancel;
                                          break;
                                        default:
                                          chipColor = Colors.grey;
                                          chipIcon = Icons.help;
                                      }
                                      return Chip(
                                        avatar: Icon(chipIcon, color: Colors.white, size: 16),
                                        label: Text(medEnt.entidadeNome),
                                        backgroundColor: chipColor,
                                        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Erro: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
  void _confirmDeleteMedium(BuildContext context, WidgetRef ref, Medium medium) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Médium'),
        content: Text('Deseja realmente excluir o médium "${medium.nome}"?\nEsta ação não poderá ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(adminRepositoryProvider).deleteMedium(medium.id);
              Navigator.pop(context);
            },
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }

  void _addMediumDialog(BuildContext context, WidgetRef ref, String terreiroId) {
    final nameCtrl = TextEditingController();
    final maxFichasCtrl = TextEditingController(text: '10');
    final allEntities = ref.read(entityListProvider(terreiroId)).value ?? [];
    final List<MediumEntidade> selectedEntities = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Novo Médium'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: maxFichasCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max. Fichas',
                      border: OutlineInputBorder(),
                      helperText: 'Padrão: 10'
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  // ... rest of entities list ...
                  Text(
                    'Entidades Incorporadas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.brown[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedEntities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Nenhuma entidade adicionada',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    ...selectedEntities.map((medEnt) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.stars, color: Colors.brown),
                          title: Text(medEnt.entidadeNome),
                          subtitle: Text('Status: ${medEnt.status}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<String>(
                                value: medEnt.status,
                                underline: Container(),
                                items: const [
                                  DropdownMenuItem(value: 'ativo', child: Text('Ativo')),
                                  DropdownMenuItem(value: 'pausado', child: Text('Pausado')),
                                  DropdownMenuItem(value: 'desativado', child: Text('Desativado')),
                                ],
                                onChanged: (newStatus) {
                                  if (newStatus != null) {
                                    setDialogState(() {
                                      final index = selectedEntities.indexOf(medEnt);
                                      selectedEntities[index] = MediumEntidade(
                                        entidadeId: medEnt.entidadeId,
                                        entidadeNome: medEnt.entidadeNome,
                                        linha: medEnt.linha,
                                        tipo: medEnt.tipo,
                                        status: newStatus,
                                      );
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setDialogState(() {
                                    selectedEntities.remove(medEnt);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('ADICIONAR ENTIDADE'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.brown,
                      side: const BorderSide(color: Colors.brown),
                    ),
                    onPressed: () {
                      _showAddEntityToMediumDialog(
                        dialogContext,
                        allEntities,
                        selectedEntities,
                        (newEntity) {
                          setDialogState(() {
                            selectedEntities.add(newEntity);
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Digite o nome do médium')),
                  );
                  return;
                }
                
                final maxFichas = int.tryParse(maxFichasCtrl.text) ?? 10;

                final med = Medium(
                  id: const Uuid().v4(),
                  terreiroId: terreiroId,
                  nome: nameCtrl.text,
                  ativo: true,
                  entidades: selectedEntities,
                  maxFichas: maxFichas,
                );
                try {
                  await ref.read(adminRepositoryProvider).addMedium(med);
                  
                  // Reset filters
                  setState(() {
                    _filterLinha = null;
                    _searchQuery = '';
                    _filterEntidade = null;
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Médium adicionado com sucesso!'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );
  }
  void _editMediumDialog(BuildContext context, WidgetRef ref, String terreiroId, Medium medium) {
    final nameCtrl = TextEditingController(text: medium.nome);
    final maxFichasCtrl = TextEditingController(text: medium.maxFichas.toString());
    final allEntities = ref.read(entityListProvider(terreiroId)).value ?? [];
    final List<MediumEntidade> selectedEntities = List.from(medium.entidades);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Editar Médium'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: maxFichasCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max. Fichas',
                      border: OutlineInputBorder(),
                      helperText: 'Padrão: 10'
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Entidades Incorporadas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.brown[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedEntities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Nenhuma entidade adicionada',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    ...selectedEntities.map((medEnt) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.stars, color: Colors.brown),
                          title: Text(medEnt.entidadeNome),
                          subtitle: Text('Status: ${medEnt.status}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<String>(
                                value: medEnt.status,
                                underline: Container(),
                                items: const [
                                  DropdownMenuItem(value: 'ativo', child: Text('Ativo')),
                                  DropdownMenuItem(value: 'pausado', child: Text('Pausado')),
                                  DropdownMenuItem(value: 'desativado', child: Text('Desativado')),
                                ],
                                onChanged: (newStatus) {
                                  if (newStatus != null) {
                                    setDialogState(() {
                                      final index = selectedEntities.indexOf(medEnt);
                                      selectedEntities[index] = MediumEntidade(
                                        entidadeId: medEnt.entidadeId,
                                        entidadeNome: medEnt.entidadeNome,
                                        linha: medEnt.linha,
                                        tipo: medEnt.tipo,
                                        status: newStatus,
                                      );
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setDialogState(() {
                                    selectedEntities.remove(medEnt);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('ADICIONAR ENTIDADE'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.brown,
                      side: const BorderSide(color: Colors.brown),
                    ),
                    onPressed: () {
                      _showAddEntityToMediumDialog(
                        dialogContext,
                        allEntities,
                        selectedEntities,
                        (newEntity) {
                          setDialogState(() {
                            selectedEntities.add(newEntity);
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                
                final maxFichas = int.tryParse(maxFichasCtrl.text) ?? 10;
                
                final updatedMed = Medium(
                  id: medium.id,
                  terreiroId: medium.terreiroId,
                  nome: nameCtrl.text,
                  ativo: medium.ativo,
                  entidades: selectedEntities,
                  maxFichas: maxFichas,
                  girasParticipadas: medium.girasParticipadas,
                  atendimentosRealizados: medium.atendimentosRealizados,
                  faltas: medium.faltas,
                );
                ref.read(adminRepositoryProvider).updateMedium(updatedMed);
                Navigator.pop(context);
              },
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEntityToMediumDialog(
    BuildContext context,
    List<Entidade> allEntities,
    List<MediumEntidade> currentEntities,
    Function(MediumEntidade) onAdd,
  ) {
    final nomeCtrl = TextEditingController();
    String? selectedLinha;
    String? selectedTipo;
    String selectedStatus = 'ativo';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Cadastrar Nova Entidade'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'As entidades cadastradas aqui serão automaticamente adicionadas ao médium e à coleção global.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nomeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Entidade',
                      hintText: 'Ex: Cabocla Jurema',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Linha',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedLinha,
                    items: LINHA_OPTIONS.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (val) => setState(() => selectedLinha = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedTipo,
                    items: TIPO_OPTIONS.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setState(() => selectedTipo = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Status Inicial',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'ativo', child: Text('Ativo')),
                      DropdownMenuItem(value: 'pausado', child: Text('Pausado')),
                      DropdownMenuItem(value: 'desativado', child: Text('Desativado')),
                    ],
                    onChanged: (val) => setState(() => selectedStatus = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nomeCtrl.text.isEmpty || selectedLinha == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Preencha o nome e a linha da entidade')),
                  );
                  return;
                }
                
                // Create entity ID
                final entityId = const Uuid().v4();
                
                onAdd(MediumEntidade(
                  entidadeId: entityId,
                  entidadeNome: nomeCtrl.text,
                  linha: selectedLinha!,
                  tipo: selectedTipo ?? selectedLinha!,
                  status: selectedStatus,
                ));
                
                Navigator.pop(context);
              },
              child: const Text('ADICIONAR'),
            ),
          ],
        ),
      ),
    );
  }
}








// -----------------------------------------------------------------------------
// TAB: ENTIDADES
// -----------------------------------------------------------------------------
class _EntitiesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terreiroId = 'demo-terreiro';
    final entitiesAsync = ref.watch(entityListProvider(terreiroId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        onPressed: () => _addEntityDialog(context, ref, terreiroId),
        icon: const Icon(Icons.groups),
        label: const Text("NOVA ENTIDADE"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: entitiesAsync.when(
          data: (entities) => GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: entities.length,
            itemBuilder: (context, index) {
              final ent = entities[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () => _editEntityDialog(context, ref, terreiroId, ent),
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: double.infinity),
                            CircleAvatar(
                              backgroundColor: Colors.brown[300],
                              radius: 30,
                              child: const Icon(Icons.star, color: Colors.white, size: 30),
                            ),
                            const SizedBox(height: 12),
                            Text(ent.nome,
                                style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            Text(ent.linha,
                                style: TextStyle(color: Colors.brown[700], fontSize: 13, fontWeight: FontWeight.w500)),
                            Text(ent.tipo, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.brown),
                              onPressed: () => _editEntityDialog(context, ref, terreiroId, ent),
                              tooltip: 'Editar Entidade',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              onPressed: () => _confirmDeleteEntity(context, ref, ent),
                              tooltip: 'Excluir Entidade',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error: $err'),
        ),
      ),
    );
  }

  void _addEntityDialog(BuildContext context, WidgetRef ref, String terreiroId) {
    final nameCtrl = TextEditingController();
    String? selectedLinha;
    String? selectedTipo;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Nova Entidade"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome da Entidade',
                  hintText: 'Ex: Cabocla Jurema',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Linha',
                  border: OutlineInputBorder(),
                ),
                value: selectedLinha,
                items: LINHA_OPTIONS.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (val) => setState(() => selectedLinha = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                value: selectedTipo,
                items: TIPO_OPTIONS.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => selectedTipo = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.isEmpty || selectedLinha == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha o nome e a linha da entidade')),
                  );
                  return;
                }
                final ent = Entidade(
                  id: const Uuid().v4(),
                  terreiroId: terreiroId,
                  nome: nameCtrl.text,
                  linha: selectedLinha!,
                  tipo: selectedTipo ?? selectedLinha!,
                );
                ref.read(adminRepositoryProvider).addEntity(ent);
                Navigator.pop(context);
              },
              child: const Text('SALVAR'),
            )
          ],
        ),
      ),
    );
  }
  void _editEntityDialog(BuildContext context, WidgetRef ref, String terreiroId, Entidade ent) {
    final nameCtrl = TextEditingController(text: ent.nome);
    String? selectedLinha = LINHA_OPTIONS.contains(ent.linha) ? ent.linha : null;
    String? selectedTipo = TIPO_OPTIONS.contains(ent.tipo) ? ent.tipo : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Editar Entidade"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome da Entidade',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Linha',
                  border: OutlineInputBorder(),
                ),
                value: selectedLinha,
                items: LINHA_OPTIONS.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (val) => setState(() => selectedLinha = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                value: selectedTipo,
                items: TIPO_OPTIONS.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => selectedTipo = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
              onPressed: () {
                if (nameCtrl.text.isEmpty || selectedLinha == null) return;
                final updated = Entidade(
                  id: ent.id,
                  terreiroId: terreiroId,
                  nome: nameCtrl.text,
                  linha: selectedLinha!,
                  tipo: selectedTipo ?? selectedLinha!,
                );
                ref.read(adminRepositoryProvider).updateEntity(updated);
                Navigator.pop(context);
              },
              child: const Text('SALVAR'),
            )
          ],
        ),
      ),
    );
  }

  void _confirmDeleteEntity(BuildContext context, WidgetRef ref, Entidade entity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Entidade'),
        content: Text('Deseja realmente excluir a entidade "${entity.nome}"?\nEsta ação não poderá ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(adminRepositoryProvider).deleteEntity(entity.id);
              Navigator.pop(context);
            },
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TELA DE CONFIGURAÇÕES DE ACESSO
// =============================================================================
class _ConfiguracoesScreen extends ConsumerStatefulWidget {
  @override
  _ConfiguracoesScreenState createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends ConsumerState<_ConfiguracoesScreen> {
  String? _selectedUsuarioId;

  final List<Map<String, String>> _availableFeatures = [
    {
      'id': 'dashboard', 
      'label': 'Dashboard', 
      'icon': 'dashboard',
      'description': 'Visão geral em tempo real (médiuns na casa, assistência), gráficos e métricas do porteiro. Ideal para monitoramento sem edição de dados.'
    },
    {
      'id': 'cadastros', 
      'label': 'Cadastros', 
      'icon': 'folder_shared',
      'description': 'Gestão completa do banco de dados: cadastrar/editar Médiuns e Entidades. Acesso sensível, recomendado apenas para Secretaria.'
    },
    {
      'id': 'calendario', 
      'label': 'Calendário', 
      'icon': 'calendar_month',
      'description': 'Controle da agenda: agendar giras, iniciar/encerrar sessões e realizar a chamada de presença dos médiuns.'
    },
    {
      'id': 'senhas', 
      'label': 'Senhas', 
      'icon': 'confirmation_number',
      'description': 'Operação da fila: chamar senhas (painel TV), marcar atendimentos e redistribuir senhas. Uso essencial para Cambonos.'
    },
    {
      'id': 'usuarios', 
      'label': 'Usuários', 
      'icon': 'people',
      'description': 'Administração de acessos: criar logins para operadores e redefinir senhas. Apenas Managers devem ter este acesso.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    const terreiroId = 'demo-terreiro';
    final usuariosAsync = ref.watch(streamUsuariosProvider(terreiroId));

    return Row(
      children: [
        // Lista de Usuários
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey[200]!)),
          ),
          child: usuariosAsync.when(
            data: (usuarios) {
              return ListView.builder(
                itemCount: usuarios.length,
                itemBuilder: (context, index) {
                  final user = usuarios[index];
                  final isSelected = _selectedUsuarioId == user.id;
                  
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.brown[50],
                    leading: CircleAvatar(
                      backgroundColor: user.perfilAcesso == 'admin' ? Colors.brown : Colors.grey[300],
                      child: Text(user.nomeCompleto.isNotEmpty ? user.nomeCompleto[0].toUpperCase() : '?', 
                        style: TextStyle(color: user.perfilAcesso == 'admin' ? Colors.white : Colors.black87)),
                    ),
                    title: Text(user.nomeCompleto, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    subtitle: Text(user.perfilAcesso.toUpperCase()),
                    onTap: () => setState(() => _selectedUsuarioId = user.id),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
          ),
        ),
        
        // Detalhes da Permissão
        Expanded(
          child: _selectedUsuarioId == null 
            ? Center(child: Text('Selecione um usuário para configurar permissões', style: GoogleFonts.outfit(color: Colors.grey)))
            : usuariosAsync.when(
                data: (usuarios) {
                  final user = usuarios.firstWhere((u) => u.id == _selectedUsuarioId);
                  
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Permissões de Acesso: ${user.nomeCompleto}', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text('Selecione abaixo quais funcionalidades este usuário poderá visualizar no sistema.', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 32),
                        
                        if (user.perfilAcesso == 'admin')
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue[800]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text('Usuários com perfil Administrador têm acesso total a todas as funcionalidades por padrão.', 
                                    style: TextStyle(color: Colors.blue[900])),
                                ),
                              ],
                            ),
                          )
                        else
                          Expanded(
                            child: ListView(
                              children: _availableFeatures.map((feature) {
                                final bool hasAccess = user.permissoes.contains(feature['id']);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: SwitchListTile(
                                    title: Text(feature['label']!, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                                    subtitle: Text(feature['description']!, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
                                    secondary: Icon(_getIconData(feature['icon']!), color: Colors.brown[700]),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    value: hasAccess,
                                    activeColor: Colors.brown,
                                    onChanged: (bool value) async {
                                      final newList = List<String>.from(user.permissoes);
                                      if (value) {
                                        newList.add(feature['id']!);
                                      } else {
                                        newList.remove(feature['id']!);
                                      }
                                      
                                      final updatedUser = Usuario(
                                        id: user.id,
                                        terreiroId: user.terreiroId,
                                        nomeCompleto: user.nomeCompleto,
                                        login: user.login,
                                        senha: user.senha,
                                        perfilAcesso: user.perfilAcesso,
                                        permissoes: newList,
                                        ativo: user.ativo,
                                      );
                                      
                                      await ref.read(adminRepositoryProvider).updateUsuario(updatedUser);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
              ),
        ),
      ],
    );
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case 'dashboard': return Icons.dashboard_outlined;
      case 'folder_shared': return Icons.folder_shared_outlined;
      case 'calendar_month': return Icons.calendar_month_outlined;
      case 'confirmation_number': return Icons.confirmation_number_outlined;
      case 'people': return Icons.people_outline;
      default: return Icons.help_outline;
    }
  }
}

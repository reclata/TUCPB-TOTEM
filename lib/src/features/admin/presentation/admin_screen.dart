
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
                      Image.asset(
                        'assets/images/logo.jpg',
                        height: 80,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.temple_buddhist, size: 60, color: Colors.white),
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
                _buildMenuItem(Icons.dashboard_outlined, 'Dashboard', 0),
                _buildMenuItem(Icons.folder_shared_outlined, 'Cadastros', 1),
                _buildMenuItem(Icons.calendar_month_outlined, 'Calendário', 2),
                _buildMenuItem(Icons.confirmation_number_outlined, 'Senhas', 3),
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
                const Divider(color: Colors.white24, height: 1),
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
      default:
        return 'T.U.C.P.B. Token';
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _DashboardScreen();
      case 1:
        return _CadastrosScreen();
      case 2:
        return _AdminDashboard();
      case 3:
        return const SenhasScreen();
      case 4:
        return const UsuariosScreen();
      default:
        return const Center(child: Text('Em construção'));
    }
  }
}

// =============================================================================
// DASHBOARD INICIAL
// =============================================================================
class _DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const terreiroId = 'demo-terreiro';
    final girasAsync = ref.watch(giraListProvider(terreiroId));
    final mediumsAsync = ref.watch(mediumListProvider(terreiroId));
    final entitiesAsync = ref.watch(entityListProvider(terreiroId));

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
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('GERAR DADOS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                  entitiesAsync.value?.length.toString() ?? '...',
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
          
          // Calendar and Recent Activity Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar Widget
              Expanded(
                flex: 2,
                child: _CalendarWidget(giras: girasAsync.value ?? []),
              ),
              
              const SizedBox(width: 24),
              
              // Recent Activity
              Expanded(
                flex: 1,
                child: Column(
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
                        final upcomingGiras = giras.where((g) => g.data.isAfter(DateTime.now().subtract(const Duration(days: 1)))).take(5).toList();
                        return Column(
                          children: upcomingGiras.map((gira) {
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
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Erro: $e'),
                    ),
                  ],
                ),
              ),
            ],
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
                items: LINHA_OPTIONS.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
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
class _AdminDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const terreiroId = 'demo-terreiro';
    final girasListAsync = ref.watch(giraListProvider(terreiroId));

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("ABRIR NOVA GIRA"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  _showCreateGiraDialog(context, ref, terreiroId);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: girasListAsync.when(
              data: (giras) {
                if (giras.isEmpty) {
                  return const Center(child: Text("Nenhuma Gira registrada."));
                }
                return ListView.builder(
                  itemCount: giras.length,
                  itemBuilder: (context, index) {
                    final gira = giras[index];
                    final isOpen = gira.status == 'aberta';
                    return Card(
                      color: isOpen ? Colors.green[50] : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(Icons.event_note, color: isOpen ? Colors.green : Colors.grey),
                        title: Text("${gira.tema} - ${DateFormat('dd/MM/yyyy').format(gira.data)}"),
                        subtitle: Text("Status: ${gira.status}"),
                        trailing: isOpen
                            ? IconButton(
                                icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                                onPressed: () {
                                  ref.read(adminRepositoryProvider).closeGira(gira.id);
                                },
                                tooltip: 'Encerrar Gira',
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erro: $err')),
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

  void _showCreateGiraDialog(BuildContext context, WidgetRef ref, String terreiroId) {
    final temaCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nova Gira"),
        content: TextField(
          controller: temaCtrl,
          decoration: const InputDecoration(labelText: "Tema da Gira", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () {
              if (temaCtrl.text.isEmpty) return;
              final newGira = Gira(
                id: const Uuid().v4(),
                terreiroId: terreiroId,
                data: DateTime.now(),
                tema: temaCtrl.text,
                linha: temaCtrl.text, // Temporary: using same value as tema
                status: 'aberta',
              );
              ref.read(adminRepositoryProvider).createGira(newGira);
              Navigator.pop(context);
            },
            child: const Text("CRIAR"),
          )
        ],
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
                if (nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Digite o nome do médium')),
                  );
                  return;
                }
                final med = Medium(
                  id: const Uuid().v4(),
                  terreiroId: terreiroId,
                  nome: nameCtrl.text,
                  ativo: true,
                  entidades: selectedEntities,
                );
                ref.read(adminRepositoryProvider).addMedium(med);
                
                // Reset filters so the user can see the new medium
                setState(() {
                  _filterLinha = null;
                  _searchQuery = '';
                  _filterEntidade = null;
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Médium adicionado com sucesso!')));
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
                final updatedMed = Medium(
                  id: medium.id,
                  terreiroId: terreiroId,
                  nome: nameCtrl.text,
                  ativo: medium.ativo,
                  entidades: selectedEntities,
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

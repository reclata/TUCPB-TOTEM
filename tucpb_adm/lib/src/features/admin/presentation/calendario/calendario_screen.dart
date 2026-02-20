import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tucpb_adm/src/features/admin/data/gira_model.dart';
import 'package:tucpb_adm/src/features/admin/data/giras_repository.dart';
import 'package:tucpb_adm/src/features/admin/presentation/calendario/nova_gira_modal.dart';
import 'package:tucpb_adm/src/features/admin/presentation/calendario/gira_detalhes_modal.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

// ───────────────────────────────────────────────────────────────
// TELA PRINCIPAL DO CALENDÁRIO
// ───────────────────────────────────────────────────────────────
class CalendarioScreen extends ConsumerStatefulWidget {
  const CalendarioScreen({super.key});

  @override
  ConsumerState<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends ConsumerState<CalendarioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _abrirNovaGira({DateTime? data}) {
    showDialog(
      context: context,
      builder: (_) => NovaGiraModal(dataPreSelecionada: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            color: AdminTheme.surface,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calendário',
                        style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                    Text('Giras, eventos e reuniões', style: TextStyle(color: AdminTheme.textSecondary)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _abrirNovaGira(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('+ Novo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: AdminTheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AdminTheme.primary,
              unselectedLabelColor: AdminTheme.textSecondary,
              indicatorColor: AdminTheme.primary,
              tabs: const [
                Tab(icon: Icon(Icons.calendar_month, size: 18), text: 'Calendário'),
                Tab(icon: Icon(Icons.view_kanban, size: 18), text: 'Visão Geral'),
              ],
            ),
          ),

          // Conteúdo das abas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CalendarioView(onNovaGira: _abrirNovaGira),
                const _KanbanView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// ABA 1 — CALENDÁRIO
// ───────────────────────────────────────────────────────────────
class _CalendarioView extends ConsumerStatefulWidget {
  final void Function({DateTime? data}) onNovaGira;
  const _CalendarioView({required this.onNovaGira});

  @override
  ConsumerState<_CalendarioView> createState() => _CalendarioViewState();
}

class _CalendarioViewState extends ConsumerState<_CalendarioView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final girasAsync = ref.watch(girasStreamProvider);

    return girasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (giras) {
        // Agrupar por dia
        final Map<DateTime, List<GiraModel>> eventosMap = {};
        for (final g in giras) {
          final key = DateTime(g.data.year, g.data.month, g.data.day);
          eventosMap.putIfAbsent(key, () => []).add(g);
        }

        List<GiraModel> _getEventos(DateTime day) {
          final key = DateTime(day.year, day.month, day.day);
          return eventosMap[key] ?? [];
        }

        final List<GiraModel> eventosDoDia = _selectedDay != null ? _getEventos(_selectedDay!) : [];

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Calendário
                        Expanded(
                          flex: 3,
                          child: _buildCalendario(_getEventos, eventosDoDia),
                        ),
                        const SizedBox(width: 16),
                        // Painel direito
                        Expanded(
                          flex: 2,
                          child: _buildPainelDia(eventosDoDia),
                        ),
                      ],
                    )
                  : _buildCalendario(_getEventos, eventosDoDia),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendario(
      List<GiraModel> Function(DateTime) getEventos,
      List<GiraModel> eventosDoDia) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(8),
      child: TableCalendar<GiraModel>(
        locale: 'pt_BR',
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: getEventos,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(color: AdminTheme.primary.withOpacity(0.3), shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: AdminTheme.primary, shape: BoxShape.circle),
          markerDecoration: BoxDecoration(color: AdminTheme.primary, shape: BoxShape.circle),
          markersMaxCount: 3,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AdminTheme.textPrimary),
          leftChevronIcon: const Icon(Icons.chevron_left, color: AdminTheme.primary),
          rightChevronIcon: const Icon(Icons.chevron_right, color: AdminTheme.primary),
        ),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onPageChanged: (focused) => setState(() => _focusedDay = focused),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;
            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((e) {
                  final cor = _corHex(e.cor ?? '#1565C0');
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPainelDia(List<GiraModel> eventosDoDia) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
              children: [
                Text(
                  _selectedDay != null
                      ? DateFormat('dd/MM/yyyy').format(_selectedDay!)
                      : 'Selecione uma data',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AdminTheme.textPrimary),
                ),
                if (_selectedDay != null)
                  TextButton.icon(
                    onPressed: () => widget.onNovaGira(data: _selectedDay),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Adicionar'),
                    style: TextButton.styleFrom(foregroundColor: AdminTheme.primary),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: eventosDoDia.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, color: Colors.grey[300], size: 48),
                        const SizedBox(height: 8),
                        Text(
                          _selectedDay != null ? 'Nenhum evento neste dia' : 'Toque uma data no calendário',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: eventosDoDia.length,
                    itemBuilder: (context, i) => _GiraCard(gira: eventosDoDia[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Color _corHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AdminTheme.primary;
    }
  }
}

// ───────────────────────────────────────────────────────────────
// ABA 2 — KANBAN (Visão Geral por Mês)
// ───────────────────────────────────────────────────────────────
class _KanbanView extends ConsumerStatefulWidget {
  const _KanbanView();

  @override
  ConsumerState<_KanbanView> createState() => _KanbanViewState();
}

class _KanbanViewState extends ConsumerState<_KanbanView> {
  // Mostrar 6 meses: 2 anteriores + atual + 3 futuros
  final List<DateTime> _meses = List.generate(6, (i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - 2 + i, 1);
  });

  @override
  Widget build(BuildContext context) {
    final girasAsync = ref.watch(girasStreamProvider);

    return girasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (giras) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _meses.map((mes) {
              final girasDoMes = giras.where((g) =>
                  g.data.year == mes.year && g.data.month == mes.month).toList();
              final isAtual = mes.year == DateTime.now().year && mes.month == DateTime.now().month;

              return _KanbanColumn(
                mes: mes,
                giras: girasDoMes,
                isAtual: isAtual,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  final DateTime mes;
  final List<GiraModel> giras;
  final bool isAtual;

  const _KanbanColumn({required this.mes, required this.giras, required this.isAtual});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nomeMes = DateFormat('MMMM yyyy', 'pt_BR').format(mes);

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do mês
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isAtual ? AdminTheme.primary : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  nomeMes.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isAtual ? Colors.white : AdminTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAtual ? Colors.white24 : AdminTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${giras.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAtual ? Colors.white : AdminTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cards das giras
          Container(
            constraints: const BoxConstraints(minHeight: 200, maxHeight: 600),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: giras.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Sem giras neste mês', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    itemCount: giras.length,
                    itemBuilder: (context, i) => _KanbanCard(gira: giras[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KanbanCard extends ConsumerWidget {
  final GiraModel gira;
  const _KanbanCard({required this.gira});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jaAconteceu = gira.data.isBefore(DateTime.now());
    final cor = _corHex(gira.cor ?? '#1565C0');

    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => GiraDetalhesModal(gira: gira),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: cor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: cor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(gira.tipo.toUpperCase(),
                            style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          if (!gira.ativo) const Icon(Icons.lock, size: 12, color: Colors.grey),
                          if (jaAconteceu && gira.historico != null)
                            const Icon(Icons.history, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          if (gira.tipo != 'comemorativa')
                            InkWell(
                              onTap: () => showDialog(
                                context: context,
                                builder: (_) => NovaGiraModal(giraParaEditar: gira),
                              ),
                              child: const Icon(Icons.edit, size: 14, color: Colors.grey),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(gira.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('dd/MM').format(gira.data)}  ${gira.horarioInicio} – ${gira.horarioFim}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  if (gira.descricao != null && gira.descricao!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(gira.descricao!, style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  if (jaAconteceu && gira.historico != null) ...[
                    const Divider(height: 16),
                    const Text('Histórico (via Totem)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 6),
                    _HistoricoRow(Icons.confirmation_number, 'Senhas', '${gira.historico!.totalSenhas}'),
                    _HistoricoRow(Icons.people, 'Médiuns', '${gira.historico!.totalMediums}'),
                    _HistoricoRow(Icons.check_circle_outline, 'Atendimentos', '${gira.historico!.totalAtendimentos}'),
                    if (gira.historico!.horarioInicioReal != null)
                      _HistoricoRow(Icons.play_circle, 'Início real', gira.historico!.horarioInicioReal!),
                    if (gira.historico!.horarioFimReal != null)
                      _HistoricoRow(Icons.stop_circle, 'Encerramento', gira.historico!.horarioFimReal!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _corHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AdminTheme.primary;
    }
  }
}

class _HistoricoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HistoricoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.green),
          const SizedBox(width: 4),
          Text('$label: ', style: const TextStyle(fontSize: 11, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────
// CARD simples para o painel lateral do calendário
// ───────────────────────────────────────────────────────────────
class _GiraCard extends ConsumerWidget {
  final GiraModel gira;
  const _GiraCard({required this.gira});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cor = _corHex(gira.cor ?? '#1565C0');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: () => showDialog(
          context: context,
          builder: (_) => GiraDetalhesModal(gira: gira),
        ),
        leading: Container(
          width: 4,
          height: double.infinity,
          decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(2)),
        ),
        title: Text(gira.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('${gira.horarioInicio} – ${gira.horarioFim}', style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!gira.ativo) const Icon(Icons.lock, size: 14, color: Colors.grey),
            if (gira.tipo != 'comemorativa')
              IconButton(
                icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => NovaGiraModal(giraParaEditar: gira),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _corHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AdminTheme.primary;
    }
  }
}

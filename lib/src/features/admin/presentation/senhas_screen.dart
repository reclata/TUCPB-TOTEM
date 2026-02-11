import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:terreiro_queue_system/src/shared/models/models.dart';
import 'package:terreiro_queue_system/src/shared/providers/global_providers.dart';
import 'package:terreiro_queue_system/src/features/admin/data/admin_repository.dart';
import 'package:terreiro_queue_system/src/features/queue/data/firestore_queue_repository.dart';

// =============================================================================
// Provider: streams ALL active tickets for a Gira (not just one entity)
// =============================================================================
final allTicketsForGiraProvider =
    StreamProvider.family<List<Ticket>, String>((ref, giraId) {
  return FirebaseFirestore.instance
      .collection('tickets')
      .where('giraId', isEqualTo: giraId)
      .where('status', whereIn: ['emitida', 'chamada'])
      .orderBy('ordemFila')
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => Ticket.fromJson(doc.data())).toList());
});

// =============================================================================
// SENHAS SCREEN - Container com TabBar
// =============================================================================
class SenhasScreen extends StatelessWidget {
  const SenhasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Colors.brown[800],
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: Colors.brown[700],
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.campaign), text: 'Chamar Senha'),
                Tab(icon: Icon(Icons.swap_horiz), text: 'Redistribuir Senhas'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _ChamarSenhaTab(),
                _RedistribuirSenhasTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ABA 1: CHAMAR SENHA
// =============================================================================
class _ChamarSenhaTab extends ConsumerStatefulWidget {
  const _ChamarSenhaTab();

  @override
  _ChamarSenhaTabState createState() => _ChamarSenhaTabState();
}

class _ChamarSenhaTabState extends ConsumerState<_ChamarSenhaTab> {
  String? _selectedMediumId;

  @override
  Widget build(BuildContext context) {
    const terreiroId = 'demo-terreiro';
    final activeGiraAsync = ref.watch(activeGiraProvider(terreiroId));
    final mediumsAsync = ref.watch(mediumListProvider(terreiroId));

    return activeGiraAsync.when(
      data: (gira) {
        if (gira == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma gira aberta no momento',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Abra uma gira no Calendário para chamar senhas.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return mediumsAsync.when(
          data: (mediums) {
            // Filtrar apenas médiuns presentes na gira
            final presentMediums = mediums.where((m) {
              return m.ativo && (gira.presencas[m.id] ?? false);
            }).toList();

            if (presentMediums.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum médium presente nesta gira',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                // PAINEL ESQUERDO: Lista de Médiuns
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.brown[50],
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gira: ${gira.tema}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.brown[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${presentMediums.length} médium(s) presente(s)',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.brown[400]),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: presentMediums.length,
                          itemBuilder: (context, index) {
                            final medium = presentMediums[index];
                            final isSelected = _selectedMediumId == medium.id;
                            return InkWell(
                              onTap: () =>
                                  setState(() => _selectedMediumId = medium.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.brown[100]
                                      : Colors.transparent,
                                  border: Border(
                                    bottom:
                                        BorderSide(color: Colors.grey[200]!),
                                    left: BorderSide(
                                      color: isSelected
                                          ? Colors.brown[700]!
                                          : Colors.transparent,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isSelected
                                          ? Colors.brown
                                          : Colors.brown[200],
                                      radius: 20,
                                      child: Text(
                                        medium.nome.isNotEmpty
                                            ? medium.nome
                                                .substring(0, 1)
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            medium.nome,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            medium.entidades
                                                .where(
                                                    (e) => e.status == 'ativo')
                                                .map((e) => e.entidadeNome)
                                                .join(', '),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600]),
                                            overflow: TextOverflow.ellipsis,
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
                      ),
                    ],
                  ),
                ),

                // PAINEL DIREITO: Fila de senhas do médium selecionado
                Expanded(
                  child: _selectedMediumId == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'Selecione um médium à esquerda',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : _MediumQueuePanel(
                          giraId: gira.id,
                          mediumId: _selectedMediumId!,
                          terreiroId: terreiroId,
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Erro: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erro: $err')),
    );
  }
}

// =============================================================================
// PAINEL DA FILA DO MÉDIUM (lado direito)
// =============================================================================
class _MediumQueuePanel extends ConsumerWidget {
  final String giraId;
  final String mediumId;
  final String terreiroId;

  const _MediumQueuePanel({
    required this.giraId,
    required this.mediumId,
    required this.terreiroId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediumsAsync = ref.watch(mediumListProvider(terreiroId));
    final allTicketsAsync = ref.watch(allTicketsForGiraProvider(giraId));

    return mediumsAsync.when(
      data: (mediums) {
        final medium = mediums.firstWhere(
          (m) => m.id == mediumId,
          orElse: () => Medium(
              id: '', terreiroId: '', nome: 'Desconhecido', ativo: false),
        );

        return allTicketsAsync.when(
          data: (allTickets) {
            // Filtrar tickets deste médium
            final mediumTickets =
                allTickets.where((t) => t.mediumId == mediumId).toList();
            mediumTickets.sort((a, b) => a.ordemFila.compareTo(b.ordemFila));

            // Separar: chamada atual VS fila de espera
            final chamadaAtual =
                mediumTickets.where((t) => t.status == 'chamada').toList();
            final filaEspera =
                mediumTickets.where((t) => t.status == 'emitida').toList();

            return Scaffold(
              backgroundColor: const Color(0xFFFAFAFA),
              body: Column(
                children: [
                  // Header com info do médium
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.brown,
                          radius: 28,
                          child: Text(
                            medium.nome.isNotEmpty
                                ? medium.nome.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medium.nome,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.brown[800]),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _infoChip(Icons.confirmation_number,
                                      '${mediumTickets.length} senha(s) na fila'),
                                  const SizedBox(width: 12),
                                  _infoChip(Icons.hourglass_empty,
                                      '${filaEspera.length} aguardando'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Senha sendo chamada atualmente
                  if (chamadaAtual.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.brown[700]!, Colors.brown[500]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.brown.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'CHAMANDO AGORA',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            chamadaAtual.first.codigoSenha,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Rechamar
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.brown[700],
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                                icon: const Icon(Icons.volume_up),
                                label: Text(
                                    'RECHAMAR (${chamadaAtual.first.chamadaCount}x)'),
                                onPressed: () {
                                  ref
                                      .read(queueRepositoryProvider)
                                      .callTicket(chamadaAtual.first.id);
                                },
                              ),
                              const SizedBox(width: 12),
                              // Confirmar Atendimento
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 16),
                                ),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('CONFIRMAR ATENDIMENTO'),
                                onPressed: () {
                                  ref
                                      .read(queueRepositoryProvider)
                                      .markAttended(chamadaAtual.first.id);
                                },
                              ),
                              const SizedBox(width: 16),
                              // Não compareceu - Voltar para o fim da fila
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange[900],
                                  side: BorderSide(color: Colors.orange[900]!),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 16),
                                ),
                                icon: const Icon(Icons.person_off),
                                label: const Text('NÃO COMPARECEU (FIM DA FILA)'),
                                onPressed: () {
                                  ref
                                      .read(queueRepositoryProvider)
                                      .markAbsentAndRequeue(
                                          chamadaAtual.first.id,
                                          chamadaAtual.first.entidadeId);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Botão CHAMAR PRÓXIMA
                  if (chamadaAtual.isEmpty && filaEspera.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          icon: const Icon(Icons.campaign, size: 28),
                          label: Text(
                              'CHAMAR PRÓXIMA: ${filaEspera.first.codigoSenha}'),
                          onPressed: () {
                            ref
                                .read(queueRepositoryProvider)
                                .callTicket(filaEspera.first.id);
                          },
                        ),
                      ),
                    ),

                  // Lista de senhas na fila
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Fila de Espera (${filaEspera.length})',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey[700]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: filaEspera.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.done_all,
                                    size: 64, color: Colors.green[200]),
                                const SizedBox(height: 16),
                                Text(
                                  chamadaAtual.isEmpty
                                      ? 'Nenhuma senha na fila'
                                      : 'Todas as senhas já foram chamadas',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filaEspera.length,
                            itemBuilder: (context, index) {
                              final ticket = filaEspera[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.brown[100],
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.brown[800]),
                                    ),
                                  ),
                                  title: Text(
                                    ticket.codigoSenha,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        letterSpacing: 2),
                                  ),
                                  subtitle: Text(
                                    'Posição: ${ticket.ordemFila}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  trailing: chamadaAtual.isEmpty && index == 0
                                      ? ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.brown,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(queueRepositoryProvider)
                                                .callTicket(ticket.id);
                                          },
                                          child: const Text('CHAMAR'),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Erro: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erro: $err')),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.brown[400]),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.brown[600])),
        ],
      ),
    );
  }
}

// =============================================================================
// ABA 2: REDISTRIBUIR SENHAS
// =============================================================================
class _RedistribuirSenhasTab extends ConsumerStatefulWidget {
  const _RedistribuirSenhasTab();

  @override
  _RedistribuirSenhasTabState createState() => _RedistribuirSenhasTabState();
}

class _RedistribuirSenhasTabState
    extends ConsumerState<_RedistribuirSenhasTab> {
  String? _selectedSourceMediumId;

  @override
  Widget build(BuildContext context) {
    const terreiroId = 'demo-terreiro';
    final activeGiraAsync = ref.watch(activeGiraProvider(terreiroId));
    final mediumsAsync = ref.watch(mediumListProvider(terreiroId));

    return activeGiraAsync.when(
      data: (gira) {
        if (gira == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma gira aberta no momento',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return mediumsAsync.when(
          data: (mediums) {
            final presentMediums = mediums.where((m) {
              return m.ativo && (gira.presencas[m.id] ?? false);
            }).toList();

            return _RedistribuirContent(
              gira: gira,
              presentMediums: presentMediums,
              allMediums: mediums,
              terreiroId: terreiroId,
              selectedSourceMediumId: _selectedSourceMediumId,
              onSelectSource: (id) =>
                  setState(() => _selectedSourceMediumId = id),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Erro: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erro: $err')),
    );
  }
}

class _RedistribuirContent extends ConsumerWidget {
  final Gira gira;
  final List<Medium> presentMediums;
  final List<Medium> allMediums;
  final String terreiroId;
  final String? selectedSourceMediumId;
  final Function(String?) onSelectSource;

  const _RedistribuirContent({
    required this.gira,
    required this.presentMediums,
    required this.allMediums,
    required this.terreiroId,
    required this.selectedSourceMediumId,
    required this.onSelectSource,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTicketsAsync = ref.watch(allTicketsForGiraProvider(gira.id));

    return allTicketsAsync.when(
      data: (allTickets) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instruções
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[800]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selecione o médium que NÃO irá mais atender. As senhas pendentes dele serão redistribuídas para outro médium.',
                        style: TextStyle(
                            fontSize: 14, color: Colors.amber[900]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Seletor de médium ORIGEM
              Text(
                'Médium que vai parar de atender:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.brown[800]),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: presentMediums.map((medium) {
                  final ticketsCount = allTickets
                      .where((t) =>
                          t.mediumId == medium.id && t.status == 'emitida')
                      .length;
                  final isSelected = selectedSourceMediumId == medium.id;

                  return InkWell(
                    onTap: () => onSelectSource(
                        isSelected ? null : medium.id),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.red[50] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.red[400]!
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color:
                                        Colors.red.withOpacity(0.15),
                                    blurRadius: 8)
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: isSelected
                                ? Colors.red
                                : Colors.brown[200],
                            child: Text(
                              medium.nome.isNotEmpty
                                  ? medium.nome
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            medium.nome,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.red[800]
                                  : Colors.brown[800],
                            ),
                          ),
                          Text(
                            '$ticketsCount senha(s) pendente(s)',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Se selecionou origem, mostra as senhas e destino
              if (selectedSourceMediumId != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                Builder(builder: (context) {
                  final pendingTickets = allTickets
                      .where((t) =>
                          t.mediumId == selectedSourceMediumId &&
                          t.status == 'emitida')
                      .toList();

                  if (pendingTickets.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.done_all,
                                size: 64, color: Colors.green[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Este médium não tem senhas pendentes para redistribuir.',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Médiuns disponíveis como destino (excluindo o selecionado)
                  final destMediums = presentMediums
                      .where((m) => m.id != selectedSourceMediumId)
                      .toList();

                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Senhas pendentes (${pendingTickets.length}):',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.brown[800]),
                        ),
                        const SizedBox(height: 12),

                        // Botão redistribuir todas
                        if (destMediums.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.swap_horiz),
                              label: const Text(
                                'REDISTRIBUIR TODAS AS SENHAS',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              onPressed: () =>
                                  _showRedistribuirDialog(
                                context,
                                ref,
                                pendingTickets,
                                destMediums,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        Expanded(
                          child: ListView.builder(
                            itemCount: pendingTickets.length,
                            itemBuilder: (context, index) {
                              final ticket = pendingTickets[index];
                              return Card(
                                margin:
                                    const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.brown[100],
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.brown[800]),
                                    ),
                                  ),
                                  title: Text(
                                    ticket.codigoSenha,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        letterSpacing: 2),
                                  ),
                                  subtitle: Text(
                                      'Posição: ${ticket.ordemFila}'),
                                  trailing: destMediums.isNotEmpty
                                      ? PopupMenuButton<String>(
                                          icon: const Icon(
                                              Icons.swap_horiz,
                                              color: Colors.brown),
                                          tooltip: 'Redistribuir esta senha',
                                          onSelected: (destMediumId) {
                                            _redistribuirTicket(
                                                context,
                                                ref,
                                                ticket,
                                                destMediumId,
                                                destMediums);
                                          },
                                          itemBuilder: (context) =>
                                              destMediums
                                                  .map(
                                                    (m) =>
                                                        PopupMenuItem<
                                                            String>(
                                                      value: m.id,
                                                      child: Text(
                                                          m.nome),
                                                    ),
                                                  )
                                                  .toList(),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erro: $err')),
    );
  }

  void _showRedistribuirDialog(BuildContext context, WidgetRef ref,
      List<Ticket> tickets, List<Medium> destMediums) {
    String? selectedDestId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Redistribuir Senhas'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecione o médium que receberá as ${tickets.length} senha(s):',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ...destMediums.map((m) {
                  final isSelected = selectedDestId == m.id;
                  return InkWell(
                    onTap: () =>
                        setDialogState(() => selectedDestId = m.id),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.green[50]
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green[400]!
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isSelected
                                ? Colors.green
                                : Colors.brown[200],
                            child: Text(
                              m.nome.isNotEmpty
                                  ? m.nome
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            m.nome,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (isSelected) ...[
                            const Spacer(),
                            Icon(Icons.check_circle,
                                color: Colors.green[400]),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              onPressed: selectedDestId == null
                  ? null
                  : () async {
                      final firestore = FirebaseFirestore.instance;
                      final batch = firestore.batch();

                      for (var ticket in tickets) {
                        batch.update(
                          firestore.collection('tickets').doc(ticket.id),
                          {'mediumId': selectedDestId},
                        );
                      }

                      await batch.commit();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${tickets.length} senha(s) redistribuída(s) com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
              child: const Text('CONFIRMAR REDISTRIBUIÇÃO'),
            ),
          ],
        ),
      ),
    );
  }

  void _redistribuirTicket(BuildContext context, WidgetRef ref,
      Ticket ticket, String destMediumId, List<Medium> destMediums) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('tickets').doc(ticket.id).update({
      'mediumId': destMediumId,
    });

    final destMedium = destMediums.firstWhere((m) => m.id == destMediumId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Senha ${ticket.codigoSenha} redistribuída para ${destMedium.nome}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

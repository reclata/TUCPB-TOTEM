import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:terreiro_queue_system/src/shared/models/models.dart';
import 'package:terreiro_queue_system/src/shared/providers/global_providers.dart';
import 'package:terreiro_queue_system/src/shared/utils/spiritual_utils.dart';
import 'package:terreiro_queue_system/src/features/admin/data/admin_repository.dart';
import 'package:terreiro_queue_system/src/features/queue/data/firestore_queue_repository.dart';

// =============================================================================
// HELPER: Sort Mediums by Priority (Sandra, Eduardo, Robson, Jucineide, then alphabetical)
// =============================================================================
void _sortMediumsByPriority(List<Medium> mediums) {
  final priorityNames = ['sandra', 'eduardo', 'robson', 'jucineide'];
  mediums.sort((a, b) {
    final aName = a.nome.toLowerCase().trim();
    final bName = b.nome.toLowerCase().trim();

    final aIndex = priorityNames.indexWhere((p) => aName.startsWith(p));
    final bIndex = priorityNames.indexWhere((p) => bName.startsWith(p));

    final aHasPriority = aIndex != -1;
    final bHasPriority = bIndex != -1;

    if (aHasPriority && bHasPriority) {
      return aIndex.compareTo(bIndex);
    } else if (aHasPriority) {
      return -1;
    } else if (bHasPriority) {
      return 1;
    } else {
      return aName.compareTo(bName);
    }
  });
}

// =============================================================================
// Provider: streams ALL active tickets for a Gira (not just one entity)
// =============================================================================
final allTicketsForGiraProvider = StreamProvider.family<List<Ticket>, String>((
  ref,
  giraId,
) {
  return FirebaseFirestore.instance
      .collection('tickets')
      .where('giraId', isEqualTo: giraId)
      .where('status', whereIn: ['emitida', 'chamada'])
      .orderBy('ordemFila')
      .snapshots()
      .map(
        (snap) => snap.docs.map((doc) => Ticket.fromJson(doc.data())).toList(),
      );
});

final selectedMediumIdProvider = StateProvider<String?>((ref) => null);
final visaoGeralSearchProvider = StateProvider<String>((ref) => '');
final chamarSenhaSearchProvider = StateProvider<String>((ref) => '');

// =============================================================================
// SENHAS SCREEN - Container com TabBar
// =============================================================================
class SenhasScreen extends StatelessWidget {
  const SenhasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
                Tab(icon: Icon(Icons.grid_view), text: 'Visão Geral'),
                Tab(icon: Icon(Icons.campaign), text: 'Chamar Senha'),
                Tab(icon: Icon(Icons.swap_horiz), text: 'Redistribuir Senhas'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _VisaoGeralTab(), // Nova aba
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
// ABA 1: VISÃO GERAL (NOVA)
// =============================================================================
class _VisaoGeralTab extends ConsumerWidget {
  const _VisaoGeralTab();

  void _showTicketOptions(
    BuildContext context,
    WidgetRef ref,
    Ticket ticket,
    Medium medium,
    Gira gira,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final adminRepo = ref.read(adminRepositoryProvider);
        return AlertDialog(
          title: Text('Ações para a Senha ${ticket.codigoSenha}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Médium: ${medium.nome}'),
              Text('Status Atual: ${ticket.status}'),
              const SizedBox(height: 16),

              // Chamar Senha
              if (ticket.status == 'emitida')
                ListTile(
                  leading: const Icon(Icons.campaign, color: Colors.green),
                  title: const Text('Chamar Senha'),
                  onTap: () {
                    adminRepo.callPassword(
                      ticket: ticket,
                      panelId: 'tv-painel-1',
                      entidadeNome: getEntityOfDay(gira, medium).entidadeNome,
                      mediumNome: medium.nome,
                      giraNome: gira.tema,
                    );
                    Navigator.pop(context);
                  },
                ),

              // Rechamar Senha
              if (ticket.status == 'chamada')
                ListTile(
                  leading: const Icon(
                    Icons.record_voice_over,
                    color: Colors.amber,
                  ),
                  title: Text('Rechamar Senha (${ticket.chamadaCount}x)'),
                  onTap: ticket.chamadaCount < 3
                      ? () {
                          adminRepo.recallPassword(
                            ticket: ticket,
                            panelId: 'tv-painel-1',
                            entidadeNome: getEntityOfDay(
                              gira,
                              medium,
                            ).entidadeNome,
                            mediumNome: medium.nome,
                            giraNome: gira.tema,
                          );
                          Navigator.pop(context);
                        }
                      : null,
                ),

              // Atendimento Realizado
              if (ticket.status == 'chamada')
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Atendimento Realizado'),
                  onTap: () {
                    adminRepo.markAsAttended(
                      ticket: ticket,
                      panelId: 'tv-painel-1',
                    );
                    Navigator.pop(context);
                  },
                ),

              // Não Compareceu
              if (ticket.status == 'chamada' || ticket.status == 'emitida')
                ListTile(
                  leading: const Icon(Icons.person_off, color: Colors.red),
                  title: const Text('Não Compareceu'),
                  onTap: () {
                    adminRepo.markAsNotShown(
                      ticket: ticket,
                      panelId: 'tv-painel-1',
                    );
                    Navigator.pop(context);
                  },
                ),

              // Encerrar Senha (Cancel)
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.grey),
                title: const Text('Encerrar/Cancelar Senha'),
                onTap: () {
                  FirebaseFirestore.instance
                      .collection('tickets')
                      .doc(ticket.id)
                      .update({'status': 'cancelada'});
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const terreiroId = 'demo-terreiro';
    final activeGiraAsync = ref.watch(activeGiraProvider(terreiroId));
    final activeMediumsAsync = ref.watch(activeMediumsProvider(terreiroId));

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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return activeMediumsAsync.when(
          data: (pairs) {
            // Filtrar e Ordenar os pares (Médium, Entidade)
            final query = ref.watch(visaoGeralSearchProvider).toLowerCase();
            final filteredPairs = pairs.where((p) => 
                p.medium.nome.toLowerCase().contains(query) || 
                p.entity.nome.toLowerCase().contains(query)
            ).toList();

            // Ordenação por prioridade
            final priorityNames = ['sandra', 'eduardo', 'robson', 'jucineide'];
            filteredPairs.sort((a, b) {
              final aName = a.medium.nome.toLowerCase().trim();
              final bName = b.medium.nome.toLowerCase().trim();

              final aIndex = priorityNames.indexWhere((p) => aName.startsWith(p));
              final bIndex = priorityNames.indexWhere((p) => bName.startsWith(p));

              final aHasPriority = aIndex != -1;
              final bHasPriority = bIndex != -1;

              if (aHasPriority && bHasPriority) {
                if (aIndex != bIndex) return aIndex.compareTo(bIndex);
                return a.entity.nome.compareTo(b.entity.nome);
              } else if (aHasPriority) {
                return -1;
              } else if (bHasPriority) {
                return 1;
              } else {
                if (aName != bName) return aName.compareTo(bName);
                return a.entity.nome.compareTo(b.entity.nome);
              }
            });

            if (filteredPairs.isEmpty) {
              return const Center(child: Text("Nenhum médium/entidade disponível."));
            }

            final allTicketsAsync = ref.watch(
              allTicketsForGiraProvider(gira.id),
            );

            return allTicketsAsync.when(
              data: (allTickets) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Pesquisar Médium ou Guia...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (val) =>
                            ref.read(visaoGeralSearchProvider.notifier).state =
                                val,
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double itemWidth = 400;
                          final int crossAxisCount =
                              (constraints.maxWidth / itemWidth).floor().clamp(
                                1,
                                4,
                              );

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount > 1
                                      ? 2
                                      : 1, // Fixado em 2 ou 1 dependendo da tela
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  mainAxisExtent: 260, // Altura fixa do card
                                ),
                            itemCount: filteredPairs.length,
                            itemBuilder: (context, index) {
                              final pair = filteredPairs[index];
                              final medium = pair.medium;
                              final entity = pair.entity;

                              // Filtrar tickets deste médium E desta entidade
                              final mediumTickets = allTickets
                                  .where((t) => t.mediumId == medium.id && t.entidadeId == entity.id)
                                  .toList();
                              final maxFichas = medium.maxFichas > 0
                                  ? medium.maxFichas
                                  : 25; // Padrão 25 como solicitado no exemplo (1 a 25)

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          ref
                                                  .read(
                                                    selectedMediumIdProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              medium.id;
                                          DefaultTabController.of(
                                            context,
                                          ).animateTo(1);
                                        },
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor:
                                                  Colors.brown[100],
                                              child: Text(
                                                medium.nome.isNotEmpty
                                                    ? medium.nome[0]
                                                          .toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  color: Colors.brown[800],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    formatMediumName(medium.nome),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Text(
                                                    entity.nome,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.brown[600],
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: List.generate(maxFichas, (i) {
                                          final fichaNum = i + 1;
                                          // Find ticket for this position (sequencial or ordemFila? Used sequencial logic based on description)
                                          // Actually better to use sequencial from ticket if we assume seq is 1..N
                                          final ticket = mediumTickets
                                              .where(
                                                (t) => t.sequencial == fichaNum,
                                              )
                                              .firstOrNull;

                                          Color bgColor = Colors.grey[100]!;
                                          Color textColor = Colors.grey[400]!;
                                          Border? border = Border.all(
                                            color: Colors.grey[300]!,
                                          );
                                          IconData? icon;

                                          if (ticket != null) {
                                            border = null;
                                            if (ticket.status == 'chamada') {
                                              bgColor = Colors.green;
                                              textColor = Colors.white;
                                              icon = Icons.campaign;
                                            } else if (ticket.status ==
                                                'emitida') {
                                              bgColor = Colors.amber[100]!;
                                              textColor = Colors.amber[900]!;
                                              border = Border.all(
                                                color: Colors.amber,
                                              );
                                            } else if (ticket.status ==
                                                'atendida') {
                                              bgColor = Colors.grey[400]!;
                                              textColor = Colors.white;
                                              icon = Icons.check;
                                            }
                                          }

                                          return InkWell(
                                            onTap: (ticket != null)
                                                ? () {
                                                    _showTicketOptions(
                                                      context,
                                                      ref,
                                                      ticket,
                                                      medium,
                                                      gira,
                                                    );
                                                  }
                                                : null,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: bgColor,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: border,
                                              ),
                                              child: Center(
                                                child: icon != null
                                                    ? Icon(
                                                        icon,
                                                        size: 20,
                                                        color: textColor,
                                                      )
                                                    : Text(
                                                        '$fichaNum',
                                                        style: TextStyle(
                                                          color: textColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text("Erro ao carregar tickets: $e"),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text("Erro: $e")),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text("Erro: $e")),
    );
  }
}

class _ChamarSenhaTab extends ConsumerWidget {
  const _ChamarSenhaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const terreiroId = 'demo-terreiro';
    final activeGiraAsync = ref.watch(activeGiraProvider(terreiroId));
    final activeMediumsAsync = ref.watch(activeMediumsProvider(terreiroId));
    final allTicketsAsync = activeGiraAsync.value != null
        ? ref.watch(allTicketsForGiraProvider(activeGiraAsync.value!.id))
        : const AsyncValue<List<Ticket>>.loading();

    final selectedMediumId = ref.watch(selectedMediumIdProvider);

    // Se um médium estiver selecionado, exibe o painel detalhado dele
    if (selectedMediumId != null && activeGiraAsync.value != null) {
      return _MediumQueuePanel(
        giraId: activeGiraAsync.value!.id,
        mediumId: selectedMediumId,
        terreiroId: terreiroId,
        onBack: () => ref.read(selectedMediumIdProvider.notifier).state = null,
      );
    }

    return activeGiraAsync.when(
      data: (gira) {
        if (gira == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('Nenhuma gira aberta no momento'),
              ],
            ),
          );
        }

        return activeMediumsAsync.when(
          data: (pairs) {
            final query = ref.watch(chamarSenhaSearchProvider).toLowerCase();
            final filteredPairs = pairs.where((p) => 
                p.medium.nome.toLowerCase().contains(query) || 
                p.entity.nome.toLowerCase().contains(query)
            ).toList();

            // Ordenação por prioridade
            final priorityNames = ['sandra', 'eduardo', 'robson', 'jucineide'];
            filteredPairs.sort((a, b) {
              final aName = a.medium.nome.toLowerCase().trim();
              final bName = b.medium.nome.toLowerCase().trim();
              final aIndex = priorityNames.indexWhere((p) => aName.startsWith(p));
              final bIndex = priorityNames.indexWhere((p) => bName.startsWith(p));
              if (aIndex != -1 && bIndex != -1) {
                if (aIndex != bIndex) return aIndex.compareTo(bIndex);
                return a.entity.nome.compareTo(b.entity.nome);
              } else if (aIndex != -1) return -1;
              else if (bIndex != -1) return 1;
              else {
                if (aName != bName) return aName.compareTo(bName);
                return a.entity.nome.compareTo(b.entity.nome);
              }
            });

            final allTicketsAsync = ref.watch(allTicketsForGiraProvider(gira.id));
            return allTicketsAsync.when(
              data: (allTickets) {
                // Filtrar tickets emitidos (aguardando) de todos os médiuns e ordenar globalmente
                final globalQueue = allTickets
                    .where((t) => t.status == 'emitida')
                    .toList();
                globalQueue.sort(
                  (Ticket a, Ticket b) => a.ordemFila.compareTo(b.ordemFila),
                );

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seção: Próximas Senhas Gerais
                      if (globalQueue.isNotEmpty) ...[
                        Text(
                          'PRÓXIMAS SENHAS GERAIS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 50,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: globalQueue.take(10).length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final ticket = globalQueue[index];
                              final mediumRecord = pairs.firstWhere(
                                (p) => p.medium.id == ticket.mediumId,
                                orElse: () => (medium: Medium(
                                  id: '',
                                  terreiroId: '',
                                  nome: '?',
                                  ativo: false,
                                ), entity: Entidade(id: '', terreiroId: '', nome: '?', linha: '', tipo: '')),
                              );
                              final medium = mediumRecord.medium;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.brown[200]!),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ticket.codigoSenha,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown[800],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 1,
                                      height: 16,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      medium.nome.split(' ')[0],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      const SizedBox(height: 16),
                      // Barra de Busca
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Pesquisar Médium ou Guia...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (val) => ref
                            .read(chamarSenhaSearchProvider.notifier)
                            .state = val,
                      ),
                      const SizedBox(height: 24),

                      // Grid de Médiuns Responsivo
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double itemWidth = 320;
                            final int crossAxisCount = (constraints.maxWidth /
                                    itemWidth)
                                .floor()
                                .clamp(1, 6);

                            return GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 220,
                              ),
                              itemCount: filteredPairs.length,
                              itemBuilder: (context, index) {
                                final pair = filteredPairs[index];
                                final medium = pair.medium;
                                final entity = pair.entity;

                                final mediumTickets = allTickets
                                    .where((t) =>
                                        t.mediumId == medium.id &&
                                        t.entidadeId == entity.id)
                                    .toList();

                                final emAtendimento = mediumTickets
                                    .where((t) => t.status == 'chamada')
                                    .toList();
                                final naFila = mediumTickets
                                    .where((t) => t.status == 'emitida')
                                    .toList();
                                // Ordenar fila para pegar o próximo
                                naFila.sort(
                                  (Ticket a, Ticket b) =>
                                      a.ordemFila.compareTo(b.ordemFila),
                                );

                                final bool isBusy = emAtendimento.isNotEmpty;
                                final bool hasQueue = naFila.isNotEmpty;

                                final entidadeDisplay = getEntityOfDay(
                                  gira,
                                  medium,
                                ).entidadeNome;

                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        ref
                                            .read(
                                              selectedMediumIdProvider.notifier,
                                            )
                                            .state = medium
                                            .id,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: isBusy
                                                    ? Colors.orange[100]
                                                    : Colors.green[100],
                                                child: Text(
                                                  medium.nome.isNotEmpty
                                                      ? medium.nome[0]
                                                            .toUpperCase()
                                                      : '?',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: isBusy
                                                        ? Colors.orange[800]
                                                        : Colors.green[800],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      formatMediumName(medium.nome),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    // ENTIDADE DO DIA
                                                    Text(
                                                      entity.nome,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color:
                                                            Colors.brown[600],
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      isBusy
                                                          ? '● Em Atendimento'
                                                          : '○ Livre',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isBusy
                                                            ? Colors.orange[800]
                                                            : Colors.green[800],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          // Status da fila
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.people,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${naFila.length} na fila',
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          // Botão de Ação
                                          SizedBox(
                                            width: double.infinity,
                                            height: 40,
                                            child: isBusy
                                                ? OutlinedButton(
                                                    onPressed: () =>
                                                        ref
                                                            .read(
                                                              selectedMediumIdProvider
                                                                  .notifier,
                                                            )
                                                            .state = medium
                                                            .id,
                                                    style:
                                                        OutlinedButton.styleFrom(
                                                          foregroundColor:
                                                              Colors
                                                                  .orange[800],
                                                          side: BorderSide(
                                                            color: Colors
                                                                .orange[200]!,
                                                          ),
                                                        ),
                                                    child: Text(
                                                      'ATENDENDO: ${emAtendimento.first.codigoSenha}',
                                                    ),
                                                  )
                                                : ElevatedButton(
                                                    onPressed: hasQueue
                                                        ? () {
                                                            // Chamar próxima
                                                            final adminRepo =
                                                                ref.read(
                                                                  adminRepositoryProvider,
                                                                );
                                                            final nextTicket =
                                                                naFila.first;
                                                            adminRepo.callPassword(
                                                              ticket:
                                                                  nextTicket,
                                                              panelId:
                                                                  'tv-painel-1',
                                                              entidadeNome:
                                                                  entidadeDisplay,
                                                              mediumNome:
                                                                  medium.nome,
                                                              giraNome:
                                                                  gira.tema,
                                                            );
                                                          }
                                                        : null,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.brown,
                                                      foregroundColor:
                                                          Colors.white,
                                                      disabledBackgroundColor:
                                                          Colors.grey[200],
                                                      disabledForegroundColor:
                                                          Colors.grey[400],
                                                    ),
                                                    child: hasQueue
                                                        ? const Text('CHAMAR')
                                                        : const Text(
                                                            'SEM FILA',
                                                          ),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Erro: $e")),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text("Erro: $e")),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text("Erro: $e")),
    );
  }
}

// =============================================================================
// PAINEL DA FILA DO MÉDIUM (lado direito)
// =============================================================================
class _MediumQueuePanel extends ConsumerStatefulWidget {
  final String giraId;
  final String mediumId;
  final String terreiroId;
  final VoidCallback? onBack;

  const _MediumQueuePanel({
    required this.giraId,
    required this.mediumId,
    required this.terreiroId,
    this.onBack,
  });

  @override
  ConsumerState<_MediumQueuePanel> createState() => _MediumQueuePanelState();
}

class _MediumQueuePanelState extends ConsumerState<_MediumQueuePanel> {
  String _selectedPanelId = 'tv-painel-1';

  @override
  Widget build(BuildContext context) {
    final mediumsAsync = ref.watch(mediumListProvider(widget.terreiroId));
    final activeGiraAsync = ref.watch(activeGiraProvider(widget.terreiroId));
    final allTicketsAsync = ref.watch(allTicketsForGiraProvider(widget.giraId));

    return mediumsAsync.when(
      data: (mediums) {
        final medium = mediums.firstWhere(
          (m) => m.id == widget.mediumId,
          orElse: () => Medium(
            id: '',
            terreiroId: '',
            nome: 'Desconhecido',
            ativo: false,
          ),
        );

        return allTicketsAsync.when(
          data: (allTickets) {
            // Filtrar tickets deste médium
            final mediumTickets = allTickets
                .where((t) => t.mediumId == widget.mediumId)
                .toList();
            mediumTickets.sort(
              (Ticket a, Ticket b) => a.ordemFila.compareTo(b.ordemFila),
            );

            // Separar: chamada atual VS fila de espera
            final chamadaAtual = mediumTickets
                .where((t) => t.status == 'chamada')
                .toList();
            final filaEspera = mediumTickets
                .where((t) => t.status == 'emitida')
                .toList();

            return Scaffold(
              backgroundColor: const Color(0xFFFAFAFA),
              body: Column(
                children: [
                  // Header com info do médium e botão Voltar
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
                        if (widget.onBack != null) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: widget.onBack,
                          ),
                          const SizedBox(width: 8),
                        ],
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
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medium.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.brown[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Entidades agora aparecem apenas aqui no detalhe
                              Text(
                                getEntityOfDay(
                                  activeGiraAsync.value!,
                                  medium,
                                ).entidadeNome,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),

                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _infoChip(
                                    Icons.confirmation_number,
                                    '${mediumTickets.length} senha(s) na fila',
                                  ),
                                  const SizedBox(width: 12),
                                  _infoChip(
                                    Icons.hourglass_empty,
                                    '${filaEspera.length} aguardando',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Dropdown Panel Selector
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.brown[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPanelId,
                              icon: const Icon(Icons.tv, color: Colors.brown),
                              items: const [
                                DropdownMenuItem(
                                  value: 'tv-painel-1',
                                  child: Text('Painel TV 1'),
                                ),
                                DropdownMenuItem(
                                  value: 'tv-painel-2',
                                  child: Text('Painel TV 2'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedPanelId = val);
                              },
                            ),
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
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            chamadaAtual.first.codigoSenha,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
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
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.volume_up),
                                label: Text(
                                  'RECHAMAR (${chamadaAtual.first.chamadaCount}x)',
                                ),
                                onPressed: () {
                                  ref
                                      .read(adminRepositoryProvider)
                                      .recallPassword(
                                        ticket: chamadaAtual.first,
                                        panelId: _selectedPanelId,
                                        entidadeNome: getEntityOfDay(
                                          activeGiraAsync.value!,
                                          medium,
                                        ).entidadeNome,
                                        mediumNome: medium.nome,
                                        giraNome: activeGiraAsync.value!.tema,
                                      );
                                },
                              ),
                              const SizedBox(width: 12),
                              // Confirmar Atendimento
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('CONFIRMAR ATENDIMENTO'),
                                onPressed: () {
                                  ref
                                      .read(adminRepositoryProvider)
                                      .markAsAttended(
                                        ticket: chamadaAtual.first,
                                        panelId: _selectedPanelId,
                                      );
                                },
                              ),
                              const SizedBox(width: 16),
                              // Não compareceu - Voltar para o fim da fila
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange[900],
                                  side: BorderSide(color: Colors.orange[900]!),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                                icon: const Icon(Icons.person_off),
                                label: const Text(
                                  'NÃO COMPARECEU (FIM DA FILA)',
                                ),
                                onPressed: () {
                                  ref
                                      .read(adminRepositoryProvider)
                                      .markAsNotShown(
                                        ticket: chamadaAtual.first,
                                        panelId: _selectedPanelId,
                                      );
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
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          icon: const Icon(Icons.campaign, size: 28),
                          label: Text(
                            'CHAMAR PRÓXIMA: ${filaEspera.first.codigoSenha}',
                          ),
                          onPressed: () {
                            ref
                                .read(adminRepositoryProvider)
                                .callPassword(
                                  ticket: filaEspera.first,
                                  panelId: _selectedPanelId,
                                  entidadeNome: getEntityOfDay(
                                    activeGiraAsync.value!,
                                    medium,
                                  ).entidadeNome,
                                  mediumNome: medium.nome,
                                  giraNome: activeGiraAsync.value!.tema,
                                );
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
                          color: Colors.grey[700],
                        ),
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
                                Icon(
                                  Icons.done_all,
                                  size: 64,
                                  color: Colors.green[200],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  chamadaAtual.isEmpty
                                      ? 'Nenhuma senha na fila'
                                      : 'Todas as senhas já foram chamadas',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                  ),
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.brown[100],
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown[800],
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    ticket.codigoSenha,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      letterSpacing: 2,
                                    ),
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
                                                .read(adminRepositoryProvider)
                                                .callPassword(
                                                  ticket: ticket,
                                                  panelId: _selectedPanelId,
                                                  entidadeNome: getEntityOfDay(
                                                    activeGiraAsync.value!,
                                                    medium,
                                                  ).entidadeNome,
                                                  mediumNome: medium.nome,
                                                  giraNome: activeGiraAsync
                                                      .value!
                                                      .tema,
                                                );
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
          Text(label, style: TextStyle(fontSize: 12, color: Colors.brown[600])),
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
            _sortMediumsByPriority(presentMediums);

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
                          fontSize: 14,
                          color: Colors.amber[900],
                        ),
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
                  color: Colors.brown[800],
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: presentMediums.map((medium) {
                  final ticketsCount = allTickets
                      .where(
                        (t) => t.mediumId == medium.id && t.status == 'emitida',
                      )
                      .length;
                  final isSelected = selectedSourceMediumId == medium.id;

                  return InkWell(
                    onTap: () => onSelectSource(isSelected ? null : medium.id),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red[50] : Colors.white,
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
                                  color: Colors.red.withOpacity(0.15),
                                  blurRadius: 8,
                                ),
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
                                  ? medium.nome.substring(0, 1).toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
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
                              color: Colors.grey[600],
                            ),
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

                Builder(
                  builder: (context) {
                    final pendingTickets = allTickets
                        .where(
                          (t) =>
                              t.mediumId == selectedSourceMediumId &&
                              t.status == 'emitida',
                        )
                        .toList();

                    if (pendingTickets.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.done_all,
                                size: 64,
                                color: Colors.green[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Este médium não tem senhas pendentes para redistribuir.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
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
                              color: Colors.brown[800],
                            ),
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
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.swap_horiz),
                                label: const Text(
                                  'REDISTRIBUIR TODAS AS SENHAS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                onPressed: () => _showRedistribuirDialog(
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
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.brown[100],
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.brown[800],
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      ticket.codigoSenha,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Posição: ${ticket.ordemFila}',
                                    ),
                                    trailing: destMediums.isNotEmpty
                                        ? PopupMenuButton<String>(
                                            icon: const Icon(
                                              Icons.swap_horiz,
                                              color: Colors.brown,
                                            ),
                                            tooltip: 'Redistribuir esta senha',
                                            onSelected: (destMediumId) {
                                              _redistribuirTicket(
                                                context,
                                                ref,
                                                ticket,
                                                destMediumId,
                                                destMediums,
                                              );
                                            },
                                            itemBuilder: (context) =>
                                                destMediums
                                                    .map(
                                                      (m) =>
                                                          PopupMenuItem<String>(
                                                            value: m.id,
                                                            child: Text(m.nome),
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
                  },
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erro: $err')),
    );
  }

  void _showRedistribuirDialog(
    BuildContext context,
    WidgetRef ref,
    List<Ticket> tickets,
    List<Medium> destMediums,
  ) {
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
                    onTap: () => setDialogState(() => selectedDestId = m.id),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green[50] : Colors.grey[50],
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
                                  ? m.nome.substring(0, 1).toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
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
                            Icon(Icons.check_circle, color: Colors.green[400]),
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
                          {'mediumId': selectedDestId, 'isRedistributed': true},
                        );
                      }

                      await batch.commit();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${tickets.length} senha(s) redistribuída(s) com sucesso!',
                            ),
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

  void _redistribuirTicket(
    BuildContext context,
    WidgetRef ref,
    Ticket ticket,
    String destMediumId,
    List<Medium> destMediums,
  ) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('tickets').doc(ticket.id).update({
      'mediumId': destMediumId,
      'isRedistributed': true,
    });

    final destMedium = destMediums.firstWhere((m) => m.id == destMediumId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Senha ${ticket.codigoSenha} redistribuída para ${destMedium.nome}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

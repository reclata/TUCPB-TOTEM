
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/models/models.dart';
import '../data/admin_repository.dart';
import '../../../../shared/providers/global_providers.dart';
import '../../queue/data/firestore_queue_repository.dart';



class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    AdminDashboard(),
    AdminConfig(),
    AdminQueue(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Gira'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Fila'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

// --- TAB 1: DASHBOARD ---
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Get real Terreiro ID from Auth
    final terreiroId = 'demo-terreiro'; 
    final girasAsync = ref.watch(giraListProvider(terreiroId));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gira Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showStartGiraDialog(context, ref, terreiroId),
            icon: const Icon(Icons.add),
            label: const Text('ABRIR NOVA GIRA'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text('Histórico:', style: TextStyle(fontSize: 18)),
          Expanded(
            child: girasAsync.when(
              data: (giras) => ListView.builder(
                itemCount: giras.length,
                itemBuilder: (context, index) {
                  final gira = giras[index];
                  return Card(
                    child: ListTile(
                      title: Text('${gira.tema} - ${DateFormat('dd/MM/yyyy').format(gira.data)}'),
                      subtitle: Text('Status: ${gira.status}'),
                      trailing: gira.status == 'aberta'
                          ? IconButton(
                              icon: const Icon(Icons.stop_circle, color: Colors.red),
                              onPressed: () => ref.read(adminRepositoryProvider).closeGira(gira.id),
                            )
                          : null,
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),
          ),
        ],
      ),
    );
  }

  void _showStartGiraDialog(BuildContext context, WidgetRef ref, String terreiroId) {
    final themeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir Gira do Dia'),
        content: TextField(
          controller: themeController,
          decoration: const InputDecoration(labelText: 'Tema (ex: Caboclo)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newGira = Gira(
                id: const Uuid().v4(),
                terreiroId: terreiroId,
                tema: themeController.text,
                data: DateTime.now(),
                status: 'aberta',
              );
              ref.read(adminRepositoryProvider).createGira(newGira);
              Navigator.pop(context);
            },
            child: const Text('ABRIR'),
          ),
        ],
      ),
    );
  }
}

// --- TAB 2: CONFIG ---
class AdminConfig extends ConsumerWidget {
  const AdminConfig({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Entidades'),
              Tab(text: 'Médiuns'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _EntitiesList(),
                _MediumsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntitiesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terreiroId = 'demo-terreiro';
    final entitiesAsync = ref.watch(entityListProvider(terreiroId));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addEntityDialog(context, ref, terreiroId),
        child: const Icon(Icons.add),
      ),
      body: entitiesAsync.when(
        data: (entities) => ListView.builder(
          itemCount: entities.length,
          itemBuilder: (context, index) {
            final entity = entities[index];
            return ListTile(
              title: Text(entity.nome),
              subtitle: Text(entity.tipo),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Text('Error: $err'),
      ),
    );
  }

  void _addEntityDialog(BuildContext context, WidgetRef ref, String terreiroId) {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController(); // Or dropdown
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Entidade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome (ex: Cabocla Indaçema)')),
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Tipo (ex: Caboclo)')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final ent = Entidade(
                id: const Uuid().v4(),
                terreiroId: terreiroId,
                nome: nameCtrl.text,
                tipo: typeCtrl.text,
              );
              ref.read(adminRepositoryProvider).addEntity(ent);
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          )
        ],
      ),
    );
  }
}

class _MediumsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terreiroId = 'demo-terreiro';
    final mediumsAsync = ref.watch(mediumListProvider(terreiroId));
    final entitiesAsync = ref.watch(entityListProvider(terreiroId));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addMediumDialog(context, ref, terreiroId),
        child: const Icon(Icons.person_add),
      ),
      body: mediumsAsync.when(
        data: (mediums) => ListView.builder(
          itemCount: mediums.length,
          itemBuilder: (context, index) {
            final medium = mediums[index];
            return SwitchListTile(
              title: Text('${medium.nome} (${medium.iniciais})'),
              subtitle: Text('Status: ${medium.ativo ? "Ativo" : "Inativo"}'),
              value: medium.ativo,
              onChanged: (val) {
                ref.read(adminRepositoryProvider).toggleMediumStatus(medium.id, val);
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Text('Error: $err'),
      ),
    );
  }

   void _addMediumDialog(BuildContext context, WidgetRef ref, String terreiroId) {
    final nameCtrl = TextEditingController();
    final initialsCtrl = TextEditingController();
    // In real app, select entity from list
    // For now, simple text input for entity ID is weird, but I'll skip entity selection for brevity 
    // or fetch entities to show in dropdown.
    final entities = ref.read(entityListProvider(terreiroId)).value ?? [];
    String? selectedEntityId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Novo Médium'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome')),
              TextField(controller: initialsCtrl, decoration: const InputDecoration(labelText: 'Iniciais (ex: SL)')),
              DropdownButton<String>(
                hint: const Text('Selecione Entidade'),
                value: selectedEntityId,
                items: entities.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nome))).toList(),
                onChanged: (val) => setState(() => selectedEntityId = val),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (selectedEntityId == null) return;
                final med = Medium(
                  id: const Uuid().v4(),
                  terreiroId: terreiroId,
                  nome: nameCtrl.text,
                  iniciais: initialsCtrl.text,
                  entidadeId: selectedEntityId!,
                  ativo: true,
                );
                ref.read(adminRepositoryProvider).addMedium(med);
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            )
          ],
        ),
      ),
    );
  }
}

// --- TAB 3: QUEUE ---
class AdminQueue extends ConsumerStatefulWidget {
  const AdminQueue({super.key});

  @override
  ConsumerState<AdminQueue> createState() => _AdminQueueState();
}

class _AdminQueueState extends ConsumerState<AdminQueue> {
  String? _selectedEntityId;

  @override
  Widget build(BuildContext context) {
    // TODO: Use real terreiroId
    const terreiroId = 'demo-terreiro';
    final activeGiraAsync = ref.watch(activeGiraProvider(terreiroId));
    final entitiesAsync = ref.watch(entityListProvider(terreiroId));

    return activeGiraAsync.when(
      data: (gira) {
        if (gira == null) {
          return const Center(child: Text('Nenhuma Gira aberta. Abra uma Gira na aba Dashboard.'));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: entitiesAsync.when(
                data: (entities) {
                  return DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Selecione uma Entidade para Gerenciar a Fila'),
                    value: _selectedEntityId,
                    items: entities.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nome))).toList(),
                    onChanged: (val) => setState(() => _selectedEntityId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('Erro ao carregar entidades: $e'),
              ),
            ),
            if (_selectedEntityId != null)
              Expanded(
                child: _QueueManager(
                  terreiroId: terreiroId,
                  giraId: gira.id,
                  entidadeId: _selectedEntityId!
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erro Gira: $e')),
    );
  }
}

class _QueueManager extends ConsumerWidget {
  final String terreiroId;
  final String giraId;
  final String entidadeId;

  const _QueueManager({required this.terreiroId, required this.giraId, required this.entidadeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We need a stream of tickets for this entity/gira
    // Create a provider family or use stream directly
    final repo = ref.watch(queueRepositoryProvider);
    
    return StreamBuilder<List<Ticket>>(
      stream: repo.streamQueue(giraId, entidadeId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final tickets = snapshot.data!;
        // Sort: called first, then queue order?
        // Actually streamQueue returns active (emitida, chamada).
        // Let's split them.
        final calling = tickets.where((t) => t.status == 'chamada').toList();
        final waiting = tickets.where((t) => t.status == 'emitida').toList(); // Already ordered by repo

        return Column(
          children: [
            // Active Call Section
            if (calling.isNotEmpty)
              Container(
                color: Colors.amber.withOpacity(0.2),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('EM ATENDIMENTO / CHAMANDO:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...calling.map((t) => ListTile(
                      title: Text(t.codigoSenha, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      subtitle: Text('Chamado às ${DateFormat('HH:mm').format(t.dataHoraChamada!)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_active, color: Colors.blue),
                            tooltip: 'Rechamar',
                            onPressed: () => repo.callTicket(t.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            tooltip: 'Concluir (Atendido)',
                            onPressed: () => repo.markAttended(t.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            tooltip: 'Não Compareceu (Final da Fila)',
                            onPressed: () => repo.markAbsentAndRequeue(t.id, entidadeId),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            
            const Divider(),
            
            // Waiting Queue
            Expanded(
              child: ListView.builder(
                itemCount: waiting.length,
                itemBuilder: (context, index) {
                  final ticket = waiting[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(ticket.codigoSenha),
                    subtitle: Text('Posição na fila: ${ticket.ordemFila}'),
                    trailing: index == 0 
                      ? ElevatedButton(
                          onPressed: () => repo.callTicket(ticket.id),
                          child: const Text('CHAMAR'),
                        )
                      : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}


// Providers moved to shared/providers/global_providers.dart

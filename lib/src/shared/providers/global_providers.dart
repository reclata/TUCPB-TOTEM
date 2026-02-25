
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terreiro_queue_system/src/features/admin/data/admin_repository.dart';
import 'package:terreiro_queue_system/src/shared/models/models.dart';

// Providers shared across Admin, Kiosk, TV

final giraListProvider = StreamProvider.family<List<Gira>, String>((ref, terreiroId) {
  return ref.watch(adminRepositoryProvider).streamGiras(terreiroId);
});

// Returns the single active Gira or null
final activeGiraProvider = Provider.family<AsyncValue<Gira?>, String>((ref, terreiroId) {
  final girasList = ref.watch(giraListProvider(terreiroId));
  return girasList.whenData((giras) {
    if (giras.isEmpty) return null;

    // 1. Procurar por gira aberta manualmente (status='aberta' ou ativo=true)
    final abertas = giras.where((g) => g.isAberta).toList();
    if (abertas.isNotEmpty) return abertas.first;

    // 2. Procurar por gira agendada/ativa para hoje (independente de hora)
    final now = DateTime.now();
    final hoje = giras.where((g) {
      try {
        return g.data.year == now.year &&
               g.data.month == now.month &&
               g.data.day == now.day &&
               g.status != 'encerrada';
      } catch (_) {
        return false;
      }
    }).toList();
    if (hoje.isNotEmpty) return hoje.first;

    // 3. Fallback: qualquer gira não encerrada recente
    final naoEncerradas = giras.where((g) => g.status != 'encerrada').toList();
    if (naoEncerradas.isNotEmpty) return naoEncerradas.first;

    return null;
  });
});


final entityListProvider = StreamProvider.family<List<Entidade>, String>((ref, terreiroId) {
  return ref.watch(adminRepositoryProvider).streamEntities(terreiroId);
});

final mediumListProvider = StreamProvider.family<List<Medium>, String>((ref, terreiroId) {
  return ref.watch(adminRepositoryProvider).streamMediums(terreiroId);
});

final ticketListProvider = StreamProvider.family<List<Ticket>, String>((ref, terreiroId) {
  return ref.watch(adminRepositoryProvider).streamTickets(terreiroId);
});

// Join Medium + Entity to show usable buttons
// Returns list of Mediums that are Active, enriched with their Entity name
final activeMediumsProvider = Provider.family<AsyncValue<List<({Medium medium, Entidade entity})>>, String>((ref, terreiroId) {
  final activeGiraAsync = ref.watch(activeGiraProvider(terreiroId));
  final mediumsAsync = ref.watch(mediumListProvider(terreiroId));
  final entitiesAsync = ref.watch(entityListProvider(terreiroId));

  if (activeGiraAsync.isLoading || mediumsAsync.isLoading || entitiesAsync.isLoading) return const AsyncLoading();
  if (activeGiraAsync.hasError || mediumsAsync.hasError || entitiesAsync.hasError) return const AsyncError("Error loading data", StackTrace.empty);

  final activeGira = activeGiraAsync.value;
  final mediums = mediumsAsync.value ?? [];
  final entities = entitiesAsync.value ?? [];

  // Filtrar médiuns que estão ATIVOS e PRESENTES na gira (se houver uma aberta)
  final visibleMediums = mediums.where((m) {
    if (!m.ativo) return false;
    // Se houver uma gira aberta com presenças configuradas, filtrar os presentes
    if (activeGira != null && activeGira.presencas.isNotEmpty) {
      return activeGira.presencas[m.id] ?? false;
    }
    // Se não há gira ou a gira não tem presenças, mostra todos os ativos
    return true;
  }).toList();
  
  // Grupos de linhagem (centralizado e sincronizado com o Admin)
  final Map<String, List<String>> lineGroups = {
    'BOIADEIRO': ['BOIADEIRO', 'MARINHEIRO', 'MALANDRO', 'VAQUEIRO'],
    'ESQUERDA': ['ESQUERDA', 'EXU', 'POMBA GIRA', 'POMBO GIRO', 'EXU MIRIM'],
    'PRETO VELHO': ['PRETO VELHO', 'PRETA VELHA', 'FEITICEIRO'],
    'CABOCLO': ['CABOCLO', 'CABOCLA'],
    'ERES': ['ERÊ', 'CRIANÇA'],
    'BAIANO': ['BAIANO', 'BAIANA'],
    'CIGANO': ['CIGANO', 'CIGANA'],
  };
  
  // Quando a linha da gira está vazia (ex: fallback), não filtrar por linha
  final allowedLines = (activeGira != null && activeGira.linha.isNotEmpty)
      ? (lineGroups[activeGira.linha.toUpperCase()] ?? [activeGira.linha.toUpperCase()])
      : null; // null = sem filtro de linha

  List<({Medium medium, Entidade entity})> result = [];
  for (var m in visibleMediums) {
    // Para cada entidade ativa do médium
    for (var medEnt in m.entidades) {
      if (medEnt.status == 'ativo') {
        // Se houver uma gira, filtrar apenas entidades da linha permitida
        if (allowedLines != null) {
          final entLinha = medEnt.linha.toUpperCase();
          if (!allowedLines.any((al) => al.toUpperCase() == entLinha)) {
            continue;
          }
        }

        try {
          final ent = entities.firstWhere((e) => e.id == medEnt.entidadeId);
          result.add((medium: m, entity: ent));
        } catch (_) {
          // Entidade não encontrada, fallback para dados denormalizados no Medium
          if (medEnt.entidadeNome.isNotEmpty) {
             result.add((medium: m, entity: Entidade(
               id: medEnt.entidadeId,
               terreiroId: m.terreiroId ?? '',
               nome: medEnt.entidadeNome,
               linha: medEnt.linha,
               tipo: medEnt.tipo,
             )));
          }
        }
      }
    }
  }
  return AsyncData(result);
});

final selectedTerreiroIdProvider = Provider<String?>((ref) {
  return 'demo-terreiro';
});

final currentUserProvider = Provider<Usuario?>((ref) {
  return const Usuario(
    id: 'admin-id',
    terreiroId: 'demo-terreiro',
    nomeCompleto: 'Admin T.U.C.P.B.',
    login: 'admin',
    senha: 'admin',
    perfilAcesso: 'admin',
    ativo: true,
  );
});

// Provider que extrai linhas únicas dos médiuns cadastrados
final linhasFromMediumsProvider = Provider.family<AsyncValue<List<String>>, String>((ref, terreiroId) {
  final mediumsAsync = ref.watch(mediumListProvider(terreiroId));
  return mediumsAsync.whenData((mediums) {
    final linhas = <String>{};
    for (var m in mediums) {
      for (var e in m.entidades) {
        if (e.linha.isNotEmpty) {
          linhas.add(e.linha);
        }
      }
    }
    final sorted = linhas.toList()..sort();
    return sorted;
  });
});

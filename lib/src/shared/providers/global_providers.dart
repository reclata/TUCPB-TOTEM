
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/admin/data/admin_repository.dart';
import 'package:terreiro_queue_system/src/shared/models/models.dart';

// Providers shared across Admin, Kiosk, TV

final giraListProvider = StreamProvider.family<List<Gira>, String>((ref, terreiroId) {
  return ref.watch(adminRepositoryProvider).streamGiras(terreiroId);
});

// Returns the single active Gira or null
final activeGiraProvider = Provider.family<AsyncValue<Gira?>, String>((ref, terreiroId) {
  final girasList = ref.watch(giraListProvider(terreiroId));
  return girasList.whenData((giras) {
    try {
      return giras.firstWhere((g) => g.status == 'aberta');
    } catch (_) {
      return null;
    }
  });
});

final entityListProvider = StreamProvider.family<List<Entidade>, String>((ref, terreiroId) {
  return ref.watch(adminRepositoryProvider).streamEntities(terreiroId);
});

final mediumListProvider = StreamProvider.family<List<Medium>, String>((ref, terreiroId) {
  return ref.watch(adminRepositoryProvider).streamMediums(terreiroId);
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
    // Se houver uma gira aberta, verificar se o médium está na lista de presenças e marcado como true
    if (activeGira != null) {
      return activeGira.presencas[m.id] ?? false;
    }
    return true; // Se não houver gira aberta, mostra os ativos (fallback)
  }).toList();
  
  List<({Medium medium, Entidade entity})> result = [];
  for (var m in visibleMediums) {
    // Para cada entidade ativa do médium
    for (var medEnt in m.entidades) {
      if (medEnt.status == 'ativo') {
        try {
          final ent = entities.firstWhere((e) => e.id == medEnt.entidadeId);
          result.add((medium: m, entity: ent));
        } catch (_) {
          // Entidade não encontrada, ignora
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


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/admin/data/admin_repository.dart';
import '../models/models.dart';

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
  final mediumsAsync = ref.watch(mediumListProvider(terreiroId));
  final entitiesAsync = ref.watch(entityListProvider(terreiroId));

  if (mediumsAsync.isLoading || entitiesAsync.isLoading) return const AsyncLoading();
  if (mediumsAsync.hasError || entitiesAsync.hasError) return const AsyncError("Error loading data", StackTrace.empty);

  final mediums = mediumsAsync.value ?? [];
  final entities = entitiesAsync.value ?? [];

  final activeMediums = mediums.where((m) => m.ativo).toList();
  
  List<({Medium medium, Entidade entity})> result = [];
  for (var m in activeMediums) {
    try {
      final ent = entities.firstWhere((e) => e.id == m.entidadeId);
      result.add((medium: m, entity: ent));
    } catch (_) {
      // Entity not found for this medium, skip
    }
  }
  return AsyncData(result);
});

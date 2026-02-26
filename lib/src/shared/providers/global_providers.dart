import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:terreiro_queue_system/src/features/admin/data/admin_repository.dart';
import 'package:terreiro_queue_system/src/shared/models/models.dart';
import 'package:terreiro_queue_system/src/shared/utils/spiritual_utils.dart';

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
  
  if (activeGiraAsync.hasError) return AsyncError("Erro na Gira: ${activeGiraAsync.error}", activeGiraAsync.stackTrace ?? StackTrace.empty);
  if (mediumsAsync.hasError) return AsyncError("Erro nos Médiuns: ${mediumsAsync.error}", mediumsAsync.stackTrace ?? StackTrace.empty);
  if (entitiesAsync.hasError) return AsyncError("Erro nas Entidades: ${entitiesAsync.error}", entitiesAsync.stackTrace ?? StackTrace.empty);

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
  
// Normalização agora vem de spiritual_utils.dart

  // Quando a linha da gira está vazia (ex: fallback), não filtrar por linha
  final activeGiraLineNorm = activeGira != null && activeGira.linha.isNotEmpty 
      ? normalizeSpiritualLine(activeGira.linha) 
      : null;

  final allowedLines = activeGiraLineNorm != null
      ? (LINE_GROUPS[activeGiraLineNorm] ?? [activeGiraLineNorm])
      : null; // null = sem filtro de linha

  List<({Medium medium, Entidade entity})> result = [];
  for (var m in visibleMediums) {
    // Para cada entidade ativa do médium
    for (var medEnt in m.entidades) {
      if (medEnt.status == 'ativo') {
        // 1. Filtrar por seleção granular da Gira (se houver)
        if (activeGira != null && (activeGira.entidadesParticipantes ?? []).isNotEmpty) {
          if (!activeGira.entidadesParticipantes!.contains(medEnt.entidadeId)) {
            continue;
          }
        }

        // 2. Filtrar apenas entidades da linha permitida (safety check)
        if (allowedLines != null) {
          final entLinha = normalizeSpiritualLine(medEnt.linha);
          final entTipo = normalizeSpiritualLine(medEnt.tipo);
          
          final isCompatible = allowedLines.any((al) {
            final alNorm = normalizeSpiritualLine(al);
            return entLinha == alNorm || entTipo == alNorm;
          });
          
          if (!isCompatible) continue;
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

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = StreamProvider<Usuario?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('usuarios')
      .doc(authUser.uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    
    // Safety mapping (same as repository)
    data['nomeCompleto'] = (data['nomeCompleto'] ?? data['nome'] ?? 'Sem nome').toString();
    data['login'] = (data['login'] ?? data['email'] ?? '').toString();
    data['perfilAcesso'] = (data['perfilAcesso'] ?? data['perfil'] ?? 'medium').toString().toLowerCase();
    data['terreiroId'] = (data['terreiroId'] ?? 'demo-terreiro').toString();
    data['senha'] = (data['senha'] ?? data['senhaInicial'] ?? '').toString();
    data['permissoes'] = List<String>.from(data['permissoes'] ?? []);
    data['ativo'] = data['ativo'] ?? true;

    return Usuario.fromJson(data);
  });
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

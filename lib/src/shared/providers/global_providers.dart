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
  final mediums = mediumsAsync.value ?? <Medium>[];
  final entities = entitiesAsync.value ?? <Entidade>[];

  // Filtrar médiuns que estão ATIVOS e PRESENTES na gira (se houver uma aberta)
  final visibleMediums = mediums.where((m) {
    if (!m.ativo) return false;
    // Se houver uma gira aberta com presenças configuradas, filtrar os presentes
    if (activeGira != null && activeGira.presencas.isNotEmpty) {
      final isPresent = activeGira.presencas[m.id] ?? false;
      return isPresent;
    }
    // Se não há gira ou a gira não tem presenças, mostra todos os ativos
    return true;
  }).toList();
  
  // Determinar as linhas permitidas (flegadas no admin ou sugeridas pelo tema)
  List<String>? allowedLines;
  if (activeGira != null) {
    print('[DEBUG-GIRA] Ativa: ${activeGira.tema}, Linha: ${activeGira.linha}');
    if (activeGira.linhasParticipantes.isNotEmpty) {
      allowedLines = activeGira.linhasParticipantes;
    } else if (activeGira.linha.isNotEmpty) {
      allowedLines = LINE_GROUPS[normalizeSpiritualLine(activeGira.linha)] ?? [activeGira.linha];
    }
    print('[DEBUG-GIRA] AllowedLines: $allowedLines');
  }

  List<({Medium medium, Entidade entity})> result = [];
  final seenKeys = <String>{}; 

  for (var m in visibleMediums) {
    for (var medEnt in m.entidades) {
      if (medEnt.status == 'ativo') {
        bool explicitlySelected = false;
        
        if (activeGira != null && activeGira.entidadesParticipantes.isNotEmpty) {
          final participatingIds = activeGira.entidadesParticipantes;
          if (participatingIds.contains(medEnt.entidadeId)) {
            explicitlySelected = true;
          }
        }

        // 2. Filtrar apenas entidades da linha permitida (safety check)
        if (allowedLines != null && !explicitlySelected) {
          final entLinha = normalizeSpiritualLine(medEnt.linha);
          final entTipo = normalizeSpiritualLine(medEnt.tipo);
          
          final isCompatible = allowedLines.any((al) {
            final alNorm = normalizeSpiritualLine(al);
            return entLinha == alNorm || entTipo == alNorm;
          });
          
          final explicitlySelectedLog = explicitlySelected;
          final participatingIdsLog = activeGira?.entidadesParticipantes ?? [];
          
          if (m.nome.toLowerCase().contains('eduardo') && m.nome.toLowerCase().contains('camargo')) {
            print('[DEBUG-EDUARDO] Entidade: ${medEnt.entidadeNome} (ID: ${medEnt.entidadeId}), Linha: $entLinha, Tipo: $entTipo');
            print('[DEBUG-EDUARDO] Compatible: $isCompatible, ExplicitlySelected: $explicitlySelectedLog');
            print('[DEBUG-EDUARDO] ParticipatingIDs: $participatingIdsLog');
            print('[DEBUG-EDUARDO] Allowed: $allowedLines');
          }

          if (!isCompatible && !explicitlySelected) continue;
        }

        final key = '${m.id}_${medEnt.entidadeId}_${medEnt.entidadeNome}';
        if (seenKeys.contains(key)) continue;
        seenKeys.add(key);

        try {
          final ent = entities.firstWhere((e) => e.id == medEnt.entidadeId);
          result.add((medium: m, entity: ent));
        } catch (_) {
          if (medEnt.entidadeNome.isNotEmpty) {
             final fallbackEnt = Entidade(
               id: medEnt.entidadeId.isEmpty ? 'fallback-${medEnt.entidadeNome}' : medEnt.entidadeId,
               terreiroId: m.terreiroId ?? '',
               nome: medEnt.entidadeNome.isEmpty ? 'Guia' : medEnt.entidadeNome,
               linha: medEnt.linha.isEmpty ? (allowedLines?.first ?? 'CABOCLO') : medEnt.linha,
               tipo: medEnt.tipo.isEmpty ? 'Guia' : medEnt.tipo,
             );
             result.add((medium: m, entity: fallbackEnt));
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
    data['permissoes'] = List<String>.from(data['permissoes'] ?? <String>[]);
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tucpb_adm/src/features/auth/presentation/auth_user_provider.dart';

// Modelos simplificados para leitura
class DashboardStats {
  final int totalTicketsHoje;
  final int ticketsAtendidosHoje;
  final int ticketsFila;
  final int proximasGiras;
  final int atendimentosPessoais;
  final int girasPresentes;
  final int girasAusentes;
  final int totalMediums;
  final int totalItensCompra;

  DashboardStats({
    this.totalTicketsHoje = 0,
    this.ticketsAtendidosHoje = 0,
    this.ticketsFila = 0,
    this.proximasGiras = 0,
    this.atendimentosPessoais = 0,
    this.girasPresentes = 0,
    this.girasAusentes = 0,
    this.totalMediums = 0,
    this.totalItensCompra = 0,
  });
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(FirebaseFirestore.instance);
});

final dashboardStatsProvider = StreamProvider<DashboardStats>((ref) {
  final userData = ref.watch(userDataProvider).asData?.value;
  final userName = userData?['nome'] ?? '';
  return ref.watch(dashboardRepositoryProvider).watchStats(userName: userName);
});

class DashboardRepository {
  final FirebaseFirestore _firestore;

  DashboardRepository(this._firestore);

  Stream<DashboardStats> watchStats({String userName = ''}) {
    final hoje = DateTime.now();
    final inicioDoDia = DateTime(hoje.year, hoje.month, hoje.day);
    
    // 1. Tickets do Dia
    final ticketsStream = _firestore.collectionGroup('tickets')
      .where('dataEmissao', isGreaterThanOrEqualTo: inicioDoDia.toIso8601String())
      .snapshots();

    // 2. Giras
    final girasStream = _firestore.collection('giras').snapshots();

    // 3. Usuários (para contar médiuns)
    final usersStream = _firestore.collection('usuarios').snapshots();

    // 4. Estoque e Checklist (para itens de compra)
    final estoqueStream = _firestore.collection('estoque_itens').snapshots();
    final manualStream = _firestore.collection('estoque_checklist_manual').where('comprado', isEqualTo: false).snapshots();

    return Rx.combineLatest5(
      ticketsStream, 
      girasStream, 
      usersStream,
      estoqueStream,
      manualStream,
      (QuerySnapshot ticketSnap, QuerySnapshot giraSnap, QuerySnapshot userSnap, QuerySnapshot estoqueSnap, QuerySnapshot manualSnap) {
        
      // 1. Tickets do dia
      int totalHoje = ticketSnap.docs.length;
      int atendidosHoje = 0;
      int filaHoje = 0;
      
      for (var doc in ticketSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        if (status == 'atendido') atendidosHoje++;
        if (status == 'aguardando' || status == 'chamado') filaHoje++;
      }

      // 2. Giras
      int proximas = 0;
      int presentes = 0;
      int ausentes = 0;
      int atendPessoais = 0;

      for (var doc in giraSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['data'] as Timestamp?;
        if (timestamp == null) continue;
        
        final giraData = timestamp.toDate();
        final isFutura = giraData.isAfter(hoje);
        
        if (isFutura) {
          proximas++;
        } else {
          final historico = data['historico'] as Map<String, dynamic>?;
          if (historico != null) {
            final atendimentosPorMedium = historico['atendimentosPorMedium'] as Map<String, dynamic>?;
            if (atendimentosPorMedium != null) {
              if (atendimentosPorMedium.containsKey(userName)) {
                presentes++;
                atendPessoais += (atendimentosPorMedium[userName] as num).toInt();
              } else {
                ausentes++;
              }
            }
          }
        }
      }

      // 3. Médiuns
      int totalMediums = userSnap.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final perfil = (data['perfil'] ?? '').toString().toLowerCase();
        final ativo = data['ativo'] == true;
        return ativo && (perfil.contains('medium') || perfil.contains('médium'));
      }).length;

      // 4. Itens de Compra
      int itensEstoque = estoqueSnap.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final qAtual = (data['quantidadeAtual'] as num? ?? 0).toDouble();
        final qMin = (data['quantidadeMinima'] as num? ?? 0).toDouble();
        return qAtual <= qMin;
      }).length;

      int totalItensCompra = itensEstoque + manualSnap.docs.length;

      return DashboardStats(
        totalTicketsHoje: totalHoje,
        ticketsAtendidosHoje: atendidosHoje,
        ticketsFila: filaHoje,
        proximasGiras: proximas,
        atendimentosPessoais: atendPessoais,
        girasPresentes: presentes,
        girasAusentes: ausentes,
        totalMediums: totalMediums,
        totalItensCompra: totalItensCompra,
      );
    });
  }
}

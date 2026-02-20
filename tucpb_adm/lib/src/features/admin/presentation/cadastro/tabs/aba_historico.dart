import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tucpb_adm/src/features/admin/data/cobranca_model.dart';
import 'package:tucpb_adm/src/features/admin/data/financeiro_repository.dart';

class AbaHistorico extends ConsumerWidget {
  final String? userId; // nulo se for novo cadastro
  const AbaHistorico({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) {
      return const Center(child: Text("O histórico estará disponível após o salvamento do cadastro."));
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Giras & Atendimentos"),
              Tab(text: "Financeiro"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildGirasHistory(),
                _buildFinanceHistory(ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGirasHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('giras').orderBy('data', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final giras = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final hist = data['historico'] as Map<String, dynamic>?;
          if (hist == null) return false;
          final atendimentos = hist['atendimentosPorMedium'] as Map<String, dynamic>?;
          return atendimentos?.containsKey(userId) ?? false;
        }).toList();

        if (giras.isEmpty) {
          return const Center(child: Text("Nenhuma participação em giras registrada."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: giras.length,
          itemBuilder: (context, index) {
            final doc = giras[index];
            final data = doc.data() as Map<String, dynamic>;
            final hist = data['historico'] as Map<String, dynamic>;
            final atendimentos = (hist['atendimentosPorMedium'] as Map<String, dynamic>)[userId];
            final date = (data['data'] as Timestamp).toDate();

            return Card(
              child: ListTile(
                title: Text(data['nome'] ?? 'Gira'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
                trailing: Chip(
                  label: Text("$atendimentos Atendimentos"),
                  backgroundColor: Colors.blue[50],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFinanceHistory(WidgetRef ref) {
    return StreamBuilder<List<CobrancaModel>>(
      stream: ref.watch(financeiroRepositoryProvider).streamCobrancasUsuario(userId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final cobrancas = snapshot.data!;
        
        if (cobrancas.isEmpty) {
          return const Center(child: Text("Nenhum histórico financeiro encontrado."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cobrancas.length,
          itemBuilder: (context, index) {
            final c = cobrancas[index];
            return Card(
              child: ListTile(
                title: Text(c.tipo),
                subtitle: Text("Vencimento: ${c.dataVencimento != null ? DateFormat('dd/MM/yyyy').format(c.dataVencimento!) : '--'}"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(NumberFormat.simpleCurrency(locale: 'pt_BR').format(c.valor), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(c.status.label, style: TextStyle(color: c.status == StatusCobranca.pago ? Colors.green : Colors.red, fontSize: 10)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

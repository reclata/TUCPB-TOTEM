import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tucpb_adm/src/features/admin/data/cobranca_model.dart';
import 'package:tucpb_adm/src/features/admin/data/financeiro_repository.dart';
import 'package:tucpb_adm/src/features/admin/data/log_repository.dart';
import 'package:tucpb_adm/src/features/admin/data/activity_log_model.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';
import 'package:tucpb_adm/src/features/auth/presentation/auth_user_provider.dart';

final _totaisProvider = StreamProvider<Map<String, double>>((ref) {
  return ref.watch(cobrancasStreamProvider).map((lista) {
    double totalPago = 0;
    double totalAvulso = 0;
    double totalAsaas = 0;
    double totalPendente = 0;
    double totalAtrasado = 0;

    for (final c in lista) {
      if (c.status == StatusCobranca.pago) {
        totalPago += c.valor;
        if (c.origem == OrigemCobranca.avulso) totalAvulso += c.valor;
        if (c.origem == OrigemCobranca.asaas) totalAsaas += c.valor;
      } else if (c.status == StatusCobranca.atrasado) {
        totalAtrasado += c.valor;
      } else {
        totalPendente += c.valor;
      }
    }

    return {
      'totalPago': totalPago,
      'totalAvulso': totalAvulso,
      'totalAsaas': totalAsaas,
      'totalPendente': totalPendente,
      'totalAtrasado': totalAtrasado,
    };
  });
});

class AbaGeral extends ConsumerStatefulWidget {
  const AbaGeral({super.key});
  @override
  ConsumerState<AbaGeral> createState() => _AbaGeralState();
}

class _AbaGeralState extends ConsumerState<AbaGeral> {
  final _buscaController = TextEditingController();
  String _filtroBusca = '';
  String? _filtroStatus;

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cobrancasAsync = ref.watch(cobrancasFiltradasProvider);
    final totaisAsync = ref.watch(_totaisProvider);
    final userData = ref.watch(userDataProvider).asData?.value;
    final perfil = (userData?['perfil'] ?? '').toString().toLowerCase();
    final isAdmin = ['admin', 'suporte', 'administrador', 'dirigente'].contains(perfil);
    final fmt = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Column(
      children: [
        // ═══ BigNumbers (Somente Admin) ═══
        if (isAdmin)
          totaisAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => const SizedBox.shrink(),
            data: (totais) => _BigNumbersRow(totais: totais, fmt: fmt),
          ),

        // ═══ Filtros ═══
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _buscaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou email...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _filtroBusca = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String?>(
                  value: _filtroStatus,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                    hintText: 'Todos os status',
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...StatusCobranca.values.map((s) => DropdownMenuItem(value: s.key, child: Text(s.label))),
                  ],
                  onChanged: (v) => setState(() => _filtroStatus = v),
                ),
              ),
            ],
          ),
        ),

        // ═══ Tabela ═══
        Expanded(
          child: cobrancasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (lista) {
              final filtrada = lista.where((c) {
                final buscaOk = _filtroBusca.isEmpty ||
                    c.usuarioNome.toLowerCase().contains(_filtroBusca) ||
                    c.usuarioEmail.toLowerCase().contains(_filtroBusca);
                final statusOk = _filtroStatus == null || c.status.key == _filtroStatus;
                return buscaOk && statusOk;
              }).toList();

              if (filtrada.isEmpty) {
                return const Center(child: Text('Nenhum resultado encontrado.', style: TextStyle(color: Colors.grey)));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                  ),
                  child: Column(
                    children: [
                      // Header da tabela
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AdminTheme.background,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Row(
                          children: [
                            _thCell('Membro', flex: 3),
                            _thCell('Tipo', flex: 2),
                            _thCell('Origem', flex: 1),
                            _thCell('Valor', flex: 1),
                            _thCell('Vencimento', flex: 2),
                            _thCell('Status', flex: 2),
                            _thCell('Ações', flex: 2, center: true),
                          ],
                        ),
                      ),
                      // Linhas
                      ...filtrada.map((c) => _TabelaLinha(cobranca: c, fmt: fmt, ref: ref)).toList(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _thCell(String text, {int flex = 1, bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// BigNumbers
// ═══════════════════════════════════════════
class _BigNumbersRow extends StatelessWidget {
  final Map<String, double> totais;
  final NumberFormat fmt;
  const _BigNumbersRow({required this.totais, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _BigCard(
              label: 'Total Arrecadado',
              value: fmt.format((totais['totalPago'] ?? 0)),
              color: const Color(0xFF2E7D32),
              icon: Icons.account_balance_wallet,
              sub: 'ASAAS + Avulso',
            ),
            _BigCard(
              label: 'Via ASAAS',
              value: fmt.format(totais['totalAsaas'] ?? 0),
              color: const Color(0xFF1565C0),
              icon: Icons.credit_card,
            ),
            _BigCard(
              label: 'Avulso (pago)',
              value: fmt.format(totais['totalAvulso'] ?? 0),
              color: const Color(0xFF6A1B9A),
              icon: Icons.receipt_long,
            ),
            _BigCard(
              label: 'Pendentes',
              value: fmt.format(totais['totalPendente'] ?? 0),
              color: const Color(0xFFE65100),
              icon: Icons.hourglass_bottom,
            ),
            _BigCard(
              label: 'Em Atraso',
              value: fmt.format(totais['totalAtrasado'] ?? 0),
              color: const Color(0xFFC62828),
              icon: Icons.warning_amber_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final String? sub;
  const _BigCard({required this.label, required this.value, required this.color, required this.icon, this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          if (sub != null) Text(sub!, style: TextStyle(color: color.withOpacity(0.6), fontSize: 10)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Linha da tabela
// ═══════════════════════════════════════════
class _TabelaLinha extends ConsumerWidget {
  final CobrancaModel cobranca;
  final NumberFormat fmt;
  final WidgetRef ref;
  const _TabelaLinha({required this.cobranca, required this.fmt, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef refW) {
    final c = cobranca;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // Membro
          Expanded(flex: 3, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.usuarioNome, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              Text(c.usuarioEmail, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          )),
          // Tipo
          Expanded(flex: 2, child: Text(c.tipo, style: const TextStyle(fontSize: 13))),
          // Origem
          Expanded(flex: 1, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: c.origem == OrigemCobranca.asaas ? Colors.blue[50] : Colors.purple[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              c.origem == OrigemCobranca.asaas ? 'ASAAS' : 'Avulso',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                color: c.origem == OrigemCobranca.asaas ? Colors.blue : Colors.purple),
            ),
          )),
          // Valor
          Expanded(flex: 1, child: Text(fmt.format(c.valor), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          // Vencimento
          Expanded(flex: 2, child: Text(
            c.dataVencimento != null ? DateFormat('dd/MM/yyyy').format(c.dataVencimento!) : '--',
            style: TextStyle(fontSize: 12, color: _vencidoColor(c)),
          )),
          // Status
          Expanded(flex: 2, child: _StatusBadge(status: c.status)),
          // Ações
          Expanded(flex: 2, child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Histórico
              IconButton(
                tooltip: 'Ver histórico',
                icon: const Icon(Icons.visibility, size: 18, color: Colors.blueGrey),
                onPressed: () => _mostrarHistorico(context, c),
              ),
              // Download relatório
              IconButton(
                tooltip: 'Baixar relatório',
                icon: const Icon(Icons.description, size: 18, color: Colors.blueGrey),
                onPressed: () => _baixarRelatorio(context, c),
              ),
              // Registrar pagamento
              if (c.status != StatusCobranca.pago)
                IconButton(
                  tooltip: 'Registrar pagamento',
                  icon: const Icon(Icons.attach_money, size: 18, color: Colors.green),
                  onPressed: () => _registrarPagamento(context, c, refW),
                ),
            ],
          )),
        ],
      ),
    );
  }

  Color _vencidoColor(CobrancaModel c) {
    if (c.status == StatusCobranca.pago) return Colors.green;
    if (c.dataVencimento != null && c.dataVencimento!.isBefore(DateTime.now())) return Colors.red;
    return Colors.black54;
  }

  void _mostrarHistorico(BuildContext context, CobrancaModel c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Histórico — ${c.usuarioNome}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Tipo', c.tipo),
              _infoRow('Valor', NumberFormat.simpleCurrency(locale: 'pt_BR').format(c.valor)),
              _infoRow('Status', c.status.label),
              _infoRow('Origem', c.origem == OrigemCobranca.asaas ? 'ASAAS' : 'Avulso'),
              _infoRow('Criado em', DateFormat('dd/MM/yyyy HH:mm').format(c.dataCriacao)),
              if (c.dataVencimento != null)
                _infoRow('Vencimento', DateFormat('dd/MM/yyyy').format(c.dataVencimento!)),
              if (c.dataPagamento != null)
                _infoRow('Pago em', DateFormat('dd/MM/yyyy HH:mm').format(c.dataPagamento!)),
              if (c.descricao != null && c.descricao!.isNotEmpty)
                _infoRow('Descrição', c.descricao!),
              if (c.asaasId != null)
                _infoRow('ID ASAAS', c.asaasId!),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _baixarRelatorio(BuildContext context, CobrancaModel c) {
    // Em web, uso Clipboard como fallback — implementação real usaria dart:html
    final relatorio =
        'RELATÓRIO DE COBRANÇA\n'
        '====================\n'
        'Membro:      ${c.usuarioNome}\n'
        'Email:       ${c.usuarioEmail}\n'
        'Tipo:        ${c.tipo}\n'
        'Valor:       R\$ ${c.valor.toStringAsFixed(2)}\n'
        'Status:      ${c.status.label}\n'
        'Criado em:   ${DateFormat('dd/MM/yyyy').format(c.dataCriacao)}\n'
        'Vencimento:  ${c.dataVencimento != null ? DateFormat('dd/MM/yyyy').format(c.dataVencimento!) : "--"}\n'
        'Pago em:     ${c.dataPagamento != null ? DateFormat('dd/MM/yyyy').format(c.dataPagamento!) : "--"}\n';
    Clipboard.setData(ClipboardData(text: relatorio));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Relatório copiado para a área de transferência!'), backgroundColor: Colors.green),
    );
  }

  Future<void> _registrarPagamento(BuildContext context, CobrancaModel c, WidgetRef refW) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registrar Pagamento'),
        content: Text('Confirmar pagamento de ${NumberFormat.simpleCurrency(locale: "pt_BR").format(c.valor)} de ${c.usuarioNome}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await refW.read(financeiroRepositoryProvider).atualizarStatus(
        c.id, StatusCobranca.pago, dataPagamento: DateTime.now(),
      );

      // Log
      final currentUser = refW.read(userDataProvider).asData?.value;
      await refW.read(logRepositoryProvider).logAction(
        userId: currentUser?['uid'] ?? '',
        userName: currentUser?['nome'] ?? 'Portal Admin',
        module: 'Financeiro',
        action: LogActionType.update,
        description: 'Registrou pagamento de ${fmt.format(c.valor)} para ${c.usuarioNome}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pagamento registrado com sucesso!'), backgroundColor: Colors.green),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final StatusCobranca status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      StatusCobranca.pago => (const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
      StatusCobranca.emAndamento => (const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
      StatusCobranca.naoIniciado => (Colors.grey, const Color(0xFFF5F5F5)),
      StatusCobranca.atrasado => (const Color(0xFFC62828), const Color(0xFFFFEBEE)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(status.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

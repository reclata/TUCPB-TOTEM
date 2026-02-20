import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tucpb_adm/src/features/admin/data/cobranca_model.dart';
import 'package:tucpb_adm/src/features/admin/data/financeiro_repository.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';
import 'package:tucpb_adm/src/features/auth/presentation/auth_user_provider.dart';

class AbaAvulsos extends ConsumerStatefulWidget {
  const AbaAvulsos({super.key});

  @override
  ConsumerState<AbaAvulsos> createState() => _AbaAvulsosState();
}

class _AbaAvulsosState extends ConsumerState<AbaAvulsos> {
  void _abrirNovaCobranca() {
    showDialog(
      context: context,
      builder: (_) => _NovaCobrancaAvulsaModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cobrancasAsync = ref.watch(cobrancasAvulsasFiltradasProvider);
    final fmt = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Column(
      children: [
        // Header da aba
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: AdminTheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cobranças Avulsas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _abrirNovaCobranca,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nova Cobrança'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),

        // Lista / Relatório
        Expanded(
          child: cobrancasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (lista) {
              if (lista.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, color: Colors.grey[300], size: 64),
                      const SizedBox(height: 16),
                      const Text('Nenhuma cobrança avulsa cadastrada.', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _abrirNovaCobranca,
                        icon: const Icon(Icons.add),
                        label: const Text('Criar primeira cobrança'),
                        style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                );
              }

              // Agrupar por status para fácil visualização
              final naoPagantes = lista.where((c) => c.status != StatusCobranca.pago).toList();
              final pagos = lista.where((c) => c.status == StatusCobranca.pago).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (naoPagantes.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Pendentes / Em atraso',
                        count: naoPagantes.length,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      ...naoPagantes.map((c) => _AvulsoCard(cobranca: c, fmt: fmt, ref: ref)),
                      const SizedBox(height: 24),
                    ],
                    if (pagos.isNotEmpty) ...[
                      _SectionHeader(title: 'Pagos', count: pagos.length, color: Colors.green),
                      const SizedBox(height: 8),
                      ...pagos.map((c) => _AvulsoCard(cobranca: c, fmt: fmt, ref: ref)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _SectionHeader({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text('$count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
        ),
      ],
    );
  }
}

class _AvulsoCard extends ConsumerWidget {
  final CobrancaModel cobranca;
  final NumberFormat fmt;
  final WidgetRef ref;
  const _AvulsoCard({required this.cobranca, required this.fmt, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef refW) {
    final c = cobranca;
    final isAtrasado = c.status == StatusCobranca.atrasado ||
        (c.dataVencimento != null && c.dataVencimento!.isBefore(DateTime.now()) && c.status != StatusCobranca.pago);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Ícone por tipo
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AdminTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_iconeTipo(c.tipo), color: AdminTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),

            // Info principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(c.usuarioNome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    _TipoBadge(tipo: c.tipo),
                  ]),
                  const SizedBox(height: 2),
                  if (c.descricao != null && c.descricao!.isNotEmpty)
                    Text(c.descricao!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),

            // Valor
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fmt.format(c.valor), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (c.dataVencimento != null)
                  Text(
                    'Venc: ${DateFormat("dd/MM/yy").format(c.dataVencimento!)}',
                    style: TextStyle(fontSize: 11, color: isAtrasado ? Colors.red : Colors.grey),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Status
            Column(
              children: [
                _StatusDropdown(cobranca: c, ref: refW),
              ],
            ),

            // Ações
            PopupMenuButton<String>(
              tooltip: 'Opções',
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (val) async {
                if (val == 'pago') {
                  await refW.read(financeiroRepositoryProvider)
                      .atualizarStatus(c.id, StatusCobranca.pago, dataPagamento: DateTime.now());
                } else if (val == 'deletar') {
                  await refW.read(financeiroRepositoryProvider).deletarCobranca(c.id);
                }
              },
              itemBuilder: (_) => [
                if (c.status != StatusCobranca.pago)
                  const PopupMenuItem(value: 'pago', child: ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Marcar como Pago'))),
                const PopupMenuItem(value: 'deletar', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Deletar'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconeTipo(String tipo) {
    switch (tipo) {
      case 'Festa': return Icons.celebration;
      case 'Ervas': return Icons.spa;
      case 'Contribuição': return Icons.volunteer_activism;
      case 'Obrigação': return Icons.star;
      default: return Icons.receipt;
    }
  }
}

class _TipoBadge extends StatelessWidget {
  final String tipo;
  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(4)),
      child: Text(tipo, style: const TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
    );
  }
}

class _StatusDropdown extends ConsumerWidget {
  final CobrancaModel cobranca;
  final WidgetRef ref;
  const _StatusDropdown({required this.cobranca, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef refW) {
    return DropdownButton<StatusCobranca>(
      value: cobranca.status,
      isDense: true,
      underline: const SizedBox.shrink(),
      items: StatusCobranca.values.map((s) => DropdownMenuItem(
        value: s,
        child: _StatusPill(status: s),
      )).toList(),
      onChanged: (v) async {
        if (v != null) {
          await refW.read(financeiroRepositoryProvider).atualizarStatus(
            cobranca.id, v,
            dataPagamento: v == StatusCobranca.pago ? DateTime.now() : null,
          );
        }
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final StatusCobranca status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = {
      StatusCobranca.pago: (const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
      StatusCobranca.emAndamento: (const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
      StatusCobranca.naoIniciado: (Colors.grey, const Color(0xFFF5F5F5)),
      StatusCobranca.atrasado: (const Color(0xFFC62828), const Color(0xFFFFEBEE)),
    };
    final (fg, bg) = colors[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(status.label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// ═══════════════════════════════════════════
// Modal Nova Cobrança Avulsa
// ═══════════════════════════════════════════
class _NovaCobrancaAvulsaModal extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NovaCobrancaAvulsaModal> createState() => __NovaCobrancaAvulsaModalState();
}

class __NovaCobrancaAvulsaModalState extends ConsumerState<_NovaCobrancaAvulsaModal> {
  late TextEditingController _nomeController;
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();
  String _tipo = kTiposAvulso.first;
  StatusCobranca _status = StatusCobranca.naoIniciado;
  DateTime? _dataVencimento;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final userData = ref.read(userDataProvider).asData?.value;
    final nome = userData?['nome'] ?? '';
    _nomeController = TextEditingController(text: nome);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nomeController.text.trim().isEmpty || _valorController.text.isEmpty) return;
    setState(() => _salvando = true);
    try {
      final userData = ref.read(userDataProvider).asData?.value;
      final userId = userData?['docId'] ?? userData?['uid'] ?? '';
      final email = userData?['email'] ?? '';

      final c = CobrancaModel(
        id: '',
        tipo: _tipo,
        valor: double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0.0,
        status: _status,
        usuarioId: userId,
        usuarioNome: _nomeController.text.trim(),
        usuarioEmail: email,
        origem: OrigemCobranca.avulso,
        dataCriacao: DateTime.now(),
        dataVencimento: _dataVencimento,
        descricao: _descricaoController.text.trim(),
        dataPagamento: _status == StatusCobranca.pago ? DateTime.now() : null,
      );
      await ref.read(financeiroRepositoryProvider).criarCobranca(c);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cobrança cadastrada!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _selecionarData() async {
    final d = await showDatePicker(
      context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030),
    );
    if (d != null) setState(() => _dataVencimento = d);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Nova Cobrança Avulsa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
              const Divider(),
              const SizedBox(height: 8),

              // Tipo
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo de Cobrança', border: OutlineInputBorder()),
                items: kTiposAvulso.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _tipo = v!),
              ),
              const SizedBox(height: 12),

              // Nome (Somente Admin edita)
              if (['admin', 'suporte', 'administrador', 'dirigente'].contains((ref.read(userDataProvider).asData?.value?['perfil'] ?? '').toString().toLowerCase()))
                TextFormField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome do Membro *', border: OutlineInputBorder())),
              
              if (!['admin', 'suporte', 'administrador', 'dirigente'].contains((ref.read(userDataProvider).asData?.value?['perfil'] ?? '').toString().toLowerCase()))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Contribuinte: ${_nomeController.text}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 12),

              // Valor + Status
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _valorController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Valor (R\$) *', border: OutlineInputBorder(), prefixText: 'R\$ '),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<StatusCobranca>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    items: StatusCobranca.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Vencimento + Descrição
              InkWell(
                onTap: _selecionarData,
                child: IgnorePointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Data de Vencimento',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today, size: 16),
                      hintText: _dataVencimento != null ? DateFormat('dd/MM/yyyy').format(_dataVencimento!) : 'Opcional',
                    ),
                    controller: TextEditingController(
                      text: _dataVencimento != null ? DateFormat('dd/MM/yyyy').format(_dataVencimento!) : '',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricaoController, maxLines: 2,
                decoration: const InputDecoration(labelText: 'Observações', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _salvando ? null : _salvar,
                  icon: _salvando ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, size: 16),
                  label: const Text('Salvar Cobrança'),
                  style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

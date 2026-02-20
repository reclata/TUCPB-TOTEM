import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

enum TipoRelatorio {
  cadastros,
  financeiro,
  estoqueGeral,
  ultimasCompras,
  ultimosChecklist,
  baixasEstoque,
  contagemEstoque,
  senhasGeradas,
}

extension TipoRelatorioExt on TipoRelatorio {
  String get label {
    switch (this) {
      case TipoRelatorio.cadastros: return 'Cadastros';
      case TipoRelatorio.financeiro: return 'Financeiro';
      case TipoRelatorio.estoqueGeral: return 'Estoque Geral';
      case TipoRelatorio.ultimasCompras: return 'Últimas Compras';
      case TipoRelatorio.ultimosChecklist: return 'Últimos Checklists';
      case TipoRelatorio.baixasEstoque: return 'Baixas de Estoque';
      case TipoRelatorio.contagemEstoque: return 'Contagem de Estoque';
      case TipoRelatorio.senhasGeradas: return 'Total de Senhas';
    }
  }

  IconData get icon {
    switch (this) {
      case TipoRelatorio.cadastros: return FontAwesomeIcons.users;
      case TipoRelatorio.financeiro: return FontAwesomeIcons.fileInvoiceDollar;
      case TipoRelatorio.estoqueGeral: return FontAwesomeIcons.boxesStacked;
      case TipoRelatorio.ultimasCompras: return FontAwesomeIcons.cartPlus;
      case TipoRelatorio.ultimosChecklist: return FontAwesomeIcons.listCheck;
      case TipoRelatorio.baixasEstoque: return FontAwesomeIcons.boxOpen;
      case TipoRelatorio.contagemEstoque: return FontAwesomeIcons.calculator;
      case TipoRelatorio.senhasGeradas: return FontAwesomeIcons.ticket;
    }
  }

  String get descricao {
    switch (this) {
      case TipoRelatorio.cadastros: return 'Lista completa de médiuns, assistência e colaboradores cadastrados.';
      case TipoRelatorio.financeiro: return 'Resumo de entradas, saídas e balanço do período selecionado.';
      case TipoRelatorio.estoqueGeral: return 'Situação atual de todos os itens em todos os depósitos.';
      case TipoRelatorio.ultimasCompras: return 'Histórico de entradas de novos itens no estoque.';
      case TipoRelatorio.ultimosChecklist: return 'Itens que foram marcados para reposição recentemente.';
      case TipoRelatorio.baixasEstoque: return 'Relatório de consumo e saídas de materiais.';
      case TipoRelatorio.contagemEstoque: return 'Diferenças encontradas entre o sistema e o físico.';
      case TipoRelatorio.senhasGeradas: return 'Análise de atendimento por período e por gira.';
    }
  }
}

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  TipoRelatorio? _relatorioSelecionado;
  DateTimeRange? _periodo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: AdminTheme.surface,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CENTRAL DE RELATÓRIOS', 
                        style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AdminTheme.primary)),
                    Text('Gere documentos e analise dados do sistema', 
                        style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                if (_relatorioSelecionado != null)
                  TextButton.icon(
                    onPressed: () => setState(() => _relatorioSelecionado = null),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar à seleção'),
                  ),
              ],
            ),
          ),

          Expanded(
            child: _relatorioSelecionado == null 
                ? _buildGridSelecao() 
                : _buildConfiguracaoRelatorio(_relatorioSelecionado!),
          ),
        ],
      ),
    );
  }

  Widget _buildGridSelecao() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selecione o tipo de relatório:', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.85,
                ),
                itemCount: TipoRelatorio.values.length,
                itemBuilder: (context, index) {
                  final tipo = TipoRelatorio.values[index];
                  return _RelatorioCard(
                    tipo: tipo,
                    onTap: () => setState(() => _relatorioSelecionado = tipo),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfiguracaoRelatorio(TipoRelatorio tipo) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          margin: const EdgeInsets.all(32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AdminTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(tipo.icon, color: AdminTheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tipo.label, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Configurações de Extração', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('PERÍODO DO RELATÓRIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: _periodo,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _periodo = picked);
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_periodo == null 
                    ? 'Selecionar período...' 
                    : '${DateFormat('dd/MM/yy').format(_periodo!.start)} - ${DateFormat('dd/MM/yy').format(_periodo!.end)}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                const SizedBox(height: 24),
                if (tipo == TipoRelatorio.senhasGeradas) ...[
                  const Text('FILTRAR POR GIRA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                    hint: const Text('Todas as Giras'),
                    items: const [
                      DropdownMenuItem(value: 'esquerda', child: Text('Gira de Esquerda')),
                      DropdownMenuItem(value: 'direita', child: Text('Gira de Direita')),
                    ],
                    onChanged: (v) {},
                  ),
                  const SizedBox(height: 24),
                ],
                const Text('FORMATO DE SAÍDA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _FormatOption(label: 'Excel (.xlsx)', icon: FontAwesomeIcons.fileExcel, color: Colors.green, isSelected: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _FormatOption(label: 'PDF Document', icon: FontAwesomeIcons.filePdf, color: Colors.red, isSelected: false)),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Relatório sendo processado... O download iniciará em breve.'), backgroundColor: Colors.green),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('GERAR RELATÓRIO AGORA', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RelatorioCard extends StatelessWidget {
  final TipoRelatorio tipo;
  final VoidCallback onTap;

  const _RelatorioCard({required this.tipo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminTheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(tipo.icon, color: AdminTheme.primary, size: 28),
            ),
            const SizedBox(height: 20),
            Text(tipo.label, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              tipo.descricao,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;

  const _FormatOption({required this.label, required this.icon, required this.color, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.05) : Colors.transparent,
        border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

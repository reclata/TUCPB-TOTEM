import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tucpb_adm/src/features/admin/data/cobranca_model.dart';
import 'package:tucpb_adm/src/features/admin/data/financeiro_repository.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class AbaPagamentos extends ConsumerStatefulWidget {
  const AbaPagamentos({super.key});
  @override
  ConsumerState<AbaPagamentos> createState() => _AbaPagamentosState();
}

class _AbaPagamentosState extends ConsumerState<AbaPagamentos> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _valorController = TextEditingController();
  final _descController = TextEditingController();
  String _metodoPagamento = 'pix';
  String? _pixGerado;
  String? _linkCartao;
  bool _gerando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _valorController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _gerarCobranca() async {
    if (_nomeController.text.isEmpty || _valorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome e valor.'), backgroundColor: Colors.red),
      );
      return;
    }
    final apiKey = await FinanceiroRepository.getAsaasKey();
    if (apiKey == null || apiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configure a API Key do ASAAS primeiro na aba ASAAS.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    setState(() { _gerando = true; _pixGerado = null; _linkCartao = null; });

    // Simular chamada ASAAS (substituir por HTTP real em produção)
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Integração real com ASAAS:
    // final response = await http.post(
    //   Uri.parse('https://api.asaas.com/v3/payments'),
    //   headers: {'access_token': apiKey, 'Content-Type': 'application/json'},
    //   body: json.encode({
    //     'customer': customerId,
    //     'billingType': _metodoPagamento.toUpperCase(),
    //     'value': double.parse(_valorController.text),
    //     'dueDate': '2025-12-31',
    //     'description': _descController.text,
    //   }),
    // );

    // Resultado simulado
    if (_metodoPagamento == 'pix') {
      setState(() => _pixGerado = '00020126360014br.gov.bcb.pix0114+5511999999999520400005303986540510.005802BR5913TUCPB SISTEMA6009SAO PAULO62070503***63044A6D');
    } else {
      setState(() => _linkCartao = 'https://pay.asaas.com/i/${DateTime.now().millisecondsSinceEpoch}');
    }

    // Registrar a cobrança no Firestore
    final c = CobrancaModel(
      id: '', tipo: 'Pagamento ${_metodoPagamento == "pix" ? "PIX" : "Cartão"}',
      valor: double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0,
      status: StatusCobranca.emAndamento,
      usuarioId: '', usuarioNome: _nomeController.text.trim(),
      usuarioEmail: _emailController.text.trim(),
      origem: OrigemCobranca.asaas,
      dataCriacao: DateTime.now(),
      dataVencimento: DateTime.now().add(const Duration(days: 3)),
      descricao: _descController.text.trim(),
      pixCopiaECola: _pixGerado,
      linkPagamento: _linkCartao,
    );
    await ref.read(financeiroRepositoryProvider).criarCobranca(c);
    setState(() => _gerando = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formulário
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gerar Cobrança', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Integrado com ASAAS e PagSeguro', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 20),

                TextFormField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome do Membro *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline, size: 18))),
                const SizedBox(height: 12),
                TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined, size: 18))),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valorController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Valor (R\$) *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money, size: 18), prefixText: 'R\$ '),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _descController, maxLines: 2, decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder())),
                const SizedBox(height: 20),

                // Método de pagamento
                const Text('Forma de Pagamento', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 10),
                Row(children: [
                  _MetodoCard(metodo: 'pix', icon: Icons.pix, label: 'PIX', selecionado: _metodoPagamento == 'pix', cor: Colors.teal, onTap: () => setState(() => _metodoPagamento = 'pix')),
                  const SizedBox(width: 10),
                  _MetodoCard(metodo: 'cartao', icon: Icons.credit_card, label: 'Cartão', selecionado: _metodoPagamento == 'cartao', cor: Colors.blue, onTap: () => setState(() => _metodoPagamento = 'cartao')),
                  const SizedBox(width: 10),
                  _MetodoCard(metodo: 'pagseguro', icon: Icons.payment, label: 'PagSeguro', selecionado: _metodoPagamento == 'pagseguro', cor: Colors.orange, onTap: () => setState(() => _metodoPagamento = 'pagseguro')),
                ]),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _gerando ? null : _gerarCobranca,
                    icon: _gerando
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send, size: 18),
                    label: Text(_gerando ? 'Gerando...' : 'Gerar Cobrança'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Resultado
          Expanded(
            flex: 2,
            child: Column(
              children: [
                if (_pixGerado != null) _ResultadoPix(pix: _pixGerado!),
                if (_linkCartao != null) _ResultadoLink(link: _linkCartao!),
                if (_pixGerado == null && _linkCartao == null)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(children: [
                      Icon(Icons.qr_code_2, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('O resultado do pagamento\naparecerá aqui.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetodoCard extends StatelessWidget {
  final String metodo, label;
  final IconData icon;
  final Color cor;
  final bool selecionado;
  final VoidCallback onTap;
  const _MetodoCard({required this.metodo, required this.icon, required this.label, required this.cor, required this.selecionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selecionado ? cor.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selecionado ? cor : Colors.grey.shade300, width: selecionado ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: selecionado ? cor : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selecionado ? cor : Colors.grey)),
        ]),
      ),
    );
  }
}

class _ResultadoPix extends StatelessWidget {
  final String pix;
  const _ResultadoPix({required this.pix});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(children: [
        const Icon(Icons.pix, size: 48, color: Colors.teal),
        const SizedBox(height: 8),
        const Text('PIX Gerado!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Text(pix, style: const TextStyle(fontSize: 10, fontFamily: 'monospace'), textAlign: TextAlign.center, maxLines: 5, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: pix));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIX copiado!')));
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar Copia e Cola'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
          ),
        ),
      ]),
    );
  }
}

class _ResultadoLink extends StatelessWidget {
  final String link;
  const _ResultadoLink({required this.link});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(children: [
        const Icon(Icons.credit_card, size: 48, color: Colors.blue),
        const SizedBox(height: 8),
        const Text('Link de Pagamento Gerado!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Text(link, style: const TextStyle(fontSize: 12, color: Colors.blue), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copiado!')));
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar Link'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
        ),
      ]),
    );
  }
}

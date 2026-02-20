import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tucpb_adm/src/features/admin/data/financeiro_repository.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class AbaAsaas extends ConsumerStatefulWidget {
  const AbaAsaas({super.key});
  @override
  ConsumerState<AbaAsaas> createState() => _AbaAsaasState();
}

class _AbaAsaasState extends ConsumerState<AbaAsaas> {
  final _keyController = TextEditingController();
  bool _keyVisivel = false;
  bool _salvando = false;
  String? _apiKeyAtual;

  @override
  void initState() {
    super.initState();
    _carregarKey();
  }

  Future<void> _carregarKey() async {
    final k = await FinanceiroRepository.getAsaasKey();
    setState(() {
      _apiKeyAtual = k;
      if (k != null) _keyController.text = k;
    });
  }

  Future<void> _salvarKey() async {
    setState(() => _salvando = true);
    await FinanceiroRepository.salvarAsaasKey(_keyController.text.trim());
    setState(() { _apiKeyAtual = _keyController.text.trim(); _salvando = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chave ASAAS salva!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  void dispose() { _keyController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isConfigurado = _apiKeyAtual != null && _apiKeyAtual!.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.credit_card, color: Colors.blue[700], size: 28)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Integração ASAAS', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
              Text('Plataforma de pagamentos e cobranças', style: TextStyle(color: AdminTheme.textSecondary)),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isConfigurado ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isConfigurado ? Colors.green : Colors.orange),
              ),
              child: Row(children: [
                Icon(isConfigurado ? Icons.check_circle : Icons.warning_amber, size: 14, color: isConfigurado ? Colors.green : Colors.orange),
                const SizedBox(width: 4),
                Text(isConfigurado ? 'Configurado' : 'Não configurado',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isConfigurado ? Colors.green : Colors.orange)),
              ]),
            ),
          ]),
          const SizedBox(height: 24),

          // API Key Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Configuração da API', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Insira sua chave de API do ASAAS', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _keyController,
                      obscureText: !_keyVisivel,
                      decoration: InputDecoration(
                        labelText: 'API Key ASAAS',
                        hintText: r'$aact_xxxx...',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.key, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(_keyVisivel ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setState(() => _keyVisivel = !_keyVisivel),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _salvando ? null : _salvarKey,
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Salvar'),
                    style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                  ),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Features
          const Text('Funcionalidades', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _FeatureCard(icon: Icons.pix, title: 'PIX', desc: 'QR Code e Copia e Cola automático', ativo: isConfigurado),
            _FeatureCard(icon: Icons.credit_card, title: 'Cartão', desc: 'Link de pagamento por cartão', ativo: isConfigurado),
            _FeatureCard(icon: Icons.receipt_long, title: 'Boleto', desc: 'Emissão de boletos bancários', ativo: isConfigurado),
            _FeatureCard(icon: Icons.sync, title: 'Webhook', desc: 'Notificações automáticas de pagamento', ativo: isConfigurado),
          ]),
          const SizedBox(height: 24),

          // Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.info_outline, color: Colors.blue, size: 16), SizedBox(width: 8), Text('Como obter sua API Key', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))]),
              const SizedBox(height: 8),
              const Text('1. Acesse app.asaas.com\n2. Configurações → Integrações → Chave de API\n3. Copie e cole no campo acima\n\nEndpoint: https://api.asaas.com/v3', style: TextStyle(fontSize: 13, color: Colors.blue, height: 1.6)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () { Clipboard.setData(const ClipboardData(text: 'https://api.asaas.com/v3')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL copiada!'))); },
                child: const Text('📋 Copiar URL da API', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final bool ativo;
  const _FeatureCard({required this.icon, required this.title, required this.desc, required this.ativo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ativo ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ativo ? Colors.blue.shade200 : Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: ativo ? Colors.blue : Colors.grey, size: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: ativo ? Colors.green[50] : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Text(ativo ? 'Ativo' : 'Inativo', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: ativo ? Colors.green : Colors.grey)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: ativo ? Colors.black87 : Colors.grey)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    );
  }
}

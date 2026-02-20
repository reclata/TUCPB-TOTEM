import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final String shopifyUrl = "https://tucpb.myshopify.com"; 

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

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
                    Text('TUCPB SHOP', 
                        style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AdminTheme.primary)),
                    Text('Portal de Gestão e Vendas', 
                        style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _openExternalUrl(shopifyUrl),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Abrir Loja'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(FontAwesomeIcons.shopify, color: Color(0xFF95BF47), size: 32),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      // Card Principal de Acesso
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF95BF47).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(FontAwesomeIcons.bagShopping, size: 48, color: Color(0xFF95BF47)),
                            ),
                            const SizedBox(height: 24),
                            Text('Sua loja está online!', 
                                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(shopifyUrl, style: const TextStyle(color: Colors.blue)),
                            const SizedBox(height: 32),
                            const Text(
                              'Por medidas de segurança do Shopify, a gestão e visualização da loja devem ser feitas em abas dedicadas para garantir a proteção dos dados dos clientes.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, height: 1.5),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _BigActionButton(
                                  label: 'VER MINHA LOJA',
                                  subtitle: 'Visão do cliente',
                                  icon: Icons.storefront,
                                  color: const Color(0xFF95BF47),
                                  onTap: () => _openExternalUrl(shopifyUrl),
                                ),
                                const SizedBox(width: 24),
                                _BigActionButton(
                                  label: 'PAINEL ADMIN',
                                  subtitle: 'Gestão de pedidos',
                                  icon: Icons.dashboard_customize,
                                  color: Colors.indigo,
                                  onTap: () => _openExternalUrl('https://admin.shopify.com'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigActionButton extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.label, 
    required this.subtitle, 
    required this.icon, 
    required this.color, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

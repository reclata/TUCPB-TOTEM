import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/novo_cadastro_controller.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/tabs/aba_entidades.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/tabs/aba_espiritual_v2.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/tabs/aba_imagem.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/tabs/aba_perfil.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/tabs/aba_pessoal_v2.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class NovoCadastroModal extends StatefulWidget {
  const NovoCadastroModal({super.key});

  @override
  State<NovoCadastroModal> createState() => _NovoCadastroModalState();
}

class _NovoCadastroModalState extends State<NovoCadastroModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CadastroFormData _formData = CadastroFormData();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _formData.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _isSaving = true);
    try {
      final map = _formData.toMap();
      await FirebaseFirestore.instance.collection('usuarios').add(map);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cadastro realizado com sucesso!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _formData,
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            child: Column(
              children: [
                // Header
                Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: AdminTheme.surface,
                     borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                     boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text("Novo Cadastro", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                       IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                     ],
                   ),
                ),
                
                // Tabs
                Container(
                  color: Colors.grey[50], // Tab bg
                  child: Consumer<CadastroFormData>(
                    builder: (context, data, _) {
                      return TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: AdminTheme.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AdminTheme.primary,
                        tabs: [
                          const Tab(text: "Dados do Perfil"),
                          Tab(text: "Dados Pessoais", icon: data.isAssistencia ? const Icon(Icons.lock, size: 14) : null),
                          Tab(text: "Uso de Imagem", icon: data.imageAuthDenied ? const Icon(Icons.circle, color: Colors.red, size: 8) : null),
                          Tab(text: "Espiritual", icon: data.isAssistencia ? const Icon(Icons.lock, size: 14) : null),
                          Tab(text: "Entidades", icon: data.isAssistencia ? const Icon(Icons.lock, size: 14) : null),
                        ],
                      );
                    }
                  ),
                ),
                
                // Content
                Expanded(
                  child: Builder(
                    builder: (context) {
                      try {
                        return TabBarView(
                          controller: _tabController,
                          children: const [
                            AbaPerfil(),
                            AbaPessoalTab(),
                            AbaImagem(),
                            AbaEspiritualTab(),
                            AbaEntidades(),
                          ],
                        );
                      } catch (e, s) {
                         return Center(child: Text("Erro ao carregar abas: $e\n$s", style: const TextStyle(color: Colors.red)));
                      }
                    }
                  ),
                ),
                
                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.black12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: _isSaving 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Salvar Cadastro"),
                      ),
                    ],
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

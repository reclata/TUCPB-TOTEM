import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/novo_cadastro_controller.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/tabs/aba_entidades.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/tabs/aba_espiritual_v2.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/tabs/aba_imagem.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/tabs/aba_perfil.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/tabs/aba_pessoal_v2.dart';
import 'package:tucpb_adm/src/features/auth/presentation/auth_user_provider.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class NovoCadastroModalFinal extends ConsumerStatefulWidget {
  const NovoCadastroModalFinal({super.key});

  @override
  ConsumerState<NovoCadastroModalFinal> createState() => _NovoCadastroModalFinalState();
}

class _NovoCadastroModalFinalState extends ConsumerState<NovoCadastroModalFinal>
    with SingleTickerProviderStateMixin {
  final CadastroFormData _formData = CadastroFormData();
  late TabController _tabController;
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

  bool _canEditPerfil(Map<String, dynamic>? userData) {
    final perfil = (userData?['perfil'] ?? '').toString().toLowerCase();
    return perfil == 'admin' || perfil == 'suporte' || perfil == 'administrador';
  }

  Future<void> _salvar() async {
    setState(() => _isSaving = true);
    try {
      final map = _formData.toMap();
      await FirebaseFirestore.instance.collection('usuarios').add(map);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cadastro realizado com sucesso!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTabSafe(Widget tab) {
    return Builder(builder: (context) {
      try {
        return tab;
      } catch (e) {
        return Center(child: Text("Erro na aba: $e", style: const TextStyle(color: Colors.red)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(userDataProvider);
    final userData = userDataAsync.asData?.value;
    final canEditPerfil = _canEditPerfil(userData);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: p.ChangeNotifierProvider<CadastroFormData>.value(
        value: _formData,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.black12)),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Novo Cadastro",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Tabs Header
              Material(
                color: Colors.grey[50],
                child: p.Consumer<CadastroFormData>(
                  builder: (context, data, _) {
                    return TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: AdminTheme.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AdminTheme.primary,
                      tabs: const [
                        Tab(text: "Dados do Perfil"),
                        Tab(text: "Dados Pessoais"),
                        Tab(text: "Uso de Imagem"),
                        Tab(text: "Espiritual"),
                        Tab(text: "Entidades"),
                      ],
                    );
                  },
                ),
              ),

              // Content Body
              Expanded(
                child: Material(
                  color: Colors.white,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabSafe(AbaPerfil(canEditPerfil: canEditPerfil)),
                      _buildTabSafe(const AbaPessoalTab()),
                      _buildTabSafe(const AbaImagem()),
                      _buildTabSafe(const AbaEspiritualTab()),
                      _buildTabSafe(const AbaEntidades()),
                    ],
                  ),
                ),
              ),

              // Footer
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
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("Salvar Cadastro"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

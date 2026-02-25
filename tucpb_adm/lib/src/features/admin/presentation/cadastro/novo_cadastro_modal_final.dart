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
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/tabs/aba_historico.dart';
import 'package:tucpb_adm/src/features/admin/data/log_repository.dart';
import 'package:tucpb_adm/src/features/admin/data/activity_log_model.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';
import 'package:tucpb_adm/src/features/auth/presentation/auth_user_provider.dart';

class NovoCadastroModalFinal extends ConsumerStatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initialData;
  const NovoCadastroModalFinal({super.key, this.docId, this.initialData});

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
    _tabController = TabController(length: 6, vsync: this);
    if (widget.initialData != null) {
      _formData.fromMap(widget.initialData!);
    }
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
      final collection = FirebaseFirestore.instance.collection('usuarios');
      
      if (widget.docId == null) {
        final docRef = collection.doc();
        map['id'] = docRef.id;
        map['terreiroId'] = 'demo-terreiro'; // Garantindo terreiroId
        await docRef.set(map);
      } else {
        map['id'] = widget.docId;
        await collection.doc(widget.docId).update(map);
      }

      // Log
      final currentUser = ref.read(userDataProvider).asData?.value;
      await ref.read(logRepositoryProvider).logAction(
        userId: currentUser?['uid'] ?? '',
        userName: currentUser?['nome'] ?? 'Portal Admin',
        module: 'Cadastros',
        action: widget.docId == null ? LogActionType.create : LogActionType.update,
        description: '${widget.docId == null ? 'Cadastrou' : 'Editou'} usuário: ${map['nome']}',
      );

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
                        Tab(text: "Histórico"),
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
                      _buildTabSafe(AbaHistorico(userId: widget.docId)),
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
                    p.Consumer<CadastroFormData>(
                      builder: (context, data, _) {
                        final isUploading = data.isUploadingFoto;
                        return ElevatedButton(
                          onPressed: (_isSaving || isUploading) ? null : _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: (_isSaving || isUploading)
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, 
                                    strokeWidth: 2,
                                    value: isUploading ? null : null, // Could add progress later
                                  ),
                                )
                              : const Text("Salvar Cadastro"),
                        );
                      },
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

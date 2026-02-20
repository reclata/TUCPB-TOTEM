import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tucpb_adm/src/features/auth/presentation/auth_user_provider.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class AdminScaffold extends ConsumerWidget {
  final Widget child;
  const AdminScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;

    return Scaffold(
      backgroundColor: AdminTheme.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            const SizedBox(
              width: 260,
              child: AdminSidebar(),
            ),
          Expanded(
            child: Column(
              children: [
                // Top Bar with User Profile
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const _NotificationBell(),
                      const SizedBox(width: 16),
                      const _UserProfileHeader(),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.grey),
                        onPressed: () => _showSettingsDialog(context),
                        tooltip: 'Configurações',
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      drawer: isDesktop ? null : const Drawer(child: AdminSidebar()),
    );
  }

  static void showTrocarSenhaDialog(BuildContext context) {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trocar Minha Senha', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Digite sua nova senha abaixo (mínimo 6 caracteres).'),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nova Senha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar Senha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_reset)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A senha deve ter no mínimo 6 caracteres.')));
                return;
              }
              if (controller.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('As senhas não conferem.')));
                return;
              }

              try {
                await FirebaseAuth.instance.currentUser?.updatePassword(controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha atualizada com sucesso!'), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e. Para trocar a senha, você precisa ter logado recentemente. Tente sair e entrar novamente.'), backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('ATUALIZAR SENHA'),
          ),
        ],
      ),
    );
  }

  static void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _AdvancedSettingsDialog(),
    );
  }
}

class _AdvancedSettingsDialog extends StatefulWidget {
  const _AdvancedSettingsDialog();

  @override
  State<_AdvancedSettingsDialog> createState() => _AdvancedSettingsDialogState();
}

class _AdvancedSettingsDialogState extends State<_AdvancedSettingsDialog> {
  String _selectedProfile = 'Medium';
  String _selectedUser = 'Selecione um usuário';
  
  // Mock de permissões
  final List<String> _modules = [
    'Visão Geral', 'Cadastros', 'Calendário', 'Financeiro', 'Estoque', 'TUCPB News', 'Relatórios'
  ];
  
  final List<String> _actions = [
    'Editar', 'Excluir', 'Incluir', 'Cadastrar', 'Visualizar', 'Ocultar aba'
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 900,
          height: 700,
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Configurar Permissões",
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange[800]),
              ),
              const SizedBox(height: 4),
              Text(
                "Customize o que vai ou não aparecer no menu e as ações permitidas por usuário ou perfil",
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              const TabBar(
                labelColor: Colors.orange,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.orange,
                tabs: [
                  Tab(text: 'Configurar por Perfil'),
                  Tab(text: 'Configurar por Usuário'),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildConfigContent(isProfile: true),
                    _buildConfigContent(isProfile: false),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("SALVAR ALTERAÇÕES"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigContent({required bool isProfile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isProfile ? "Selecione um perfil" : "Selecione um usuário",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: isProfile ? _selectedProfile : _selectedUser,
              items: (isProfile 
                ? ['Medium', 'Cambono', 'Dirigente', 'Administrador']
                : ['Selecione um usuário', 'Thabata', 'João Silva', 'Maria Souza']
              ).map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() {
                if (isProfile) _selectedProfile = v!;
                else _selectedUser = v!;
              }),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: _modules.length,
            itemBuilder: (context, index) {
              final module = _modules[index];
              return _buildModulePermissions(module);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModulePermissions(String moduleName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, size: 20, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                moduleName.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1, color: Colors.black87),
              ),
            ],
          ),
          const Divider(),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: _actions.map((action) => _buildPermissionCheckbox(action)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCheckbox(String label) {
    bool isChecked = label == 'Visualizar'; // Simulação
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: isChecked,
            activeColor: Colors.orange,
            onChanged: (v) {},
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[800])),
      ],
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDataProvider);
    
    return userAsync.when(
      data: (userData) {
        final userId = userData?['docId'] ?? userData?['uid'] ?? '';
        if (userId.isEmpty) return const SizedBox();

            return StreamBuilder(
              stream: FirebaseFirestore.instance.collection('usuarios').doc(userId).collection('anotacoes').snapshots(),
              builder: (context, anotacoesSnap) {
                return StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('giras').where('tipo', isEqualTo: 'limpeza').where('mediumId', isEqualTo: userId).where('data', isGreaterThanOrEqualTo: DateTime.now()).snapshots(),
                  builder: (context, girasSnap) {
                    int uncheckedCount = 0;
                    if (anotacoesSnap.hasData) {
                      final dynamic data = anotacoesSnap.data;
                      final docs = data.docs;
                      for (var doc in docs) {
                        final itemData = doc.data() as Map<String, dynamic>;
                        final checklist = itemData['checklist'] as List? ?? [];
                        uncheckedCount += checklist.where((item) => item['checked'] == false).length;
                      }
                    }
                    if (girasSnap.hasData) {
                      final dynamic data = girasSnap.data;
                      uncheckedCount += (data.docs.length as int);
                    }

                    return IconButton(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none_outlined, color: Colors.grey),
                          if (uncheckedCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                child: Text(
                                  '$uncheckedCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () => _showNotifications(context, userId),
                    );
                  },
                );
              },
            );
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        );
  }

  void _showNotifications(BuildContext context, String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('anotacoes')
        .get();

    final List<Map<String, dynamic>> forgotten = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final checklist = data['checklist'] as List? ?? [];
      final unchecked = checklist.where((item) => item['checked'] == false).map((i) => i['item']).toList();
      if (unchecked.isNotEmpty) {
        forgotten.add({
          'tipo': 'Anotação',
          'linha': doc.id,
          'itens': unchecked,
        });
      }
    }

    // Load Cleaning Assignments
    final cleaningSnapshot = await FirebaseFirestore.instance
        .collection('giras')
        .where('tipo', isEqualTo: 'limpeza')
        .where('mediumId', isEqualTo: userId)
        .where('data', isGreaterThanOrEqualTo: DateTime.now())
        .get();

    final List<Map<String, dynamic>> assignments = cleaningSnapshot.docs.map((d) {
      final data = d.data();
      final date = (data['data'] as Timestamp).toDate();
      return {
        'tipo': 'Limpeza',
        'titulo': data['nome'],
        'data': DateFormat('dd/MM').format(date),
      };
    }).toList();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Itens Esquecidos / Pendentes', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: (forgotten.isEmpty && assignments.isEmpty)
            ? const Text('Tudo pronto! Você não tem pendências no momento.')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (forgotten.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('ITENS ESQUECIDOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                      ),
                      ...forgotten.map((f) => ListTile(
                        title: Text(f['linha'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Pendentes: ${f['itens'].join(', ')}', style: const TextStyle(fontSize: 12)),
                      )),
                    ],
                    if (assignments.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('LIMPEZAS ESCALADAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal)),
                      ),
                      ...assignments.map((a) => ListTile(
                        leading: const Icon(Icons.cleaning_services, color: Colors.teal),
                        title: Text(a['titulo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Escalado para o dia ${a['data']}', style: const TextStyle(fontSize: 12)),
                      )),
                    ],
                  ],
                ),
              ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('FECHAR')),
          ],
        ),
      );
    }
  }
}

class _UserProfileHeader extends ConsumerWidget {
  const _UserProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider);

    return userDataAsync.when(
      data: (userData) {
        final nome = userData?['nome'] ?? 'Usuário';
        final perfil = userData?['perfil'] ?? '';
        final fotoUrl = userData?['fotoUrl'] as String?;

        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          onSelected: (value) {
            if (value == 'sair') {
              FirebaseAuth.instance.signOut();
              context.go('/login');
            } else if (value == 'senha') {
              AdminScaffold.showTrocarSenhaDialog(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'senha',
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 18, color: AdminTheme.primary),
                  const SizedBox(width: 12),
                  const Text('Trocar Senha'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'sair',
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 18, color: Colors.red),
                  const SizedBox(width: 12),
                  const Text('Sair do Sistema', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF8D6E63),
                backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty) ? NetworkImage(fotoUrl) : null,
                child: (fotoUrl == null || fotoUrl.isEmpty)
                    ? Text(nome.isNotEmpty ? nome[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3E2723), fontSize: 14)),
                  Text(perfil, style: const TextStyle(fontSize: 10, color: Color(0xFF8D6E63))),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
            ],
          ),
        );
      },
      loading: () => const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const Icon(Icons.error),
    );
  }
}

class AdminSidebar extends ConsumerWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = GoRouterState.of(context).uri.toString();
    final userData = ref.watch(userDataProvider).asData?.value;
    final perfil = (userData?['perfil'] ?? '').toString().toLowerCase();
    
    final isAdmin = ['admin', 'suporte', 'administrador', 'dirigente'].contains(perfil);
    final isMedium = perfil.contains('medium') || perfil.contains('médium') || perfil.contains('cambone') || perfil.contains('cambono');
    final isAssistencia = perfil.contains('assistencia') || perfil == 'público' || perfil == 'visitante';

    return Container(
      color: AdminTheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 50,
              ),
            ),
          ),
          const SizedBox(height: 48),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (isAdmin || isMedium || isAssistencia)
                  _SidebarItem(
                    icon: FontAwesomeIcons.chartPie, 
                    label: "Visão Geral", 
                    isSelected: uri == '/dashboard',
                    onTap: () => context.go('/dashboard'),
                  ),
                if (isAdmin)
                  _SidebarItem(
                    icon: FontAwesomeIcons.users, 
                    label: "Cadastros",
                    isSelected: uri.startsWith('/cadastros'),
                    onTap: () => context.go('/cadastros'),
                  ),
                if (isAdmin || isMedium || isAssistencia)
                  _SidebarItem(
                    icon: FontAwesomeIcons.calendar,
                    label: "Calendário",
                    isSelected: uri.startsWith('/calendario'),
                    onTap: () => context.go('/calendario'),
                  ),
                if (isAdmin || isMedium || isAssistencia)
                  _SidebarItem(
                    icon: FontAwesomeIcons.circleDollarToSlot,
                    label: "Financeiro",
                    isSelected: uri.startsWith('/financeiro'),
                    onTap: () => context.go('/financeiro'),
                  ),
                if (isAdmin)
                  _SidebarItem(
                    icon: FontAwesomeIcons.boxesStacked,
                    label: "Estoque",
                    isSelected: uri.startsWith('/estoque'),
                    onTap: () => context.go('/estoque'),
                  ),
                if (isAdmin || isMedium || isAssistencia)
                  _SidebarItem(
                    icon: FontAwesomeIcons.newspaper, 
                    label: "TUCPB News",
                    isSelected: uri.startsWith('/news'),
                    onTap: () => context.go('/news'),
                  ),
                if (isAdmin || isMedium || isAssistencia)
                  _SidebarItem(
                    icon: FontAwesomeIcons.shop, 
                    label: "TUCPB Shop",
                    isSelected: uri.startsWith('/shop'),
                    onTap: () => html.window.open('https://tucpb.myshopify.com', '_blank'),
                  ),
                if (isAdmin)
                  _SidebarItem(
                    icon: FontAwesomeIcons.fileLines, 
                    label: "Relatórios",
                    isSelected: uri.startsWith('/relatorios'),
                    onTap: () => context.go('/relatorios'),
                  ),
                if (isAdmin)
                  _SidebarItem(
                    icon: FontAwesomeIcons.bullhorn, 
                    label: "Lembretes",
                    isSelected: uri.startsWith('/lembretes'),
                    onTap: () => context.go('/lembretes'),
                  ),
                if (isAdmin || isMedium || isAssistencia)
                  _SidebarItem(
                    icon: FontAwesomeIcons.bookOpen, 
                    label: "Anotações",
                    isSelected: uri.startsWith('/anotacoes'),
                    onTap: () => context.go('/anotacoes'),
                  ),
                if (isAdmin || isMedium)
                  _SidebarItem(
                    icon: FontAwesomeIcons.images, 
                    label: "Álbum de Fotos",
                    isSelected: uri.startsWith('/album'),
                    onTap: () => context.go('/album'),
                  ),
                const Divider(height: 32),
                _SidebarItem(
                  icon: FontAwesomeIcons.computer, 
                  label: "Acessar Totem",
                  onTap: () => html.window.open('https://tucpb---token.web.app/kiosk', '_self'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SidebarItem({required this.icon, required this.label, this.isSelected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AdminTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : AdminTheme.textSecondary,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AdminTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
      ),
    );
  }
}

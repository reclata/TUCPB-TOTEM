import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/models.dart';
import '../../../shared/providers/global_providers.dart';
import '../data/admin_repository.dart';

class UsuariosScreen extends ConsumerWidget {
  const UsuariosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const terreiroId = 'demo-terreiro'; // TODO: Get from auth
    final usuariosAsync = ref.watch(streamUsuariosProvider(terreiroId));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gerenciar Usuários',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Usuário'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onPressed: () => _addUsuarioDialog(context, ref, terreiroId),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Lista de Usuários
            Expanded(
              child: usuariosAsync.when(
                data: (usuarios) {
                  if (usuarios.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum usuário cadastrado',
                            style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: usuarios.length,
                    itemBuilder: (context, index) {
                      final usuario = usuarios[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(20),
                          leading: CircleAvatar(
                            backgroundColor: Colors.brown[300],
                            radius: 30,
                            child: Text(
                              usuario.nomeCompleto.isNotEmpty ? usuario.nomeCompleto[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            usuario.nomeCompleto,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.login, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text('Login: ${usuario.login}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Perfil: ${_getPerfilLabel(usuario.perfilAcesso)}',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: usuario.ativo ? Colors.green[100] : Colors.red[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  usuario.ativo ? 'ATIVO' : 'INATIVO',
                                  style: TextStyle(
                                    color: usuario.ativo ? Colors.green[900] : Colors.red[900],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.brown[600]),
                                onPressed: () => _editUsuarioDialog(context, ref, terreiroId, usuario),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(context, ref, usuario),
                                tooltip: 'Excluir',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Erro: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPerfilLabel(String perfil) {
    switch (perfil) {
      case 'admin':
        return 'Administrador';
      case 'operador':
        return 'Operador';
      case 'visualizador':
        return 'Visualizador';
      default:
        return perfil;
    }
  }

  void _addUsuarioDialog(BuildContext context, WidgetRef ref, String terreiroId) {
    final nameCtrl = TextEditingController();
    final loginCtrl = TextEditingController();
    final senhaCtrl = TextEditingController();
    String selectedPerfil = 'operador';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Novo Usuário'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: loginCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Login',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: senhaCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Perfil de Acesso',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedPerfil,
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                      DropdownMenuItem(value: 'operador', child: Text('Operador')),
                      DropdownMenuItem(value: 'visualizador', child: Text('Visualizador')),
                    ],
                    onChanged: (val) => setState(() => selectedPerfil = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameCtrl.text.isEmpty || loginCtrl.text.isEmpty || senhaCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
                  );
                  return;
                }

                final usuario = Usuario(
                  id: const Uuid().v4(),
                  terreiroId: terreiroId,
                  nomeCompleto: nameCtrl.text,
                  login: loginCtrl.text,
                  senha: senhaCtrl.text, // TODO: Hash in production
                  perfilAcesso: selectedPerfil,
                  permissoes: const [],
                  ativo: true,
                );

                ref.read(adminRepositoryProvider).addUsuario(usuario);
                Navigator.pop(context);
              },
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _editUsuarioDialog(BuildContext context, WidgetRef ref, String terreiroId, Usuario usuario) {
    final nameCtrl = TextEditingController(text: usuario.nomeCompleto);
    final loginCtrl = TextEditingController(text: usuario.login);
    final senhaCtrl = TextEditingController(text: usuario.senha);
    String selectedPerfil = usuario.perfilAcesso;
    bool ativo = usuario.ativo;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Editar Usuário'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: loginCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Login',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: senhaCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Perfil de Acesso',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedPerfil,
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                      DropdownMenuItem(value: 'operador', child: Text('Operador')),
                      DropdownMenuItem(value: 'visualizador', child: Text('Visualizador')),
                    ],
                    onChanged: (val) => setState(() => selectedPerfil = val!),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Usuário Ativo'),
                    value: ativo,
                    onChanged: (val) => setState(() => ativo = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameCtrl.text.isEmpty || loginCtrl.text.isEmpty || senhaCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
                  );
                  return;
                }

                final updatedUsuario = Usuario(
                  id: usuario.id,
                  terreiroId: terreiroId,
                  nomeCompleto: nameCtrl.text,
                  login: loginCtrl.text,
                  senha: senhaCtrl.text,
                   perfilAcesso: selectedPerfil,
                  permissoes: usuario.permissoes,
                  ativo: ativo,
                );

                ref.read(adminRepositoryProvider).updateUsuario(updatedUsuario);
                Navigator.pop(context);
              },
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Usuario usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o usuário "${usuario.nomeCompleto}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(adminRepositoryProvider).deleteUsuario(usuario.id);
              Navigator.pop(context);
            },
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }
}

// Provider para stream de usuários
final streamUsuariosProvider = StreamProvider.family<List<Usuario>, String>((ref, terreiroId) {
  return ref.watch(adminRepositoryProvider).streamUsuarios(terreiroId);
});

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/novo_cadastro_controller.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class AbaPerfil extends StatefulWidget {
  final bool canEditPerfil;
  const AbaPerfil({super.key, this.canEditPerfil = true});

  @override
  State<AbaPerfil> createState() => _AbaPerfilState();
}

class _AbaPerfilState extends State<AbaPerfil> {
  Uint8List? _imagemBytes;

  Future<void> _pickImage(CadastroFormData data) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      
      // Mostrar preview local imediatamente e avisar que está subindo
      setState(() {
        _imagemBytes = bytes;
      });
      data.setUploadingFoto(true);

      // Upload para Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('fotos_usuarios/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      
      // Monitorar progresso se necessário, mas por enquanto basta o wait
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      // Salvar no controller de dados
      data.updateFotoUrl(url);
      data.setUploadingFoto(false);

    } catch (e) {
      data.setUploadingFoto(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao selecionar foto: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<CadastroFormData>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Dados do Perfil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: data.nomeController,
            decoration: const InputDecoration(labelText: "Nome Completo", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: data.emailController,
                  decoration: const InputDecoration(labelText: "E-mail / Login", border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: data.telefoneController,
                  decoration: const InputDecoration(labelText: "Telefone", border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: widget.canEditPerfil ? '' : 'Apenas Admin ou Suporte podem alterar o perfil de acesso.',
                  child: Builder(
                    builder: (context) {
                      final options = ["Medium", "Oga", "Dirigente", "Portaria", "Suporte", "Assistencia", "Admin", "Administrador"];
                      
                      // Normalização para evitar crash caso o Firestore retorne "medium" (minúsculo)
                      String? normalizedValue;
                      if (data.perfilAcesso != null) {
                        normalizedValue = options.firstWhere(
                          (e) => e.toLowerCase() == data.perfilAcesso!.toLowerCase(),
                          orElse: () => options.first,
                        );
                      }

                      return DropdownButtonFormField<String>(
                        value: normalizedValue,
                        decoration: InputDecoration(
                          labelText: "Perfil de Acesso",
                          border: const OutlineInputBorder(),
                          filled: !widget.canEditPerfil,
                          fillColor: !widget.canEditPerfil ? Colors.grey[100] : null,
                          suffixIcon: !widget.canEditPerfil
                              ? const Icon(Icons.lock, color: Colors.grey, size: 18)
                              : null,
                        ),
                        items: options
                            .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: widget.canEditPerfil ? (v) => data.updatePerfil(v!) : null,
                      );
                    }
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: data.senhaController,
                  decoration: const InputDecoration(labelText: "Senha Inicial", border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text("Cadastro Ativo?"),
            value: data.ativo,
            onChanged: (v) {
               data.ativo = v;
               // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
               data.notifyListeners();
            },
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                data.entradaTerreiroController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                data.notifyListeners();
              }
            },
            child: IgnorePointer(
              child: TextFormField(
                controller: data.entradaTerreiroController,
                decoration: const InputDecoration(
                  labelText: "Data de Entrada",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: data.observacaoController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Observações do Cadastro",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text("Foto de Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          // Foto Upload
          Center(
            child: GestureDetector(
              onTap: () => _pickImage(data),
              child: Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminTheme.primary.withValues(alpha: 0.3), width: 2),
                  image: _imagemBytes != null
                      ? DecorationImage(image: MemoryImage(_imagemBytes!), fit: BoxFit.cover)
                      : data.fotoUrl != null
                          ? DecorationImage(image: NetworkImage(data.fotoUrl!), fit: BoxFit.cover)
                          : null,
                ),
                child: data.isUploadingFoto
                    ? const Center(child: CircularProgressIndicator())
                    : (_imagemBytes == null && data.fotoUrl == null)
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: Colors.grey, size: 48),
                                SizedBox(height: 12),
                                Text("Clique para selecionar\numa foto nitida", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          )
                        : Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                child: const Icon(Icons.edit, color: AdminTheme.primary, size: 20),
                              ),
                            ),
                          ),
              ),
            ),
          ),
          if (data.fotoUrl != null && !data.isUploadingFoto)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _imagemBytes != null ? "Foto enviada com sucesso!" : "Foto carregada", 
                    style: const TextStyle(color: Colors.green, fontSize: 12)
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

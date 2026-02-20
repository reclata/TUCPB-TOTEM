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
  String? _uploadedFotoUrl;
  bool _uploadingFoto = false;

  Future<void> _pickImage(CadastroFormData data) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _imagemBytes = bytes;
        _uploadingFoto = true;
      });

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('fotos_usuarios/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      setState(() {
        _uploadedFotoUrl = url;
        _uploadingFoto = false;
      });

      // Salvar no controller de dados
      data.fotoUrl = url;
    } catch (e) {
      setState(() => _uploadingFoto = false);
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
                  child: DropdownButtonFormField<String>(
                    value: data.perfilAcesso,
                    decoration: InputDecoration(
                      labelText: "Perfil de Acesso",
                      border: const OutlineInputBorder(),
                      filled: !widget.canEditPerfil,
                      fillColor: !widget.canEditPerfil ? Colors.grey[100] : null,
                      suffixIcon: !widget.canEditPerfil
                          ? const Icon(Icons.lock, color: Colors.grey, size: 18)
                          : null,
                    ),
                    items: ["Medium", "Oga", "Dirigente", "Portaria", "Suporte", "Assistencia", "Admin", "Administrador"]
                        .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: widget.canEditPerfil ? (v) => data.updatePerfil(v!) : null,
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
          GestureDetector(
            onTap: () => _pickImage(data),
            child: Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminTheme.primary.withOpacity(0.3), width: 2),
                image: _imagemBytes != null
                    ? DecorationImage(image: MemoryImage(_imagemBytes!), fit: BoxFit.cover)
                    : null,
              ),
              child: _uploadingFoto
                  ? const Center(child: CircularProgressIndicator())
                  : _imagemBytes == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.grey, size: 40),
                              SizedBox(height: 8),
                              Text("Clique para\nselecionar", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        )
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.edit, color: Colors.grey, size: 16),
                            ),
                          ),
                        ),
            ),
          ),
          if (_uploadedFotoUrl != null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text("Foto enviada com sucesso!", style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

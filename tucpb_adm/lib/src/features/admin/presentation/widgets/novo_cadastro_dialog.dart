import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class NovoCadastroDialog extends ConsumerStatefulWidget {
  const NovoCadastroDialog({super.key});

  @override
  ConsumerState<NovoCadastroDialog> createState() => _NovoCadastroDialogState();
}

class _NovoCadastroDialogState extends ConsumerState<NovoCadastroDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  String _perfilSelecionado = "Médium";
  DateTime _dataEntrada = DateTime.now();
  bool _isLoading = false;

  final List<String> _perfis = ["Médium", "Cambono", "Ogan", "Dirigente", "Admin", "Assistência"];

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Salvar no Firestore
      await FirebaseFirestore.instance.collection('usuarios').add({
        'nome': _nomeController.text.trim(),
        'perfil': _perfilSelecionado,
        'dataEntrada': Timestamp.fromDate(_dataEntrada),
        'ativo': true,
        'dataCriacao': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        Navigator.of(context).pop(); // Fechar Dialog
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Novo Cadastro", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),
              
              // Nome
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: "Nome Completo",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v == null || v.isEmpty ? "Nome obrigatório" : null,
              ),
              const SizedBox(height: 16),
              
              // Perfil e Data
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _perfilSelecionado,
                      decoration: const InputDecoration(
                        labelText: "Perfil",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      items: _perfis.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _perfilSelecionado = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dataEntrada,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _dataEntrada = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Data de Entrada",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_dataEntrada)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Botões
              Row(
                children: [
                   Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: const Text("Cancelar"),
                    ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AdminTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Salvar Cadastro"),
                    ),
                   ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

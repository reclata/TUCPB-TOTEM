import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/novo_cadastro_controller.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class AbaPessoalTab extends StatelessWidget {
  const AbaPessoalTab({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<CadastroFormData>();

    if (data.isAssistencia) {
      return const Center(child: Text("Aba não disponível para perfil Assistência (somente Perfil e Imagem)."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Dados Pessoais", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
          const SizedBox(height: 16),
          
          // Data e CPF
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      data.dtNascimentoController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                    }
                  },
                  child: IgnorePointer(
                    child: TextFormField(
                      controller: data.dtNascimentoController,
                      decoration: const InputDecoration(
                        labelText: "Data de Nascimento", 
                        border: OutlineInputBorder(), 
                        hintText: "dd/mm/aaaa",
                        suffixIcon: Icon(Icons.calendar_today)
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: data.cpfController,
                  decoration: const InputDecoration(labelText: "CPF", border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Endereço
          const Text("Endereço Completo", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
               Expanded(flex: 2, child: TextFormField(controller: data.cepController, decoration: const InputDecoration(labelText: "CEP", border: OutlineInputBorder()))),
               const SizedBox(width: 16),
               Expanded(flex: 2, child: TextFormField(controller: data.cidadeController, decoration: const InputDecoration(labelText: "Cidade", border: OutlineInputBorder()))),
               const SizedBox(width: 16),
               Expanded(flex: 3, child: TextFormField(controller: data.bairroController, decoration: const InputDecoration(labelText: "Bairro", border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 8),
           Row(
            children: [
               Expanded(flex: 4, child: TextFormField(controller: data.ruaController, decoration: const InputDecoration(labelText: "Rua", border: OutlineInputBorder()))),
               const SizedBox(width: 16),
               Expanded(flex: 1, child: TextFormField(controller: data.numeroController, decoration: const InputDecoration(labelText: "Número", border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(controller: data.complementoController, decoration: const InputDecoration(labelText: "Complemento", border: OutlineInputBorder())),
          const SizedBox(height: 16),

          // Estado Civil
          DropdownButtonFormField<String>(
            value: data.estadoCivil,
            decoration: const InputDecoration(labelText: "Estado Civil", border: OutlineInputBorder()),
            items: ["Solteiro", "Casado", "Namorando", "Viuvo"]
                .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) {
                data.estadoCivil = v!;
                // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                data.notifyListeners();
            },
          ),
          const SizedBox(height: 16),

          // Filhos Logic
          Row(
            children: [
               const Text("Filhos?"),
               const SizedBox(width: 16),
               Switch(value: data.temFilhos, onChanged: data.updateFilhos),
               if (data.temFilhos) ...[
                  const SizedBox(width: 16),
                  const Text("Quantos?"),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: data.qtdFilhos,
                    items: List.generate(10, (index) => index + 1).map<DropdownMenuItem<int>>((e) => DropdownMenuItem(value: e, child: Text("$e"))).toList(),
                    onChanged: (v) => data.setQtdFilhos(v!),
                  ),
               ],
            ],
          ),
          
          if (data.temFilhos) 
             const SizedBox(height: 8),
          
          if (data.temFilhos)
             for (int index = 0; index < data.nomesFilhosControllers.length; index++)
               Padding(
                 padding: const EdgeInsets.only(bottom: 8.0),
                 child: TextFormField(
                   controller: data.nomesFilhosControllers[index],
                   decoration: InputDecoration(labelText: "Nome do Filho ${index + 1}", border: const OutlineInputBorder()),
                 ),
               ),
          
          const SizedBox(height: 16),
          // Saúde
           SwitchListTile(
            title: const Text("Possui alguma restrição física ou de saúde?"),
            value: data.restricaoSaude,
            onChanged: (v) { data.restricaoSaude = v; // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
            data.notifyListeners(); },
            contentPadding: EdgeInsets.zero,
          ),
          if (data.restricaoSaude)
            TextFormField(controller: data.qualRestricaoController, decoration: const InputDecoration(labelText: "Qual?", border: OutlineInputBorder())),
            
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text("Possui alergias?"),
            value: data.alergias,
            onChanged: (v) { data.alergias = v; // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
            data.notifyListeners(); },
            contentPadding: EdgeInsets.zero,
          ),
          if (data.alergias)
            TextFormField(controller: data.quaisAlergiasController, decoration: const InputDecoration(labelText: "Quais?", border: OutlineInputBorder())),

          const SizedBox(height: 24),
          const Text("Contato de Emergência", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextFormField(controller: data.contatoEmergenciaNome, decoration: const InputDecoration(labelText: "Nome", border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: data.contatoEmergenciaParentesco, decoration: const InputDecoration(labelText: "Parentesco", border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: data.contatoEmergenciaTel, decoration: const InputDecoration(labelText: "Telefone", border: OutlineInputBorder()))),
            ],
          ),
        ],
      ),
    );
  }
}

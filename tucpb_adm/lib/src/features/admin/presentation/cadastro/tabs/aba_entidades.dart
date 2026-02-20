import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/novo_cadastro_controller.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class AbaEntidades extends StatelessWidget {
  const AbaEntidades({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<CadastroFormData>();

    if (data.isAssistencia) return const Center(child: Text("Não aplicável."));

    return SingleChildScrollView(
       padding: const EdgeInsets.all(24),
       child: Column(
         children: [
           for (int index = 0; index < data.entidades.length; index++)
             Card(
               margin: const EdgeInsets.only(bottom: 16),
               child: Padding(
                 padding: const EdgeInsets.all(16),
                 child: Column(
                   children: [
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                          Text("Entidade ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(onPressed: () => data.removeEntidade(index), icon: const Icon(Icons.delete, color: Colors.red)),
                       ],
                     ),
                     const SizedBox(height: 8),
                     Row(
                       children: [
                         Expanded(
                           child: DropdownButtonFormField<String>(
                             value: data.entidades[index].linha,
                             decoration: const InputDecoration(labelText: "Linha", border: OutlineInputBorder()),
                             items: ["CABOCLO", "ERÊ", "PRETO VELHO", "BOIADEIRO", "BAIANO", "MALANDRO", "MARINHEIRO", "CAPOEIRA", "POMBOGIRO", "POMBAGIRA", "EXÚ", "EXÚ - MIRIM", "FEITICEIRO"]
                                 .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                             onChanged: (v) { data.entidades[index].linha = v!; // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                             data.notifyListeners(); },
                           ),
                         ),
                         const SizedBox(width: 16),
                         Expanded(
                           child: DropdownButtonFormField<String>(
                             value: data.entidades[index].tipo,
                             decoration: const InputDecoration(labelText: "Tipo", border: OutlineInputBorder()),
                             items: ["CABOCLO", "CABOCLA", "ERÊ MENINO", "ERÊ MENINA", "PRETO VELHO", "PRETA VELHA", "BOIADEIRO", "VAQUEIRO", "BAIANO", "BAIANA", "MALANDRO", "MALANDRA", "MARINHEIRO", "CAPOEIRA", "POMBOGIRO", "POMBAGIRA", "EXÚ", "EXÚ - MIRIM MENINO", "EXÚ - MIRIM MENINA", "FEITICEIRO", "FEITICEIRA"]
                                 .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                             onChanged: (v) { data.entidades[index].tipo = v!; // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                             data.notifyListeners(); },
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 8),
                     TextFormField(
                       controller: data.entidades[index].nomeController,
                       decoration: const InputDecoration(labelText: "Nome da Entidade", border: OutlineInputBorder()),
                     ),
                   ],
                 ),
               ),
             ),
           
           const SizedBox(height: 16),
           ElevatedButton.icon(
             onPressed: data.addEntidade,
             icon: const Icon(Icons.add),
             label: const Text("Adicionar Nova Entidade"),
             style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.secondary, foregroundColor: Colors.white),
           ),
         ],
       ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/novo_cadastro_controller.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class AbaEspiritualTab extends StatelessWidget {
  const AbaEspiritualTab({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<CadastroFormData>();

    if (data.isAssistencia) return const Center(child: Text("Não aplicável."));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Pais de Cabeça", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _buildMultiSelect(
            "Pai", 
            ["OGUM", "OXÓSSI", "OSSÃE", "OMOLUM", "OBALUAÊ", "XANGÔ", "EXÚ"], 
            data.paisCabecaPai, 
            (n) => data.togglePaiHeader(n, true)
          ),
          const SizedBox(height: 16),
          _buildMultiSelect(
            "Mãe", 
            ["OXUM", "IEMANJÁ", "IANSÃ", "OBÁ", "EWÁ", "NANÃ"], 
            data.paisCabecaMae, 
            (n) => data.togglePaiHeader(n, false)
          ),
          
          const Divider(height: 32),
          
          _DateTextField(
            controller: data.entradaTerreiroController, 
            label: "Data de Entrada no Terreiro"
          ),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text("Obrigações", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
               IconButton(onPressed: data.addObrigacao, icon: const Icon(Icons.add_circle, color: AdminTheme.primary)),
            ],
          ),
          // List Obligations
          for (int index = 0; index < data.obrigacoes.length; index++)
            _buildObrigacaoCard(data, index),
          
          const Divider(height: 32),
          // Batismos
          SwitchListTile(
            title: const Text("Batizado na Igreja Católica?"),
            value: data.batizadoCatolica,
            onChanged: (v) { data.batizadoCatolica = v; // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
            data.notifyListeners(); },
            contentPadding: EdgeInsets.zero,
          ),
          
          SwitchListTile(
            title: const Text("Batizado no TUCPB?"),
            value: data.batizadoTucpb,
            onChanged: (v) { data.batizadoTucpb = v; // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
            data.notifyListeners(); },
            contentPadding: EdgeInsets.zero,
          ),
          if (data.batizadoTucpb) 
             Padding(
               padding: const EdgeInsets.only(left: 16),
               child: Column(
                 children: [
                    _DateTextField(controller: data.dataBatismoController, label: "Data Batismo"),
                    const SizedBox(height: 8),
                    TextFormField(controller: data.padrinhoBatismoController, decoration: const InputDecoration(labelText: "Nome Padrinho", border: OutlineInputBorder())),
                     const SizedBox(height: 8),
                    TextFormField(controller: data.madrinhaBatismoController, decoration: const InputDecoration(labelText: "Nome Madrinha", border: OutlineInputBorder())),
                 ],
               ),
             ),
          
           const SizedBox(height: 16),
           SwitchListTile(
            title: const Text("Crismado no TUCPB?"),
            value: data.crismadoTucpb,
            onChanged: (v) { data.crismadoTucpb = v; // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
            data.notifyListeners(); },
            contentPadding: EdgeInsets.zero,
          ),
          if (data.crismadoTucpb) 
             Padding(
               padding: const EdgeInsets.only(left: 16),
               child: Column(
                 children: [
                    _DateTextField(controller: data.dataCrismaController, label: "Data Crisma"),
                    const SizedBox(height: 8),
                    TextFormField(controller: data.padrinhoCrismaController, decoration: const InputDecoration(labelText: "Nome Padrinho", border: OutlineInputBorder())),
                     const SizedBox(height: 8),
                    TextFormField(controller: data.madrinhaCrismaController, decoration: const InputDecoration(labelText: "Nome Madrinha", border: OutlineInputBorder())),
                 ],
               ),
             ),
        ],
      ),
    );
  }
  
  Widget _buildObrigacaoCard(CadastroFormData data, int index) {
    final item = data.obrigacoes[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: item.tipo,
                items: ["Macifi", "Buri", "Obrigação", "Firmeza", "Feitura", "Jubileu"]
                  .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) {
                  item.tipo = v!; 
                  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                  data.notifyListeners(); 
                },
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DateTextField(
                controller: item.dataController,
                label: "Data",
              ),
            ),
            IconButton(onPressed: () => data.removeObrigacao(index), icon: const Icon(Icons.delete, color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelect(String label, List<String> options, List<String> selected, Function(String) toggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Wrap(
          spacing: 8,
          children: options.map<Widget>((opt) {
            final isSelected = selected.contains(opt);
            return FilterChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (_) => toggle(opt),
              checkmarkColor: Colors.white,
              selectedColor: AdminTheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DateTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _DateTextField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          controller.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
        }
      },
      child: IgnorePointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today, size: 16),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        ),
      ),
    );
  }
}

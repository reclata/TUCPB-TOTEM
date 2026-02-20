import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/novo_cadastro_controller.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class AbaImagem extends StatelessWidget {
  const AbaImagem({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<CadastroFormData>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Uso de Imagem e Voz",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Quais finalidades você autoriza para o uso da sua imagem/voz?"),
          const SizedBox(height: 16),
          
          for (var key in data.usoImagem.keys)
             Builder(builder: (context) { // Builder ou check direto
               final isDenied = key == "Não Autorizo";
               final isChecked = data.usoImagem[key]!;
               
               return CheckboxListTile(
                 title: Text(
                   key, 
                   style: TextStyle(
                     color: isDenied && isChecked ? Colors.red : null,
                     fontWeight: isDenied && isChecked ? FontWeight.bold : FontWeight.normal
                   )
                 ),
                 value: isChecked,
                 activeColor: isDenied ? Colors.red : AdminTheme.primary,
                 secondary: isChecked ? IconButton(
                   icon: const Icon(Icons.close, size: 16),
                   onPressed: () => data.toggleImagemAuth(key),
                 ) : null,
                 onChanged: (v) => data.toggleImagemAuth(key),
               );
             }),
          
          if (data.imageAuthDenied)
            Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                   Icon(Icons.warning, color: Colors.red),
                   SizedBox(width: 8),
                   Expanded(child: Text("O membro NÃO autoriza o uso de imagem. Esta restrição será visível no perfil.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

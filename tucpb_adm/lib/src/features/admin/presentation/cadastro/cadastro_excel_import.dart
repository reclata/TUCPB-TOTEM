import 'package:tucpb_adm/src/shared/utils/html_stub.dart' if (dart.library.html) 'dart:html' as html;
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastro/novo_cadastro_controller.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';
import 'package:tucpb_adm/src/features/admin/data/log_repository.dart';
import 'package:tucpb_adm/src/features/admin/data/activity_log_model.dart';
import 'package:tucpb_adm/src/features/auth/presentation/auth_user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════
// Botão de Importação no Header de Cadastros
// ═══════════════════════════════════════════════════════════
class BotoesImportExcelCadastro extends StatelessWidget {
  const BotoesImportExcelCadastro({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () => _baixarTemplate(context),
          icon: const Icon(Icons.download, size: 16),
          label: const Text('Baixar Modelo'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminTheme.primary,
            side: BorderSide(color: AdminTheme.primary),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        const SizedBox(width: 8),
        Consumer(
          builder: (ctx, ref, _) => ElevatedButton.icon(
            onPressed: () => _importarExcel(ctx, ref),
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('Importar Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  void _baixarTemplate(BuildContext context) {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    final sheet = excel['Cadastros_Modelo'];

    final headerCells = [
      'NOME COMPLETO', 'EMAIL', 'TELEFONE', 'PERFIL', 'ATIVO', 'DATA NASCIMENTO', 
      'CPF', 'ESTADO CIVIL', 'CEP', 'RUA', 'NUMERO', 'BAIRRO', 'CIDADE', 
      'RESTRICAO SAUDE', 'ALERGIAS', 'MEDICACOES', 'EMERGENCIA NOME', 'EMERGENCIA TEL', 
      'PAIS CABECA', 'MAES CABECA', 'DATA ENTRADA', 'BATIZADO CATOLICA'
    ];
    
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#3E2723'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    for (var i = 0; i < headerCells.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headerCells[i]);
      cell.cellStyle = headerStyle;
    }

    // Linha de exemplo
    final exemplo = [
      'João da Silva', 'joao@email.com', '(11) 99999-9999', 'Medium', 'Sim', '01/01/1990',
      '123.456.789-00', 'Solteiro', '01001-000', 'Rua Exemplo', '123', 'Centro', 'São Paulo',
      'Não', '', '', 'Maria Silva', '(11) 98888-8888',
      'Ogum', 'Iemanjá', '10/01/2023', 'Sim'
    ];

    for (var i = 0; i < exemplo.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
      cell.value = TextCellValue(exemplo[i]);
    }

    final bytes = excel.encode();
    if (bytes == null) return;
    final blob = html.Blob([Uint8List.fromList(bytes)], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'modelo_cadastro_tucpb.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modelo baixado com sucesso!'), backgroundColor: Colors.green),
    );
  }

  Future<void> _importarExcel(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bytes = result.files.single.bytes!;
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables['Cadastros_Modelo'];

      if (sheet == null) {
        if (context.mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planilha "Cadastros_Modelo" não encontrada.'), backgroundColor: Colors.red),
        );
        return;
      }

      int importados = 0;
      final logRepo = ref.read(logRepositoryProvider);
      final currentUser = ref.read(userDataProvider).asData?.value;

      for (var r = 1; r < sheet.maxRows; r++) {
        final row = sheet.row(r);
        if (row.isEmpty || row[0]?.value == null) continue;

        final nome = row[0]?.value?.toString() ?? '';
        final email = row[1]?.value?.toString() ?? '';
        
        if (nome.isEmpty || email.isEmpty) continue;

        // Criar estrutura do usuário (Simplificada para o toMap do Controller)
        final userData = {
          'id': const Uuid().v4(),
          'terreiroId': 'demo-terreiro',
          'nome': nome,
          'email': email,
          'telefone': row[2]?.value?.toString() ?? '',
          'perfil': row[3]?.value?.toString() ?? 'Medium',
          'ativo': (row[4]?.value?.toString().toLowerCase() == 'sim'),
          'senhaInicial': 'TUCPB',
          'dadosPessoais': {
            'dtNascimento': row[5]?.value?.toString() ?? '',
            'cpf': row[6]?.value?.toString() ?? '',
            'estadoCivil': row[7]?.value?.toString() ?? 'Solteiro',
            'endereco': {
              'cep': row[8]?.value?.toString() ?? '',
              'rua': row[9]?.value?.toString() ?? '',
              'numero': row[10]?.value?.toString() ?? '',
              'bairro': row[11]?.value?.toString() ?? '',
              'cidade': row[12]?.value?.toString() ?? '',
            },
            'restricoes': row[13]?.value?.toString(),
            'alergias': row[14]?.value?.toString(),
            'medicacao': row[15]?.value?.toString()?.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList() ?? [],
            'emergencia': {
              'nome': row[16]?.value?.toString() ?? '',
              'telefone': row[17]?.value?.toString() ?? '',
            }
          },
          'espiritual': {
            'pais': row[18]?.value?.toString()?.split(',').map((e) => e.trim()).toList() ?? [],
            'maes': row[19]?.value?.toString()?.split(',').map((e) => e.trim()).toList() ?? [],
            'entrada': row[20]?.value?.toString() ?? '',
            'batizadoCatolica': (row[21]?.value?.toString().toLowerCase() == 'sim'),
          },
          'entidades': [],
          'dataCriacao': FieldValue.serverTimestamp(),
        };

        // Salvar via repository
        // Nota: O repo precisa de um método genérico ou usaremos o Usuario.fromMap
        // Para este contexto, usaremos o firestore direto ou o repo de admin se disponível
        await FirebaseFirestore.instance.collection('usuarios').doc(userData['id'] as String).set(userData);
        
        // Log individual ou em lote? Faremos individual por simplicidade como no modal
        await logRepo.logAction(
          userId: currentUser?['uid'] ?? '',
          userName: currentUser?['nome'] ?? 'Portal Admin',
          module: 'Cadastros',
          action: LogActionType.create,
          description: 'Importou via Excel: $nome',
        );
        
        importados++;
      }

      if (context.mounted) Navigator.pop(context); // fecha loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$importados cadastros importados com sucesso!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na importação: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

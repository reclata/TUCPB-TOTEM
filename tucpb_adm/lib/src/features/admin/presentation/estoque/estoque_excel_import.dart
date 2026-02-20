import 'package:tucpb_adm/src/shared/utils/html_stub.dart' if (dart.library.html) 'dart:html' as html;
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tucpb_adm/src/features/admin/data/estoque_model.dart';
import 'package:tucpb_adm/src/features/admin/data/estoque_repository.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

// ═══════════════════════════════════════════════════════════
// Botão que aparece no header do EstoqueScreen
// ═══════════════════════════════════════════════════════════
class BotoesImportExcel extends StatelessWidget {
  const BotoesImportExcel({super.key});

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

  // ── Gera e faz download do arquivo modelo ──
  void _baixarTemplate(BuildContext context) {
    final excel = Excel.createExcel();

    // Remover sheet padrão
    excel.delete('Sheet1');

    final sheet = excel['Estoque_Modelo'];

    // ── Cabeçalho com estilo ──
    final headerCells = ['nome', 'unidade', 'quantidade', 'quantidade_minima', 'categoria'];
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

    // ── Linha de exemplo ──
    final exemplos = [
      ['Vela branca', 'un', '10', '2', 'espiritual'],
      ['Arroz branco', 'kg', '5', '1', 'cozinha'],
      ['Detergente', 'un', '3', '1', 'limpeza'],
      ['Camiseta TUCPB', 'un', '20', '5', 'shop'],
    ];

    for (var r = 0; r < exemplos.length; r++) {
      final rowStyle = CellStyle(
        backgroundColorHex: r % 2 == 0
            ? ExcelColor.fromHexString('#FFF8E1')
            : ExcelColor.fromHexString('#FFFFFF'),
      );
      for (var c = 0; c < exemplos[r].length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
        cell.value = TextCellValue(exemplos[r][c]);
        cell.cellStyle = rowStyle;
      }
    }

    // ── Larguras das colunas ──
    sheet.setColumnWidth(0, 30); // nome
    sheet.setColumnWidth(1, 15); // unidade
    sheet.setColumnWidth(2, 15); // quantidade
    sheet.setColumnWidth(3, 20); // quantidade_minima
    sheet.setColumnWidth(4, 20); // categoria

    // ── Planilha de referência: categorias e unidades ──
    final refSheet = excel['Referência'];
    refSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('Categorias válidas');
    refSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue('Unidades válidas');

    final cats = ['espiritual', 'cozinha', 'limpeza', 'shop'];
    final units = kUnidadesEstoque;
    for (var i = 0; i < cats.length; i++) {
      refSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = TextCellValue(cats[i]);
    }
    for (var i = 0; i < units.length; i++) {
      refSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = TextCellValue(units[i]);
    }

    // ── Download no browser ──
    final bytes = excel.encode();
    if (bytes == null) return;
    final blob = html.Blob([Uint8List.fromList(bytes)],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'modelo_estoque_tucpb.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modelo baixado! Preencha e importe.'), backgroundColor: Colors.green),
    );
  }

  // ── Lê o Excel e importa itens no Firestore ──
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
      builder: (_) => const _ImportandoDialog(),
    );

    try {
      final bytes = result.files.single.bytes!;
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables['Estoque_Modelo'];

      if (sheet == null) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Planilha "Estoque_Modelo" não encontrada. Use o modelo correto.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      final repo = ref.read(estoqueRepositoryProvider);
      int importados = 0;
      int erros = 0;
      final List<String> linhasComErro = [];

      for (var r = 1; r < sheet.maxRows; r++) {
        final row = sheet.row(r);
        if (row.isEmpty || row[0]?.value == null) continue;

        try {
          final nome = row[0]?.value?.toString().trim() ?? '';
          final unidade = row[1]?.value?.toString().trim() ?? 'un';
          final qtdStr = row[2]?.value?.toString().trim() ?? '0';
          final qtdMinStr = row[3]?.value?.toString().trim() ?? '1';
          final catStr = row[4]?.value?.toString().trim().toLowerCase() ?? 'espiritual';

          if (nome.isEmpty) continue;

          final quantidade = double.tryParse(qtdStr) ?? 0;
          final qtdMin = double.tryParse(qtdMinStr) ?? 1;
          final categoria = CategoriaEstoqueExt.fromKey(catStr);

          // Criar item no Firestore (sem checar duplicatas por simplicidade)
          await repo.criarItem(ItemEstoque(
            id: '',
            nome: nome,
            unidade: kUnidadesEstoque.contains(unidade) ? unidade : 'un',
            categoria: categoria,
            quantidadeAtual: quantidade,
            quantidadeMinima: qtdMin,
            dataCriacao: DateTime.now(),
            dataAtualizacao: DateTime.now(),
          ));
          importados++;
        } catch (_) {
          erros++;
          linhasComErro.add('Linha ${r + 1}');
        }
      }

      if (context.mounted) Navigator.pop(context); // fecha loading
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => _ResultadoImportDialog(
            importados: importados,
            erros: erros,
            linhasComErro: linhasComErro,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao ler arquivo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ── Dialog de loading ──
class _ImportandoDialog extends StatelessWidget {
  const _ImportandoDialog();

  @override
  Widget build(BuildContext context) {
    return const Dialog(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Importando itens...'),
          ],
        ),
      ),
    );
  }
}

// ── Dialog de resultado ──
class _ResultadoImportDialog extends StatelessWidget {
  final int importados, erros;
  final List<String> linhasComErro;
  const _ResultadoImportDialog({required this.importados, required this.erros, required this.linhasComErro});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        Icon(importados > 0 ? Icons.check_circle : Icons.error, color: importados > 0 ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        const Text('Resultado da Importação'),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (importados > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.check, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text('$importados item(ns) importado(s) com sucesso!', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ]),
            ),
          if (erros > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.warning, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text('$erros erro(s) encontrado(s):', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ]),
                  ...linhasComErro.map((l) => Text(' • $l', style: const TextStyle(fontSize: 12, color: Colors.red))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text('Dica: Verifique se as colunas estão no formato correto e se as categorias/unidades são válidas.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
      ],
    );
  }
}

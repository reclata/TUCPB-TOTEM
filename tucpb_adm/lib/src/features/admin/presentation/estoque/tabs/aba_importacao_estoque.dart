import 'dart:html' as html;
import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border, BorderStyle;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tucpb_adm/src/features/admin/data/estoque_model.dart';
import 'package:tucpb_adm/src/features/admin/data/estoque_repository.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';

class AbaImportacaoEstoque extends ConsumerStatefulWidget {
  const AbaImportacaoEstoque({super.key});

  @override
  ConsumerState<AbaImportacaoEstoque> createState() => _AbaImportacaoEstoqueState();
}

class _AbaImportacaoEstoqueState extends ConsumerState<AbaImportacaoEstoque> {
  bool _importando = false;
  int? _importados;
  int? _erros;
  List<String> _linhasComErro = [];
  String? _arquivoNome;

  // ══════════════════════════════════════════
  // Gerar e baixar template Excel
  // ══════════════════════════════════════════
  void _baixarTemplate() {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    final sheet = excel['Estoque_Modelo'];

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#3E2723'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    final cols = ['nome', 'unidade', 'quantidade', 'quantidade_minima', 'categoria'];
    for (var i = 0; i < cols.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(cols[i]);
      cell.cellStyle = headerStyle;
    }

    final exemplos = [
      ['Vela branca', 'un', '10', '2', 'espiritual'],
      ['Vela preta', 'un', '5', '2', 'espiritual'],
      ['Arroz branco', 'kg', '5', '1', 'cozinha'],
      ['Feijão preto', 'kg', '3', '1', 'cozinha'],
      ['Detergente', 'un', '4', '1', 'limpeza'],
      ['Sabão em pó', 'un', '2', '1', 'limpeza'],
      ['Camiseta TUCPB P', 'un', '10', '3', 'shop'],
      ['Camiseta TUCPB M', 'un', '10', '3', 'shop'],
    ];

    for (var r = 0; r < exemplos.length; r++) {
      final bg = r % 2 == 0
          ? ExcelColor.fromHexString('#FFF8E1')
          : ExcelColor.fromHexString('#FFFFFF');
      for (var c = 0; c < exemplos[r].length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
        cell.value = TextCellValue(exemplos[r][c]);
        cell.cellStyle = CellStyle(backgroundColorHex: bg);
      }
    }

    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 20);

    // Aba de referência
    final ref = excel['Referência'];
    ref.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('Categorias válidas');
    ref.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue('Unidades válidas');
    final cats = ['espiritual', 'cozinha', 'limpeza', 'shop'];
    for (var i = 0; i < cats.length; i++) {
      ref.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = TextCellValue(cats[i]);
    }
    for (var i = 0; i < kUnidadesEstoque.length; i++) {
      ref.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = TextCellValue(kUnidadesEstoque[i]);
    }

    final bytes = excel.encode();
    if (bytes == null) return;
    final blob = html.Blob(
      [Uint8List.fromList(bytes)],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'modelo_estoque_tucpb.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modelo baixado! Preencha e importe.'), backgroundColor: Colors.green),
    );
  }

  // ══════════════════════════════════════════
  // Importar Excel
  // ══════════════════════════════════════════
  Future<void> _importarExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() {
      _importando = true;
      _importados = null;
      _erros = null;
      _linhasComErro = [];
      _arquivoNome = result.files.single.name;
    });

    try {
      final bytes = result.files.single.bytes!;
      final excelFile = Excel.decodeBytes(bytes);
      final sheet = excelFile.tables['Estoque_Modelo'];

      if (sheet == null) {
        setState(() => _importando = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Planilha "Estoque_Modelo" não encontrada. Use o modelo oficial.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final repo = ref.read(estoqueRepositoryProvider);
      int ok = 0;
      int err = 0;
      final erros = <String>[];

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

          await repo.criarItem(ItemEstoque(
            id: '',
            nome: nome,
            unidade: kUnidadesEstoque.contains(unidade) ? unidade : 'un',
            categoria: CategoriaEstoqueExt.fromKey(catStr),
            quantidadeAtual: double.tryParse(qtdStr) ?? 0,
            quantidadeMinima: double.tryParse(qtdMinStr) ?? 1,
            dataCriacao: DateTime.now(),
            dataAtualizacao: DateTime.now(),
          ));
          ok++;
        } catch (_) {
          err++;
          erros.add('Linha ${r + 1}');
        }
      }

      setState(() {
        _importando = false;
        _importados = ok;
        _erros = err;
        _linhasComErro = erros;
      });
    } catch (e) {
      setState(() => _importando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao ler arquivo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Título ──
              Text('Importação via Excel',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AdminTheme.textPrimary)),
              const SizedBox(height: 4),
              const Text(
                'Cadastre múltiplos itens de estoque de uma só vez usando uma planilha Excel.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // ── Passo 1: Baixar modelo ──
              _StepCard(
                numero: 1,
                titulo: 'Baixe o modelo oficial',
                descricao: 'Clique no botão abaixo para baixar a planilha padrão já com exemplos preenchidos.',
                cor: Colors.indigo,
                icone: Icons.download_rounded,
                acao: ElevatedButton.icon(
                  onPressed: _baixarTemplate,
                  icon: const Icon(Icons.download),
                  label: const Text('Baixar modelo_estoque_tucpb.xlsx'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Passo 2: Preencher ──
              _StepCard(
                numero: 2,
                titulo: 'Preencha as colunas',
                descricao: 'Abra o arquivo no Excel ou Google Sheets e preencha cada linha com um item.',
                cor: Colors.teal,
                icone: Icons.table_chart_outlined,
                acao: _TabelaColunas(),
              ),
              const SizedBox(height: 16),

              // ── Passo 3: Importar ──
              _StepCard(
                numero: 3,
                titulo: 'Importe o arquivo',
                descricao: 'Selecione o arquivo preenchido para cadastrar todos os itens automaticamente.',
                cor: Colors.green,
                icone: Icons.upload_file,
                acao: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _importando ? null : _importarExcel,
                      icon: _importando
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.upload_file),
                      label: Text(_importando ? 'Importando...' : 'Selecionar arquivo .xlsx'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                    if (_arquivoNome != null && !_importando) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.attach_file, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(_arquivoNome!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Resultado da importação ──
              if (_importados != null) _ResultadoCard(
                importados: _importados!,
                erros: _erros!,
                linhasComErro: _linhasComErro,
              ),

              // ── Alerta de dicas ──
              const SizedBox(height: 8),
              _DicasCard(),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════
// Widgets auxiliares
// ════════════════════

class _StepCard extends StatelessWidget {
  final int numero;
  final String titulo, descricao;
  final Color cor;
  final IconData icone;
  final Widget acao;
  const _StepCard({
    required this.numero, required this.titulo, required this.descricao,
    required this.cor, required this.icone, required this.acao,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cor.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Text('$numero', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Icon(icone, color: cor, size: 20),
              const SizedBox(width: 8),
              Text(titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cor)),
            ]),
            const SizedBox(height: 8),
            Text(descricao, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 14),
            acao,
          ],
        ),
      ),
    );
  }
}

class _TabelaColunas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colunas = [
      ['nome', 'Obrigatório', 'Nome do item (ex: Vela branca, Arroz 5kg)', Colors.red],
      ['unidade', 'Obrigatório', 'un / kg / g / L / mL / cx / pct / fd / par / rolo', Colors.red],
      ['quantidade', 'Obrigatório', 'Quantidade atual em estoque (ex: 10)', Colors.red],
      ['quantidade_minima', 'Opcional', 'Nivel mínimo para alertas (padrão: 1)', Colors.orange],
      ['categoria', 'Obrigatório', 'espiritual / cozinha / limpeza / shop', Colors.red],
    ];

    return Table(
      border: TableBorder.all(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: FlexColumnWidth(),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: ['Coluna', 'Tipo', 'Instrução'].map((h) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          )).toList(),
        ),
        ...colunas.map((c) => TableRow(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(c[0] as String, style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.bold,
                color: Colors.indigo)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (c[3] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(c[1] as String, style: TextStyle(fontSize: 10, color: c[3] as Color, fontWeight: FontWeight.bold)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(c[2] as String, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
        ])),
      ],
    );
  }
}

class _ResultadoCard extends StatelessWidget {
  final int importados, erros;
  final List<String> linhasComErro;
  const _ResultadoCard({required this.importados, required this.erros, required this.linhasComErro});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: importados > 0 ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: importados > 0 ? Colors.green.shade300 : Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(importados > 0 ? Icons.check_circle : Icons.error,
                color: importados > 0 ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Text('Resultado da Importação', style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: importados > 0 ? Colors.green[800] : Colors.red[800],
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _StatChip(label: 'Importados', value: '$importados', color: Colors.green),
            const SizedBox(width: 8),
            _StatChip(label: 'Erros', value: '$erros', color: Colors.red),
          ]),
          if (linhasComErro.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Linhas com erro: ${linhasComErro.join(", ")}',
                style: const TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ]),
    );
  }
}

class _DicasCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.lightbulb_outline, color: Colors.blue, size: 16),
            SizedBox(width: 6),
            Text('Dicas importantes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          ...[
            'Use sempre o modelo oficial para garantir que as colunas estejam na ordem correta.',
            'A planilha deve ter a aba chamada exatamente "Estoque_Modelo".',
            'Não apague o cabeçalho (primeira linha com os nomes das colunas).',
            'Itens com o mesmo nome serão cadastrados como itens duplicados — verifique antes de importar.',
            'Confira os valores válidos de categoria e unidade na aba "Referência" do modelo.',
          ].map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('• ', style: TextStyle(color: Colors.blue)),
              Expanded(child: Text(d, style: const TextStyle(fontSize: 12, color: Colors.blue))),
            ]),
          )),
        ],
      ),
    );
  }
}

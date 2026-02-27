
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gertec_pos_printer/gertec_pos_printer.dart';
import 'package:gertec_pos_printer/printer/setup/text_print.dart';
import 'package:gertec_pos_printer/printer/domain/enum/font_type.dart';
import 'package:gertec_pos_printer/printer/domain/enum/text_alignment.dart';
import 'package:gertec_pos_printer/printer/domain/enum/gertec_type.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:terreiro_queue_system/src/shared/setup/printer_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

final printerServiceProvider = Provider((ref) => PrinterService());

class PrinterService {

  Future<void> printTicket({
    required String terreiroName,
    required String giraName,
    required String entityName,
    required String mediumName,
    required String mediumInitials,
    required String ticketCode,
    required String pixKey,
    required DateTime date,
  }) async {
    if (kIsWeb) {
      _mockPrint(terreiroName, giraName, entityName, mediumName, ticketCode, date);
      return;
    }

    final types = [GertecType.sk210, GertecType.gpos700, GertecType.network];
    
    for (final type in types) {
      try {
        debugPrint('[PRINTER] Preparando instância para GertecType: $type');
        final printer = GertecPOSPrinter(gertecType: type);
        await Future.delayed(const Duration(milliseconds: 500));
        
        final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(date);

        if (type == GertecType.sk210) {
          debugPrint('[PRINTER] >>> INICIANDO RENDERIZAÇÃO BITMAP (v10) PARA SK210 <<<');
          final bytes = await _generateTicketBitmap(
            terreiroName: terreiroName,
            giraName: giraName,
            entityName: entityName,
            mediumName: mediumName,
            mediumInitials: mediumInitials,
            ticketCode: ticketCode,
            dateStr: dateStr,
          );

          debugPrint('[PRINTER] Enviando BITMAP (${bytes.length} bytes) para o hardware...');
          await printer.instance.printBitmap(bytes);
        } else if (type == GertecType.network) {
          debugPrint('[PRINTER] >>> CONFIGURANDO IMPRESSÃO VIA REDE <<<');
          final bytes = await _generateTicketBitmap(
            terreiroName: terreiroName,
            giraName: giraName,
            entityName: entityName,
            mediumName: mediumName,
            mediumInitials: mediumInitials,
            ticketCode: ticketCode,
            dateStr: dateStr,
          );
          await _printViaNetwork(bytes);
        } else {
          TextPrint txt(String msg, {bool bold = false, TextAlignment align = TextAlignment.left}) =>
              TextPrint(message: msg, bold: bold, alignment: align, fontType: FontType.def);

          final lines = [
            txt('================================', align: TextAlignment.center),
            txt(terreiroName.toUpperCase(), bold: true, align: TextAlignment.center),
            txt('Gira: $giraName', align: TextAlignment.center),
            txt('================================', align: TextAlignment.center),
            txt(' '),
            txt('ENTIDADE:'),
            txt(entityName.toUpperCase(), bold: true, align: TextAlignment.center),
            txt(' '),
            txt('MEDIUM: $mediumName ($mediumInitials)'),
            txt(' '),
            txt('================================', align: TextAlignment.center),
            txt('SENHA:', bold: true, align: TextAlignment.center),
            txt(ticketCode, bold: true, align: TextAlignment.center),
            txt('================================', align: TextAlignment.center),
            txt(' '),
            txt(dateStr, align: TextAlignment.center),
            txt(' '),
            txt('Axe! Salve os Guias!', bold: true, align: TextAlignment.center),
            txt('Aguarde ser chamado(a).', align: TextAlignment.center),
            txt(' '),
          ];
          await printer.instance.printTextList(lines);
        }

        debugPrint('[PRINTER] Avancando papel e cortando ticket único...');
        await printer.instance.wrapLine(type == GertecType.sk210 ? 1 : 3);
        await printer.instance.cut();

        debugPrint('[PRINTER] Impressão concluída com sucesso usando $type.');
        return; 
      } catch (e, stack) {
        debugPrint('[PRINTER] Erro com GertecType $type: $e');
        debugPrint('[PRINTER] Stack: $stack');
      }
    }
    
    debugPrint('[PRINTER] AVISO: Impressão falhou com todos os tipos de Gertec disponíveis.');
  }

  Future<Uint8List> _generateTicketBitmap({
    required String terreiroName,
    required String giraName,
    required String entityName,
    required String mediumName,
    required String mediumInitials,
    required String ticketCode,
    required String dateStr,
  }) async {
    const double width = 384; 
    const double padding = 20;
    
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, 2000), paint);

    double currentY = padding;

    // Retirada carga de imagem da Logo, trocada por texto

    void drawText(String text, {double fontSize = 20, bool bold = false, bool center = false}) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: center ? TextAlign.center : TextAlign.left,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ))
      ..pushStyle(ui.TextStyle(color: Colors.black))
      ..addText(text);

      final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: width - (padding * 2)));
      
      canvas.drawParagraph(paragraph, Offset(padding, currentY));
      currentY += paragraph.height + 15; // Aumentado de 5 para 15 para separar mais as linhas
    }

    // 1. Cabecalho T.U.C.P.B no lugar da Logo
    currentY = 40;
    drawText('T.U.C.P.B.', bold: true, fontSize: 50, center: true);
    currentY += 20;

    // 2. Título da Gira (Não duplicar 'GIRA DE')
    final String giraTitleUpper = giraName.toUpperCase().trim();
    if (giraTitleUpper.startsWith('GIRA DE')) {
      drawText(giraTitleUpper, bold: true, fontSize: 30, center: true);
    } else {
      drawText('GIRA DE $giraTitleUpper', bold: true, fontSize: 30, center: true);
    }
    
    // 3. Data e Hora
    drawText(dateStr, fontSize: 18, center: true);

    // 4. Entidade Direta (Sem título, +20% -> 42)
    drawText(entityName.toUpperCase(), bold: true, fontSize: 42, center: true);

    // 5. Médium Simplificado (Primeiro e Último Nome, Sem título)
    final mediumParts = mediumName.trim().split(' ');
    final displayName = mediumParts.length > 1 
        ? '${mediumParts.first} ${mediumParts.last}' 
        : mediumName;
    drawText(displayName.toUpperCase(), fontSize: 18, center: true);

    // 6. Senha (Centralizada)
    drawText('SENHA:', bold: true, fontSize: 22, center: true);
    drawText(ticketCode, bold: true, fontSize: 70, center: true); 

    // 7. Rodapé (Novas frases)
    drawText('Axé!', bold: true, fontSize: 24, center: true);
    drawText('Os orixás são bons o tempo todo!', fontSize: 18, center: true);
    
    // Pequeno respiro extra no fim do bitmap para evitar corte prematuro
    currentY += 40;
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), (currentY + padding).toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }

  Future<void> _printViaNetwork(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString(PrinterConfig.ipKey) ?? PrinterConfig.defaultIp;
    final port = prefs.getInt(PrinterConfig.portKey) ?? PrinterConfig.defaultPort;
    
    final url = Uri.parse('http://$ip:$port/print');
    try {
      debugPrint('[PRINTER] Enviando para $url...');
      final response = await http.post(
        url,
        body: bytes,
        headers: {'Content-Type': 'application/octet-stream'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        debugPrint('[PRINTER] Impressão via rede enviada com sucesso!');
      } else {
        debugPrint('[PRINTER] Erro na resposta da rede: ${response.statusCode}');
        throw Exception('Erro de rede: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[PRINTER] Falha na impressão via rede: $e');
      rethrow;
    }
  }

  void _mockPrint(String terreiro, String gira, String entity, String medium, String code, DateTime date) {
    debugPrint('--- [MOCK] IMPRESSÃO DE SENHA ---');
    debugPrint('Terreiro: $terreiro | Gira: $gira');
    debugPrint('Entidade: $entity | Médium: $medium');
    debugPrint('SENHA: $code');
    debugPrint('Data: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}');
    debugPrint('---------------------------------');
  }
}

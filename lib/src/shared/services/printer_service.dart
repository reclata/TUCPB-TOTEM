
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

    final types = [GertecType.sk210, GertecType.gpos700];
    
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

    // Carregar imagem da Logo
    final ByteData data = await rootBundle.load('assets/images/logo.png');
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 270);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image logoImg = fi.image;

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

    // 1. Logo do Terreiro (Ajustada para 270px e centralizada no topo)
    // Retornado para Offset 0 para evitar cortes reportados na v24
    canvas.drawImage(logoImg, Offset((width - 270) / 2, 0), paint); 
    currentY = 280; // Recalibrado para dar um pequeno respiro após a imagem inteira

    // 2. Título da Gira (GIRA DE [TEMA]) - Letra 50% maior (30)
    drawText('GIRA DE ${giraName.toUpperCase()}', bold: true, fontSize: 30, center: true);
    
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

  void _mockPrint(String terreiro, String gira, String entity, String medium, String code, DateTime date) {
    debugPrint('--- [MOCK] IMPRESSÃO DE SENHA ---');
    debugPrint('Terreiro: $terreiro | Gira: $gira');
    debugPrint('Entidade: $entity | Médium: $medium');
    debugPrint('SENHA: $code');
    debugPrint('Data: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}');
    debugPrint('---------------------------------');
  }
}

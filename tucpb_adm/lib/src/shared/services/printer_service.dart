
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final printerServiceProvider = Provider((ref) => AdminPrinterService());

class AdminPrinterService {
  final String printerIp = '192.168.1.17';
  final int printerPort = 43645;

  Future<void> imprimirRecibo({
    required String usuario,
    required String tipo,
    required double valor,
    required DateTime data,
    String? descricao,
  }) async {
    final fmt = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dataStr = DateFormat('dd/MM/yyyy HH:mm').format(data);

    debugPrint('[PRINTER] Gerando recibo para $usuario...');
    
    // Para simplificar no admin (Web/Desktop), enviamos um texto formatado
    // Se o G-Printer aceitar texto puro ou JSON, seria assim:
    final content = """
================================
       RECIBO T.U.C.P.B.
================================
PAGAMENTO: $tipo
VALOR: ${fmt.format(valor)}
USUARIO: $usuario
DATA: $dataStr
--------------------------------
${descricao ?? ''}
================================
      AGRADECEMOS O SEU AXÉ!
================================
""";

    final url = Uri.parse('http://$printerIp:$printerPort/print_text');
    try {
      final response = await http.post(
        url,
        body: content,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('Erro na impressora: ${response.statusCode}');
      }
      debugPrint('[PRINTER] Recibo enviado com sucesso!');
    } catch (e) {
      debugPrint('[PRINTER] Erro ao imprimir recibo: $e');
      // Fallback para log
      debugPrint(content);
      rethrow;
    }
  }
}

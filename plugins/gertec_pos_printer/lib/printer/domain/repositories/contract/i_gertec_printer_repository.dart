import 'package:gertec_pos_printer/printer/setup/text_print.dart';

abstract class IGertecPrinterRepository {
  Future<dynamic> printText(Map<String, dynamic> params);
  Future<dynamic> printTextList(List<TextPrint> params);
  Future<dynamic> barcodePrint(Map<String, dynamic> params);
  Future<dynamic> qrcodePrint(Map<String, dynamic> params);
  Future<dynamic> wrapLine(int lines);
  Future<dynamic> cut();
  Future<dynamic> printBitmap(List<int> bytes);
  Future<dynamic> checkStatusPrinter();
}

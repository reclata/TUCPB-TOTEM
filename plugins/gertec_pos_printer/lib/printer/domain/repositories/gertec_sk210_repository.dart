import 'package:flutter/services.dart';
import 'package:gertec_pos_printer/printer/setup/text_print.dart';
import 'package:gertec_pos_printer/printer/domain/repositories/contract/i_gertec_printer_repository.dart';
import '../../setup/constants.dart';
import '../../style/gertec_printer_style.dart';

class GertecSK210Repository implements IGertecPrinterRepository {
  static const MethodChannel _channel = MethodChannel(channelName);

  @override
  Future<dynamic> barcodePrint(Map<String, dynamic> params) async {
    return await _channel.invokeMethod('callPrinterBarcode210', {'params': params});
  }

  @override
  Future<dynamic> checkStatusPrinter() async {
    return await _channel.invokeMethod('callPrinterStatus210', {});
  }

  @override
  Future<dynamic> cut() async {
    return await _channel.invokeMethod('callCut210', {'mode': 0});
  }

  @override
  Future<dynamic> printText(Map<String, dynamic> params) async {
    return await _channel.invokeMethod('callPrint210', params);
  }

  @override
  Future<dynamic> printTextList(List<TextPrint> textPrintList) async {
    final List<Map<String, dynamic>> listParams = textPrintList
        .map((line) => GertecPrinterStyle.lineToMethodChannel(line))
        .toList();

    return await _channel.invokeMethod('callPrintTextList210', {
      'params': listParams,
    });
  }

  @override
  Future<dynamic> wrapLine(int lines) async {
    return await _channel.invokeMethod('callPrinterWrap210', {'linesWrap': lines});
  }

  @override
  Future<dynamic> printBitmap(List<int> bytes) async {
    return await _channel.invokeMethod('callPrintBitmap210', {
      'bitmap': bytes,
    });
  }

  @override
  Future<dynamic> qrcodePrint(Map<String, dynamic> params) async {
    return await _channel.invokeMethod('callPrinterQRCode210', {'params': params});
  }
}

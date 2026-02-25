import 'package:flutter/services.dart';
import 'package:gertec_pos_printer/printer/domain/exception/gertec_printer_exception.dart';
import 'package:gertec_pos_printer/printer/setup/text_print.dart';
import 'package:gertec_pos_printer/printer/style/gertec_printer_style.dart';
import '../../setup/constants.dart';
import 'contract/i_gertec_printer_repository.dart';

class GertecPrinterRepository implements IGertecPrinterRepository {
  static const MethodChannel _channel = MethodChannel(channelName);

  @override
  Future<dynamic> barcodePrint(Map<String, dynamic> params) async {
    try {
      return await _channel.invokeMethod('callPrintGertec', params);
    } catch (e) {
      throw GertecPrinterException(e.toString());
    }
  }

  @override
  Future<dynamic> checkStatusPrinter() async {
    try {
      return await _channel.invokeMethod('callStatusGertec');
    } catch (e) {
      throw GertecPrinterException(e.toString());
    }
  }

  @override
  Future<dynamic> cut() async {
    try {
      return await _channel.invokeMethod('callCutGertec');
    } catch (e) {
      throw GertecPrinterException(e.toString());
    }
  }

  @override
  Future<dynamic> printText(Map<String, dynamic> params) async {
    try {
      return await _channel.invokeMethod('callPrintGertec', params);
    } catch (e) {
      throw GertecPrinterException(e.toString());
    }
  }

  @override
  Future<dynamic> printTextList(List<TextPrint> textPrintList) async {
    try {
      for (var line in textPrintList) {
        await _channel.invokeMethod('callPrintGertec', GertecPrinterStyle.lineToMethodChannel(line));
      }
      return await cut();
    } catch (e) {
      throw GertecPrinterException(e.toString());
    }
  }

  @override
  Future<dynamic> wrapLine(int lineQuantity) async {
    try {
      return await _channel.invokeMethod('callNextLine', {'lineQuantity': lineQuantity});
    } catch (e) {
      throw GertecPrinterException(e.toString());
    }
  }

  @override
  Future<dynamic> printBitmap(List<int> bytes) async {
    return null;
  }

  @override
  Future<dynamic> qrcodePrint(Map<String, dynamic> params) async {
    try {
      return await _channel.invokeMethod('callPrintGertec', params);
    } catch (e) {
      throw GertecPrinterException(e.toString());
    }
  }
}

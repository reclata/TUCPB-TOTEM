import 'package:gertec_pos_printer/printer/domain/enum/gertec_type.dart';
import 'package:gertec_pos_printer/printer/setup/text_print.dart';

import 'domain/repositories/contract/i_gertec_printer_repository.dart';
import 'domain/repositories/gertec_printer_repository.dart';
import 'domain/repositories/gertec_sk210_repository.dart';

class GertecPosPrinterController extends IGertecPrinterRepository {
  final GertecType _gertecType;

  final GertecPrinterRepository _gertecPrinterRepository =
      GertecPrinterRepository();
  final GertecSK210Repository _gertecSK210Repository = GertecSK210Repository();

  GertecPosPrinterController({required GertecType gertecType})
      : _gertecType = gertecType;

  @override
  Future<dynamic> barcodePrint(Map<String, dynamic> params) async {
    if (_gertecType == GertecType.gpos700) {
      return await _gertecPrinterRepository.barcodePrint(params);
    }
    return await _gertecSK210Repository.barcodePrint(params);
  }

  @override
  Future<dynamic> checkStatusPrinter() async {
    if (_gertecType == GertecType.gpos700) {
      return await _gertecPrinterRepository.checkStatusPrinter();
    }
    return await _gertecSK210Repository.checkStatusPrinter();
  }

  @override
  Future<dynamic> cut() async {
    if (_gertecType == GertecType.gpos700) {
      return await _gertecPrinterRepository.cut();
    }
    return await _gertecSK210Repository.cut();
  }

  @override
  Future<dynamic> printText(Map<String, dynamic> params) async {
    if (_gertecType == GertecType.gpos700) {
      return await _gertecPrinterRepository.printText(params);
    }
    return await _gertecSK210Repository.printText(params);
  }

  @override
  Future<dynamic> printTextList(List<TextPrint> textPrintList) async {
    if (_gertecType == GertecType.gpos700) {
      return await _gertecPrinterRepository.printTextList(textPrintList);
    }
    return await _gertecSK210Repository.printTextList(textPrintList);
  }

  @override
  Future<dynamic> wrapLine(int lines) async {
    if (_gertecType == GertecType.gpos700) {
      return await _gertecPrinterRepository.wrapLine(lines);
    }
    return await _gertecSK210Repository.wrapLine(lines);
  }

  @override
  Future<dynamic> printBitmap(List<int> bytes) async {
    if (_gertecType == GertecType.gpos700) {
      return null; 
    }
    return await _gertecSK210Repository.printBitmap(bytes);
  }

  @override
  Future<dynamic> qrcodePrint(Map<String, dynamic> params) async {
    if (_gertecType == GertecType.gpos700) {
      return await _gertecPrinterRepository.qrcodePrint(params);
    }
    return await _gertecSK210Repository.qrcodePrint(params);
  }
}

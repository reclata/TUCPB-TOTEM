
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final printerServiceProvider = Provider((ref) => PrinterService());

class PrinterService {
  // Mock implementation for development/web
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
    debugPrint("--- MOCK PRINTING TICKET ---");
    debugPrint("Terreiro: $terreiroName");
    debugPrint("Gira: $giraName");
    debugPrint("Entity: $entityName");
    debugPrint("Medium: $mediumName ($mediumInitials)");
    debugPrint("CODE: $ticketCode");
    debugPrint("PIX: $pixKey");
    debugPrint("AXE PELA CONTRIBUIÇÃO");
    debugPrint("----------------------------");
    
    // Simulate delay
    await Future.delayed(const Duration(seconds: 2));
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  // Cores baseadas no pedido (Marrom e Off-white) e na imagem de referência
  static const Color primary = Color(0xFF5D4037); // Marrom Principal
  static const Color primaryLight = Color(0xFF8D6E63); // Marrom Claro
  static const Color background = Color(0xFFF5F6FA); // Off-white/Cinza muito claro para fundo
  static const Color surface = Colors.white; // Branco para cards e sidebar
  static const Color textPrimary = Color(0xFF3E2723); // Texto Escuro (Marrom quase preto)
  static const Color textSecondary = Color(0xFF8D6E63); // Texto Secundário
  static const Color secondary = Color(0xFF8D6E63); // Cor Secundária (Alias para compatibilidade)
  
  // Cores de destaque para gráficos e ícones (inspirado na imagem Unity mas adaptado)
  static const Color accentBlue = Color(0xFF29B6F6);
  static const Color accentPurple = Color(0xFFAB47BC);
  static const Color accentOrange = Color(0xFFFFA726);
  static const Color accentRed = Color(0xFFEF5350);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        background: background,
        surface: surface,
      ),
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(color: primary, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: primary),
    );
  }
}

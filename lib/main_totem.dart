import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:terreiro_queue_system/firebase_options.dart';
import 'package:terreiro_queue_system/main.dart';
import 'package:terreiro_queue_system/src/features/kiosk/presentation/kiosk_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  GoogleFonts.config.allowRuntimeFetching = false;

  // Inicia o modo Kiosk (bloqueia a saída do app no Android)
  try {
    await startKioskMode();
  } catch (e) {
    debugPrint('Erro ao iniciar modo Kiosk: $e');
  }

  final totemRouter = GoRouter(
    initialLocation: '/kiosk', // Abre direto no Totem
    routes: [
      GoRoute(
        path: '/kiosk',
        builder: (context, state) => const KioskScreen(),
      ),
    ],
  );

  runApp(ProviderScope(child: TerreiroApp(routerConfig: totemRouter)));
}

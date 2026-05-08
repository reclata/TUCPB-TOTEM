import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:terreiro_queue_system/firebase_options.dart';
import 'package:terreiro_queue_system/main.dart';
import 'package:terreiro_queue_system/src/features/tv/presentation/tv_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  GoogleFonts.config.allowRuntimeFetching = false;

  final tvRouter = GoRouter(
    initialLocation: '/tv/tv-painel-1', // Abre direto no painel da TV
    routes: [
      GoRoute(
        path: '/tv/:panelId',
        builder: (context, state) => TvScreen(panelId: state.pathParameters['panelId']!),
      ),
    ],
  );

  runApp(ProviderScope(child: TerreiroApp(routerConfig: tvRouter)));
}

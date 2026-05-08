import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:terreiro_queue_system/firebase_options.dart';
import 'package:terreiro_queue_system/main.dart';
import 'package:terreiro_queue_system/src/features/auth/presentation/login_screen.dart';
import 'package:terreiro_queue_system/src/features/admin/presentation/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  GoogleFonts.config.allowRuntimeFetching = false;

  final adminRouter = GoRouter(
    initialLocation: '/login', // Abre na tela de login
    refreshListenable: GoInfra.authStream,
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/admin';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
    ],
  );

  runApp(ProviderScope(child: TerreiroApp(routerConfig: adminRouter)));
}

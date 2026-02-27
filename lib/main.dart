
import 'package:firebase_auth/firebase_auth.dart';
import 'package:terreiro_queue_system/src/features/auth/presentation/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Screens
import 'package:terreiro_queue_system/src/features/kiosk/presentation/kiosk_screen.dart';
import 'package:terreiro_queue_system/src/features/admin/presentation/admin_screen.dart';
import 'package:terreiro_queue_system/src/features/tv/presentation/tv_screen.dart';
import 'package:terreiro_queue_system/src/features/queue/presentation/queue_web_screen.dart';
import 'package:terreiro_queue_system/src/shared/services/printer_service.dart';
import 'package:terreiro_queue_system/firebase_options.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:terreiro_queue_system/src/shared/providers/global_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar formatação de data para pt_BR
  await initializeDateFormatting('pt_BR', null);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Desabilitar download de fontes da rede — usar apenas fontes bundled no app
    // Isso evita texto invisível quando o dispositivo não tem internet
    GoogleFonts.config.allowRuntimeFetching = false;
    
    // No Kiosk (Android), autenticar anonimamente para permitir leitura do Firestore
    // sem exigir login manual do usuário
    if (!kIsWeb) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
          debugPrint('[KIOSK] Autenticação anônima realizada com sucesso.');
        } else {
          debugPrint('[KIOSK] Usuário já autenticado: ${currentUser.uid}');
        }
      } catch (authError) {
        debugPrint('[KIOSK] Falha na autenticação anônima: $authError');
      }
    }
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }



  runApp(const ProviderScope(child: TerreiroApp()));
}

// Router configuration with Auth Guard
final _router = GoRouter(
  initialLocation: kIsWeb ? '/login' : '/kiosk',
  refreshListenable: GoInfra.authStream, // Listen to auth changes
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isLoggingIn = state.uri.toString() == '/login';
    final isPublicRoute = state.uri.toString().startsWith('/tv') || 
                          state.uri.toString().startsWith('/queue') ||
                          state.uri.toString().startsWith('/kiosk');

    if (!isLoggedIn && !isPublicRoute && !isLoggingIn) {
      return '/login';
    }
    
    // Once logged in, if on login page, go to admin
    if (isLoggedIn && isLoggingIn) {
      return '/admin';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) {
        _setTitle('TUCPB_TABLET');
        return NoTransitionPage(child: const LoginScreen());
      },
    ),
    GoRoute(
      path: '/kiosk',
      pageBuilder: (context, state) {
        _setTitle('TUCPB_KIOSK');
        return NoTransitionPage(child: const KioskScreen());
      },
    ),
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) {
        debugPrint('[ROUTER] Navegando para Admin Tablet (Web Mode: $kIsWeb)');
        _setTitle('TUCPB_TABLET');
        return NoTransitionPage(child: const AdminScreen());
      },
    ),
    GoRoute(
      path: '/tv/:terreiroId',
      pageBuilder: (context, state) {
        _setTitle('TUCPB_SENHAS');
        return NoTransitionPage(
          child: TvScreen(terreiroId: state.pathParameters['terreiroId']!),
        );
      },
    ),
    GoRoute(
      path: '/queue/:terreiroId',
      pageBuilder: (context, state) {
        _setTitle('TUCPB_KIOSK');
        return NoTransitionPage(
          child: QueueWebScreen(terreiroId: state.pathParameters['terreiroId']!),
        );
      },
    ),
  ],
);

void _setTitle(String title) {
  // Muda o título da aba do navegador
  SystemChrome.setApplicationSwitcherDescription(
    ApplicationSwitcherDescription(label: title, primaryColor: 0xFF4E342E),
  );
}

// Helper for GoRouter listenable
class GoInfra {
  static final authStream = GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges());
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }
  late final dynamic _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class TerreiroApp extends ConsumerWidget {
  const TerreiroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'TUCPB Token',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          primary: Colors.brown,
          secondary: Colors.amber, 
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: Colors.brown[50],
          selectedIconTheme: const IconThemeData(color: Colors.brown),
          unselectedIconTheme: const IconThemeData(color: Colors.black54),
          labelType: NavigationRailLabelType.none,
        ),
      ),
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}

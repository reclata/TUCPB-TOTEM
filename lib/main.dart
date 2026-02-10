
import 'package:firebase_auth/firebase_auth.dart';
import 'src/features/auth/presentation/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// Screens
import 'src/features/kiosk/presentation/kiosk_screen.dart';
import 'src/features/admin/presentation/admin_screen.dart';
import 'src/features/tv/presentation/tv_screen.dart';
import 'src/features/queue/presentation/queue_web_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Habilitar persistência offline para que os dados fiquem no navegador
    // mesmo após fechar a aba ou reiniciar o aplicativo.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  runApp(const ProviderScope(child: TerreiroApp()));
}

// Router configuration with Auth Guard
final _router = GoRouter(
  initialLocation: '/admin',
  refreshListenable: GoInfra.authStream, // Listen to auth changes
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isLoggingIn = state.uri.toString() == '/login';
    final isPublicRoute = state.uri.toString().startsWith('/tv') || 
                          state.uri.toString().startsWith('/queue');

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
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/kiosk',
      builder: (context, state) => const KioskScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminScreen(),
    ),
    GoRoute(
      path: '/tv/:terreiroId',
      builder: (context, state) => TvScreen(terreiroId: state.pathParameters['terreiroId']!),
    ),
    GoRoute(
      path: '/queue/:terreiroId', // Public User Queue View
      builder: (context, state) => QueueWebScreen(terreiroId: state.pathParameters['terreiroId']!),
    ),
  ],
);

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
      title: 'T.U.C.P.B. Token',
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
      routerConfig: _router,
    );
  }
}

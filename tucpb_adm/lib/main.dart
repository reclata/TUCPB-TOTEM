import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tucpb_adm/firebase_options.dart';
import 'package:tucpb_adm/src/features/admin/presentation/dashboard_screen.dart';
import 'package:tucpb_adm/src/features/admin/presentation/cadastros_screen.dart';
import 'package:tucpb_adm/src/features/admin/presentation/calendario/calendario_screen.dart';
import 'package:tucpb_adm/src/features/admin/presentation/financeiro/financeiro_screen.dart';
import 'package:tucpb_adm/src/features/admin/presentation/estoque/estoque_screen.dart';
import 'package:tucpb_adm/src/features/admin/presentation/news/news_screen.dart';
import 'package:tucpb_adm/src/features/admin/presentation/shop/shop_screen.dart';
import 'package:tucpb_adm/src/features/admin/presentation/relatorios/relatorios_screen.dart';
import 'package:tucpb_adm/src/features/admin/presentation/album/album_screen.dart';
import 'package:tucpb_adm/src/features/admin/presentation/anotacoes/anotacoes_screen.dart';
import 'package:tucpb_adm/src/features/admin/presentation/lembretes_screen.dart';
import 'package:tucpb_adm/src/features/admin/presentation/widgets/admin_scaffold.dart';
import 'package:tucpb_adm/src/features/auth/presentation/login_screen.dart';
import 'package:tucpb_adm/src/shared/theme/admin_theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeDateFormatting('pt_BR', null);
  } catch (e) {
    debugPrint("Erro na inicialização: $e");
  }

  runApp(const ProviderScope(child: AdminApp()));
}

// Router configuration with Auth Guard
// Router provider to ensure initialization after Firebase is ready
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoInfra.authStream, // Listen to auth changes
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      
      // Once logged in, if on login page, go to dashboard
      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AdminScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/cadastros',
            builder: (context, state) => const CadastrosScreen(),
          ),
          GoRoute(
            path: '/calendario',
            builder: (context, state) => const CalendarioScreen(),
          ),
          GoRoute(
            path: '/financeiro',
            builder: (context, state) => const FinanceiroScreen(),
          ),
          GoRoute(
            path: '/estoque',
            builder: (context, state) => const EstoqueScreen(),
          ),
          GoRoute(
            path: '/news',
            builder: (context, state) => const NewsScreen(),
          ),
          GoRoute(
            path: '/shop',
            builder: (context, state) => const ShopScreen(),
          ),
          GoRoute(
            path: '/relatorios',
            builder: (context, state) => const RelatoriosScreen(),
          ),
          GoRoute(
            path: '/album',
            builder: (context, state) => const AlbumScreen(),
          ),
          GoRoute(
            path: '/anotacoes',
            builder: (context, state) => const AnotacoesScreen(),
          ),
          GoRoute(
            path: '/lembretes',
            builder: (context, state) => const LembretesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
});

// Helper for GoRouter listenable
class GoInfra {
  static final authStream = GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges());
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }
  late final dynamic _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'TUCPB Admin',
      theme: AdminTheme.theme, // Applying the Unity-inspired Theme
      routerConfig: router,
    );
  }
}

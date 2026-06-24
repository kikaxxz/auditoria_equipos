import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'equipo_form_provider.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'onboarding_page.dart';
import 'sincronizacion_service.dart';
import 'equipos_list_provider.dart';
import 'configuracion_provider.dart';

const Color _isaPrimary = Color(0xFF1F5C3D);
const Color _isaSecondary = Color(0xFF2F7A4F);
const Color _isaAccent = Color(0xFFA6C85A);
const Color _isaBackground = Color(0xFFF5F6F7);
const Color _isaSurface = Color(0xFFFFFFFF);
const Color _isaTextPrimary = Color(0xFF1A1C1E);
const Color _isaTextSecondary = Color(0xFF5F6368);
const Color _isaDivider = Color(0xFFE0E2E5);
const Color _isaError = Color(0xFFDC362E);

ThemeData _buildIsaTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _isaPrimary,
      primary: _isaPrimary,
      secondary: _isaSecondary,
      tertiary: _isaAccent,
      surface: _isaSurface,
      error: _isaError,
      onPrimary: _isaSurface,
      onSurface: _isaTextPrimary,
      surfaceContainerHighest: _isaBackground,
    ),
    scaffoldBackgroundColor: _isaBackground,
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: _isaPrimary,
      foregroundColor: _isaSurface,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: _isaSurface, size: 24),
      actionsIconTheme: const IconThemeData(color: _isaSurface, size: 24),
      titleTextStyle: const TextStyle(
        color: _isaSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      shadowColor: _isaTextPrimary.withValues(alpha: 0.1),
    ),
    cardTheme: CardThemeData(
      color: _isaSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _isaDivider, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _isaSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      elevation: 4,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _isaSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _isaPrimary,
        foregroundColor: _isaSurface,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => _isaSurface.withValues(alpha: 0.1),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _isaPrimary,
        side: const BorderSide(color: _isaPrimary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _isaSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _isaDivider, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _isaDivider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _isaPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _isaError, width: 1.5),
      ),
      labelStyle: const TextStyle(color: _isaTextSecondary, fontSize: 15),
      floatingLabelStyle: const TextStyle(color: _isaPrimary, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: _isaTextSecondary.withValues(alpha: 0.7), fontSize: 15),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
      },
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('==================================================');
    debugPrint('ERROR_FLUTTER_CORE: ${details.exceptionAsString()}');
    debugPrint('TRAZA: ${details.stack}');
    debugPrint('==================================================');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('==================================================');
    debugPrint('ERROR_ASINCRONO_GLOBAL: $error');
    debugPrint('TRAZA: $stack');
    debugPrint('==================================================');
    return true;
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox('configuracion_cache');
  await Hive.openBox('borrador');
  await Hive.openBox('equipos_pendientes');
  await Hive.openBox('equipos_cache');
  await Hive.openBox('cache_imagenes');

  if (kIsWeb) {
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  } catch (e) {
    debugPrint(e.toString());
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EquipoFormProvider()),
        ChangeNotifierProvider(create: (_) => EquiposListProvider()),
        ChangeNotifierProvider(create: (_) => ConfiguracionProvider()),
      ],
      child: MaterialApp(
        title: 'Sistema de Registro AYC - ISA',
        theme: _buildIsaTheme(),
        debugShowCheckedModeBanner: false,
        home: const EnrutadorPrincipal(),
      ),
    ),
  );
}

class EnrutadorPrincipal extends StatefulWidget {
  const EnrutadorPrincipal({super.key});

  @override
  State<EnrutadorPrincipal> createState() => _EnrutadorPrincipalState();
}

class _EnrutadorPrincipalState extends State<EnrutadorPrincipal> {
  @override
  void initState() {
    super.initState();
    SincronizacionService().iniciarEscucha();
  }

  Widget _buildLoadingView(String message) {
    return Scaffold(
      backgroundColor: _isaBackground,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: _isaSurface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _isaPrimary.withValues(alpha: 0.08),
                      blurRadius: 32,
                      spreadRadius: 8,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: _isaPrimary,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _isaTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sistema de Registro ISA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _isaTextSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView('Verificando sesión...');
        }

        if (snapshot.hasData && snapshot.data != null) {
          return VerificadorRol(usuario: snapshot.data!);
        }

        return const LoginPage();
      },
    );
  }
}

class VerificadorRol extends StatelessWidget {
  final User usuario;

  const VerificadorRol({super.key, required this.usuario});

  Widget _buildCenteredCard({required BuildContext context, required Widget child}) {
    return Scaffold(
      backgroundColor: _isaBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, animatedChild) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: animatedChild,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _isaSurface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _isaTextPrimary.withValues(alpha: 0.04),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                  border: Border.all(color: _isaDivider, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (usuario.email == null) {
      return _buildCenteredCard(
        context: context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isaError.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: _isaError),
            ),
            const SizedBox(height: 32),
            const Text(
              'Error de Autenticación',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isaTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No se pudo obtener la dirección de correo electrónico asociada a esta cuenta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: _isaTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 20),
                onPressed: () => FirebaseAuth.instance.signOut(),
                label: const Text('Cerrar Sesión'),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(usuario.email).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: _isaBackground,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      color: _isaPrimary,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Consultando permisos...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _isaTextSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildCenteredCard(
            context: context,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isaError.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi_off_rounded, size: 48, color: _isaError),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Error de Conexión',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isaTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No se pudo conectar con la base de datos corporativa.\n\nDetalle:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _isaTextSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    label: const Text('Volver al inicio de sesión'),
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildCenteredCard(
            context: context,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _isaError.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, size: 56, color: _isaError),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Acceso Restringido',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _isaTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: _isaBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _isaDivider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, color: _isaPrimary, size: 22),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          usuario.email!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _isaTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Esta cuenta no tiene los permisos necesarios para acceder a la plataforma de Registro de Equipos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: _isaTextSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    label: const Text('Usar otra cuenta'),
                  ),
                ),
              ],
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String rol = userData['rol'] ?? 'tecnico';
        final bool perfilCompletado = userData['perfil_completado'] ?? false;

        if (!perfilCompletado) {
          return OnboardingPage(email: usuario.email!, rol: rol);
        }

        return DashboardPage(rol: rol);
      },
    );
  }
}
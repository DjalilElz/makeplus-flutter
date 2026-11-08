// lib/main.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/django_auth_service.dart';
import 'data/services/django_api_service.dart';
import 'logic/authentication/auth_bloc.dart';
import 'logic/authentication/auth_event.dart';
import 'logic/authentication/auth_state.dart';
import 'routes/app_router.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _trustSslComRoot();

  runApp(const MakePlusApp());
}

class MakePlusApp extends StatelessWidget {
  const MakePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => DjangoAuthService(),
        ),
        RepositoryProvider(
          create: (context) => DjangoApiService(),
        ),
        RepositoryProvider(
          create: (context) => AuthRepository(
            authService: context.read<DjangoAuthService>(),
          ),
        ),
      ],
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
        )..add(AuthCheckRequested()),
        child: BlocSelector<AuthBloc, AuthState, Color?>(
          selector: (state) => state.event?.primaryColor,
          builder: (context, eventColor) {
            return MaterialApp(
              title: 'DendrIQ',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(seedColor: eventColor),
              darkTheme: AppTheme.dark(seedColor: eventColor),
              themeMode: ThemeMode.system,
              home: const SplashScreen(),
              onGenerateRoute: AppRouter.generateRoute,
            );
          },
        ),
      ),
    );
  }
}

/// The event files (programme and guide PDFs, banners, logos) are served by
/// wemakeplus.com, whose certificate chains to "SSL.com TLS RSA Root CA 2022".
/// Android 13 and older don't ship that root, so every download from that host
/// failed there ("Impossible de charger le PDF", missing banners). This adds
/// that one public root to the app's trusted roots, next to the system ones.
Future<void> _trustSslComRoot() async {
  if (kIsWeb) return;
  try {
    final pem =
        await rootBundle.load('assets/certs/sslcom_tls_rsa_root_2022.pem');
    SecurityContext.defaultContext
        .setTrustedCertificatesBytes(pem.buffer.asUint8List());
  } catch (_) {
    // Already trusted by the system (newer Android) or asset missing: the
    // system roots still apply.
  }
}

// lib/main.dart

import 'package:flutter/material.dart';
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
              title: 'MakePlus',
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
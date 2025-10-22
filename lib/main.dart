// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/supabase_auth_service.dart';
import 'data/services/django_api_service.dart';
import 'logic/authentication/auth_bloc.dart';
import 'logic/authentication/auth_event.dart';
import 'routes/app_router.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://atwsdqeeymqpvsugeyko.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0d3NkcWVleW1xcHZzdWdleWtvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4NzAwNTgsImV4cCI6MjA3NjQ0NjA1OH0.gg2JT8gVvOqqM_MaLUdwiO7CwaCQ4QfXdSuF2kP9Zbo',
  );
  
  runApp(const MakePlusApp());
}

class MakePlusApp extends StatelessWidget {
  const MakePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => SupabaseAuthService(),
        ),
        RepositoryProvider(
          create: (context) => DjangoApiService(),
        ),
        RepositoryProvider(
          create: (context) => AuthRepository(
            authService: context.read<SupabaseAuthService>(),
            apiService: context.read<DjangoApiService>(),
          ),
        ),
      ],
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
        )..add(AuthCheckRequested()),
        child: MaterialApp(
          title: 'MakePlus 2025',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: const SplashScreen(),
          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
  }
}
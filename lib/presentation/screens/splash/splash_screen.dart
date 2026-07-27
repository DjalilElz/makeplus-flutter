// lib/presentation/screens/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../../routes/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Logo grows from nothing into place with a bounce, then settles.
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateBasedOnAuthState(AuthState state) {
    if (state.status == AuthStatus.authenticated && state.role != null) {
      // User is authenticated, navigate to role-based home
      Navigator.of(context).pushReplacementNamed(
        AppRouter.getRoleHomeRoute(state.role!),
      );
    } else {
      // User is not authenticated, navigate to login
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Navigate as soon as the auth check resolves -- no artificial
        // wait for the logo animation. On a fast/cached check this keeps
        // the splash near-instant; on a slow one (Render cold start) it
        // avoids piling an extra fixed delay on top of an already-slow
        // network wait.
        if (state.status != AuthStatus.loading) {
          _navigateBasedOnAuthState(state);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.eventPrimary(context),
        body: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _logoScaleAnimation.value,
                child: child,
              );
            },
            child: SvgPicture.asset(
              'assets/logos/Les adidas.svg',
              width: 140,
              height: 140,
            ),
          ),
        ),
      ),
    );
  }
}

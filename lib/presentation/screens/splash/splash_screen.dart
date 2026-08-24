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
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Kept short and understated on purpose -- this runs on every single
    // cold start, so a long or showy animation is friction the user pays
    // every time, not a one-off flourish.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    // Logo travels up into its resting spot rather than just popping/
    // fading in place -- reads as "arriving", per the ask.
    _logoSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
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
        // Solid fallback behind the image in case the asset is ever slow
        // to decode on a very first frame -- avoids a flash of the
        // system's default white/black before it paints.
        backgroundColor: AppColors.eventPrimary(context),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icons/image-mesh-gradient (7).png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _logoSlideAnimation.value),
                  child: Opacity(
                    opacity: _logoFadeAnimation.value,
                    child: Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: child,
                    ),
                  ),
                );
              },
              // The icon's own two-tone navy/white art assumes a solid
              // backdrop; centered on this gradient it lands over the
              // lighter middle band, where its white dendrite nodes would
              // nearly vanish. Flattening to solid navy keeps it legible
              // across the whole gradient (green, white, or navy) instead
              // of being contrast-dependent on exactly where it lands.
              child: SvgPicture.asset(
                'assets/images/Icon.svg',
                width: 140,
                height: 140 * (550.87 / 606.86),
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

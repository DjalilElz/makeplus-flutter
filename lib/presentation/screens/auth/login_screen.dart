// lib/presentation/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:makeplus/routes/app_router.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_event.dart';
import '../../../logic/authentication/auth_state.dart';
import 'event_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            // Navigate to role-specific home screen
            Navigator.of(context).pushReplacementNamed(
              AppRouter.getRoleHomeRoute(state.role ?? 'participant'),
            );
          } else if (state.status == AuthStatus.requiresEventSelection) {
            // Navigate to event selection screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => EventSelectionScreen(
                  availableEvents: state.availableEvents ?? [],
                ),
              ),
            );
          } else if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Login failed'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Center(
                        child: Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: AppColors.eventPrimary(context),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/logos/Les adidas.svg',
                              width: 56,
                              height: 56,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'MakePlus',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.eventPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'Connectez-vous à votre compte',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'votre.email@exemple.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre email';
                          }
                          if (!value.contains('@')) {
                            return 'Veuillez entrer un email valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          if (value.length < 6) {
                            return 'Le mot de passe doit contenir au moins 6 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AppRouter.forgotPassword),
                          child: const Text('Mot de passe oublié ?'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: state.status == AuthStatus.loading
                              ? null
                              : _handleLogin,
                          child: state.status == AuthStatus.loading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Se connecter'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Pas encore de compte ? ',
                            style: TextStyle(
                                color: AppColors.textSecondary(context)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/signup');
                            },
                            child: const Text('S\'inscrire'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

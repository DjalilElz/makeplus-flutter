// lib/presentation/screens/auth/forgot_password_screen.dart

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../routes/app_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();

  final ApiClient _apiClient = ApiClient();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  int _currentStep = 1;
  int _resendWaitSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  /// The backend already replies with a French, user-facing message --
  /// surface that instead of dumping the raw DioException.
  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Impossible de contacter le serveur. Vérifiez votre connexion internet.';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  int? _waitSecondsFrom(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['wait_seconds'] is int) {
        return data['wait_seconds'] as int;
      }
    }
    return null;
  }

  void _startResendTimer(int seconds) {
    setState(() {
      _resendWaitSeconds = seconds;
    });

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendWaitSeconds > 0) {
          _resendWaitSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _requestResetCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.post(
        '/auth/password-reset/request/',
        data: {
          'email': _emailController.text.trim(),
          'new_password': _passwordController.text,
        },
      );

      if (response.data['success'] == true) {
        setState(() {
          _currentStep = 2;
          _isLoading = false;
        });
        _startResendTimer(60);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code de vérification envoyé à votre email'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resendWaitSeconds > 0) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.post(
        '/auth/password-reset/resend/',
        data: {
          'email': _emailController.text.trim(),
          'new_password': _passwordController.text,
        },
      );

      if (response.data['success'] == true) {
        _startResendTimer(60);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code renvoyé à votre email'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      final waitSeconds = _waitSecondsFrom(e);
      if (waitSeconds != null && waitSeconds > 0) {
        _startResendTimer(waitSeconds);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCodeAndResetPassword() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le code à 6 chiffres'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.post(
        '/auth/password-reset/verify/',
        data: {
          'email': _emailController.text.trim(),
          'code': _codeController.text.trim(),
        },
      );

      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mot de passe réinitialisé avec succès'),
              backgroundColor: AppColors.success,
            ),
          );

          Navigator.of(context).pushReplacementNamed(AppRouter.login);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: AppColors.eventPrimary(context),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock_reset,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator(context, 1, 'Nouveau mot de passe'),
                      _buildStepLine(context),
                      _buildStepIndicator(context, 2, 'Vérification'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (_currentStep == 1) _buildStep1(),
                  if (_currentStep == 2) _buildStep2(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context, int step, String label) {
    final isActive = _currentStep >= step;
    final inactiveColor = AppColors.surfaceContainerHigh(context);
    final inactiveText = AppColors.textHint(context);
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.eventPrimary(context) : inactiveColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : inactiveText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppColors.eventPrimary(context) : inactiveText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepLine(BuildContext context) {
    final isActive = _currentStep > 1;
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? AppColors.eventPrimary(context) : AppColors.surfaceContainerHigh(context),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Réinitialiser votre mot de passe',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Entrez votre email et votre nouveau mot de passe',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
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
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Nouveau mot de passe',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un mot de passe';
            }
            if (value.length < 8) {
              return 'Le mot de passe doit contenir au moins 8 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirmer le mot de passe',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () {
                setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez confirmer votre mot de passe';
            }
            if (value != _passwordController.text) {
              return 'Les mots de passe ne correspondent pas';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _requestResetCode,
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Continuer'),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Vérification',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Entrez le code à 6 chiffres envoyé à\n${_emailController.text}',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: const InputDecoration(
            labelText: 'Code de vérification',
            hintText: '000000',
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _resendWaitSeconds > 0 ? null : _resendCode,
            child: Text(
              _resendWaitSeconds > 0
                  ? 'Renvoyer le code dans ${_resendWaitSeconds}s'
                  : 'Renvoyer le code',
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCodeAndResetPassword,
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Réinitialiser le mot de passe'),
          ),
        ),
      ],
    );
  }
}

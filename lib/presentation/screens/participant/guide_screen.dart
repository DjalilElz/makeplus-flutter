// lib/presentation/screens/participant/guide_screen.dart

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';

class ParticipantGuideScreen extends StatefulWidget {
  const ParticipantGuideScreen({super.key});

  @override
  State<ParticipantGuideScreen> createState() => _ParticipantGuideScreenState();
}

class _ParticipantGuideScreenState extends State<ParticipantGuideScreen> {
  String? _pdfPath;
  bool _isLoadingPdf = false;
  String? _pdfError;

  @override
  void initState() {
    super.initState();
    final guideUrl = context.read<AuthBloc>().state.event?.guideFile;
    if (guideUrl != null && guideUrl.isNotEmpty) {
      _loadPdf(guideUrl);
    }
  }

  Future<void> _loadPdf(String url) async {
    setState(() {
      _isLoadingPdf = true;
      _pdfError = null;
    });

    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/event_guide.pdf';
      final file = File(path);
      // The guide rarely changes -- if it's already on disk from an earlier
      // load this session, use it directly instead of re-downloading.
      if (!await file.exists()) {
        await Dio().download(url, path);
      }
      if (!mounted) return;
      setState(() {
        _pdfPath = path;
        _isLoadingPdf = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pdfError = 'Impossible de charger le PDF.';
        _isLoadingPdf = false;
      });
    }
  }

  Future<void> _openPdfExternally(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir le PDF'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  int _getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/participant/home':
        return 0;
      case '/participant/program':
        return 1;
      case '/participant/profile':
        return 2;
      case '/participant/guide':
        return 3;
      case '/participant/announcements':
        return 4;
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final event = (authState.status == AuthStatus.authenticated)
            ? authState.event
            : null;
        final guideUrl = event?.guideFile;
        final hasGuide = guideUrl != null && guideUrl.isNotEmpty;

        return RootTabPopScope(
          homeRoute: '/participant/home',
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Guide'),
              actions: [
                if (hasGuide)
                  IconButton(
                    tooltip: 'Ouvrir dans une autre application',
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => _openPdfExternally(guideUrl),
                  ),
              ],
            ),
            body: _buildPdfView(context, hasGuide, guideUrl),
            bottomNavigationBar: BottomNavBar(
              currentIndex: _getCurrentIndex(context),
              userRole: 'participant',
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.pushReplacementNamed(
                        context, '/participant/home');
                    break;
                  case 1:
                    Navigator.pushReplacementNamed(
                        context, '/participant/program');
                    break;
                  case 2:
                    Navigator.pushReplacementNamed(
                        context, '/participant/profile');
                    break;
                  case 3:
                    // Already on Guide
                    break;
                  case 4:
                    Navigator.pushReplacementNamed(
                        context, '/participant/announcements');
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPdfView(BuildContext context, bool hasGuide, String? guideUrl) {
    if (!hasGuide) {
      return _buildMessage(
        context,
        icon: Icons.info_outline,
        title: 'Guide non disponible',
        message: 'Le guide de l\'événement n\'a pas encore été publié.',
      );
    }
    if (_isLoadingPdf || (_pdfPath == null && _pdfError == null)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pdfError != null) {
      return _buildMessage(
        context,
        icon: Icons.error_outline,
        title: 'Erreur',
        message: _pdfError!,
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _loadPdf(guideUrl!),
              child: const Text('Réessayer'),
            ),
            TextButton(
              onPressed: () => _openPdfExternally(guideUrl!),
              child: const Text('Ouvrir dans une autre application'),
            ),
          ],
        ),
      );
    }
    return PDFView(
      filePath: _pdfPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      onError: (error) {
        if (mounted) {
          setState(() => _pdfError = 'Impossible d\'afficher le PDF.');
        }
      },
    );
  }

  Widget _buildMessage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint(context)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint(context),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

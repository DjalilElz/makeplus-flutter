// lib/presentation/screens/participant/program_screen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/session_types.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../data/models/room_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/session_service.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../../routes/app_router.dart';
import '../../widgets/cards/session_card.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';

enum _ProgramView { cards, pdf }

class ParticipantProgramScreen extends StatefulWidget {
  const ParticipantProgramScreen({super.key});

  @override
  State<ParticipantProgramScreen> createState() =>
      _ParticipantProgramScreenState();
}

class _ParticipantProgramScreenState extends State<ParticipantProgramScreen> {
  _ProgramView _view = _ProgramView.cards;
  late final SessionService _sessionService;

  List<SessionModel>? _sessions;
  bool _isLoadingSessions = false;
  String? _sessionsError;

  String? _pdfPath;
  bool _isLoadingPdf = false;
  String? _pdfError;

  @override
  void initState() {
    super.initState();
    _sessionService = SessionService(ApiClient());
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final event = context.read<AuthBloc>().state.event;
    if (event == null) return;

    setState(() {
      _isLoadingSessions = true;
      _sessionsError = null;
    });

    try {
      final sessions = await _sessionService.getSessions(eventId: event.id);
      sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _isLoadingSessions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sessionsError = 'Impossible de charger le programme.';
        _isLoadingSessions = false;
      });
    }
  }

  Future<void> _loadPdf(String url) async {
    setState(() {
      _isLoadingPdf = true;
      _pdfError = null;
    });

    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/event_programme.pdf';
      await Dio().download(url, path);
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

  void _toggleView(bool hasProgram, String? programmeUrl) {
    setState(() {
      _view = _view == _ProgramView.cards
          ? _ProgramView.pdf
          : _ProgramView.cards;
    });
    if (_view == _ProgramView.pdf &&
        hasProgram &&
        _pdfPath == null &&
        !_isLoadingPdf &&
        programmeUrl != null) {
      _loadPdf(programmeUrl);
    }
  }

  void _openSessionDetail(SessionModel session) {
    Navigator.pushNamed(
      context,
      AppRouter.sessionDetail,
      arguments: {
        'id': session.id,
        'title': session.title,
        'speaker': session.speakerName ?? '',
        'room': session.roomName ?? '',
        'time':
            '${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
        'description': session.description ?? '',
        'isLive': session.isLive,
        'hasLiveStream': (session.youtubeLiveUrl ?? '').isNotEmpty,
        'youtubeUrl': session.youtubeLiveUrl ?? '',
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final event = (authState.status == AuthStatus.authenticated)
            ? authState.event
            : null;
        final programmeUrl = event?.programmeFile;
        final hasProgram = programmeUrl != null && programmeUrl.isNotEmpty;

        return RootTabPopScope(
          homeRoute: '/participant/home',
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Programme'),
              actions: [
                IconButton(
                  tooltip: _view == _ProgramView.cards
                      ? 'Voir le PDF'
                      : 'Voir les sessions',
                  icon: Icon(
                    _view == _ProgramView.cards
                        ? Icons.picture_as_pdf_outlined
                        : Icons.view_agenda_outlined,
                  ),
                  onPressed: () => _toggleView(hasProgram, programmeUrl),
                ),
                if (_view == _ProgramView.pdf && hasProgram)
                  IconButton(
                    tooltip: 'Ouvrir dans une autre application',
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => _openPdfExternally(programmeUrl),
                  ),
              ],
            ),
            body: _view == _ProgramView.cards
                ? _buildSessionsView(context)
                : _buildPdfView(context, hasProgram, programmeUrl),
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
                    // Already on Programme
                    break;
                  case 2:
                    Navigator.pushReplacementNamed(
                        context, '/participant/profile');
                    break;
                  case 3:
                    Navigator.pushReplacementNamed(
                        context, '/participant/guide');
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

  Widget _buildSessionsView(BuildContext context) {
    if (_isLoadingSessions) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sessionsError != null) {
      return _buildMessage(
        context,
        icon: Icons.error_outline,
        title: 'Erreur',
        message: _sessionsError!,
        action: TextButton(
          onPressed: _loadSessions,
          child: const Text('Réessayer'),
        ),
      );
    }
    final sessions = _sessions ?? [];
    if (sessions.isEmpty) {
      return _buildMessage(
        context,
        icon: Icons.event_busy,
        title: 'Aucune session pour le moment',
        message: 'Le programme détaillé n\'a pas encore été publié.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return SessionCard(
            session: session,
            typeLabel: SessionTypes.getDisplayName(session.sessionType),
            onTap: () => _openSessionDetail(session),
          );
        },
      ),
    );
  }

  Widget _buildPdfView(
      BuildContext context, bool hasProgram, String? programmeUrl) {
    if (!hasProgram) {
      return _buildMessage(
        context,
        icon: Icons.info_outline,
        title: 'Programme non disponible',
        message:
            'Le programme PDF de l\'événement n\'a pas encore été publié.',
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
              onPressed: () => _loadPdf(programmeUrl!),
              child: const Text('Réessayer'),
            ),
            TextButton(
              onPressed: () => _openPdfExternally(programmeUrl!),
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

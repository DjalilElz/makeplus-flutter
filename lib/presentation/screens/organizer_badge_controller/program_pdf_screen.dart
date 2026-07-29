// lib/presentation/screens/organizer_badge_controller/program_pdf_screen.dart

import 'dart:io';

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
import '../../../data/services/page_cache_service.dart';
import '../../../data/services/session_service.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../../routes/app_router.dart';
import '../../widgets/cards/session_card.dart';
import '../../widgets/navigation/bottom_nav_bar.dart';
import '../../widgets/navigation/root_tab_pop_scope.dart';

enum _ProgramView { cards, pdf }

class ProgramPdfScreen extends StatefulWidget {
  const ProgramPdfScreen({super.key});

  @override
  State<ProgramPdfScreen> createState() => _ProgramPdfScreenState();
}

class _ProgramPdfScreenState extends State<ProgramPdfScreen> {
  _ProgramView _view = _ProgramView.cards;
  late final SessionService _sessionService;

  List<SessionModel>? _sessions;
  bool _isLoadingSessions = false;
  String? _sessionsError;

  // Live, client-side filters for the cards view -- null means "Tous"
  // (no filter on that dimension). Applied in-memory to the already-loaded
  // session list, no re-fetch.
  String? _typeFilter;
  SessionStatus? _statusFilter;
  DateTime? _dateFilter;
  String? _roomFilter;

  String? _pdfPath;
  bool _isLoadingPdf = false;
  String? _pdfError;

  @override
  void initState() {
    super.initState();
    _sessionService = SessionService(ApiClient());
    _loadFromCacheThenRefresh();
  }

  void _loadFromCacheThenRefresh() {
    final eventId = context.read<AuthBloc>().state.event?.id;
    final cached = eventId == null
        ? null
        : PageCacheService.instance.get<List<SessionModel>>(
            'badge_controller_program_sessions_$eventId');
    if (cached != null) _sessions = cached;
    _loadSessions(showSpinner: cached == null);
  }

  Future<void> _loadSessions({bool showSpinner = true}) async {
    final event = context.read<AuthBloc>().state.event;
    if (event == null) return;

    if (showSpinner) {
      setState(() {
        _isLoadingSessions = true;
        _sessionsError = null;
      });
    }

    try {
      final sessions = await _sessionService.getSessions(eventId: event.id);
      sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
      if (!mounted) return;
      PageCacheService.instance
          .set('badge_controller_program_sessions_${event.id}', sessions);
      setState(() {
        _sessions = sessions;
        _isLoadingSessions = false;
        _sessionsError = null;
      });
    } catch (_) {
      if (!mounted) return;
      if (showSpinner) {
        setState(() {
          _sessionsError = 'Impossible de charger le programme.';
          _isLoadingSessions = false;
        });
      }
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
      final file = File(path);
      // The programme rarely changes -- if it's already on disk from an
      // earlier load this session, use it directly instead of
      // re-downloading.
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

  void _toggleView(bool hasProgram, String? programmeUrl) {
    setState(() {
      _view =
          _view == _ProgramView.cards ? _ProgramView.pdf : _ProgramView.cards;
    });
    if (_view == _ProgramView.pdf &&
        hasProgram &&
        _pdfPath == null &&
        !_isLoadingPdf &&
        programmeUrl != null) {
      _loadPdf(programmeUrl);
    }
  }

  int _getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/organizer-badge-controller/home':
        return 0;
      case '/organizer-badge-controller/announcements':
        return 1;
      case '/organizer-badge-controller/badge-scanner':
        return 2;
      case '/organizer-badge-controller/program':
        return 3;
      case '/organizer-badge-controller/stats':
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
        final programmeUrl = event?.programmeFile;
        final hasProgram = programmeUrl != null && programmeUrl.isNotEmpty;

        return RootTabPopScope(
          homeRoute: AppRouter.organizerBadgeControllerHome,
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
              userRole: 'organizer_badge_controller',
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.pushReplacementNamed(
                        context, AppRouter.organizerBadgeControllerHome);
                    break;
                  case 1:
                    Navigator.pushReplacementNamed(
                      context,
                      AppRouter.badgeControllerAnnouncements,
                    );
                    break;
                  case 2:
                    Navigator.pushReplacementNamed(
                        context, AppRouter.badgeScanner);
                    break;
                  case 3:
                    // Already on Programme
                    break;
                  case 4:
                    Navigator.pushReplacementNamed(
                        context, AppRouter.badgeControllerStats);
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  List<SessionModel> _applyFilters(List<SessionModel> sessions) {
    return sessions.where((s) {
      if (_typeFilter != null && s.sessionType != _typeFilter) return false;
      if (_statusFilter != null && s.status != _statusFilter) return false;
      if (_roomFilter != null && s.roomId != _roomFilter) return false;
      if (_dateFilter != null) {
        final d = s.startTime;
        if (d.year != _dateFilter!.year ||
            d.month != _dateFilter!.month ||
            d.day != _dateFilter!.day) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  String _formatFilterDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  String _statusLabel(SessionStatus status) {
    switch (status) {
      case SessionStatus.inProgress:
        return 'En cours';
      case SessionStatus.finished:
        return 'Terminé';
      case SessionStatus.notStarted:
        return 'Pas encore';
    }
  }

  Widget _buildFilterBar(BuildContext context, List<SessionModel> sessions) {
    final types = sessions.map((s) => s.sessionType).toSet().toList();
    final statuses = sessions.map((s) => s.status).toSet().toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final dates = sessions
        .map((s) =>
            DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
        .toList()
      ..sort();
    final rooms = <String, String>{};
    for (final s in sessions) {
      final roomLabel = (s.roomName ?? '').isNotEmpty ? s.roomName! : s.roomId;
      rooms[s.roomId] = roomLabel;
    }
    final roomEntries = rooms.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final hasAnyFilter = types.length > 1 ||
        statuses.length > 1 ||
        dates.length > 1 ||
        roomEntries.length > 1;
    if (!hasAnyFilter) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (types.length > 1) ...[
            _FilterSectionLabel(icon: Icons.category_rounded, label: 'Type'),
            const SizedBox(height: 10),
            _FilterRow<String>(
              selected: _typeFilter,
              options: [
                for (final type in types)
                  (label: SessionTypes.getDisplayName(type), value: type),
              ],
              onSelected: (value) => setState(() => _typeFilter = value),
            ),
          ],
          if (types.length > 1 && (statuses.length > 1 || dates.length > 1))
            const SizedBox(height: 18),
          if (statuses.length > 1) ...[
            _FilterSectionLabel(icon: Icons.timelapse_rounded, label: 'Statut'),
            const SizedBox(height: 10),
            _FilterRow<SessionStatus>(
              selected: _statusFilter,
              options: [
                for (final status in statuses)
                  (label: _statusLabel(status), value: status),
              ],
              onSelected: (value) => setState(() => _statusFilter = value),
            ),
          ],
          if (statuses.length > 1 &&
              (roomEntries.length > 1 || dates.length > 1))
            const SizedBox(height: 18),
          if (roomEntries.length > 1) ...[
            _FilterSectionLabel(
                icon: Icons.meeting_room_rounded, label: 'Salle'),
            const SizedBox(height: 10),
            _FilterRow<String>(
              selected: _roomFilter,
              options: [
                for (final entry in roomEntries)
                  (label: entry.value, value: entry.key),
              ],
              onSelected: (value) => setState(() => _roomFilter = value),
            ),
          ],
          if (roomEntries.length > 1 && dates.length > 1)
            const SizedBox(height: 18),
          if (dates.length > 1) ...[
            _FilterSectionLabel(
                icon: Icons.calendar_today_rounded, label: 'Date'),
            const SizedBox(height: 10),
            _FilterRow<DateTime>(
              selected: _dateFilter,
              options: [
                for (final date in dates)
                  (label: _formatFilterDate(date), value: date),
              ],
              onSelected: (value) => setState(() => _dateFilter = value),
            ),
          ],
        ],
      ),
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

    final filtered = _applyFilters(sessions);

    // A single CustomScrollView (not a fixed filter bar + separate scroll
    // area) so the filter card scrolls away with the rest of the content
    // instead of staying pinned at the top.
    return RefreshIndicator(
      onRefresh: () => _loadSessions(showSpinner: false),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildFilterBar(context, sessions)),
          if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: _buildMessage(
                  context,
                  icon: Icons.filter_alt_off,
                  title: 'Aucun résultat',
                  message:
                      'Aucune session ne correspond aux filtres sélectionnés.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final session = filtered[index];
                    // Read-only for controllers -- no tap-through to the
                    // participant-only session detail screen (its actions,
                    // like "ask a question" or "watch live", don't apply
                    // to this role).
                    return SessionCard(
                      session: session,
                      typeLabel:
                          SessionTypes.getDisplayName(session.sessionType),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
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
        message: 'Le programme PDF de l\'événement n\'a pas encore été publié.',
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

// Small caption-style header ("Type", "Statut", "Date") above a filter row.
class _FilterSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FilterSectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.eventPrimary(context)),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}

// Single-select chip row for the program filters ("Tous" plus one chip per
// distinct value present in the loaded sessions). Selecting a chip calls
// [onSelected] with its value, or null when "Tous" is tapped -- callers
// apply this purely in-memory against the already-loaded session list.
class _FilterRow<T> extends StatelessWidget {
  final T? selected;
  final List<({String label, T value})> options;
  final ValueChanged<T?> onSelected;

  const _FilterRow({
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(context,
              label: 'Tous',
              isSelected: selected == null,
              onTap: () => onSelected(null)),
          for (final option in options) ...[
            const SizedBox(width: 8),
            _buildChip(
              context,
              label: option.label,
              isSelected: selected == option.value,
              onTap: () => onSelected(option.value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: isSelected ? 10 : 14,
          right: 14,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.eventPrimary(context)
              : AppColors.surfaceContainer(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: isSelected
                  ? const Padding(
                      key: ValueKey('check'),
                      padding: EdgeInsets.only(right: 5),
                      child: Icon(Icons.check_rounded,
                          size: 14, color: Colors.white),
                    )
                  : const SizedBox.shrink(key: ValueKey('nocheck')),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

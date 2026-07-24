// lib/presentation/screens/auth/event_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../logic/authentication/auth_bloc.dart';
import '../../../logic/authentication/auth_event.dart';
import '../../../logic/authentication/auth_state.dart';
import '../../../routes/app_router.dart';

class EventSelectionScreen extends StatelessWidget {
  final List<EventModel> availableEvents;

  const EventSelectionScreen({
    super.key,
    required this.availableEvents,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          // Navigate to role-specific home screen
          Navigator.of(context).pushReplacementNamed(
            AppRouter.getRoleHomeRoute(state.role ?? 'participant'),
          );
        } else if (state.status == AuthStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Event selection failed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.eventPrimary(context),
                AppColors.eventPrimaryDark(context),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.event,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sélectionner un événement',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Vous avez accès à plusieurs événements. Choisissez celui que vous souhaitez utiliser.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Events list
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: availableEvents.length,
                      itemBuilder: (context, index) {
                        final event = availableEvents[index];
                        return _EventCard(
                          event: event,
                          onTap: () {
                            context.read<AuthBloc>().add(
                                  AuthEventSelectionRequested(
                                      eventId: event.id),
                                );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.onTap,
  });

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'upcoming':
        return 'À venir';
      case 'active':
      case 'ongoing':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status ?? 'Inconnu';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'upcoming':
        return AppColors.info;
      case 'active':
      case 'ongoing':
        return AppColors.success;
      case 'completed':
        return AppColors.textSecondaryLight;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role?.toLowerCase()) {
      case 'participant':
        return Icons.person;
      case 'exposant':
        return Icons.store;
      case 'controller':
      case 'controlleur_des_badges':
        return Icons.qr_code_scanner;
      case 'gestionnaire':
      case 'responsable_de_salle':
        return Icons.meeting_room;
      case 'admin':
      case 'president':
      case 'organisateur':
        return Icons.admin_panel_settings;
      default:
        return Icons.badge;
    }
  }

  String _getRoleLabel(String? role) {
    switch (role?.toLowerCase()) {
      case 'participant':
        return 'Participant';
      case 'exposant':
        return 'Exposant';
      case 'controller':
      case 'controlleur_des_badges':
        return 'Contrôleur';
      case 'gestionnaire':
      case 'responsable_de_salle':
        return 'Responsable';
      case 'admin':
        return 'Admin';
      case 'president':
        return 'Président';
      case 'organisateur':
        return 'Organisateur';
      default:
        return role ?? 'Inconnu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(event.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(event.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Role badge
              Row(
                children: [
                  Icon(
                    _getRoleIcon(event.role),
                    size: 18,
                    color: event.primaryColor ?? AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getRoleLabel(event.role),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: event.primaryColor ?? AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Location
              if (event.location != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Dates
              if (event.startDate != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDate(event.startDate!)}${event.endDate != null ? ' - ${_formatDate(event.endDate!)}' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Select button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Sélectionner',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: event.primaryColor ?? AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: event.primaryColor ?? AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

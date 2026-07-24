// lib/presentation/screens/organizer/room_management/create_room_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/theme/app_colors.dart';
import '../../../../logic/organizer_room_manager/room_management/room_bloc.dart';
import '../../../../logic/organizer_room_manager/room_management/room_event.dart';
import '../../../../logic/organizer_room_manager/room_management/room_state.dart';
import '../../../../logic/event/event_bloc.dart';
import '../../../../logic/event/event_state.dart' as event_state;

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _handleCreate() {
    if (_formKey.currentState!.validate()) {
      final eventId = context.read<EventBloc>().state.currentEvent?.id;

      if (eventId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun événement sélectionné'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      context.read<RoomBloc>().add(
            RoomCreateRequested({
              'event_id': eventId,
              'name': _nameController.text.trim(),
              'description': _descriptionController.text.trim(),
              'capacity': int.parse(_capacityController.text),
              'location': _locationController.text.trim(),
              'is_active': true,
            }),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une salle'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<RoomBloc, RoomState>(
        listener: (context, state) {
          if (state.status == RoomStatus.created) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Salle créée avec succès'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          } else if (state.status == RoomStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(state.errorMessage ?? 'Erreur lors de la création'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: BlocBuilder<EventBloc, event_state.EventState>(
          builder: (context, eventState) {
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Event Info
                  if (eventState.currentEvent != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.eventPrimary(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: AppColors.eventPrimary(context),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eventState.currentEvent!.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  eventState.currentEvent!.location,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Room Name
                  const Text(
                    'Nom de la salle *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Salle 3, Amphithéâtre A',
                      prefixIcon: Icon(Icons.meeting_room),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer un nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Capacity
                  const Text(
                    'Capacité *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Ex: 100',
                      prefixIcon: Icon(Icons.people),
                      suffixText: 'personnes',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer la capacité';
                      }
                      final capacity = int.tryParse(value);
                      if (capacity == null || capacity < 1) {
                        return 'La capacité doit être supérieure à 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Location
                  const Text(
                    'Emplacement *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Rez-de-chaussée, Hall A',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer l\'emplacement';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Décrivez la salle (optionnel)...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Create Button
                  BlocBuilder<RoomBloc, RoomState>(
                    builder: (context, state) {
                      return SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: state.status == RoomStatus.creating
                              ? null
                              : _handleCreate,
                          child: state.status == RoomStatus.creating
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Créer la salle'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

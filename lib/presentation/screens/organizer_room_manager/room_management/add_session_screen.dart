// lib/presentation/screens/organizer/room_management/add_session_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/theme/app_colors.dart';

class AddSessionScreen extends StatefulWidget {
  const AddSessionScreen({super.key});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedType = 'Changement de salle';
  String _selectedRoom = 'Salle 3';
  String _selectedTheme = 'Santé';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final List<String> _announcementTypes = [
    'Changement de salle',
    'Retard - Atelier "DataOps"',
  ];

  final List<String> _rooms = [
    'Salle 3',
    'Salle 1',
    'Salle 2',
    'Salle A',
    'Salle B',
  ];

  final List<String> _themes = [
    'Santé',
    'Technologie',
    'Business',
    'Innovation',
    'Education',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement session creation logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session créée avec succès'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ajouter une session'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Announcement Type Selector
            const Text(
              'Type d\'annonce',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _announcementTypes.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Title Field
            const Text(
              'Titre',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Changement de salle',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un titre';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Message Field
            const Text(
              'Message',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'La Conférence Plénière En Salle A Est Déplacée...',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un message';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Cible (Target) Field
            const Text(
              'Cible',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: 'Participants',
              decoration: const InputDecoration(),
              items: ['Participants', 'Exposants', 'Tous']
                  .map((target) => DropdownMenuItem(
                        value: target,
                        child: Text(target),
                      ))
                  .toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 24),

            // Conference/Room Selector
            const Text(
              'Conférencier',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: 'Dr M. Ali',
              decoration: const InputDecoration(),
              items: ['Dr M. Ali', 'Prof. Sarah', 'Dr. Ahmed']
                  .map((speaker) => DropdownMenuItem(
                        value: speaker,
                        child: Text(speaker),
                      ))
                  .toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 24),

            // Room Selector
            const Text(
              'Salle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedRoom,
              decoration: const InputDecoration(),
              items: _rooms
                  .map((room) => DropdownMenuItem(
                        value: room,
                        child: Text(room),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRoom = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            // Theme Selector
            const Text(
              'Thématique',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedTheme,
              decoration: const InputDecoration(),
              items: _themes
                  .map((theme) => DropdownMenuItem(
                        value: theme,
                        child: Text(theme),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            // Time Range
            const Text(
              'Créneau horaire',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(context, true),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _startTime != null
                          ? _startTime!.format(context)
                          : '10:00',
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-'),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(context, false),
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _endTime != null ? _endTime!.format(context) : '12:00',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cover Image
            const Text(
              'Photo de couverture',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.backgroundLight,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // TODO: Implement image picker
                  },
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Télécharger une photo',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'La taille maximale est de 2MB',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                child: const Text('Créer une annonce'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

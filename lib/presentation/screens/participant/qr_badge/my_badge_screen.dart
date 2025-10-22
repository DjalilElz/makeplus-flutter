// lib/presentation/screens/participant/qr_badge/my_badge_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/theme/app_colors.dart';
import '../../../../logic/authentication/auth_bloc.dart';
import '../../../../logic/authentication/auth_state.dart';
import '../../../widgets/qr/qr_display_widget.dart';
import '../../../widgets/navigation/bottom_nav_bar.dart';

class MyBadgeScreen extends StatefulWidget {
  const MyBadgeScreen({super.key});

  @override
  State<MyBadgeScreen> createState() => _MyBadgeScreenState();
}

class _MyBadgeScreenState extends State<MyBadgeScreen> {
  int _currentIndex = 2; // Badge tab

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon badge'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _handleShare,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _handleDownload,
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state.user == null) {
            return const Center(
              child: Text('Utilisateur non connecté'),
            );
          }

          final user = state.user!;
          final qrData = 'MAKEPLUS_${user.id}_${DateTime.now().millisecondsSinceEpoch}';

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Badge Display
                QRDisplayWidget(
                  data: qrData,
                  userName: user.name,
                  userRole: _getUserRoleDisplay(user.role),
                  userPhoto: user.photoUrl,
                ),

                const SizedBox(height: 24),

                // Instructions Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: AppColors.info,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Instructions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInstructionItem(
                            Icons.qr_code_scanner,
                            'Présentez ce QR code à l\'entrée de l\'événement',
                          ),
                          _buildInstructionItem(
                            Icons.meeting_room,
                            'Scannez à nouveau pour accéder aux salles',
                          ),
                          _buildInstructionItem(
                            Icons.phone_android,
                            'Gardez votre téléphone chargé',
                          ),
                          _buildInstructionItem(
                            Icons.security,
                            'Ne partagez pas votre QR code',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildActionButton(
                        'Télécharger en PDF',
                        Icons.picture_as_pdf,
                        AppColors.error,
                        _handleDownloadPDF,
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        'Ajouter au Wallet',
                        Icons.wallet,
                        AppColors.primary,
                        _handleAddToWallet,
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        'Partager par email',
                        Icons.email,
                        AppColors.info,
                        _handleShareEmail,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        userRole: 'participant',
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  String _getUserRoleDisplay(String? role) {
    switch (role) {
      case 'participant':
        return 'Participant - Conférencier';
      case 'exhibitor':
        return 'Exposant';
      case 'organizer':
        return 'Organisateur';
      case 'controller':
        return 'Contrôleur';
      default:
        return 'Participant';
    }
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage du badge...')),
    );
    // TODO: Implement share functionality
  }

  void _handleDownload() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Badge téléchargé'),
        backgroundColor: AppColors.success,
      ),
    );
    // TODO: Implement download functionality
  }

  void _handleDownloadPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Génération du PDF...')),
    );
    // TODO: Implement PDF generation
  }

  void _handleAddToWallet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajout au Wallet...')),
    );
    // TODO: Implement wallet integration
  }

  void _handleShareEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Envoi par email...')),
    );
    // TODO: Implement email sharing
  }
}
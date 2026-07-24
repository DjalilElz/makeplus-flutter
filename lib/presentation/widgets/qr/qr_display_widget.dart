// lib/presentation/widgets/qr/qr_display_widget.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/theme/app_colors.dart';

class QRDisplayWidget extends StatelessWidget {
  final String data;
  final String userName;
  final String userRole;
  final String? userPhoto;

  const QRDisplayWidget({
    super.key,
    required this.data,
    required this.userName,
    required this.userRole,
    this.userPhoto,
  });

  // This widget renders a physical-badge look — a white card with a QR code —
  // and is deliberately NOT theme-reactive: a printed badge doesn't invert for
  // dark mode, and the QR needs a white backing for scanner contrast regardless
  // of the app theme. Text on the card is pinned to the light-theme colors so
  // it stays legible against the permanently-white card even when the rest of
  // the app is in dark mode.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.eventPrimary(context).withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.eventPrimary(context), AppColors.eventPrimaryDark(context)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event,
                    color: AppColors.eventPrimary(context),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'MakePlus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '2025',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // User Info & QR Code
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // User Photo
                if (userPhoto != null)
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(userPhoto!),
                  )
                else
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.eventPrimary(context).withValues(alpha: 0.1),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.eventPrimary(context),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // User Name — fixed dark text: sits on the permanently-white card.
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // User Role
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.eventPrimary(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    userRole,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.eventPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.eventPrimary(context).withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: QrImageView(
                    data: data,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                ),
                const SizedBox(height: 16),

                // Instructions — fixed grey: sits on the permanently-white card.
                const Text(
                  'Présentez ce code QR à l\'entrée',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Full Screen QR Badge
class QRBadgeScreen extends StatelessWidget {
  final String data;
  final String userName;
  final String userRole;
  final String? userPhoto;

  const QRBadgeScreen({
    super.key,
    required this.data,
    required this.userName,
    required this.userRole,
    this.userPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon badge'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: QRDisplayWidget(
            data: data,
            userName: userName,
            userRole: userRole,
            userPhoto: userPhoto,
          ),
        ),
      ),
    );
  }
}
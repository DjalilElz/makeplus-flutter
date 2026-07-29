// lib/presentation/screens/organizer_badge_controller/participant_verification_result_screen.dart

import 'package:flutter/material.dart';

import '../../../core/constants/theme/app_colors.dart';

class ParticipantVerificationDialog {
  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> qrData,
  ) {
    // Extract participant info from QR data
    final String fullName = qrData['full_name'] ?? qrData['name'] ?? 'N/A';
    final List<dynamic> paidItems = qrData['paid_items'] ?? [];

    // paid_items comes straight from /participants/scan/, built from the
    // participant's completed CaisseTransaction records -- always real,
    // always freshly queried for this scan (never a free/unpaid item, since
    // the endpoint only ever returns items that were actually paid for).
    final List<dynamic> actuallyPaidItems = paidItems;

    // Group paid items by type for better display
    final Map<String, List<dynamic>> groupedItems = {
      'session': [],
      'access': [],
      'dinner': [],
      'other': [],
    };

    for (var item in actuallyPaidItems) {
      final type = item['type'] ?? 'other';
      if (groupedItems.containsKey(type)) {
        groupedItems[type]!.add(item);
      } else {
        groupedItems['other']!.add(item);
      }
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 350,
              maxHeight: 500,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Compact Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.eventPrimary(dialogContext),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Paid Items
                        if (actuallyPaidItems.isNotEmpty) ...[
                          Text(
                            'Articles Payés (${actuallyPaidItems.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Sessions
                          if (groupedItems['session']!.isNotEmpty) ...[
                            _buildSectionHeader('Ateliers', Icons.event),
                            ...groupedItems['session']!
                                .map((item) => _buildMinimalItemCard(item)),
                          ],

                          // Access
                          if (groupedItems['access']!.isNotEmpty) ...[
                            _buildSectionHeader('Accès', Icons.vpn_key),
                            ...groupedItems['access']!
                                .map((item) => _buildMinimalItemCard(item)),
                          ],

                          // Dinner
                          if (groupedItems['dinner']!.isNotEmpty) ...[
                            _buildSectionHeader('Repas', Icons.restaurant),
                            ...groupedItems['dinner']!
                                .map((item) => _buildMinimalItemCard(item)),
                          ],

                          // Other
                          if (groupedItems['other']!.isNotEmpty) ...[
                            _buildSectionHeader('Autres', Icons.shopping_bag),
                            ...groupedItems['other']!
                                .map((item) => _buildMinimalItemCard(item)),
                          ],

                          const SizedBox(height: 12),
                        ],

                        // No items
                        if (actuallyPaidItems.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Aucun accès enregistré',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Compact Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.eventPrimary(dialogContext),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Fermer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Minimal section header
  static Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.black45, size: 14),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  // Minimal item card without icon
  static Widget _buildMinimalItemCard(Map<String, dynamic> item) {
    final String title = item['title'] ?? 'N/A';
    final double amountPaid = (item['amount_paid'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.success,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (amountPaid > 0)
                  Text(
                    '${amountPaid.toStringAsFixed(0)} DA',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'PAYÉ',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

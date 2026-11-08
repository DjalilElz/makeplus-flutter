// lib/presentation/screens/organizer_badge_controller/participant_verification_result_screen.dart

import 'package:flutter/material.dart';

import '../../../core/constants/theme/app_colors.dart';

/// Result of a badge scan: who it is, what they paid for, and -- when the
/// backend returned a `scan_id` -- the controller's decision buttons
/// ("Laisser entrer" / "Refuser l'accès"), recorded on that scan so the
/// dashboard knows who was let in or turned away.
class ParticipantVerificationDialog {
  /// [data] keys: full_name, email, badge_id, paid_items, registered (bool,
  /// default true), message, scan_id (int?).
  /// [onDecision] records 'granted' / 'denied'; it throws on failure so the
  /// dialog can show the error and let the controller retry.
  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> data, {
    Future<void> Function(String decision)? onDecision,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VerificationDialog(data: data, onDecision: onDecision),
    );
  }
}

class _VerificationDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  final Future<void> Function(String decision)? onDecision;

  const _VerificationDialog({required this.data, this.onDecision});

  @override
  State<_VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<_VerificationDialog> {
  String? _sending; // decision being recorded
  String? _error;

  bool get _registered => widget.data['registered'] != false;
  bool get _canDecide =>
      widget.onDecision != null && widget.data['scan_id'] != null;

  Future<void> _decide(String decision) async {
    setState(() {
      _sending = decision;
      _error = null;
    });
    try {
      await widget.onDecision!(decision);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = null;
        _error = "La décision n'a pas pu être enregistrée. Réessayez.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final String fullName =
        (data['full_name'] ?? data['name'] ?? '').toString().trim();
    final String email = (data['email'] ?? '').toString();
    final String badgeId = (data['badge_id'] ?? '').toString();
    final List<dynamic> paidItems = data['paid_items'] ?? [];

    // Group paid items by type for display
    final Map<String, List<dynamic>> grouped = {
      'session': [],
      'access': [],
      'dinner': [],
      'other': [],
    };
    for (final item in paidItems) {
      final type = item['type'] ?? 'other';
      (grouped[type] ?? grouped['other']!).add(item);
    }

    final headerColor =
        _registered ? AppColors.eventPrimary(context) : AppColors.warning;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: name + email/badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _registered
                        ? Icons.verified_user
                        : Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fullName.isEmpty ? 'Participant' : fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (email.isNotEmpty || badgeId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        [email, badgeId].where((s) => s.isNotEmpty).join(' · '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_registered)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Text(
                          (data['message'] ??
                                  "Ce participant n'est pas inscrit à cet événement.")
                              .toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                    if (paidItems.isNotEmpty) ...[
                      Text(
                        'Articles payés (${paidItems.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (grouped['session']!.isNotEmpty) ...[
                        _sectionHeader('Ateliers', Icons.event),
                        ...grouped['session']!.map(_itemCard),
                      ],
                      if (grouped['access']!.isNotEmpty) ...[
                        _sectionHeader('Accès', Icons.vpn_key),
                        ...grouped['access']!.map(_itemCard),
                      ],
                      if (grouped['dinner']!.isNotEmpty) ...[
                        _sectionHeader('Repas', Icons.restaurant),
                        ...grouped['dinner']!.map(_itemCard),
                      ],
                      if (grouped['other']!.isNotEmpty) ...[
                        _sectionHeader('Autres', Icons.shopping_bag),
                        ...grouped['other']!.map(_itemCard),
                      ],
                    ] else if (_registered)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Aucun accès payant enregistré',
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

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _canDecide ? _decisionButtons() : _closeButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decisionButtons() {
    final busy = _sending != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _decisionButton(
                label: "Refuser l'accès",
                icon: Icons.block,
                color: AppColors.error,
                decision: 'denied',
                busy: busy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _decisionButton(
                label: 'Laisser entrer',
                icon: Icons.meeting_room,
                color: AppColors.success,
                decision: 'granted',
                busy: busy,
              ),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: Text(
            'Fermer sans décision',
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ),
      ],
    );
  }

  Widget _decisionButton({
    required String label,
    required IconData icon,
    required Color color,
    required String decision,
    required bool busy,
  }) {
    return ElevatedButton(
      onPressed: busy ? null : () => _decide(decision),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: _sending == decision
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _closeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.eventPrimary(context),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: const Text(
          'Fermer',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary(context), size: 14),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(dynamic item) {
    final String title = (item['title'] ?? 'N/A').toString();
    final num rawAmount = item['amount_paid'] is num
        ? item['amount_paid'] as num
        : num.tryParse('${item['amount_paid'] ?? 0}') ?? 0;
    final double amountPaid = rawAmount.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                if (amountPaid > 0)
                  Text(
                    '${amountPaid.toStringAsFixed(0)} DA',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary(context)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'PAYÉ',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

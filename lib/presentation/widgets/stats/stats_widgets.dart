import 'package:flutter/material.dart';

import '../../../core/constants/theme/app_colors.dart';

/// Small figure tile: big number + label with an icon.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.textSecondary(context)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Aujourd'hui, par heure" card: one bar per hour from the backend's
/// `hourly_today` ({labels, counts}), the peak hour highlighted.
class HourlyBarsCard extends StatelessWidget {
  final Map<String, dynamic>? hourly;
  final Map<String, dynamic>? peak;

  /// Singular unit for the peak line, e.g. 'scan' or 'visite'.
  final String unit;

  const HourlyBarsCard({
    super.key,
    required this.hourly,
    required this.peak,
    required this.unit,
  });

  static List<String> _labels(Map<String, dynamic>? hourly) =>
      ((hourly?['labels'] as List?) ?? const []).map((e) => '$e').toList();

  static List<int> _counts(Map<String, dynamic>? hourly) =>
      ((hourly?['counts'] as List?) ?? const [])
          .map((e) => e is num ? e.toInt() : int.tryParse('$e') ?? 0)
          .toList();

  /// Whether there is anything to draw.
  static bool hasData(Map<String, dynamic>? hourly) => _labels(hourly).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final labels = _labels(hourly);
    final counts = _counts(hourly);
    if (labels.isEmpty || counts.length != labels.length) return const SizedBox.shrink();
    final maxCount = counts.fold<int>(1, (m, c) => c > m ? c : m);
    final peakCount = peak?['count'] is num ? (peak!['count'] as num).toInt() : null;
    final primary = AppColors.eventPrimary(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Aujourd'hui, par heure",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),
            if (peak != null && peakCount != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Pointe : ${peak!['label']} ($peakCount $unit${peakCount > 1 ? 's' : ''})',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(labels.length, (i) {
                  final count = counts[i];
                  final isPeak = peakCount != null && count == peakCount && count > 0;
                  return Expanded(
                    child: Tooltip(
                      message: '${labels[i]} : $count $unit${count > 1 ? 's' : ''}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (count > 0)
                              Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            const SizedBox(height: 2),
                            Container(
                              height: count == 0 ? 2 : 90 * count / maxCount,
                              constraints: const BoxConstraints(maxWidth: 28),
                              decoration: BoxDecoration(
                                color: isPeak ? AppColors.accent : primary,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                labels[i],
                                style: TextStyle(fontSize: 10, color: AppColors.textSecondary(context)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

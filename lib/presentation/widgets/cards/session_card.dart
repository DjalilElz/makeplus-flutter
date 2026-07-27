// lib/presentation/widgets/cards/session_card.dart

import 'package:flutter/material.dart';
import '../../../core/constants/theme/app_colors.dart';
import '../../../data/models/room_model.dart';

class SessionCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback? onTap;
  final bool showLiveIndicator;
  final String? typeLabel;

  const SessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.showLiveIndicator = true,
    this.typeLabel,
  });

  static const List<String> _months = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.eventPrimary(context).withValues(alpha: 0.08),
          highlightColor:
              AppColors.eventPrimary(context).withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date + time on the left, session status on the right --
                // always shown in full (wraps to a 2nd line if it must).
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${_formatDate(session.startTime)} • ${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.eventPrimary(context),
                        ),
                      ),
                    ),
                    if (showLiveIndicator) ...[
                      const SizedBox(width: 8),
                      _StatusBadge(status: session.status),
                    ],
                  ],
                ),

                // Speaker / author, with the session type chip beside the
                // name -- right after the date/time, before the title.
                if (session.speakerName != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.eventPrimary(context)
                            .withValues(alpha: 0.1),
                        child: Text(
                          session.speakerName![0].toUpperCase(),
                          style: TextStyle(
                            color: AppColors.eventPrimary(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.speakerName!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (session.speakerTitle != null)
                              Text(
                                session.speakerTitle!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (typeLabel != null) ...[
                        const SizedBox(width: 8),
                        _Chip(
                          text: typeLabel!,
                          background: AppColors.accent.withValues(alpha: 0.15),
                          foreground: AppColors.accent,
                        ),
                      ],
                    ],
                  ),
                ] else if (typeLabel != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _Chip(
                      text: typeLabel!,
                      background: AppColors.accent.withValues(alpha: 0.15),
                      foreground: AppColors.accent,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Session Title
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Theme, shown in full, never truncated.
                if ((session.theme ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _Chip(
                    text: session.theme!,
                    background:
                        AppColors.eventPrimary(context).withValues(alpha: 0.1),
                    foreground: AppColors.eventPrimary(context),
                    fullWidth: true,
                  ),
                ],

                if (session.description != null) ...[
                  const SizedBox(height: 10),
                  _ExpandableText(
                    text: session.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                      height: 1.4,
                    ),
                  ),
                ],

                // Salle -- moved to the bottom of the card.
                if ((session.roomName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _IconLabel(
                    icon: Icons.meeting_room_outlined,
                    text: session.roomName!,
                    color: AppColors.textSecondary(context),
                  ),
                ],

                // Tappable affordance -- makes it obvious the whole card
                // navigates to the session detail screen.
                if (onTap != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Voir les détails',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.eventPrimary(context),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.eventPrimary(context),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Description text truncated to 2 lines with a tappable ellipsis -- tapping
// the truncated text (the "..." included) expands it to show the full
// text; tapping again collapses it back.
class _ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _ExpandableText({required this.text, required this.style});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (_expanded) {
      return GestureDetector(
        onTap: () => setState(() => _expanded = false),
        child: Text(widget.text, style: widget.style),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        if (!painter.didExceedMaxLines) {
          return Text(widget.text, style: widget.style);
        }

        return GestureDetector(
          onTap: () => setState(() => _expanded = true),
          child: Text(
            widget.text,
            style: widget.style,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}

// Small pill label (session type, theme) used in SessionCard's tags row.
// Capped at a fixed max width with ellipsis so a long label can never
// overflow its Wrap line, no matter how long the text is -- unless
// [fullWidth] is set, in which case the text wraps and shows completely.
class _Chip extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final bool fullWidth;

  const _Chip({
    required this.text,
    required this.background,
    required this.foreground,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: fullWidth ? null : const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
        maxLines: fullWidth ? null : 1,
        overflow: fullWidth ? TextOverflow.visible : TextOverflow.ellipsis,
      ),
    );
  }
}

// Session status badge (Pas encore / En cours / Terminé) shown top-right
// of SessionCard, next to the date/time.
class _StatusBadge extends StatelessWidget {
  final SessionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    late final bool pulsing;

    switch (status) {
      case SessionStatus.inProgress:
        label = 'En cours';
        color = AppColors.success;
        pulsing = true;
        break;
      case SessionStatus.finished:
        label = 'Terminé';
        color = AppColors.textHint(context);
        pulsing = false;
        break;
      case SessionStatus.notStarted:
        label = 'Pas encore';
        color = AppColors.warning;
        pulsing = false;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulsing) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Icon + label (room name) used in SessionCard's tags row -- same
// max-width/ellipsis guarantee as _Chip.
class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _IconLabel({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Compact version for lists
class SessionCardCompact extends StatelessWidget {
  final SessionModel session;
  final VoidCallback? onTap;

  const SessionCardCompact({
    super.key,
    required this.session,
    this.onTap,
  });

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 50,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: session.isLive
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.eventPrimary(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(session.startTime),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: session.isLive
                      ? AppColors.success
                      : AppColors.eventPrimary(context),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          session.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          session.speakerName ?? '',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: session.isLive
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              )
            : const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}

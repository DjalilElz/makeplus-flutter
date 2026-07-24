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
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date + time on its own row -- always shown in full (wraps
              // to a 2nd line if it must, never shares space with the
              // live badge, so nothing else can ever squeeze it).
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary(context),
                  ),
                  const SizedBox(width: 4),
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
                ],
              ),
              if (showLiveIndicator && session.isLive) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'EN DIRECT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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

              // Theme, then type directly below it in a column (not
              // side-by-side) -- each capped at a max width with ellipsis
              // so a long label can never overflow.
              if ((session.theme ?? '').isNotEmpty || typeLabel != null) ...[
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((session.theme ?? '').isNotEmpty)
                      _Chip(
                        text: session.theme!,
                        background: AppColors.eventPrimary(context).withValues(alpha: 0.1),
                        foreground: AppColors.eventPrimary(context),
                      ),
                    if ((session.theme ?? '').isNotEmpty && typeLabel != null)
                      const SizedBox(height: 4),
                    if (typeLabel != null)
                      _Chip(
                        text: typeLabel!,
                        background: AppColors.accent.withValues(alpha: 0.15),
                        foreground: AppColors.accent,
                      ),
                  ],
                ),
              ],

              if ((session.roomName ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                _IconLabel(
                  icon: Icons.meeting_room_outlined,
                  text: session.roomName!,
                  color: AppColors.textSecondary(context),
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

              if (session.speakerName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.eventPrimary(context).withValues(alpha: 0.1),
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
                  ],
                ),
              ],
            ],
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
// overflow its Wrap line, no matter how long the text is.
class _Chip extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Chip({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
                  color: session.isLive ? AppColors.success : AppColors.eventPrimary(context),
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
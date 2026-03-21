// lib/presentation/widgets/set_alarm_sheet.dart
// Bottom sheet that lets user choose: Clock Alarm or Google Calendar

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/alarm_intent_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/hive_models.dart';

class SetAlarmSheet extends StatelessWidget {
  final Task task;

  const SetAlarmSheet({Key? key, required this.task}) : super(key: key);

  /// Static helper to show the sheet
  static void show(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SetAlarmSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(task.dueDate);
    final dateStr = DateFormat('EEE, MMM d').format(task.dueDate);
    final isPast = task.dueDate.isBefore(DateTime.now());

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          const Text(
            'Set Alarm / Reminder',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryDark,
            ),
          ),

          const SizedBox(height: 4),

          // Task info
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cardBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$dateStr at $timeStr',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryColor.withOpacity(0.55),
                ),
              ),
            ],
          ),

          if (isPast) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppTheme.danger),
                  const SizedBox(width: 8),
                  Text(
                    'This task time has already passed.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.danger,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Option 1: Clock Alarm
          _AlarmOption(
            icon: Icons.alarm,
            iconColor: const Color(0xFF1565C0),
            iconBg: const Color(0xFFE3F2FD),
            title: 'Set Alarm in Clock App',
            subtitle: 'Opens your phone\'s Clock with alarm at $timeStr',
            onTap: () async {
              Navigator.pop(context);
              final ok =
                  await AlarmIntentService.instance.setAlarmInClock(
                alarmTime: task.dueDate,
                taskTitle: task.title,
              );
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open Clock app'),
                    backgroundColor: AppTheme.danger,
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 12),

          // Option 2: Google Calendar
          _AlarmOption(
            icon: Icons.calendar_month,
            iconColor: const Color(0xFF1A73E8),
            iconBg: const Color(0xFFE8F0FE),
            title: 'Add to Google Calendar',
            subtitle: 'Creates an event on $dateStr at $timeStr',
            onTap: () async {
              Navigator.pop(context);
              final ok =
                  await AlarmIntentService.instance.addToGoogleCalendar(
                taskTitle: task.title,
                startTime: task.dueDate,
                description: task.description,
              );
              if (!ok && context.mounted) {
                // Fallback: try system calendar
                await AlarmIntentService.instance.addToSystemCalendar(
                  taskTitle: task.title,
                  startTime: task.dueDate,
                  description: task.description,
                );
              }
            },
          ),

          const SizedBox(height: 12),

          // Option 3: Reminder (timer)
          if (!isPast)
            _AlarmOption(
              icon: Icons.timer_outlined,
              iconColor: const Color(0xFF2E7D32),
              iconBg: const Color(0xFFE8F5E9),
              title: 'Set Countdown Timer',
              subtitle: _countdownLabel(task.dueDate),
              onTap: () async {
                Navigator.pop(context);
                await AlarmIntentService.instance.setReminderInClock(
                  reminderTime: task.dueDate,
                  taskTitle: task.title,
                );
              },
            ),

          // Option 4: System Calendar (any calendar app)
          const SizedBox(height: 12),
          _AlarmOption(
            icon: Icons.date_range,
            iconColor: const Color(0xFF6A1B9A),
            iconBg: const Color(0xFFF3E5F5),
            title: 'Add to Any Calendar App',
            subtitle: 'Opens your default calendar app',
            onTap: () async {
              Navigator.pop(context);
              await AlarmIntentService.instance.addToSystemCalendar(
                taskTitle: task.title,
                startTime: task.dueDate,
                description: task.description,
              );
            },
          ),
        ],
      ),
    );
  }

  String _countdownLabel(DateTime dueDate) {
    final diff = dueDate.difference(DateTime.now());
    if (diff.inDays > 0) {
      return 'Counts down ${diff.inDays}d ${diff.inHours % 24}h from now';
    } else if (diff.inHours > 0) {
      return 'Counts down ${diff.inHours}h ${diff.inMinutes % 60}m from now';
    } else if (diff.inMinutes > 0) {
      return 'Counts down ${diff.inMinutes} minutes from now';
    } else {
      return 'Task is due very soon';
    }
  }
}

// ─── Alarm Option Row ────────────────────────────────────────────────────────
class _AlarmOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AlarmOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.primaryColor.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}
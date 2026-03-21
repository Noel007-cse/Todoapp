// lib/presentation/widgets/task_card.dart - MINDFUL FLOW REDESIGN

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/local/hive_models.dart';
import '../../core/theme/app_theme.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(bool) onComplete;
  final bool isSelected;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onDelete,
    required this.onEdit,
    required this.onComplete,
    this.isSelected = false,
  }) : super(key: key);

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  String _getTimeRemaining() {
    if (widget.task.isCompleted) return 'Completed';
    if (widget.task.isOverdue) return 'Overdue';

    final remaining = widget.task.timeRemaining;
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d remaining';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h remaining';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m remaining';
    } else {
      return 'Due soon';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, hh:mm a');

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onLongPress: widget.onEdit,
        child: Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => widget.onDelete(),
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: widget.task.isOverdue && !widget.task.isCompleted
                    ? AppTheme.dangerColor.withOpacity(0.3)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            elevation: widget.task.isOverdue && !widget.task.isCompleted
                ? 2
                : 0,
            shadowColor: widget.task.isOverdue && !widget.task.isCompleted
                ? AppTheme.dangerColor.withOpacity(0.2)
                : AppTheme.primaryColor.withOpacity(0.08),
            child: InkWell(
              onTap: () => widget.onComplete(!widget.task.isCompleted),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Top Row: Checkbox, Title, Menu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Checkbox - Teal when selected
                        Checkbox(
                          value: widget.task.isCompleted,
                          onChanged: (value) =>
                              widget.onComplete(value ?? false),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          activeColor: AppTheme.primaryColor,
                        ),

                        /// Title and Category Badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Title
                              Text(
                                widget.task.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall!
                                    .copyWith(
                                      decoration: widget.task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: Colors.grey,
                                      fontWeight: FontWeight.w700,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              /// Category Badge
                              if (widget.task.category.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightBlueCard,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      widget.task.category.toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(fontSize: 10),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        /// Options Menu
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              widget.onEdit();
                            } else if (value == 'delete') {
                              widget.onDelete();
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 18,
                                      color: AppTheme.dangerColor),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(
                                          color: AppTheme.dangerColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    /// Description (if any)
                    if (widget.task.description != null &&
                        widget.task.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, left: 40),
                        child: Text(
                          widget.task.description!,
                          style:
                              Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    const SizedBox(height: 12),

                    /// Due Date and Time Status
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// Date and Time
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: widget.task.isOverdue &&
                                        !widget.task.isCompleted
                                    ? AppTheme.dangerColor
                                    : AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateFormat.format(widget.task.dueDate),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: widget.task.isOverdue &&
                                              !widget.task.isCompleted
                                          ? AppTheme.dangerColor
                                          : null,
                                      fontWeight: widget.task.isOverdue &&
                                              !widget.task.isCompleted
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                              ),
                            ],
                          ),
                          /// Time Remaining
                          Text(
                            _getTimeRemaining(),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                  color: widget.task.isOverdue &&
                                          !widget.task.isCompleted
                                      ? AppTheme.dangerColor
                                      : AppTheme.successColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),

                    /// Notification Indicators (Reminder & Alarm Badges)
                    if (widget.task.hasReminder ||
                        widget.task.hasAlarm)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 12, left: 40),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (widget.task.hasReminder)
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightBlueCard,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.notifications,
                                      size: 12,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Reminder',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            if (widget.task.hasAlarm)
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightBlueCard,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.alarm,
                                      size: 12,
                                      color: AppTheme.primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Alarm',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
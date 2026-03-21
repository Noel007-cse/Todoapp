// lib/presentation/screens/add_edit_task_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/hive_models.dart';
import '../providers/task_provider.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;
  const AddEditTaskScreen({Key? key, this.task}) : super(key: key);

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  final TextEditingController _subtaskCtrl = TextEditingController();
  final TextEditingController _tagCtrl = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedCategory;
  late String _selectedPriority;
  late List<Subtask> _subtasks;
  late List<String> _tags;
  late bool _hasReminder;
  late int _reminderMinutes;
  late bool _hasAlarm;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _selectedDate = t?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _selectedTime = TimeOfDay.fromDateTime(
        t?.dueDate ?? DateTime.now().add(const Duration(hours: 1)));
    _selectedCategory = t?.category ?? 'work';
    _selectedPriority = t?.priority ?? 'medium';
    _subtasks = List<Subtask>.from(t?.subtasks ?? []);
    _tags = List<String>.from(t?.tags ?? []);
    _hasReminder = t?.hasReminder ?? true;
    _reminderMinutes = t?.reminderMinutesBefore ?? 15;
    _hasAlarm = t?.hasAlarm ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subtaskCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _addSubtask() {
    if (_subtaskCtrl.text.trim().isNotEmpty) {
      setState(() {
        _subtasks.add(Subtask(
          id: const Uuid().v4(),
          title: _subtaskCtrl.text.trim(),
          createdDate: DateTime.now(),
        ));
        _subtaskCtrl.clear();
      });
    }
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagCtrl.clear();
      });
    }
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  void _removeSubtask(String id) =>
      setState(() => _subtasks.removeWhere((s) => s.id == id));

  void _toggleSubtask(String id) {
    setState(() {
      for (final s in _subtasks) {
        if (s.id == id) s.isCompleted = !s.isCompleted;
      }
    });
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    final dueDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final provider = context.read<TaskProvider>();

    if (_isEditing) {
      final updated = widget.task!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        dueDate: dueDate,
        category: _selectedCategory,
        priority: _selectedPriority,
        subtasks: _subtasks,
        tags: _tags,
        hasReminder: _hasReminder,
        reminderMinutesBefore: _reminderMinutes,
        hasAlarm: _hasAlarm,
      );
      provider.updateTask(updated);
    } else {
      final newTask = Task(
        id: const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        dueDate: dueDate,
        createdDate: DateTime.now(),
        category: _selectedCategory,
        priority: _selectedPriority,
        subtasks: _subtasks,
        tags: _tags,
        hasReminder: _hasReminder,
        reminderMinutesBefore: _reminderMinutes,
        hasAlarm: _hasAlarm,
      );
      provider.addTask(newTask);
    }

    Navigator.pop(context);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Task'),
        content:
            const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<TaskProvider>().deleteTask(widget.task!.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedSubtasks =
        _subtasks.where((s) => s.isCompleted).length;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: GestureDetector(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Task Title ─────────────────────────────────────────
            _label('TASK TITLE'),
            const SizedBox(height: 10),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDark,
              ),
              decoration: InputDecoration(
                hintText: 'Enter task title...',
                hintStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 20),

            // ── Notes & Context ────────────────────────────────────
            _label('NOTES & CONTEXT'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _descCtrl,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor.withOpacity(0.7),
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Add notes, context, or details...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                minLines: 3,
                maxLines: 6,
              ),
            ),

            const SizedBox(height: 20),

            // ── Schedule ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ScheduleRow(
                    label: 'Date',
                    value:
                        DateFormat('MMM d, yyyy').format(_selectedDate),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 10),
                  _ScheduleRow(
                    label: 'Time',
                    value: _selectedTime.format(context),
                    onTap: _pickTime,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Reminders ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_outlined,
                          size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Reminders',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_hasReminder)
                        _ReminderChip(
                          label: '${_reminderMinutes}m before',
                          onRemove: () =>
                              setState(() => _hasReminder = false),
                        ),
                      GestureDetector(
                        onTap: () => _showReminderPicker(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.primaryColor
                                    .withOpacity(0.2)),
                          ),
                          child: Text(
                            '+ Add',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor
                                  .withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Breakdown (Subtasks) ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDark,
                  ),
                ),
                if (_subtasks.isNotEmpty)
                  Text(
                    '$completedSubtasks / ${_subtasks.length} COMPLETE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor.withOpacity(0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Subtask list
            ..._subtasks.map((s) => _SubtaskRow(
                  subtask: s,
                  onToggle: () => _toggleSubtask(s.id),
                  onRemove: () => _removeSubtask(s.id),
                )),

            // Add subtask row
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _addSubtask,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _subtaskCtrl,
                      onSubmitted: (_) => _addSubtask(),
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryDark),
                      decoration: InputDecoration(
                        hintText: 'Add a sub-task...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color:
                              AppTheme.primaryColor.withOpacity(0.4),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Tags & Classification ──────────────────────────────
            _label('TAGS & CLASSIFICATION'),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._tags.map((tag) => _TagBadge(
                      label: tag,
                      onRemove: () => _removeTag(tag),
                    )),
                GestureDetector(
                  onTap: () => _showAddTagDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          style: BorderStyle.solid),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 14,
                            color: AppTheme.primaryColor.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Text(
                          'Add Tag',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Category & Priority ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('CATEGORY'),
                      const SizedBox(height: 8),
                      _DropdownField<String>(
                        value: _selectedCategory,
                        items: const [
                          'work',
                          'personal',
                          'shopping',
                          'health',
                          'ideas'
                        ],
                        labelBuilder: (v) =>
                            v[0].toUpperCase() + v.substring(1),
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('PRIORITY'),
                      const SizedBox(height: 8),
                      _DropdownField<String>(
                        value: _selectedPriority,
                        items: const ['low', 'medium', 'high'],
                        labelBuilder: (v) =>
                            v[0].toUpperCase() + v.substring(1),
                        onChanged: (v) =>
                            setState(() => _selectedPriority = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Delete Button ──────────────────────────────────────
            if (_isEditing)
              Center(
                child: GestureDetector(
                  onTap: _delete,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.delete_outline,
                            size: 14, color: AppTheme.danger),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delete this task',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppTheme.primaryColor.withOpacity(0.5),
      ),
    );
  }

  void _showReminderPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Reminder',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            ...[5, 10, 15, 30, 60].map(
              (min) => ListTile(
                leading: const Icon(Icons.alarm,
                    color: AppTheme.primaryColor),
                title: Text('$min minutes before'),
                onTap: () {
                  setState(() {
                    _hasReminder = true;
                    _reminderMinutes = min;
                  });
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Tag'),
        content: TextField(
          controller: _tagCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., Work Flow, High Priority',
          ),
          onSubmitted: (_) {
            _addTag();
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _addTag();
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ─────────────────────────────────────────────────────────
class _ScheduleRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ScheduleRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.primaryColor.withOpacity(0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ReminderChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  final Subtask subtask;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _SubtaskRow({
    required this.subtask,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: subtask.isCompleted
                    ? AppTheme.primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: subtask.isCompleted
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: subtask.isCompleted
                  ? const Icon(Icons.check,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subtask.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: subtask.isCompleted
                    ? AppTheme.primaryColor.withOpacity(0.4)
                    : AppTheme.primaryDark,
                decoration: subtask.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: AppTheme.primaryColor.withOpacity(0.4),
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close,
                size: 18,
                color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _TagBadge({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close,
                size: 14,
                color: AppTheme.primaryColor.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      labelBuilder(item),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.expand_more,
              color: AppTheme.primaryColor),
        ),
      ),
    );
  }
}
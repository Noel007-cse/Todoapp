// lib/main.dart — Mindful Flow v2

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'data/local/hive_models.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/notification/notification_service.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/task_provider.dart';
import 'presentation/providers/analytics_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/habit_provider.dart';
import 'presentation/providers/ai_chat_provider.dart';
import 'presentation/screens/day_screen.dart';
import 'presentation/screens/growth_screen.dart';
import 'presentation/screens/focus_screen.dart';
import 'presentation/screens/life_screen.dart';
import 'presentation/screens/flow_screen.dart';
import 'presentation/screens/add_edit_task_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force dark status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bgSecondary,
  ));

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(SubtaskAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(TaskListAdapter());
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(MoodEntryAdapter());
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(ChatMessageAdapter());

  await Hive.openBox<Task>('tasks');
  await Hive.openBox<TaskList>('lists');

  // Initialize Notifications
  await NotificationService.instance.initialize();

  runApp(const MindfulFlowApp());
}

class MindfulFlowApp extends StatelessWidget {
  const MindfulFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => AIChatProvider()),
      ],
      child: MaterialApp(
        title: 'Mindful Flow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const MainNavigationScreen(),
      ),
    );
  }
}

/// ─── 5-Tab Navigation ───────────────────────────────────────────────────────
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DayScreen(),
    GrowthScreen(),
    FocusScreen(),
    LifeScreen(),
    FlowScreen(),
  ];

  void _showAddTask(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      fullscreenDialog: true, builder: (_) => const AddEditTaskScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border(top: BorderSide(color: AppColors.cardBorder, width: 0.5)),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.grid_view_rounded, label: 'Day',
                  isActive: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
                _NavItem(icon: Icons.trending_up_rounded, label: 'Growth',
                  isActive: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
                // Center FAB
                GestureDetector(
                  onTap: () => _showAddTask(context),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.add, color: AppColors.bg, size: 26),
                  ),
                ),
                _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Life',
                  isActive: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
                _NavItem(icon: Icons.water_drop_outlined, label: 'Flow',
                  isActive: _currentIndex == 4, onTap: () => setState(() => _currentIndex = 4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isActive ? AppColors.primary : AppColors.textMuted, size: 22),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
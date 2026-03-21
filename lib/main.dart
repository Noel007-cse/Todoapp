// lib/main.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'data/local/hive_models.dart';
import 'core/theme/app_theme.dart';
import 'core/notification/notification_service.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/task_provider.dart';
import 'presentation/providers/analytics_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/my_lists_screen.dart';
import 'presentation/screens/weekly_focus_screen.dart';
import 'presentation/screens/archive_screen.dart';
import 'presentation/screens/add_edit_task_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(SubtaskAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(TaskListAdapter());

  await Hive.openBox<Task>('tasks');
  await Hive.openBox<TaskList>('lists');

  // 🔔 Initialize Notifications (handles permissions + timezone)
  await NotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Mindful Flow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }
}

/// ─── Main Navigation ────────────────────────────────────────────────────────
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MyListsScreen(),
    WeeklyFocusScreen(),
    ArchiveScreen(),
  ];

  void _showAddTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AddEditTaskScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTask(context),
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.wb_sunny_outlined,
              activeIcon: Icons.wb_sunny,
              label: 'Day',
              isActive: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            _NavItem(
              icon: Icons.list_alt_outlined,
              activeIcon: Icons.list_alt,
              label: 'Lists',
              isActive: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            const SizedBox(width: 60), // Space for FAB
            _NavItem(
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month,
              label: 'Schedule',
              isActive: _currentIndex == 2,
              onTap: () => setState(() => _currentIndex = 2),
            ),
            _NavItem(
              icon: Icons.archive_outlined,
              activeIcon: Icons.archive,
              label: 'Archive',
              isActive: _currentIndex == 3,
              onTap: () => setState(() => _currentIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withOpacity(0.4),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
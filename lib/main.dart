import 'package:flutter/material.dart';

import 'screens/history_screen.dart';
import 'screens/plans_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/studio_screen.dart';
import 'theme.dart';

void main() => runApp(const TikTokStudioApp());

class TikTokStudioApp extends StatelessWidget {
  const TikTokStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = buildAppTheme();
    return MaterialApp(
      title: 'ستوديو التيكتوك',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark, // التصميم dark ديما
      // الواجهة الكل من اليمين لليسار
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const SplashScreen(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _historyKey = 0;
  int _plansKey = 0;
  int _settingsKey = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const StudioScreen(),
          HistoryScreen(key: ValueKey(_historyKey)),
          PlansScreen(key: ValueKey(_plansKey)),
          SettingsScreen(key: ValueKey(_settingsKey)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          _index = i;
          // نعاودو نقراو (ينجمو يتبدّلو من شاشة النتيجة/التوليد)
          if (i == 1) _historyKey++;
          if (i == 2) _plansKey++;
          if (i == 3) _settingsKey++;
        }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.movie_creation_outlined), label: 'حضّر'),
          NavigationDestination(icon: Icon(Icons.bookmarks_outlined), label: 'المحفوظات'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'البرنامج'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

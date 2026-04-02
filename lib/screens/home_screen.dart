import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'expenses_screen.dart';
import 'add_expense_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import '../models/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ExpensesScreen(),
    const SizedBox(), // placeholder for FAB
    const StatsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isAr = state?.isArabic ?? true;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: [
          const DashboardScreen(),
          const ExpensesScreen(),
          const StatsScreen(),
          const SettingsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          setState(() {});
        },
        backgroundColor: const Color(0xFF1A3A5C),
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.dashboard_rounded, label: isAr ? 'لوحة' : 'Tableau', index: 0, current: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
              _NavItem(icon: Icons.receipt_long_rounded, label: isAr ? 'النفقات' : 'Dépenses', index: 1, current: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
              const SizedBox(width: 48),
              _NavItem(icon: Icons.bar_chart_rounded, label: isAr ? 'إحصاء' : 'Stats', index: 2, current: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
              _NavItem(icon: Icons.settings_rounded, label: isAr ? 'إعدادات' : 'Réglages', index: 3, current: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: current ? const Color(0xFF1A3A5C) : Colors.grey, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: current ? const Color(0xFF1A3A5C) : Colors.grey,
                fontWeight: current ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

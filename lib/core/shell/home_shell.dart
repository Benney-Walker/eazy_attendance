import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../../features/dashboard/ui/dashboard_screen.dart';
import '../../features/settings/ui/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [DashboardScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.gray100, width: 1.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.blue50,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined, color: AppColors.gray400),
              selectedIcon: Icon(Icons.checklist, color: AppColors.blue600),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: AppColors.gray400),
              selectedIcon: Icon(Icons.settings, color: AppColors.blue600),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
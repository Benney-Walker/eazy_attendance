import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../sync/sync_controller.dart';
import '../../features/dashboard/ui/dashboard_screen.dart';
import '../../features/settings/ui/settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _index = 0;

  static const _tabs = [DashboardScreen(), SettingsScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ask for notification permission once the user is in the app (Android 13+).
    // Deferred to after first frame so it doesn't race the initial build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncNotifierProvider).requestPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Returning to the foreground: try to drain any queued attendance.
      ref.read(syncControllerProvider.notifier).onResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the sync engine alive for the whole signed-in session so its
    // connectivity trigger stays active regardless of which tab is showing.
    ref.watch(syncControllerProvider);

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

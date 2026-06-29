import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'home_tab.dart';
import 'jadwal_tab.dart';
import 'belajar_tab.dart';
import 'profil_tab.dart';


/// Main shell — bottom nav with 4 tabs and the persistent top app bar.
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _tab,
        children: [
          HomeTab(onSettingsPressed: () => setState(() => _tab = 3)),
          const JadwalTab(),
          const BelajarTab(),
          const ProfilTab(),
        ],
      ),
      floatingActionButton: null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            indicatorColor: AppColors.primary.withValues(alpha: 0.15),
            labelTextStyle: WidgetStatePropertyAll(
              AppText.labelCaps().copyWith(fontSize: 10),
            ),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: AppColors.onSurfaceVariant),
                selectedIcon: Icon(Icons.home, color: AppColors.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.schedule_outlined, color: AppColors.onSurfaceVariant),
                selectedIcon: Icon(Icons.schedule, color: AppColors.primary),
                label: 'Jadwal',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined, color: AppColors.onSurfaceVariant),
                selectedIcon: Icon(Icons.menu_book, color: AppColors.primary),
                label: 'Belajar',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline, color: AppColors.onSurfaceVariant),
                selectedIcon: Icon(Icons.person, color: AppColors.primary),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/theme_service.dart';
import '../../widgets/common.dart';
import 'home_tab.dart';
import 'jadwal_tab.dart';
import 'belajar_tab.dart';
import 'profil_tab.dart';

/// Main shell — bottom nav with 4 tabs and the persistent top app bar.
class DashboardShell extends StatefulWidget {
  final int initialTab;
  const DashboardShell({super.key, this.initialTab = 0});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  static const _items = [
    (Icons.home_outlined, Icons.home, 'HOME'),
    (Icons.schedule_outlined, Icons.schedule, 'JADWAL'),
    (Icons.menu_book_outlined, Icons.menu_book, 'BELAJAR'),
    (Icons.person_outline, Icons.person, 'PROFIL'),
  ];

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder: theme toggle rebuilds shell + non-const tabs.
    // JANGAN pakai const pada tab children — Flutter skip updateChild
    // kalau widget instance identical, jadi AppColors getter gak ke-baca ulang.
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: AmbientBackground(
            child: IndexedStack(
              index: _tab,
              children: [
                HomeTab(onSettingsPressed: () => setState(() => _tab = 3)),
                JadwalTab(),
                BelajarTab(),
                ProfilTab(),
              ],
            ),
          ),
          bottomNavigationBar: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.75),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      children: List.generate(
                        _items.length,
                        (i) => Expanded(child: _navItem(i)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _navItem(int i) {
    final (iconOff, iconOn, label) = _items[i];
    final selected = _tab == i;
    return InkResponse(
      onTap: () => setState(() => _tab = i),
      highlightShape: BoxShape.rectangle,
      containedInkWell: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedScale(
              scale: selected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(
                selected ? iconOn : iconOff,
                size: 24,
                color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: AppText.labelCaps().copyWith(
              fontSize: 9,
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
              shadows: selected
                  ? [Shadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 8)]
                  : null,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

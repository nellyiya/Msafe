import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import 'chw/chw_dashboard_screen.dart';
import 'chw/mothers_list_screen.dart';
import 'chw/predictions_overview_screen.dart';
import 'chw/register_mother_screen.dart';
import 'health_professional/hospital_home_screen.dart';
import 'health_professional/referrals_list_screen.dart';
import 'health_professional/hospital_reports_screen.dart';
import 'health_professional/hospital_profile_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/admin_mothers_screen.dart';
import 'admin/admin_referrals_screen.dart';
import 'admin/admin_appointments_screen.dart';
import 'admin/admin_chws_screen.dart';
import 'admin/admin_healthcare_pro_screen.dart';
import 'admin/admin_facilities_screen.dart';
import 'admin/admin_ai_insights_screen.dart';
import 'admin/admin_reports_screen.dart';
import 'settings_screen.dart';

// ─────────────────────────────────────────────
//  TOKENS
// ─────────────────────────────────────────────
const _teal     = Color(0xFF1A7A6E);
const _tealGlow = Color(0xFF1A7A6E);
const _white    = Color(0xFFFFFFFF);
const _neu      = Color(0xFFEDF2F1);
const _gray     = Color(0xFF9CA3AF);
const _navy     = Color(0xFF1E2D4E);

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  VoidCallback? _chwRefreshCallback;
  VoidCallback? _hospitalRefreshCallback;
  VoidCallback? _adminRefreshCallback;

  @override
  Widget build(BuildContext context) {
    final authProvider    = context.watch<AuthProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final isEnglish       = languageProvider.isEnglish;
    final userRole        = authProvider.currentUserRole;

    if (userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: _teal)));
    }

    final screens  = _getScreens(userRole, isEnglish);
    final navItems = _getNavItems(userRole, isEnglish);

    // Admin uses sidebar
    if (userRole == AppUserRole.admin) {
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(navItems, userRole),
            Expanded(child: screens[_currentIndex]),
          ],
        ),
      );
    }

    // CHW gets the notched FAB layout
    if (userRole == AppUserRole.chw) {
      return Scaffold(
        backgroundColor: _neu,
        extendBody: true,
        body: IndexedStack(index: _currentIndex, children: screens),
        floatingActionButton: _RegisterFAB(isEnglish: isEnglish),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _ChwBottomBar(
          currentIndex: _currentIndex,
          isEnglish: isEnglish,
          onTap: (i) {
            setState(() => _currentIndex = i);
            if (i == 0) _chwRefreshCallback?.call();
          },
        ),
      );
    }

    // Healthcare professional
    return Scaffold(
      backgroundColor: _neu,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _SimpleBottomBar(
        items: navItems,
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 0) _hospitalRefreshCallback?.call();
        },
      ),
    );
  }

  // ── Admin Sidebar ──────────────────────────────────────────────────────────
  Widget _buildSidebar(List<BottomNavigationBarItem> navItems, AppUserRole role) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF0D6B5E),
        border: Border(right: BorderSide(color: Color(0xFF0A5549))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.health_and_safety, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('MamaSafe',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.2)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item       = navItems[index];
                final isSelected = _currentIndex == index;
                return InkWell(
                  onTap: () {
                    setState(() => _currentIndex = index);
                    if (index == 0) _adminRefreshCallback?.call();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? (item.activeIcon as Icon).icon : (item.icon as Icon).icon,
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(item.label!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.2)),
          InkWell(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: Colors.white.withOpacity(0.9), size: 22),
                  const SizedBox(width: 12),
                  Text('Logout',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout',
            style: TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: _gray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: _gray),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _refreshDashboard(AppUserRole role) {
    switch (role) {
      case AppUserRole.chw:
        _chwRefreshCallback?.call();
        break;
      case AppUserRole.healthcareProfessional:
        _hospitalRefreshCallback?.call();
        break;
      case AppUserRole.admin:
        _adminRefreshCallback?.call();
        break;
    }
  }

  List<Widget> _getScreens(AppUserRole role, bool isEnglish) {
    switch (role) {
      case AppUserRole.chw:
        return [
          ChwDashboardScreen(onRefreshCallback: (cb) => _chwRefreshCallback = cb),
          const MothersListScreen(),
          const PredictionsOverviewScreen(),
          const SettingsScreen(),
        ];
      case AppUserRole.healthcareProfessional:
        return [
          HospitalHomeScreen(onRefreshCallback: (cb) => _hospitalRefreshCallback = cb),
          ReferralsScreen(),
          const HospitalReportsScreen(),
          const HospitalProfileScreen(),
        ];
      case AppUserRole.admin:
        return [
          const AdminDashboardScreen(),
          const AdminMothersScreen(),
          const AdminReferralsScreen(),
          const AdminAppointmentsScreen(),
          const AdminCHWsScreen(),
          const AdminHealthcareProScreen(),
          const AdminFacilitiesScreen(),
          const AdminAIInsightsScreen(),
          const AdminReportsScreen(),
        ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems(AppUserRole role, bool isEnglish) {
    switch (role) {
      case AppUserRole.chw:
        return [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_rounded),
            label: isEnglish ? 'Home' : 'Ahabanza',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            activeIcon: const Icon(Icons.people_rounded),
            label: isEnglish ? 'Mothers' : 'Ababyeyi',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.psychology_outlined),
            activeIcon: const Icon(Icons.psychology_rounded),
            label: isEnglish ? 'Predictions' : 'Ibitekerezo',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person_rounded),
            label: isEnglish ? 'Profile' : 'Profili',
          ),
        ];
      case AppUserRole.healthcareProfessional:
        return [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_rounded),
            label: isEnglish ? 'Home' : 'Ahabanza',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inbox_outlined),
            activeIcon: const Icon(Icons.inbox_rounded),
            label: isEnglish ? 'Referrals' : 'Referrals',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assessment_outlined),
            activeIcon: const Icon(Icons.assessment),
            label: isEnglish ? 'Reports' : 'Raporo',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person_rounded),
            label: isEnglish ? 'Profile' : 'Profili',
          ),
        ];
      case AppUserRole.admin:
        return [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          const BottomNavigationBarItem(icon: Icon(Icons.pregnant_woman_outlined), activeIcon: Icon(Icons.pregnant_woman), label: 'Mothers'),
          const BottomNavigationBarItem(icon: Icon(Icons.local_hospital_outlined), activeIcon: Icon(Icons.local_hospital), label: 'Referrals'),
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Appointments'),
          const BottomNavigationBarItem(icon: Icon(Icons.health_and_safety_outlined), activeIcon: Icon(Icons.health_and_safety), label: 'CHWs'),
          const BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), activeIcon: Icon(Icons.medical_services), label: 'Healthcare Pro'),
          const BottomNavigationBarItem(icon: Icon(Icons.business_outlined), activeIcon: Icon(Icons.business), label: 'Facilities'),
          const BottomNavigationBarItem(icon: Icon(Icons.psychology_outlined), activeIcon: Icon(Icons.psychology), label: 'AI Insights'),
          const BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), activeIcon: Icon(Icons.assessment), label: 'Reports'),
        ];
    }
  }
}

// ─────────────────────────────────────────────
//  CHW NOTCHED BOTTOM BAR  (4 items + center notch)
// ─────────────────────────────────────────────
class _ChwBottomBar extends StatelessWidget {
  final int currentIndex;
  final bool isEnglish;
  final ValueChanged<int> onTap;

  const _ChwBottomBar({
    required this.currentIndex,
    required this.isEnglish,
    required this.onTap,
  });

  static const _items = [
    _NavMeta(Icons.home_outlined,      Icons.home_rounded,       'Home',        'Ahabanza'),
    _NavMeta(Icons.people_outline,     Icons.people_rounded,     'Mothers',     'Ababyeyi'),
    _NavMeta(Icons.psychology_outlined, Icons.psychology_rounded, 'Predictions', 'Ibitekerezo'),
    _NavMeta(Icons.person_outline,     Icons.person_rounded,     'Profile',     'Profili'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [
          BoxShadow(
            color: _teal.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              // Left 2 items
              _buildItem(0),
              _buildItem(1),
              // Center gap for FAB
              const SizedBox(width: 72),
              // Right 2 items
              _buildItem(2),
              _buildItem(3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    final meta       = _items[index];
    final isSelected = currentIndex == index;
    final label      = isEnglish ? meta.labelEn : meta.labelRw;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: 42,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected ? _teal.withOpacity(0.10) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  isSelected ? meta.activeIcon : meta.icon,
                  color: isSelected ? _teal : _gray,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? _teal : _gray,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  REGISTER MOTHER FAB
// ─────────────────────────────────────────────
class _RegisterFAB extends StatelessWidget {
  final bool isEnglish;
  const _RegisterFAB({required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterMotherScreen()),
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: _teal,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _tealGlow.withOpacity(0.45),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: _tealGlow.withOpacity(0.20),
              blurRadius: 40,
              spreadRadius: 4,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: _white, size: 30),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SIMPLE BOTTOM BAR  (healthcare professional)
// ─────────────────────────────────────────────
class _SimpleBottomBar extends StatelessWidget {
  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SimpleBottomBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [
          BoxShadow(
            color: _teal.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(items.length, (i) {
              final item       = items[i];
              final isSelected = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 42,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isSelected ? _teal.withOpacity(0.10) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            isSelected
                                ? (item.activeIcon as Icon).icon
                                : (item.icon as Icon).icon,
                            color: isSelected ? _teal : _gray,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isSelected ? _teal : _gray,
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        child: Text(item.label ?? ''),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  NAV META  (icon + label data)
// ─────────────────────────────────────────────
class _NavMeta {
  final IconData icon;
  final IconData activeIcon;
  final String labelEn;
  final String labelRw;
  const _NavMeta(this.icon, this.activeIcon, this.labelEn, this.labelRw);
}

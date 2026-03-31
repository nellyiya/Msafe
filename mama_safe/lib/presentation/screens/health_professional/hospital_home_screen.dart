import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../../core/responsive.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../services/api_service.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
const _teal = Color(0xFF1A7A6E);
const _tealDark = Color(0xFF145F55);
const _navy = Color(0xFF1E2D4E);
const _white = Color(0xFFFFFFFF);
const _bgGradientStart = Color(0xFFEDF2F1);
const _bgGradientEnd = Color(0xFFF5F7FA);
const _gray = Color(0xFF6B7280);
const _border = Color(0xFFDDE3E2);

/// Hospital Home Screen - Shows only stat cards
class HospitalHomeScreen extends StatefulWidget {
  final Function(VoidCallback)? onRefreshCallback;

  const HospitalHomeScreen({super.key, this.onRefreshCallback});

  @override
  State<HospitalHomeScreen> createState() => _HospitalHomeScreenState();
}

class _HospitalHomeScreenState extends State<HospitalHomeScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.onRefreshCallback?.call(_loadDashboardData);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final data = await apiService.getHealthcareProDashboard();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final isEnglish = languageProvider.isEnglish;
    final userName = authProvider.currentUserName ?? 'Doctor';

    return Scaffold(
      backgroundColor: _white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgGradientStart, _bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.padding(context),
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isEnglish ? 'Hello' : 'Muraho'}, Dr. $userName',
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEnglish
                          ? 'Welcome to your Health Dashboard'
                          : 'Karibu ku Dashboard',
                      style: TextStyle(
                        color: _gray.withOpacity(0.70),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Body ────────────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: _teal,
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.padding(context),
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_buildDashboard(context, isEnglish)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, bool isEnglish) {
    final totalReferrals = _dashboardData?['total_referrals'] ?? 0;
    final pendingReferrals = _dashboardData?['pending_referrals'] ?? 0;
    final emergencyCases = _dashboardData?['emergency_cases'] ?? 0;
    final scheduledAppointments =
        _dashboardData?['scheduled_appointments'] ?? 0;

    final dashboardCards = [
      {
        'title': isEnglish ? 'Total Referrals' : 'Referrals Zose',
        'value': totalReferrals.toString(),
        'status': isEnglish ? 'This Month' : 'Ukwezi',
        'gradient': [const Color(0xFF1A7A6E), const Color(0xFF259883)],
        'icon': Icons.inbox_rounded,
        'progress': 75.0,
      },
      {
        'title': isEnglish ? 'Pending Cases' : 'Ibibazo Zigihari',
        'value': pendingReferrals.toString(),
        'status': isEnglish ? 'Urgent' : 'Bikomeye',
        'gradient': [const Color(0xFF1A7A6E), const Color(0xFF259883)],
        'icon': Icons.pending_actions_rounded,
        'progress': 45.0,
      },
      {
        'title': isEnglish ? 'Emergency Cases' : 'Ibibazo Bikomeye',
        'value': emergencyCases.toString(),
        'status': isEnglish ? 'Active' : 'Ukuri',
        'gradient': [const Color(0xFF1A7A6E), const Color(0xFF259883)],
        'icon': Icons.emergency_rounded,
        'progress': 60.0,
      },
      {
        'title': isEnglish ? 'Appointments' : 'Gahunda',
        'value': scheduledAppointments.toString(),
        'status': isEnglish ? 'Scheduled' : 'Byahitanwe',
        'gradient': [const Color(0xFF1A7A6E), const Color(0xFF259883)],
        'icon': Icons.calendar_today_rounded,
        'progress': 85.0,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.95,
      ),
      itemCount: dashboardCards.length,
      itemBuilder: (context, index) {
        final card = dashboardCards[index];
        return _GlassmorphCard(
          title: card['title'] as String,
          value: card['value'] as String,
          status: card['status'] as String,
          gradient: card['gradient'] as List<Color>,
          icon: card['icon'] as IconData,
          progress: card['progress'] as double,
        );
      },
    );
  }

  Widget _buildStatsSection(BuildContext context, bool isEnglish) {
    final totalReferrals = _dashboardData?['total_referrals'] ?? 0;
    final pendingReferrals = _dashboardData?['pending_referrals'] ?? 0;
    final emergencyCases = _dashboardData?['emergency_cases'] ?? 0;
    final scheduledAppointments =
        _dashboardData?['scheduled_appointments'] ?? 0;
    final completedCases = _dashboardData?['completed_cases'] ?? 0;
    final avgResponseTime = _dashboardData?['avg_response_time'] ?? '0h';

    final stats = [
      {
        'title': isEnglish ? 'Total Referrals Received' : 'Referrals zose',
        'value': totalReferrals.toString(),
        'icon': Icons.inbox_rounded,
        'accentColor': _teal,
      },
      {
        'title': isEnglish ? 'Pending Referrals' : 'Referrals zigihari',
        'value': pendingReferrals.toString(),
        'icon': Icons.pending_actions_rounded,
        'accentColor': const Color(0xFFF59E0B),
      },
      {
        'title': isEnglish ? 'Emergency Cases' : 'Ibibazo bikomeye',
        'value': emergencyCases.toString(),
        'icon': Icons.emergency_rounded,
        'accentColor': const Color(0xFFDC2626),
      },
      {
        'title': isEnglish ? 'Scheduled Appointments' : 'Gahunda',
        'value': scheduledAppointments.toString(),
        'icon': Icons.calendar_today_rounded,
        'accentColor': const Color(0xFF059669),
      },
      {
        'title': isEnglish ? 'Completed Cases' : 'Byakiriwe',
        'value': completedCases.toString(),
        'icon': Icons.check_circle_outline_rounded,
        'accentColor': _teal,
      },
      {
        'title': isEnglish ? 'Avg Response Time' : 'Igihe',
        'value': avgResponseTime.toString(),
        'icon': Icons.timer_outlined,
        'accentColor': const Color(0xFF6366F1),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.gridCrossAxisCount(context),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _StatCard(
          title: stat['title'] as String,
          value: stat['value'] as String,
          icon: stat['icon'] as IconData,
          accentColor: stat['accentColor'] as Color,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  GLASSMORPHISM CARD
// ─────────────────────────────────────────────
class _GlassmorphCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;
  final List<Color> gradient;
  final IconData icon;
  final double progress;

  const _GlassmorphCard({
    required this.title,
    required this.value,
    required this.status,
    required this.gradient,
    required this.icon,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradient[0].withOpacity(0.85),
                gradient[1].withOpacity(0.70),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _white.withOpacity(0.20), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.30),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top: Title and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: _white.withOpacity(0.80),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          status,
                          style: TextStyle(
                            color: _white.withOpacity(0.65),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _white.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: _white, size: 22),
                  ),
                ],
              ),
              // Middle: Big Number
              Text(
                value,
                style: const TextStyle(
                  color: _white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  height: 1.0,
                ),
              ),
              // Bottom: Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 4,
                      backgroundColor: _white.withOpacity(0.20),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _white.withOpacity(0.80),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${progress.toStringAsFixed(0)}% Complete',
                    style: TextStyle(
                      color: _white.withOpacity(0.70),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STAT CARD (Legacy)
// ─────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.25),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top section with icon and number
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: _white, size: 24),
                  ),
                  // Number
                  Text(
                    value,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom dark label bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: _white.withOpacity(0.95),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

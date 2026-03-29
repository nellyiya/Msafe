import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
const _bgPage = Color(0xFFEDF2F1);
const _neuBase = Color(0xFFEDF2F1);
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
      backgroundColor: _bgPage,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.padding(context),
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: _teal,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0xFFFFFFFF),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: Offset(-6, -6),
                  ),
                  BoxShadow(
                    color: const Color(0xFF1A7A6E).withOpacity(0.30),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(6, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isEnglish ? 'Hello' : 'Muraho'}, Dr. $userName',
                          style: const TextStyle(
                            color: _white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEnglish ? 'Healthcare Professional' : 'Umuganga',
                          style: TextStyle(
                            color: _white.withOpacity(0.80),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _neuBase,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        const BoxShadow(
                          color: Color(0xFFFFFFFF),
                          blurRadius: 6,
                          offset: Offset(-3, -3),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'D',
                        style: const TextStyle(
                          color: _teal,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
                    children: [
                      _buildStatsSection(context, isEnglish),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
//  STAT CARD
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _teal.withOpacity(0.35), width: 1.2),
        boxShadow: [
          const BoxShadow(
            color: Color(0xFFFFFFFF),
            blurRadius: 14,
            spreadRadius: 1,
            offset: Offset(-5, -5),
          ),
          BoxShadow(
            color: const Color(0xFF1A7A6E).withOpacity(0.12),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(5, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top: inset icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _neuBase,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                const BoxShadow(
                  color: Color(0xFFFFFFFF),
                  blurRadius: 5,
                  offset: Offset(-3, -3),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 5,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          // Bottom: big number + label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: _gray.withOpacity(0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

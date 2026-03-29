import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/app_colors.dart';
import '../../../core/responsive.dart';
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

/// Hospital Reports Screen - Performance & Analytics
class HospitalReportsScreen extends StatefulWidget {
  const HospitalReportsScreen({super.key});

  @override
  State<HospitalReportsScreen> createState() => _HospitalReportsScreenState();
}

class _HospitalReportsScreenState extends State<HospitalReportsScreen> {
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _referrals = [];
  List<dynamic> _hospitalPerformance = [];
  Map<String, dynamic>? _referralDistribution;
  List<dynamic> _hospitalWorkload = [];
  bool _isLoading = true;
  Timer? _autoRefreshTimer;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _loadReports();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final futures = await Future.wait([
        apiService.getHealthcareProDashboard(),
        apiService.getIncomingReferrals(),
        apiService.getHospitalPerformance(days: _selectedDays),
        apiService.getReferralDistribution(days: _selectedDays),
        apiService.getHospitalWorkload(days: _selectedDays),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboardData = futures[0] as Map<String, dynamic>;
        _referrals = futures[1] as List<dynamic>;
        _hospitalPerformance = futures[2] as List<dynamic>;
        _referralDistribution = futures[3] as Map<String, dynamic>;
        _hospitalWorkload = futures[4] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _downloadReport(String type) {
    final parts = type.split('_');
    final period = parts[0];
    final format = parts[1];
    final now = DateTime.now();
    String dateRange;
    List<dynamic> filteredData;

    switch (period) {
      case 'daily':
        dateRange =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        filteredData = _referrals.where((ref) {
          if (ref['created_at'] == null) return false;
          final createdAt = DateTime.parse(ref['created_at']);
          return createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day;
        }).toList();
        break;
      case 'monthly':
        dateRange = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        filteredData = _referrals.where((ref) {
          if (ref['created_at'] == null) return false;
          final createdAt = DateTime.parse(ref['created_at']);
          return createdAt.year == now.year && createdAt.month == now.month;
        }).toList();
        break;
      case 'yearly':
        dateRange = '${now.year}';
        filteredData = _referrals.where((ref) {
          if (ref['created_at'] == null) return false;
          final createdAt = DateTime.parse(ref['created_at']);
          return createdAt.year == now.year;
        }).toList();
        break;
      default:
        filteredData = _referrals;
        dateRange = 'all';
    }

    final emergencyCount = filteredData
        .where((r) => r['status'] == 'Emergency Care Required')
        .length;
    final completedCount =
        filteredData.where((r) => r['status'] == 'Completed').length;
    final totalCount = filteredData.length;
    final emergencyRate = totalCount > 0
        ? (emergencyCount / totalCount * 100).toStringAsFixed(1)
        : '0.0';
    final completionRate = totalCount > 0
        ? (completedCount / totalCount * 100).toStringAsFixed(1)
        : '0.0';

    final reportData = '''
HOSPITAL PERFORMANCE REPORT
Period: ${period.toUpperCase()} ($dateRange)
Generated: ${DateTime.now()}

=== KEY METRICS ===
Total Referrals: $totalCount
Emergency Cases: $emergencyCount
Completed Cases: $completedCount
Emergency Rate: $emergencyRate%
Completion Rate: $completionRate%
Avg Response Time: ${_dashboardData?['avg_response_time'] ?? 'N/A'}

=== STATUS DISTRIBUTION ===
Pending: ${filteredData.where((r) => r['status'] == 'Pending').length}
Received: ${filteredData.where((r) => r['status'] == 'Received').length}
Emergency: $emergencyCount
Scheduled: ${filteredData.where((r) => r['status'] == 'Appointment Scheduled').length}
Completed: $completedCount

=== REFERRAL DETAILS ===
''';

    final csvData = format == 'csv' ? _generateCSV(filteredData) : reportData;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Downloading ${period.toUpperCase()} report as ${format.toUpperCase()}...'),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'View',
          textColor: _white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: _white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: const Text(
                  'Report Preview',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Text(
                    csvData,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: _navy,
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: _gray),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _generateCSV(List<dynamic> data) {
    String csv =
        'ID,Patient Name,Age,Status,Severity,Risk Level,Created At,CHW Name\n';
    for (var ref in data) {
      csv +=
          '${ref['id']},"${ref['mother']?['name'] ?? 'N/A'}",${ref['mother']?['age'] ?? 'N/A'},"${ref['status'] ?? 'N/A'}","${ref['severity'] ?? 'N/A'}","${ref['mother']?['risk_level'] ?? 'N/A'}","${ref['created_at'] ?? 'N/A'}","${ref['chw']?['name'] ?? 'N/A'}"\n';
    }
    return csv;
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isEnglish = languageProvider.isEnglish;

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: Column(
          children: [
            // ── Teal header ─────────────────────────────────────
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
                          isEnglish ? 'Reports' : 'Raporo',
                          style: const TextStyle(
                            color: _white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEnglish
                              ? 'Performance & Analytics'
                              : 'Imikorere n\'isesengura',
                          style: TextStyle(
                            color: _white.withOpacity(0.80),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // ── Time filter ──
                      PopupMenuButton<int>(
                        initialValue: _selectedDays,
                        onSelected: (days) {
                          setState(() => _selectedDays = days);
                          _loadReports();
                        },
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        color: _white,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _white.withOpacity(0.3), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  color: _white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${_selectedDays}d',
                                style: const TextStyle(
                                  color: _white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down_rounded,
                                  color: _white, size: 18),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 7, child: Text('Last 7 days')),
                          const PopupMenuItem(value: 30, child: Text('Last 30 days')),
                          const PopupMenuItem(value: 90, child: Text('Last 90 days')),
                          const PopupMenuItem(value: 365, child: Text('Last year')),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // ── Download button ──
                      PopupMenuButton<String>(
                        onSelected: _downloadReport,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        color: _white,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _white.withOpacity(0.35), width: 1.2),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download_rounded, color: _white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Export',
                                style: TextStyle(
                                  color: _white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.arrow_drop_down_rounded,
                                  color: _white, size: 20),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'comprehensive_pdf',
                            child: _popupItem(Icons.picture_as_pdf_rounded,
                                'Full Report (PDF)', const Color(0xFFDC2626)),
                          ),
                          PopupMenuItem(
                            value: 'analytics_csv',
                            child: _popupItem(Icons.analytics_rounded,
                                'Analytics (CSV)', const Color(0xFF059669)),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'performance_pdf',
                            child: _popupItem(Icons.trending_up_rounded,
                                'Performance (PDF)', const Color(0xFF7C3AED)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: _teal,
                onRefresh: _loadReports,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.padding(context),
                    vertical: 20,
                  ),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: CircularProgressIndicator(color: _teal),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPerformanceIndicators(context, isEnglish),
                            const SizedBox(height: 16),
                            _buildReferralTrends(context, isEnglish),
                            const SizedBox(height: 16),
                            _buildWorkloadAnalysis(context, isEnglish),
                            const SizedBox(height: 16),
                            _buildStatusDistribution(context, isEnglish),
                            const SizedBox(height: 16),
                            _buildReferralDistribution(context, isEnglish),
                            const SizedBox(height: 8),
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

  // ── Popup menu item helper ───────────────────────────────────
  Widget _popupItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
              color: _navy, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ── Section header helper ────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: _neuBase,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                const BoxShadow(color: Color(0xFFFFFFFF), blurRadius: 5, offset: Offset(-3, -3)),
                BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 5, offset: const Offset(3, 3)),
              ],
            ),
            child: Icon(icon, color: _teal, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsSection(BuildContext context, bool isEnglish) {
    final avgResponseTime = _dashboardData?['avg_response_time'] ?? '0h';
    final emergencyCases = _dashboardData?['emergency_cases'] ?? 0;
    final totalReferrals = _dashboardData?['total_referrals'] ?? 0;
    final completedCases = _dashboardData?['completed_cases'] ?? 0;
    final patientsSatisfaction = _dashboardData?['patient_satisfaction'] ?? 85;
    final bedOccupancy = _dashboardData?['bed_occupancy'] ?? 72;

    final emergencyRate = totalReferrals > 0
        ? (emergencyCases / totalReferrals * 100).toStringAsFixed(1)
        : '0.0';
    final completionRate = totalReferrals > 0
        ? (completedCases / totalReferrals * 100).toStringAsFixed(1)
        : '0.0';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(
          icon: Icons.timer_outlined,
          label: isEnglish ? 'Response Time' : 'Igihe',
          value: avgResponseTime,
          iconBg: _navy,
        ),
        _buildMetricCard(
          icon: Icons.emergency_rounded,
          label: isEnglish ? 'Emergency Rate' : 'Ibibazo bikomeye',
          value: '$emergencyRate%',
          iconBg: const Color(0xFFDC2626),
        ),
        _buildMetricCard(
          icon: Icons.check_circle_outline_rounded,
          label: isEnglish ? 'Completion' : 'Byarangiye',
          value: '$completionRate%',
          iconBg: const Color(0xFF059669),
        ),
        _buildMetricCard(
          icon: Icons.calendar_month_rounded,
          label: isEnglish ? 'Total Cases' : 'Byose',
          value: totalReferrals.toString(),
          iconBg: _teal,
        ),
        _buildMetricCard(
          icon: Icons.sentiment_satisfied_rounded,
          label: isEnglish ? 'Satisfaction' : 'Kunyurwa',
          value: '$patientsSatisfaction%',
          iconBg: const Color(0xFF7C3AED),
        ),
        _buildMetricCard(
          icon: Icons.hotel_rounded,
          label: isEnglish ? 'Bed Usage' : 'Ibitanda',
          value: '$bedOccupancy%',
          iconBg: const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
            color: _neuBase,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              const BoxShadow(color: Color(0xFFFFFFFF), blurRadius: 5, offset: Offset(-3, -3)),
              BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 5, offset: const Offset(3, 3)),
            ],
          ),
          child: Icon(icon, color: iconBg, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: _navy,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: _gray, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralTrends(BuildContext context, bool isEnglish) {
    final now = DateTime.now();
    final last7Days =
        List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    final dailyCounts = <int>[];
    for (var day in last7Days) {
      final count = _referrals.where((ref) {
        if (ref['created_at'] == null) return false;
        final createdAt = DateTime.parse(ref['created_at']);
        return createdAt.year == day.year &&
            createdAt.month == day.month &&
            createdAt.day == day.day;
      }).length;
      dailyCounts.add(count);
    }

    final maxCount =
        dailyCounts.isEmpty ? 1 : dailyCounts.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          _sectionHeader(
            isEnglish
                ? 'Referrals Per Day (Last 7 Days)'
                : 'Referrals ku munsi',
            Icons.bar_chart_rounded,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final barH =
                    maxCount > 0 ? (dailyCounts[i] / maxCount * 110) : 0.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      dailyCounts[i].toString(),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _navy),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: barH < 20 ? 20 : barH,
                      decoration: BoxDecoration(
                        color: _teal,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ][last7Days[i].weekday - 1],
                      style: const TextStyle(fontSize: 10, color: _gray),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistribution(BuildContext context, bool isEnglish) {
    final emergencyCount = _referrals
        .where((r) => r['status'] == 'Emergency Care Required')
        .length;
    final scheduledCount =
        _referrals.where((r) => r['status'] == 'Appointment Scheduled').length;
    final completedCount =
        _referrals.where((r) => r['status'] == 'Completed').length;
    final pendingCount =
        _referrals.where((r) => r['status'] == 'Pending').length;
    final receivedCount =
        _referrals.where((r) => r['status'] == 'Received').length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          _sectionHeader(
            isEnglish ? 'Status Distribution' : 'Imiterere',
            Icons.pie_chart_outline_rounded,
          ),
          const SizedBox(height: 16),
          _buildStatusBar('Emergency', emergencyCount, const Color(0xFFDC2626)),
          const SizedBox(height: 10),
          _buildStatusBar('Scheduled', scheduledCount, _teal),
          const SizedBox(height: 10),
          _buildStatusBar('Completed', completedCount, const Color(0xFF059669)),
          const SizedBox(height: 10),
          _buildStatusBar('Pending', pendingCount, const Color(0xFFF59E0B)),
          const SizedBox(height: 10),
          _buildStatusBar('Received', receivedCount, _navy),
        ],
      ),
    );
  }

  Widget _buildStatusBar(String label, int count, Color color) {
    final total = _referrals.length;
    final percentage = total > 0 ? (count / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              '$count (${(percentage * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(fontSize: 12, color: _gray),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: _border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceIndicators(BuildContext context, bool isEnglish) {
    final performance = _hospitalPerformance.isNotEmpty ? _hospitalPerformance[0] : {};
    final responseTime = performance['avg_response_time'] ?? 0;
    final patientThroughput = performance['patient_throughput'] ?? 0;
    final qualityScore = performance['quality_score'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          _sectionHeader(
            isEnglish ? 'Performance Indicators' : 'Imikorere',
            Icons.trending_up_rounded,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildIndicator(
                  'Response Time',
                  '${responseTime}min',
                  responseTime < 30 ? _teal : const Color(0xFFF59E0B),
                  Icons.timer_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIndicator(
                  'Throughput',
                  '$patientThroughput/day',
                  _navy,
                  Icons.people_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildIndicator(
                  'Quality Score',
                  '$qualityScore%',
                  qualityScore > 80 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  Icons.star_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _gray,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadAnalysis(BuildContext context, bool isEnglish) {
    final workload = _hospitalWorkload;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          _sectionHeader(
            isEnglish ? 'Workload Analysis' : 'Akazi',
            Icons.work_outline_rounded,
          ),
          const SizedBox(height: 16),
          if (workload.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No workload data available',
                  style: TextStyle(color: _gray, fontSize: 14),
                ),
              ),
            )
          else
            ...workload.take(5).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['department'] ?? 'Unknown Department',
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${item['cases'] ?? 0} cases',
                    style: const TextStyle(
                      color: _gray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildReferralDistribution(BuildContext context, bool isEnglish) {
    final distribution = _referralDistribution ?? {};
    final byRisk = distribution['by_risk_level'] ?? {};
    final bySeverity = distribution['by_severity'] ?? {};
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          _sectionHeader(
            isEnglish ? 'Referral Distribution' : 'Ikwirakwiza',
            Icons.donut_small_rounded,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnglish ? 'By Risk Level' : 'Ku rwego rw\'akaga',
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDistributionItem('High', byRisk['high'] ?? 0, const Color(0xFFDC2626)),
                    _buildDistributionItem('Medium', byRisk['medium'] ?? 0, const Color(0xFFF59E0B)),
                    _buildDistributionItem('Low', byRisk['low'] ?? 0, const Color(0xFF059669)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnglish ? 'By Severity' : 'Ku kigereranyo',
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDistributionItem('Critical', bySeverity['critical'] ?? 0, const Color(0xFFDC2626)),
                    _buildDistributionItem('Moderate', bySeverity['moderate'] ?? 0, _teal),
                    _buildDistributionItem('Mild', bySeverity['mild'] ?? 0, const Color(0xFF7C3AED)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _navy,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              color: _gray,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

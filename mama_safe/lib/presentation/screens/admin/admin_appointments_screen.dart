import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF0D6B5E);
const _kPrimaryDark = Color(0xFF0A5549);
const _kAccentBlue = Color(0xFF3498DB);
const _kAccentOrange = Color(0xFFE67E22);
const _kDanger = Color(0xFFE74C3C);
const _kBg = Color(0xFFF0F4F3);
const _kSurface = Colors.white;
const _kTextDark = Color(0xFF1A2E2B);
const _kTextMid = Color(0xFF9CA3AF);
const _kTextLight = Color(0xFF8AADA8);
const _kBorder = Color(0xFFECF0F1);

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  String _search = '';
  String _statusFilter = 'All';
  bool _isLoading = true;

  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _mothers = [];
  List<Map<String, dynamic>> _chws = [];
  List<Map<String, dynamic>> _healthcarePros = [];

  int _total = 0, _upcoming = 0, _missed = 0, _today = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final results = await Future.wait([
        _apiService.getAppointments(),
        _apiService.getAllMothersAdmin(),
        _apiService.getCHWs(),
        _apiService.getHealthcarePros(),
      ]);

      _processAppointments(
        List<Map<String, dynamic>>.from(results[0]),
        List<Map<String, dynamic>>.from(results[1]),
        List<Map<String, dynamic>>.from(results[2]),
        List<Map<String, dynamic>>.from(results[3]),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading appointments: $e'),
          backgroundColor: _kDanger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      setState(() => _isLoading = false);
      _fadeCtrl.forward(from: 0);
    }
  }

  void _processAppointments(
    List<Map<String, dynamic>> appointments,
    List<Map<String, dynamic>> mothers,
    List<Map<String, dynamic>> chws,
    List<Map<String, dynamic>> healthcarePros,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _appointments = appointments.map((a) {
      // Find mother
      final mother = mothers.firstWhere(
        (m) => m['id'] == a['mother_id'],
        orElse: () => {'name': 'Unknown Mother', 'id': a['mother_id'], 'chw_id': null}
      );
      
      // Find CHW - Use EXACT same logic as mothers screen
      String chwName = 'Unassigned CHW';
      int? chwId;
      
      // Use the SAME pattern as mothers screen: mother['chw']?['id'] ?? mother['created_by_chw_id']
      final motherChwId = mother['chw']?['id'] ?? mother['created_by_chw_id'];
      if (motherChwId != null) {
        final chw = chws.firstWhere(
          (c) => c['id'].toString() == motherChwId.toString(),
          orElse: () => <String, dynamic>{},
        );
        if (chw.isNotEmpty) {
          chwName = chw['name'] ?? 'Unassigned CHW';
          chwId = chw['id'];
        }
      }
      
      // Find healthcare professional - handle null assignments properly
      String doctorName = 'Not Assigned';
      
      // Try to find doctor by ID if available
      final doctorId = a['healthcare_professional_id'];
      if (doctorId != null) {
        final hp = healthcarePros.firstWhere(
          (h) => h['id'].toString() == doctorId.toString(),
          orElse: () => <String, dynamic>{},
        );
        
        if (hp.isNotEmpty) {
          doctorName = hp['name'] ?? 'Unknown Doctor';
        }
      }
      
      // If no doctor ID, try facility matching
      if (doctorName == 'Not Assigned') {
        final facility = a['facility'];
        if (facility != null && facility.toString().isNotEmpty) {
          final facilityLower = facility.toString().toLowerCase();
          
          final facilityDoctor = healthcarePros.firstWhere(
            (h) {
              final hFacility = h['facility']?.toString().toLowerCase() ?? '';
              return hFacility.contains(facilityLower) || facilityLower.contains(hFacility);
            },
            orElse: () => <String, dynamic>{},
          );
          
          if (facilityDoctor.isNotEmpty) {
            doctorName = facilityDoctor['name'] ?? 'Unknown Doctor';
          }
        }
      }
      

      return {
        ...a,
        'mother_name': mother['name'] ?? 'Unknown Mother',
        'chw_name': chwName,
        'chw_id': chwId,
        'healthcare_pro_name': doctorName,
        'mother_chw_id': mother['chw_id'], // Keep track of mother's assigned CHW
      };
    }).toList();

    // Sort newest first
    _appointments.sort((a, b) {
      final da =
          DateTime.tryParse(a['appointment_date'] ?? '') ?? DateTime(2000);
      final db =
          DateTime.tryParse(b['appointment_date'] ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });

    _total = _appointments.length;
    _upcoming = 0;
    _missed = 0;
    _today = 0;
    int withAppointments = 0;
    int noAppointments = 0;

    for (final a in _appointments) {
      final status = a['status']?.toString().toLowerCase() ?? '';
      final d = DateTime.tryParse(a['appointment_date'] ?? '');
      
      // Count appointment types
      if (status == 'no_appointment' || d == null) {
        noAppointments++;
      } else {
        withAppointments++;
        
        // Calculate date-based statistics for actual appointments
        final day = DateTime(d.year, d.month, d.day);
        final today = DateTime(now.year, now.month, now.day);
        
        if (day == today) {
          _today++;
        } else if (day.isAfter(today)) {
          _upcoming++;
        } else if (!status.contains('completed') && !status.contains('resolved')) {
          _missed++;
        }
      }
    }

    setState(() {
      _mothers = mothers;
      _chws = chws;
      _healthcarePros = healthcarePros;
    });
    
    // Debug: Print healthcare professionals data
    print('👨‍⚕️ Available Healthcare Professionals:');
    for (var hp in healthcarePros) {
      print('  - ${hp['name']} (ID: ${hp['id']}) at ${hp['facility'] ?? hp['hospital'] ?? 'Unknown facility'}');
    }
    print('Total healthcare professionals: ${healthcarePros.length}\n');
  }

  String _getDefaultDoctorName(String facility) {
    // Map facilities to default doctors - doctors are the ones booking appointments
    final facilityLower = facility.toLowerCase();
    
    if (facilityLower.contains('king faisal') || facilityLower.contains('kfh')) {
      return 'Dr. Aurore Isimbi';
    } else if (facilityLower.contains('kibagabaga') || facilityLower.contains('kbh')) {
      return 'Dr. Keza Diana';
    } else if (facilityLower.contains('kacyiru') || facilityLower.contains('kch')) {
      return 'Dr. Sonia Uwera';
    } else if (facilityLower.contains('muhima') || facilityLower.contains('mhh')) {
      return 'Dr. Jean Baptiste';
    } else if (facilityLower.contains('nyagatare') || facilityLower.contains('ngh')) {
      return 'Dr. Marie Claire';
    } else if (facilityLower.contains('butaro') || facilityLower.contains('bch')) {
      return 'Dr. Emmanuel Nzeyimana';
    } else if (facilityLower.contains('hospital') || facilityLower.contains('health center')) {
      // Generic hospital/health center - assign a default doctor
      return 'Dr. Aurore Isimbi'; // Default to King Faisal doctor
    } else {
      // If no facility specified, still assign a doctor since they book appointments
      return 'Dr. Aurore Isimbi'; // Default doctor
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var filtered = _appointments.where((a) {
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          (a['mother_name']?.toString().toLowerCase() ?? '').contains(q) ||
          (a['chw_name']?.toString().toLowerCase() ?? '').contains(q) ||
          (a['healthcare_pro_name']?.toString().toLowerCase() ?? '')
              .contains(q) ||
          (a['status']?.toString().toLowerCase() ?? '').contains(q);
      
      bool matchStatus = _statusFilter == 'All';
      if (!matchStatus) {
        final status = a['status']?.toString().toLowerCase() ?? '';
        final appointmentDate = DateTime.tryParse(a['appointment_date'] ?? '');
        final now = DateTime.now();
        
        switch (_statusFilter.toLowerCase()) {
          case 'appointment':
            // Has any appointment scheduled (any status that indicates appointment exists)
            matchStatus = status.contains('appointment') || 
                         status.contains('scheduled') ||
                         appointmentDate != null;
            break;
          case 'no appointment':
            // No appointment scheduled (no appointment date or status)
            matchStatus = appointmentDate == null && 
                         !status.contains('appointment') && 
                         !status.contains('scheduled');
            break;
          case 'pending':
            matchStatus = status.contains('pending') || 
                         status.contains('waiting') ||
                         status.contains('scheduled');
            break;
          case 'completed':
            matchStatus = status.contains('completed') || 
                         status.contains('resolved') || 
                         status.contains('closed') ||
                         status.contains('done');
            break;
          case 'missed':
            if (appointmentDate != null) {
              final appointmentDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
              final today = DateTime(now.year, now.month, now.day);
              matchStatus = appointmentDay.isBefore(today) && 
                           !status.contains('completed') &&
                           !status.contains('resolved') &&
                           !status.contains('done');
            } else {
              matchStatus = false;
            }
            break;
          default:
            matchStatus = status.contains(_statusFilter.toLowerCase());
        }
      }
      
      return matchSearch && matchStatus;
    }).toList();
    
    return filtered;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('completed') || s.contains('resolved') || s.contains('done')) return _kPrimary;
    if (s.contains('scheduled') || s.contains('appointment')) return _kAccentBlue;
    if (s.contains('pending') || s.contains('waiting')) return _kAccentOrange;
    if (s.contains('missed')) return _kDanger;
    if (s == 'no_appointment') return _kTextMid;
    return _kTextMid;
  }

  String _statusLabel(String status) {
    final s = status.toLowerCase();
    if (s == 'no_appointment') return 'NO APPOINTMENT';
    if (s.contains('appointment_scheduled')) return 'SCHEDULED';
    return status.replaceAll('_', ' ').toUpperCase();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: _AppTopBar(onRefresh: _loadData),
      ),
      floatingActionButton: _AddFab(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Create new appointment — coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : FadeTransition(
              opacity: _fadeAnim,
              child: _AppBody(
                total: _total,
                upcoming: _upcoming,
                missed: _missed,
                today: _today,
                search: _search,
                statusFilter: _statusFilter,
                filtered: _filtered,
                onSearch: (v) => setState(() => _search = v),
                onStatusFilter: (v) => setState(() => _statusFilter = v!),
                onMissedFilter: () => setState(() => _statusFilter = 'Missed'),
                statusColor: _statusColor,
                statusLabel: _statusLabel,
                onTap: _showDetails,
              ),
            ),
    );
  }

  // ─── Detail Dialog ─────────────────────────────────────────────────────────

  void _showDetails(Map<String, dynamic> a) {
    showDialog(
      context: context,
      builder: (_) => _DetailDialog(
        appointment: a,
        statusColor: _statusColor,
        statusLabel: _statusLabel,
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _AppTopBar extends StatelessWidget {
  final VoidCallback onRefresh;
  const _AppTopBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text('Appointments Management',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kTextDark)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _kTextMid, size: 20),
            onPressed: onRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _AppBody extends StatelessWidget {
  final int total, upcoming, missed, today;
  final String search, statusFilter;
  final List<Map<String, dynamic>> filtered;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatusFilter;
  final VoidCallback onMissedFilter;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;
  final void Function(Map<String, dynamic>) onTap;

  const _AppBody({
    required this.total,
    required this.upcoming,
    required this.missed,
    required this.today,
    required this.search,
    required this.statusFilter,
    required this.filtered,
    required this.onSearch,
    required this.onStatusFilter,
    required this.onMissedFilter,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Cards ────────────────────────────────────────────────────
          Row(children: [
            _KpiCard(
              label: 'Total',
              value: '$total',
              sub: 'All appointments',
              icon: Icons.calendar_month_rounded,
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D6B5E), Color(0xFF0D6B5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            const SizedBox(width: 10),
            _KpiCard(
              label: 'Upcoming',
              value: '$upcoming',
              sub: 'Scheduled ahead',
              icon: Icons.schedule_rounded,
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D6B5E), Color(0xFF0D6B5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            const SizedBox(width: 10),
            _KpiCard(
              label: 'Missed',
              value: '$missed',
              sub: 'Needs follow-up',
              icon: Icons.event_busy_rounded,
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D6B5E), Color(0xFF0D6B5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            const SizedBox(width: 10),
            _KpiCard(
              label: 'Today',
              value: '$today',
              sub: 'Scheduled today',
              icon: Icons.today_rounded,
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D6B5E), Color(0xFF0D6B5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
          ]),

          const SizedBox(height: 14),

          // ── Missed Alert ──────────────────────────────────────────────────
          if (missed > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kDanger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kDanger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event_busy_rounded,
                        color: _kDanger, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$missed Missed Appointment${missed > 1 ? 's' : ''} Need Follow-up',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _kDanger,
                              fontSize: 13),
                        ),
                        const Text(
                          'Mothers who missed scheduled visits',
                          style: TextStyle(fontSize: 11, color: _kDanger),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onMissedFilter,
                    style: TextButton.styleFrom(
                      backgroundColor: _kDanger,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('View Missed',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Search + Filter ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder),
                  ),
                  child: TextField(
                    onChanged: onSearch,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search appointments...',
                      hintStyle: TextStyle(fontSize: 13, color: _kTextLight),
                      prefixIcon:
                          Icon(Icons.search_rounded, color: _kTextMid, size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _FilterDropdown(
                value: statusFilter,
                items: const [
                  'All',
                  'Appointment',
                  'No Appointment',
                  'Pending',
                  'Completed',
                  'Missed'
                ],
                onChanged: onStatusFilter,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Table ─────────────────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 10,
                      offset: Offset(0, 2))
                ],
              ),
              child: filtered.isEmpty
                  ? _EmptyState()
                  : Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFB),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 3, child: _ColHeader('MOTHER')),
                              Expanded(flex: 2, child: _ColHeader('CHW')),
                              Expanded(flex: 2, child: _ColHeader('DOCTOR')),
                              Expanded(child: _ColHeader('DATE')),
                              SizedBox(width: 160, child: _ColHeader('STATUS')),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: _kBorder),

                        // Rows
                        Expanded(
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: _kBorder),
                            itemBuilder: (_, i) => _AppRow(
                              appointment: filtered[i],
                              statusColor: statusColor,
                              statusLabel: statusLabel,
                              onTap: () => onTap(filtered[i]),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final LinearGradient gradient;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: gradient.colors.first,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withOpacity(0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFE0F0EE),
                          fontWeight: FontWeight.w600)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFFE0F0EE))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Dropdown ──────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(fontSize: 13, color: _kTextDark),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _kTextMid, size: 18),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Column Header ────────────────────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _kTextLight,
          letterSpacing: 0.5));
}

// ─── Appointment Row ──────────────────────────────────────────────────────────

class _AppRow extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;
  final VoidCallback onTap;

  const _AppRow({
    required this.appointment,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = appointment['status']?.toString() ?? 'Unknown';
    final sc = statusColor(status);
    final date = DateTime.tryParse(appointment['appointment_date'] ?? '');
    final initial = (appointment['mother_name']?.toString().isNotEmpty == true
            ? appointment['mother_name'].toString()[0]
            : 'M')
        .toUpperCase();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // ── Mother ────────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _kPrimary.withOpacity(0.15),
                    child: Text(initial,
                        style: const TextStyle(
                            color: _kPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      appointment['mother_name'] ?? 'Unknown Mother',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _kTextDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ── CHW ───────────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  // CHW indicator icon
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: appointment['chw_name'] != 'Unassigned CHW' 
                          ? _kPrimary 
                          : _kDanger,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appointment['chw_name'] ?? 'Unassigned CHW',
                      style: TextStyle(
                        fontSize: 12, 
                        color: appointment['chw_name'] != 'Unassigned CHW' 
                            ? _kTextDark 
                            : _kDanger,
                        fontWeight: appointment['chw_name'] != 'Unassigned CHW' 
                            ? FontWeight.w500 
                            : FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ── Doctor ────────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Text(
                appointment['healthcare_pro_name'] == 'Not Assigned'
                  ? 'Not Assigned'
                  : appointment['healthcare_pro_name']?.startsWith('Dr.') == true 
                    ? appointment['healthcare_pro_name'] 
                    : 'Dr. ${appointment['healthcare_pro_name']}',
                style: TextStyle(
                  fontSize: 12, 
                  color: appointment['healthcare_pro_name'] == 'Not Assigned' 
                      ? _kTextMid 
                      : _kTextDark,
                  fontWeight: appointment['healthcare_pro_name'] == 'Not Assigned' 
                      ? FontWeight.w400 
                      : FontWeight.w500,
                  fontStyle: appointment['healthcare_pro_name'] == 'Not Assigned' 
                      ? FontStyle.italic 
                      : FontStyle.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Date ──────────────────────────────────────────────────────
            Expanded(
              child: Text(
                date != null ? DateFormat('dd MMM').format(date) : '—',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kTextDark),
              ),
            ),

            // ── Status Badge ──────────────────────────────────────────────
            SizedBox(
              width: 160,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sc.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusLabel(status),
                    style: TextStyle(
                        color: sc,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kBorder.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today_rounded,
                size: 48, color: _kTextLight),
          ),
          const SizedBox(height: 16),
          const Text('No appointments found',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: _kTextMid)),
          const SizedBox(height: 4),
          const Text('Try adjusting your search',
              style: TextStyle(fontSize: 12, color: _kTextLight)),
        ],
      ),
    );
  }
}

// ─── FAB ─────────────────────────────────────────────────────────────────────

class _AddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _kPrimaryDark,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kPrimaryDark.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}

// ─── Detail Dialog ────────────────────────────────────────────────────────────

class _DetailDialog extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;

  const _DetailDialog({
    required this.appointment,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final status = appointment['status']?.toString() ?? 'Unknown';
    final sc = statusColor(status);
    final date = DateTime.tryParse(appointment['appointment_date'] ?? '');
    final initial = (appointment['mother_name']?.toString().isNotEmpty == true
            ? appointment['mother_name'].toString()[0]
            : 'M')
        .toUpperCase();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _kPrimary.withOpacity(0.15),
                  child: Text(initial,
                      style: const TextStyle(
                          color: _kPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment['mother_name'] ?? 'Unknown Mother',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _kTextDark)),
                      Text(
                          date != null
                              ? DateFormat('dd MMM yyyy, HH:mm').format(date)
                              : 'No Date',
                          style:
                              const TextStyle(fontSize: 11, color: _kTextMid)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sc.withOpacity(0.3)),
                  ),
                  child: Text(statusLabel(status),
                      style: TextStyle(
                          color: sc,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: _kTextMid, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: _kBorder),
            const SizedBox(height: 14),

            // ── Detail chips ──────────────────────────────────────────────
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _Chip(
                  'Assigned CHW', 
                  appointment['chw_name'] ?? 'Unassigned CHW',
                  isError: appointment['chw_name'] == 'Unassigned CHW',
                ),
                _Chip(
                  'Healthcare Professional', 
                  appointment['healthcare_pro_name'] == 'Not Assigned'
                    ? 'Not Assigned'
                    : appointment['healthcare_pro_name']?.startsWith('Dr.') == true 
                      ? appointment['healthcare_pro_name'] 
                      : 'Dr. ${appointment['healthcare_pro_name']}',
                  isError: appointment['healthcare_pro_name'] == 'Not Assigned',
                ),
                if (appointment['notes'] != null &&
                    appointment['notes'].toString().isNotEmpty)
                  _Chip('Notes', appointment['notes']),
                if (appointment['reason'] != null &&
                    appointment['reason'].toString().isNotEmpty)
                  _Chip('Reason', appointment['reason']),
                if (appointment['mother_chw_id'] != null)
                  _Chip('CHW ID', appointment['mother_chw_id'].toString()),
              ],
            ),

            const SizedBox(height: 20),

            // ── Close button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: _kPrimaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Close',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label, value;
  final bool isError;
  const _Chip(this.label, this.value, {this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isError ? _kDanger.withOpacity(0.05) : _kBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? _kDanger.withOpacity(0.3) : _kBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: isError ? _kDanger : _kTextLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  color: isError ? _kDanger : _kTextDark,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

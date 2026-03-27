import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../dialogs/admin_create_referral_dialog.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF0D6B5E);
const _kPrimaryLight = Color(0xFF12876F);
const _kPrimaryDark = Color(0xFF084F45);
const _kAccentBlue = Color(0xFF3498DB);
const _kAccentOrange = Color(0xFFD97706);
const _kDanger = Color(0xFFCF3030);
const _kDangerLight = Color(0xFFFF4D4D);
const _kWarning = Color(0xFFD97706);
const _kSuccess = Color(0xFF059669);
const _kBg = Color(0xFFF5F8F7);
const _kBgDeep = Color(0xFFEDF3F1);
const _kSurface = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFE2EDEB);
const _kTextDark = Color(0xFF0C1F1C);
const _kTextBody = Color(0xFF374845);
const _kTextMid = Color(0xFF6E8E8A);
const _kTextLight = Color(0xFFA3BFBB);

class AdminReferralsScreen extends StatefulWidget {
  const AdminReferralsScreen({super.key});

  @override
  State<AdminReferralsScreen> createState() => _AdminReferralsScreenState();
}

class _AdminReferralsScreenState extends State<AdminReferralsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _search = '';
  String _statusFilter = 'All Status';

  int _total = 0, _emergency = 0, _pending = 0, _completed = 0;
  List<Map<String, dynamic>> _referrals = [];

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  // Doctor and facility mapping
  final Map<String, Map<String, String>> _doctorFacilityMap = {
    'aurore_isimbi': {
      'name': 'Dr. Aurore Isimbi',
      'facility': 'King Faisal Hospital Rwanda',
      'email': 'aurore.ismbi@kfh.rw',
    },
    'keza_diana': {
      'name': 'Dr. Keza Diana',
      'facility': 'Kibagabaga Level II Teaching Hospital',
      'email': 'keza.diana@kibagabagahospital.rw',
    },
    'sonia_uwera': {
      'name': 'Dr. Sonia Uwera',
      'facility': 'Kacyiru District Hospital',
      'email': 'sonia.uwera@kacyiruhospital.rw',
    },
  };

  String _getDoctorName(Map<String, dynamic> referral) {
    // Check if there's a healthcare professional assigned
    final hpId = referral['healthcare_pro_id'];
    final doctorName = referral['doctor_name'];
    final hospital = referral['hospital'];

    if (hpId != null || doctorName != null || hospital != null) {
      // Try to match by hospital/facility first
      if (hospital != null) {
        final hospitalLower = hospital.toString().toLowerCase();
        if (hospitalLower.contains('king faisal') ||
            hospitalLower.contains('kfh')) {
          return _doctorFacilityMap['aurore_isimbi']!['name']!;
        }
        if (hospitalLower.contains('kibagabaga')) {
          return _doctorFacilityMap['keza_diana']!['name']!;
        }
        if (hospitalLower.contains('kacyiru')) {
          return _doctorFacilityMap['sonia_uwera']!['name']!;
        }
      }

      // Try to match by doctor name
      if (doctorName != null) {
        final nameLower = doctorName.toString().toLowerCase();
        if (nameLower.contains('aurore') || nameLower.contains('isimbi')) {
          return _doctorFacilityMap['aurore_isimbi']!['name']!;
        }
        if (nameLower.contains('keza') || nameLower.contains('diana')) {
          return _doctorFacilityMap['keza_diana']!['name']!;
        }
        if (nameLower.contains('sonia') || nameLower.contains('uwera')) {
          return _doctorFacilityMap['sonia_uwera']!['name']!;
        }
        // If we have a doctor name but no match, format it properly
        return doctorName.toString().startsWith('Dr.')
            ? doctorName.toString()
            : 'Dr. $doctorName';
      }

      // If we have an ID but no name, return generic
      return 'Dr. Assigned';
    }
    return 'No Referral Doctor';
  }

  String _getFacilityName(Map<String, dynamic> referral) {
    // Check if there's a healthcare professional assigned
    final hpId = referral['healthcare_pro_id'];
    final hospital = referral['hospital'];
    final facility = referral['facility'];

    if (hpId != null || hospital != null || facility != null) {
      // Try to match by hospital/facility name
      final facilityName = hospital ?? facility ?? '';
      final facilityLower = facilityName.toString().toLowerCase();

      if (facilityLower.contains('king faisal') ||
          facilityLower.contains('kfh')) {
        return _doctorFacilityMap['aurore_isimbi']!['facility']!;
      }
      if (facilityLower.contains('kibagabaga')) {
        return _doctorFacilityMap['keza_diana']!['facility']!;
      }
      if (facilityLower.contains('kacyiru')) {
        return _doctorFacilityMap['sonia_uwera']!['facility']!;
      }

      // If we have a facility name but no match, return it as is
      if (facilityName.isNotEmpty) {
        return facilityName.toString();
      }

      // If we have an ID but no facility name, return generic
      return 'Health Facility';
    }
    return 'No Referral';
  }

  Future<void> _load() async {
    try {
      setState(() => _isLoading = true);

      final allReferrals = await _apiService.getAllReferrals();
      final allMothers = await _apiService.getAllMothersAdmin();
      final allCHWs = await _apiService.getCHWs();
      final allHealthcarePros = await _apiService.getHealthcarePros();

      final processed = allReferrals.map<Map<String, dynamic>>((r) {
        final mother = allMothers.firstWhere(
            (m) => m['id'].toString() == r['mother_id'].toString(),
            orElse: () => {'name': 'Unknown Mother'});
        final chw = allCHWs.firstWhere(
            (c) => c['id'].toString() == r['chw_id'].toString(),
            orElse: () => {'name': 'Unknown CHW'});

        DateTime createdAt;
        try {
          createdAt = DateTime.parse(
              r['created_at'] ?? r['date'] ?? DateTime.now().toIso8601String());
        } catch (_) {
          createdAt = DateTime.now();
        }

        return {
          'id': r['id'],
          'motherName': mother['name'] ?? 'Unknown Mother',
          'chwName': chw['name'] ?? 'Unknown CHW',
          'doctorName': _getDoctorName(r),
          'facility': _getFacilityName(r),
          'status': r['status'] ?? 'Pending',
          'createdAt': createdAt,
          'reason': r['reason'] ?? r['notes'] ?? 'Medical consultation',
          'urgency': r['urgency'] ?? r['priority'] ?? 'Normal',
        };
      }).toList()
        ..sort((a, b) =>
            (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));

      setState(() {
        _referrals = processed;
        _total = allReferrals.length;
        _emergency = allReferrals
            .where((r) =>
                r['status']?.toLowerCase() == 'emergency' ||
                r['urgency']?.toLowerCase() == 'emergency' ||
                r['priority']?.toLowerCase() == 'emergency')
            .length;
        _pending = allReferrals
            .where((r) =>
                r['status']?.toLowerCase() == 'pending' ||
                r['status']?.toLowerCase() == 'waiting')
            .length;
        _completed = allReferrals
            .where((r) =>
                r['status']?.toLowerCase() == 'completed' ||
                r['status']?.toLowerCase() == 'resolved' ||
                r['status']?.toLowerCase() == 'closed')
            .length;
        _isLoading = false;
      });

      _fadeCtrl.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filtered => _referrals.where((r) {
        final q = _search.toLowerCase();
        final matchSearch = q.isEmpty ||
            r['motherName'].toLowerCase().contains(q) ||
            r['chwName'].toLowerCase().contains(q) ||
            r['doctorName'].toLowerCase().contains(q) ||
            r['facility'].toLowerCase().contains(q);
        final matchStatus = _statusFilter == 'All Status' ||
            r['status'].toLowerCase().contains(_statusFilter.toLowerCase());
        return matchSearch && matchStatus;
      }).toList();

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'emergency':
        return _kDanger;
      case 'completed':
      case 'resolved':
      case 'closed':
        return _kSuccess;
      case 'assigned':
      case 'in_progress':
      case 'appointment_scheduled':
        return _kAccentBlue;
      default:
        return _kWarning;
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'Just now';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: _ReferralsTopBar(onRefresh: _load),
      ),
      floatingActionButton: _NewReferralFab(
        onTap: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (_) => const AdminCreateReferralDialog(),
          );
          if (result == true) {
            _load(); // Refresh the referrals list
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : FadeTransition(
              opacity: _fadeAnim,
              child: _ReferralsBody(
                total: _total,
                emergency: _emergency,
                pending: _pending,
                completed: _completed,
                search: _search,
                statusFilter: _statusFilter,
                filtered: _filtered,
                onSearch: (v) => setState(() => _search = v),
                onStatus: (v) => setState(() => _statusFilter = v!),
                onEmergency: () => setState(() => _statusFilter = 'Emergency'),
                statusColor: _statusColor,
                timeAgo: _timeAgo,
                onTap: _showDetails,
              ),
            ),
    );
  }

  // ─── Detail Dialog ─────────────────────────────────────────────────────────

  void _showDetails(Map<String, dynamic> r) {
    showDialog(
      context: context,
      builder: (_) => _ReferralDetailDialog(
        referral: r,
        statusColor: _statusColor,
        onUpdate: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Update referral status — coming soon'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _ReferralsTopBar extends StatelessWidget {
  final VoidCallback onRefresh;
  const _ReferralsTopBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Referrals Management',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _kTextDark,
                      letterSpacing: -0.5)),
              SizedBox(height: 1),
              Text('Patient referral tracking & status',
                  style: TextStyle(
                      fontSize: 11, color: _kTextMid, letterSpacing: 0.1)),
            ],
          ),
          const Spacer(),
          _TopIconBtn(
              icon: Icons.refresh_rounded,
              onTap: onRefresh,
              tooltip: 'Refresh'),
        ],
      ),
    );
  }
}

class _TopIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _TopIconBtn(
      {required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kBgDeep,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: Icon(icon, color: _kTextMid, size: 17),
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _ReferralsBody extends StatelessWidget {
  final int total, emergency, pending, completed;
  final String search, statusFilter;
  final List<Map<String, dynamic>> filtered;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final VoidCallback onEmergency;
  final Color Function(String) statusColor;
  final String Function(DateTime) timeAgo;
  final void Function(Map<String, dynamic>) onTap;

  const _ReferralsBody({
    required this.total,
    required this.emergency,
    required this.pending,
    required this.completed,
    required this.search,
    required this.statusFilter,
    required this.filtered,
    required this.onSearch,
    required this.onStatus,
    required this.onEmergency,
    required this.statusColor,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Cards — differentiated by type ──────────────────────────
          Row(children: [
            _StatCard(
              label: 'Total',
              value: '$total',
              sub: 'All referrals',
              icon: Icons.send_rounded,
              accentColor: _kPrimary,
            ),
            const SizedBox(width: 10),
            _AlertCard(
              label: 'Emergency',
              value: '$emergency',
              sub: 'Needs urgent care',
              icon: Icons.warning_amber_rounded,
              cardColor: _kDanger,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'Pending',
              value: '$pending',
              sub: 'Awaiting action',
              icon: Icons.pending_rounded,
              accentColor: _kWarning,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'Completed',
              value: '$completed',
              sub: 'Resolved cases',
              icon: Icons.check_circle_rounded,
              accentColor: _kSuccess,
            ),
          ]),

          const SizedBox(height: 12),

          // ── Emergency Alert Banner ────────────────────────────────────────
          if (emergency > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: _kDanger.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kDanger.withOpacity(0.22)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _kDanger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: _kDanger, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$emergency Emergency Referral${emergency > 1 ? 's' : ''} Need Immediate Attention',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _kDanger,
                              fontSize: 12,
                              letterSpacing: -0.1),
                        ),
                        Text('High-risk mothers requiring urgent care',
                            style: TextStyle(
                                fontSize: 11,
                                color: _kDanger.withOpacity(0.75))),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onEmergency,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _kDanger,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                              color: _kDanger.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: const Text('Handle Now',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Search + Filter ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: TextField(
                    onChanged: onSearch,
                    style: const TextStyle(fontSize: 13, color: _kTextDark),
                    decoration: const InputDecoration(
                      hintText:
                          'Search by mother name, CHW, doctor, or facility...',
                      hintStyle: TextStyle(fontSize: 13, color: _kTextLight),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: _kTextMid, size: 17),
                      suffixIcon: Icon(Icons.filter_list_rounded,
                          color: _kTextLight, size: 17),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FilterDropdown(
                value: statusFilter,
                items: const [
                  'All Status',
                  'Emergency',
                  'Pending',
                  'Assigned',
                  'Completed'
                ],
                onChanged: onStatus,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Referrals Table ───────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4)),
                  BoxShadow(
                      color: _kPrimary.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: filtered.isEmpty
                  ? const _EmptyState()
                  : Column(
                      children: [
                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 13),
                          decoration: const BoxDecoration(
                            color: _kBgDeep,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            border: Border(
                                bottom: BorderSide(color: _kBorder, width: 1)),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 3, child: _ColHeader('MOTHER')),
                              Expanded(
                                  flex: 2, child: _ColHeader('CHW / DOCTOR')),
                              Expanded(flex: 2, child: _ColHeader('FACILITY')),
                              Expanded(child: _ColHeader('REASON')),
                              SizedBox(width: 120, child: _ColHeader('STATUS')),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _ReferralRow(
                              referral: filtered[i],
                              statusColor: statusColor,
                              timeAgo: timeAgo,
                              isEven: i.isEven,
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

// ─── Stat Card (white, colored left accent) ───────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color accentColor;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.sub,
      required this.icon,
      required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder, width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accentColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: accentColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(value,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: _kTextDark,
                                      letterSpacing: -1.0,
                                      height: 1.0)),
                              const SizedBox(height: 2),
                              Text(label,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: _kTextBody,
                                      fontWeight: FontWeight.w600)),
                              Text(sub,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: accentColor,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Alert Card (dramatic solid — for Emergency) ──────────────────────────────

class _AlertCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color cardColor;
  const _AlertCard(
      {required this.label,
      required this.value,
      required this.sub,
      required this.icon,
      required this.cardColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cardColor,
              Color.lerp(cardColor, const Color(0xFF8B0000), 0.35)!
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: cardColor.withOpacity(0.38),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: -2),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1.0,
                          height: 1.0)),
                  const SizedBox(height: 2),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w600)),
                  Text(sub,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.70),
                          fontWeight: FontWeight.w500)),
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
  const _FilterDropdown(
      {required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(
              fontSize: 12, color: _kTextDark, fontWeight: FontWeight.w600),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _kTextMid, size: 17),
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
          color: _kTextMid,
          letterSpacing: 0.7));
}

// ─── Referral Row ─────────────────────────────────────────────────────────────

class _ReferralRow extends StatelessWidget {
  final Map<String, dynamic> referral;
  final Color Function(String) statusColor;
  final String Function(DateTime) timeAgo;
  final VoidCallback onTap;
  final bool isEven;

  const _ReferralRow({
    required this.referral,
    required this.statusColor,
    required this.timeAgo,
    required this.onTap,
    this.isEven = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = referral['status'] as String;
    final sc = statusColor(status);
    final isEmergency = status.toLowerCase() == 'emergency';
    final initials = (referral['motherName'] as String)
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join();

    return InkWell(
      onTap: onTap,
      hoverColor: _kBgDeep,
      child: Container(
        color: isEmergency
            ? _kDanger.withOpacity(0.04)
            : isEven
                ? _kBg.withOpacity(0.55)
                : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            // ── Mother ────────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isEmergency
                          ? _kDanger.withOpacity(0.10)
                          : _kPrimary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isEmergency
                            ? _kDanger.withOpacity(0.20)
                            : _kPrimary.withOpacity(0.18),
                      ),
                    ),
                    child: Center(
                      child: Text(initials,
                          style: TextStyle(
                              color: isEmergency ? _kDanger : _kPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(referral['motherName'],
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _kTextDark,
                                letterSpacing: -0.2)),
                        const SizedBox(height: 1),
                        Text(
                            DateFormat('dd MMM yyyy')
                                .format(referral['createdAt']),
                            style: const TextStyle(
                                fontSize: 10, color: _kTextMid)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── CHW / Doctor ──────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(referral['chwName'],
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kTextDark),
                      overflow: TextOverflow.ellipsis),
                  Text(referral['doctorName'],
                      style: const TextStyle(fontSize: 11, color: _kTextMid),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            // ── Facility ──────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Text(referral['facility'],
                  style: const TextStyle(fontSize: 12, color: _kTextMid),
                  overflow: TextOverflow.ellipsis),
            ),

            // ── Reason ────────────────────────────────────────────────────
            Expanded(
              child: Text(referral['reason'],
                  style: const TextStyle(fontSize: 11, color: _kTextLight),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2),
            ),

            // ── Status + Time ─────────────────────────────────────────────
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: sc.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: sc.withOpacity(0.22)),
                    ),
                    child: Text(
                      _fmt(status),
                      style: TextStyle(
                          color: sc,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(timeAgo(referral['createdAt']),
                      style: const TextStyle(fontSize: 10, color: _kTextLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String s) {
    return s.replaceAll('_', ' ').toUpperCase();
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: _kBgDeep,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.inbox_rounded, size: 36, color: _kTextLight),
          ),
          const SizedBox(height: 14),
          const Text('No referrals found',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _kTextMid)),
          const SizedBox(height: 4),
          const Text('Try adjusting your search or filters',
              style: TextStyle(fontSize: 12, color: _kTextLight)),
        ],
      ),
    );
  }
}

// ─── New Referral FAB ─────────────────────────────────────────────────────────

class _NewReferralFab extends StatelessWidget {
  final VoidCallback onTap;
  const _NewReferralFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kPrimaryLight, _kPrimary, _kPrimaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: _kPrimary.withOpacity(0.40),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: -2),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}

// ─── Helper ──────────────────────────────────────────────────────────────────
String _fmt(String s) => s.replaceAll("_", " ").toUpperCase();

// ─── Detail Dialog ────────────────────────────────────────────────────────────

class _ReferralDetailDialog extends StatelessWidget {
  final Map<String, dynamic> referral;
  final Color Function(String) statusColor;
  final VoidCallback onUpdate;

  const _ReferralDetailDialog({
    required this.referral,
    required this.statusColor,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final status = referral['status'] as String;
    final sc = statusColor(status);
    final isEmergency = status.toLowerCase() == 'emergency';
    final initials = (referral['motherName'] as String)
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: _kSurface,
      child: Container(
        width: 460,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isEmergency
                          ? _kDanger.withOpacity(0.10)
                          : _kPrimary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: isEmergency
                            ? _kDanger.withOpacity(0.20)
                            : _kPrimary.withOpacity(0.18),
                      ),
                    ),
                    child: Center(
                      child: Text(initials,
                          style: TextStyle(
                              color: isEmergency ? _kDanger : _kPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(referral['motherName'],
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _kTextDark,
                                letterSpacing: -0.4)),
                        Text(
                            '${referral['chwName']} · ${referral['doctorName']}',
                            style: const TextStyle(
                                fontSize: 11, color: _kTextMid)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sc.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: sc.withOpacity(0.22)),
                    ),
                    child: Text(_fmt(status),
                        style: TextStyle(
                            color: sc,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _kBgDeep,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kBorder),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: _kTextMid, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _Chip('Facility', referral['facility']),
                        _Chip('Urgency', referral['urgency']),
                        _Chip('Reason', referral['reason']),
                        _Chip(
                            'Created',
                            DateFormat('dd MMM yyyy, HH:mm')
                                .format(referral['createdAt'])),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: _kBgDeep,
                border: Border(top: BorderSide(color: _kBorder, width: 1)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kBorder, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Close',
                          style: TextStyle(
                              color: _kTextMid, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Update Status',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
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
  const _Chip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kBgDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: _kTextMid,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: _kTextDark,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF2ECC71);
const _kPrimaryDark = Color(0xFF27AE60);
const _kAccentBlue = Color(0xFF3498DB);
const _kAccentPurple = Color(0xFF9B59B6);
const _kDanger = Color(0xFFE74C3C);
const _kBg = Color(0xFFF4F7F6);
const _kSurface = Colors.white;
const _kTextDark = Color(0xFF2C3E50);
const _kTextMid = Color(0xFF7F8C8D);
const _kTextLight = Color(0xFFBDC3C7);
const _kBorder = Color(0xFFECF0F1);

class AdminFacilitiesScreen extends StatefulWidget {
  const AdminFacilitiesScreen({super.key});

  @override
  State<AdminFacilitiesScreen> createState() => _AdminFacilitiesScreenState();
}

class _AdminFacilitiesScreenState extends State<AdminFacilitiesScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _search = '';
  List<Map<String, dynamic>> _facilities = [];

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

  Future<void> _load() async {
    try {
      setState(() => _isLoading = true);
      final data = await _apiService.getFacilities();

      setState(() {
        _facilities = data
            .map<Map<String, dynamic>>((f) => {
                  'id': f['id'] ?? 0,
                  'name': f['name'] ?? 'Unknown Facility',
                  'staffCount': f['staff_count'] ?? 0,
                  'referralsCount': f['referrals_count'] ?? 0,
                  'isActive': true,
                  'type': f['type'] ?? 'Hospital',
                  'district': f['district'] ?? 'Gasabo',
                })
            .toList();
        _isLoading = false;
      });

      _fadeCtrl.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading facilities: $e'),
          backgroundColor: _kDanger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  List<Map<String, dynamic>> get _filtered => _facilities.where((f) {
        final q = _search.toLowerCase();
        return f['name'].toLowerCase().contains(q) ||
            f['district'].toLowerCase().contains(q);
      }).toList();

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final active = _facilities.where((f) => f['isActive'] == true).length;
    final totalStaff =
        _facilities.fold<int>(0, (s, f) => s + (f['staffCount'] as int));
    final totalRef =
        _facilities.fold<int>(0, (s, f) => s + (f['referralsCount'] as int));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: _FacTopBar(onRefresh: _load),
      ),
      floatingActionButton: _AddFab(onTap: _addNewFacility),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : FadeTransition(
              opacity: _fadeAnim,
              child: _FacBody(
                total: _facilities.length,
                active: active,
                totalStaff: totalStaff,
                totalRef: totalRef,
                search: _search,
                filtered: _filtered,
                onSearch: (v) => setState(() => _search = v),
                onTap: _showDetails,
              ),
            ),
    );
  }

  void _showDetails(Map<String, dynamic> f) {
    showDialog(
      context: context,
      builder: (_) => _FacDetailDialog(facility: f),
    );
  }

  void _addNewFacility() {
    showDialog(
      context: context,
      builder: (_) => _AddFacilityDialog(
        onSave: (data) async {
          try {
            // Since there's no direct facility creation endpoint, we'll simulate it
            // In a real app, you'd call await _apiService.createFacility(data);
            
            // For now, we'll add it to the local list and show success
            final newFacility = {
              'id': DateTime.now().millisecondsSinceEpoch,
              'name': data['name'],
              'staffCount': 0,
              'referralsCount': 0,
              'isActive': true,
              'type': data['type'],
              'district': data['district'],
            };
            
            setState(() {
              _facilities.add(newFacility);
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Facility added successfully'),
                backgroundColor: _kPrimary,
                behavior: SnackBarBehavior.floating,
              ));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Error adding facility: $e'),
                backgroundColor: _kDanger,
                behavior: SnackBarBehavior.floating,
              ));
            }
          }
        },
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _FacTopBar extends StatelessWidget {
  final VoidCallback onRefresh;
  const _FacTopBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text('Facilities Management',
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

class _FacBody extends StatelessWidget {
  final int total, active, totalStaff, totalRef;
  final String search;
  final List<Map<String, dynamic>> filtered;
  final ValueChanged<String> onSearch;
  final void Function(Map<String, dynamic>) onTap;

  const _FacBody({
    required this.total,
    required this.active,
    required this.totalStaff,
    required this.totalRef,
    required this.search,
    required this.filtered,
    required this.onSearch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Cards ────────────────────────────────────────────────────
          Row(children: [
            _KpiCard(
              label: 'Total Facilities',
              value: '$total',
              sub: '$active active',
              icon: Icons.local_hospital_rounded,
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D6B5E), Color(0xFF0D6B5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            const SizedBox(width: 14),
            _KpiCard(
              label: 'Total Staff',
              value: '$totalStaff',
              sub: 'Healthcare professionals',
              icon: Icons.people_alt_rounded,
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D6B5E), Color(0xFF0D6B5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            const SizedBox(width: 14),
            _KpiCard(
              label: 'Total Referrals',
              value: '$totalRef',
              sub: 'Handled by all facilities',
              icon: Icons.send_rounded,
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D6B5E), Color(0xFF0D6B5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
          ]),

          const SizedBox(height: 14),

          // ── Search ────────────────────────────────────────────────────────
          Container(
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
                hintText: 'Search facilities by name or district...',
                hintStyle: TextStyle(fontSize: 13, color: _kTextLight),
                prefixIcon:
                    Icon(Icons.search_rounded, color: _kTextMid, size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Facilities List ───────────────────────────────────────────────
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
                              Expanded(
                                  flex: 3, child: _ColHeader('FACILITY NAME')),
                              Expanded(child: _ColHeader('TYPE')),
                              Expanded(child: _ColHeader('DISTRICT')),
                              Expanded(child: _ColHeader('STAFF')),
                              Expanded(child: _ColHeader('REFERRALS')),
                              SizedBox(width: 100, child: _ColHeader('STATUS')),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: _kBorder),

                        Expanded(
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: _kBorder),
                            itemBuilder: (_, i) => _FacRow(
                              facility: filtered[i],
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
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
                color: Colors.white.withOpacity(0.25),
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
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600)),
                  Text(sub,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white60)),
                ],
              ),
            ),
          ],
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

// ─── Facility Row ─────────────────────────────────────────────────────────────

class _FacRow extends StatelessWidget {
  final Map<String, dynamic> facility;
  final VoidCallback onTap;

  const _FacRow({required this.facility, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool active = facility['isActive'] == true;
    final Color ac = active ? _kPrimary : _kDanger;

    // Build a short abbreviation from facility name
    final words = (facility['name'] as String).split(' ');
    final abbr = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : words[0].substring(0, 2).toUpperCase();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // ── Facility Name ─────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kPrimary.withOpacity(0.25)),
                    ),
                    child: const Center(
                      child: Icon(Icons.local_hospital_rounded,
                          color: _kPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(facility['name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: _kTextDark)),
                        Text(
                            '${facility['staffCount']} staff member${facility['staffCount'] != 1 ? 's' : ''}',
                            style: const TextStyle(
                                fontSize: 11, color: _kTextMid)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Type ──────────────────────────────────────────────────────
            Expanded(
              child: Text(facility['type'],
                  style: const TextStyle(fontSize: 12, color: _kTextMid)),
            ),

            // ── District ──────────────────────────────────────────────────
            Expanded(
              child: Text(facility['district'],
                  style: const TextStyle(fontSize: 12, color: _kTextMid),
                  overflow: TextOverflow.ellipsis),
            ),

            // ── Staff count ───────────────────────────────────────────────
            Expanded(
              child: Text('${facility['staffCount']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _kTextDark)),
            ),

            // ── Referrals ─────────────────────────────────────────────────
            Expanded(
              child: Row(
                children: [
                  Text('${facility['referralsCount']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _kTextDark)),
                  const SizedBox(width: 4),
                  const Text('referrals',
                      style: TextStyle(fontSize: 10, color: _kTextLight)),
                ],
              ),
            ),

            // ── Status badge ──────────────────────────────────────────────
            SizedBox(
              width: 100,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ac.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ac.withOpacity(0.3)),
                ),
                child: Text(
                  active ? 'Active' : 'Inactive',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: ac, fontSize: 11, fontWeight: FontWeight.w700),
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
            child: const Icon(Icons.local_hospital_rounded,
                size: 48, color: _kTextLight),
          ),
          const SizedBox(height: 16),
          const Text('No facilities found',
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

// ─── Add Facility FAB ─────────────────────────────────────────────────────────

class _AddFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _kPrimaryDark,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _kPrimaryDark.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Add Facility',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Dialog ────────────────────────────────────────────────────────────

class _FacDetailDialog extends StatelessWidget {
  final Map<String, dynamic> facility;
  const _FacDetailDialog({required this.facility});

  @override
  Widget build(BuildContext context) {
    final bool active = facility['isActive'] == true;
    final Color ac = active ? _kPrimary : _kDanger;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kPrimary.withOpacity(0.25)),
                  ),
                  child: const Center(
                    child: Icon(Icons.local_hospital_rounded,
                        color: _kPrimary, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(facility['name'],
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _kTextDark)),
                      Text(facility['type'],
                          style:
                              const TextStyle(fontSize: 11, color: _kTextMid)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ac.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ac.withOpacity(0.3)),
                  ),
                  child: Text(active ? 'Active' : 'Inactive',
                      style: TextStyle(
                          color: ac,
                          fontSize: 11,
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

            // Stats row
            Row(
              children: [
                _StatPill(
                    icon: Icons.people_alt_rounded,
                    label: 'Staff',
                    value: '${facility['staffCount']}',
                    color: _kAccentBlue),
                const SizedBox(width: 12),
                _StatPill(
                    icon: Icons.send_rounded,
                    label: 'Referrals',
                    value: '${facility['referralsCount']}',
                    color: _kAccentPurple),
              ],
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _Chip('Type', facility['type']),
                _Chip('District', facility['district']),
              ],
            ),

            const SizedBox(height: 20),

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

// ─── Stat Pill (dialog) ───────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text(label,
                    style: const TextStyle(fontSize: 10, color: _kTextMid)),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: _kTextLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  color: _kTextDark,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Add Facility Dialog ──────────────────────────────────────────────────────

class _AddFacilityDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _AddFacilityDialog({required this.onSave});

  @override
  State<_AddFacilityDialog> createState() => _AddFacilityDialogState();
}

class _AddFacilityDialogState extends State<_AddFacilityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _districtController = TextEditingController();
  String _selectedType = 'Hospital';
  bool _isLoading = false;

  final List<String> _facilityTypes = [
    'Hospital',
    'Health Center',
    'Clinic',
    'Dispensary',
    'Polyclinic',
  ];

  final List<String> _districts = [
    'Gasabo',
    'Kicukiro',
    'Nyarugenge',
    'Bugesera',
    'Gatsibo',
    'Kayonza',
    'Kirehe',
    'Ngoma',
    'Rwamagana',
    'Burera',
    'Gakenke',
    'Gicumbi',
    'Musanze',
    'Rulindo',
    'Gisagara',
    'Huye',
    'Kamonyi',
    'Muhanga',
    'Nyamagabe',
    'Nyanza',
    'Nyaruguru',
    'Ruhango',
    'Karongi',
    'Ngororero',
    'Nyabihu',
    'Rubavu',
    'Rusizi',
    'Rutsiro',
    'Gicumbi',
    'Nyagatare',
    'Rwampara',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_business_rounded, color: _kPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Add New Facility',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _kTextDark)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _kTextMid),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: _kBorder),
              const SizedBox(height: 16),
              
              _buildTextField('Facility Name', _nameController, Icons.local_hospital_rounded),
              const SizedBox(height: 16),
              _buildDropdown('Facility Type', _selectedType, _facilityTypes, (value) {
                setState(() => _selectedType = value!);
              }),
              const SizedBox(height: 16),
              _buildDistrictDropdown(),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: _kBorder),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: _kTextMid, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : _save,
                      style: TextButton.styleFrom(
                        backgroundColor: _kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Add Facility',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w600)),
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

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _kTextDark)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: (v) => v?.isEmpty == true ? 'This field is required' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _kTextMid, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _kTextDark)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.category_rounded, color: _kTextMid, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildDistrictDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('District',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _kTextDark)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: null,
          hint: const Text('Select District'),
          validator: (v) => v == null ? 'Please select a district' : null,
          onChanged: (value) => _districtController.text = value ?? '',
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_on_rounded, color: _kTextMid, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _districts.map((district) => DropdownMenuItem(
            value: district,
            child: Text(district),
          )).toList(),
        ),
      ],
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final data = {
      'name': _nameController.text.trim(),
      'type': _selectedType,
      'district': _districtController.text.trim(),
    };

    await widget.onSave(data);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

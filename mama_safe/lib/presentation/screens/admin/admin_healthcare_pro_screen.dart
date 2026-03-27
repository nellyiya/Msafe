import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF0D6B5E);
const _kPrimaryDark = Color(0xFF0A5549);
const _kAccentBlue = Color(0xFF3498DB);
const _kAccentOrange = Color(0xFFE67E22);
const _kAccentPurple = Color(0xFF9B59B6);
const _kDanger = Color(0xFFE74C3C);
const _kBg = Color(0xFFF0F4F3);
const _kSurface = Colors.white;
const _kTextDark = Color(0xFF1A2E2B);
const _kTextMid = Color(0xFF9CA3AF);
const _kTextLight = Color(0xFF8AADA8);
const _kBorder = Color(0xFFECF0F1);

class AdminHealthcareProScreen extends StatefulWidget {
  const AdminHealthcareProScreen({super.key});

  @override
  State<AdminHealthcareProScreen> createState() =>
      _AdminHealthcareProScreenState();
}

class _AdminHealthcareProScreenState extends State<AdminHealthcareProScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _search = '';
  String _statusFilter = 'All';
  List<Map<String, dynamic>> _pros = [];

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
      final data = await _apiService.getHealthcarePros();

      setState(() {
        _pros = data.map<Map<String, dynamic>>((pro) {
          DateTime joinDate;
          try {
            joinDate = DateTime.parse(
                pro['created_at'] ?? DateTime.now().toIso8601String());
          } catch (_) {
            joinDate = DateTime.now().subtract(const Duration(days: 180));
          }

          DateTime lastActivity;
          try {
            lastActivity = DateTime.parse(pro['last_login'] ??
                pro['updated_at'] ??
                DateTime.now().toIso8601String());
          } catch (_) {
            lastActivity = DateTime.now().subtract(const Duration(days: 1));
          }

          final isActive =
              DateTime.now().difference(lastActivity).inDays <= 7 &&
                  pro['is_approved'] == true &&
                  (pro['status'] == 'active' || pro['status'] == null);

          return {
            'id': pro['id'],
            'name': pro['name'] ?? 'Unknown Doctor',
            'email': pro['email'] ?? 'unknown@hospital.rw',
            'phone': pro['phone'] ?? '+250788000000',
            'facility': pro['facility'] ?? 'Unknown Hospital',
            'specialty': 'General Practitioner',
            'isActive': isActive,
            'referralsCount': pro['referrals_count'] ?? 0,
            'completedCount': pro['completed_count'] ?? 0,
            'lastActivity': lastActivity,
            'joinDate': joinDate,
            'isApproved': pro['is_approved'] ?? false,
            'status': pro['status'] ?? 'pending',
          };
        }).toList();
        _isLoading = false;
      });

      _fadeCtrl.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading healthcare professionals: $e'),
          backgroundColor: _kDanger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final list = _pros.where((pro) {
      final q = _search.toLowerCase();
      final matchSearch = pro['name'].toLowerCase().contains(q) ||
          pro['facility'].toLowerCase().contains(q) ||
          pro['email'].toLowerCase().contains(q);
      final matchStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Active' && pro['isActive'] == true) ||
          (_statusFilter == 'Inactive' && pro['isActive'] != true);
      return matchSearch && matchStatus;
    }).toList();
    list.sort((a, b) =>
        (b['referralsCount'] as int).compareTo(a['referralsCount'] as int));
    return list;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final active = _pros.where((p) => p['isActive'] == true).length;
    final inactive = _pros.length - active;
    final totalRef =
        _pros.fold<int>(0, (s, p) => s + (p['referralsCount'] as int));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: _ProTopBar(onRefresh: _load),
      ),
      floatingActionButton: _AddProFab(onTap: _addNewPro),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : FadeTransition(
              opacity: _fadeAnim,
              child: _ProBody(
                total: _pros.length,
                active: active,
                totalRef: totalRef,
                inactive: inactive,
                search: _search,
                statusFilter: _statusFilter,
                filtered: _filtered,
                onSearch: (v) => setState(() => _search = v),
                onStatus: (v) => setState(() => _statusFilter = v!),
                onView: _showProDetails,
                onEdit: _editPro,
              ),
            ),
    );
  }

  void _showProDetails(Map<String, dynamic> pro) {
    showDialog(
      context: context,
      builder: (_) => _ProDetailDialog(pro: pro),
    );
  }

  void _editPro(Map<String, dynamic> pro) {
    showDialog(
      context: context,
      builder: (_) => _EditProDialog(
        pro: pro,
        onSave: (data) async {
          try {
            await _apiService.updateUser(pro['id'], data);
            _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Dr. ${pro['name']} updated successfully'),
                backgroundColor: _kPrimary,
                behavior: SnackBarBehavior.floating,
              ));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Error updating professional: $e'),
                backgroundColor: _kDanger,
                behavior: SnackBarBehavior.floating,
              ));
            }
          }
        },
      ),
    );
  }

  void _addNewPro() {
    showDialog(
      context: context,
      builder: (_) => _AddProDialog(
        onSave: (data) async {
          try {
            await _apiService.register(
              name: data['name'],
              email: data['email'],
              phone: data['phone'],
              password: data['password'],
              role: 'healthcare_professional',
              facility: data['facility'],
            );
            _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Healthcare professional added successfully'),
                backgroundColor: _kPrimary,
                behavior: SnackBarBehavior.floating,
              ));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Error adding professional: $e'),
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

class _ProTopBar extends StatelessWidget {
  final VoidCallback onRefresh;
  const _ProTopBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text('Healthcare Professionals',
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
          IconButton(
            icon:
                const Icon(Icons.download_rounded, color: _kTextMid, size: 20),
            onPressed: () {},
            tooltip: 'Export',
          ),
        ],
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _ProBody extends StatelessWidget {
  final int total, active, totalRef, inactive;
  final String search, statusFilter;
  final List<Map<String, dynamic>> filtered;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final void Function(Map<String, dynamic>) onView, onEdit;

  const _ProBody({
    required this.total,
    required this.active,
    required this.totalRef,
    required this.inactive,
    required this.search,
    required this.statusFilter,
    required this.filtered,
    required this.onSearch,
    required this.onStatus,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final activeRate = total > 0 ? (active / total * 100).toInt() : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Cards ────────────────────────────────────────────────────
          Row(children: [
            _KpiCard(
              label: 'Total Doctors',
              value: '$total',
              sub: '$active active',
              icon: Icons.medical_services_rounded,
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D6B5E), Color(0xFF0D6B5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            const SizedBox(width: 10),
            _KpiCard(
              label: 'Active',
              value: '$active',
              sub: '$activeRate% active rate',
              icon: Icons.check_circle_rounded,
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D6B5E), Color(0xFF0D6B5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            const SizedBox(width: 10),
            _KpiCard(
              label: 'Total Referrals',
              value: '$totalRef',
              sub: 'Handled by all',
              icon: Icons.send_rounded,
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D6B5E), Color(0xFF0D6B5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            const SizedBox(width: 10),
            _KpiCard(
              label: 'Inactive',
              value: '$inactive',
              sub: 'Need attention',
              icon: Icons.schedule_rounded,
              gradient: const LinearGradient(
                  colors: [Color(0xFF0D6B5E), Color(0xFF0D6B5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
          ]),

          const SizedBox(height: 14),

          // ── Inactive Alert ────────────────────────────────────────────────
          if (inactive > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kAccentOrange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kAccentOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.schedule_rounded,
                        color: _kAccentOrange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$inactive Inactive Professional${inactive > 1 ? 's' : ''} Need Attention',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _kAccentOrange,
                              fontSize: 13),
                        ),
                        const Text(
                          'Consider re-engaging or reviewing their accounts',
                          style: TextStyle(fontSize: 11, color: _kAccentOrange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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
                    border: Border.all(color: _kBorder),
                  ),
                  child: TextField(
                    onChanged: onSearch,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText:
                          'Search healthcare professionals by name, facility, or email...',
                      hintStyle: TextStyle(fontSize: 13, color: _kTextLight),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: _kTextMid, size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _FilterDropdown(
                value: statusFilter,
                items: const ['All', 'Active', 'Inactive'],
                onChanged: onStatus,
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
                              Expanded(
                                  flex: 3,
                                  child: _ColHeader('PROFESSIONAL DETAILS')),
                              Expanded(flex: 2, child: _ColHeader('FACILITY')),
                              Expanded(child: _ColHeader('REFERRALS')),
                              Expanded(child: _ColHeader('COMPLETED')),
                              Expanded(child: _ColHeader('STATUS')),
                              SizedBox(width: 80, child: _ColHeader('ACTIONS')),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: _kBorder),

                        Expanded(
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: _kBorder),
                            itemBuilder: (_, i) => _ProRow(
                              pro: filtered[i],
                              onView: () => onView(filtered[i]),
                              onEdit: () => onEdit(filtered[i]),
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

// ─── Pro Row ──────────────────────────────────────────────────────────────────

class _ProRow extends StatelessWidget {
  final Map<String, dynamic> pro;
  final VoidCallback onView, onEdit;

  const _ProRow({
    required this.pro,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = pro['isActive'] == true;
    final Color ac = active ? _kPrimary : _kDanger;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // ── Professional Details ──────────────────────────────────────
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
                    child: Text('Dr',
                        style: TextStyle(
                            color: _kPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. ${pro['name']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _kTextDark)),
                      Text(pro['email'],
                          style:
                              const TextStyle(fontSize: 11, color: _kTextMid),
                          overflow: TextOverflow.ellipsis),
                      Text(pro['specialty'],
                          style: const TextStyle(
                              fontSize: 10, color: _kTextLight)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Facility ─────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pro['facility'],
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kTextDark),
                    overflow: TextOverflow.ellipsis),
                Text('Joined ${DateFormat('MMM yyyy').format(pro['joinDate'])}',
                    style: const TextStyle(fontSize: 10, color: _kTextLight)),
              ],
            ),
          ),

          // ── Referrals ─────────────────────────────────────────────────
          Expanded(
            child: Text('${pro['referralsCount']}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _kTextDark)),
          ),

          // ── Completed ─────────────────────────────────────────────────
          Expanded(
            child: Text('${pro['completedCount']}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _kTextDark)),
          ),

          // ── Status badge ──────────────────────────────────────────────
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

          // ── Actions ───────────────────────────────────────────────────
          SizedBox(
            width: 80,
            child: Row(
              children: [
                _ActionBtn(
                    icon: Icons.visibility_outlined,
                    color: _kTextMid,
                    tooltip: 'View',
                    onTap: onView),
                _ActionBtn(
                    icon: Icons.edit_outlined,
                    color: _kAccentBlue,
                    tooltip: 'Edit',
                    onTap: onEdit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
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
            child: const Icon(Icons.medical_services_rounded,
                size: 48, color: _kTextLight),
          ),
          const SizedBox(height: 16),
          const Text('No healthcare professionals found',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: _kTextMid)),
          const SizedBox(height: 4),
          const Text('Try adjusting your search or filters',
              style: TextStyle(fontSize: 12, color: _kTextLight)),
        ],
      ),
    );
  }
}

// ─── Add Professional FAB ─────────────────────────────────────────────────────

class _AddProFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddProFab({required this.onTap});

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
            Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Add Professional',
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

class _ProDetailDialog extends StatelessWidget {
  final Map<String, dynamic> pro;
  const _ProDetailDialog({required this.pro});

  @override
  Widget build(BuildContext context) {
    final bool active = pro['isActive'] == true;
    final Color ac = active ? _kPrimary : _kDanger;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 440,
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
                    child: Text('Dr',
                        style: TextStyle(
                            color: _kPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. ${pro['name']}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _kTextDark)),
                      Text(pro['specialty'],
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

            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _Chip('Email', pro['email']),
                _Chip('Phone', pro['phone']),
                _Chip('Facility', pro['facility']),
                _Chip('Referrals', '${pro['referralsCount']}'),
                _Chip('Completed', '${pro['completedCount']}'),
                _Chip('Joined',
                    DateFormat('dd MMM yyyy').format(pro['joinDate'])),
                _Chip('Last Active',
                    DateFormat('dd MMM yyyy').format(pro['lastActivity'])),
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

// ─── Edit Professional Dialog ─────────────────────────────────────────────────

class _EditProDialog extends StatefulWidget {
  final Map<String, dynamic> pro;
  final Function(Map<String, dynamic>) onSave;

  const _EditProDialog({required this.pro, required this.onSave});

  @override
  State<_EditProDialog> createState() => _EditProDialogState();
}

class _EditProDialogState extends State<_EditProDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _facilityController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pro['name']);
    _emailController = TextEditingController(text: widget.pro['email']);
    _phoneController = TextEditingController(text: widget.pro['phone']);
    _facilityController = TextEditingController(text: widget.pro['facility']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _facilityController.dispose();
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
                    child: const Icon(Icons.edit_rounded, color: _kPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Edit Healthcare Professional',
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
              
              _buildTextField('Full Name', _nameController, Icons.person_rounded),
              const SizedBox(height: 16),
              _buildTextField('Email Address', _emailController, Icons.email_rounded),
              const SizedBox(height: 16),
              _buildTextField('Phone Number', _phoneController, Icons.phone_rounded),
              const SizedBox(height: 16),
              _buildTextField('Facility/Hospital', _facilityController, Icons.local_hospital_rounded),
              
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
                          : const Text('Save Changes',
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

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'facility': _facilityController.text.trim(),
    };

    await widget.onSave(data);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

// ─── Add Professional Dialog ──────────────────────────────────────────────────

class _AddProDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _AddProDialog({required this.onSave});

  @override
  State<_AddProDialog> createState() => _AddProDialogState();
}

class _AddProDialogState extends State<_AddProDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facilityController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _facilityController.dispose();
    _passwordController.dispose();
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
                    child: const Icon(Icons.person_add_rounded, color: _kPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Add Healthcare Professional',
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
              
              _buildTextField('Full Name', _nameController, Icons.person_rounded),
              const SizedBox(height: 16),
              _buildTextField('Email Address', _emailController, Icons.email_rounded),
              const SizedBox(height: 16),
              _buildTextField('Phone Number', _phoneController, Icons.phone_rounded),
              const SizedBox(height: 16),
              _buildTextField('Facility/Hospital', _facilityController, Icons.local_hospital_rounded),
              const SizedBox(height: 16),
              _buildPasswordField(),
              
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
                          : const Text('Add Professional',
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

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Password',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _kTextDark)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: (v) {
            if (v?.isEmpty == true) return 'Password is required';
            if (v!.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_rounded, color: _kTextMid, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: _kTextMid,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
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

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'facility': _facilityController.text.trim(),
      'password': _passwordController.text,
    };

    await widget.onSave(data);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

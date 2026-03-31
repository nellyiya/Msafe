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

class AdminCHWsScreen extends StatefulWidget {
  const AdminCHWsScreen({super.key});

  @override
  State<AdminCHWsScreen> createState() => _AdminCHWsScreenState();
}

class _AdminCHWsScreenState extends State<AdminCHWsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _search = '';
  String _statusFilter = 'All';
  List<Map<String, dynamic>> _chws = [];

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadCHWsData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadCHWsData() async {
    try {
      setState(() => _isLoading = true);
      final chwsData = await _apiService.getCHWs();

      setState(() {
        _chws = chwsData.map<Map<String, dynamic>>((chw) {
          DateTime joinDate;
          try {
            joinDate = DateTime.parse(
                chw['created_at'] ?? DateTime.now().toIso8601String());
          } catch (_) {
            joinDate = DateTime.now().subtract(const Duration(days: 90));
          }

          DateTime lastVisit;
          try {
            lastVisit = DateTime.parse(chw['last_login'] ??
                chw['updated_at'] ??
                DateTime.now().toIso8601String());
          } catch (_) {
            lastVisit = DateTime.now().subtract(const Duration(days: 1));
          }

          final mothers = chw['mothers_count'] ?? 0;
          final assessments = chw['assessments_count'] ?? 0;
          final referrals = chw['referrals_count'] ?? 0;

          int perf = 70;
          if (mothers > 40) {
            perf += 15;
          } else if (mothers > 20)
            perf += 10;
          else if (mothers > 10) perf += 5;
          if (assessments > 100) {
            perf += 10;
          } else if (assessments > 50) perf += 5;
          if (referrals > 15) perf += 5;

          final isActive = DateTime.now().difference(lastVisit).inDays <= 7 &&
              chw['is_approved'] == true &&
              (chw['status'] == 'active' || chw['status'] == null);

          return {
            'id': chw['id'],
            'name': chw['name'] ?? 'Unknown CHW',
            'email': chw['email'] ?? 'unknown@chw.rw',
            'phone': chw['phone'] ?? '+250788000000',
            'healthCenter': chw['facility'] ?? '',
            'district': chw['district'] ?? 'Gasabo',
            'sector': chw['sector'] ?? 'Unknown Sector',
            'cell': chw['cell'] ?? 'Unknown Cell',
            'village': chw['village'] ?? 'Unknown Village',
            'isActive': isActive,
            'mothersRegistered': mothers,
            'predictionsMade': assessments,
            'referralsCreated': referrals,
            'lastVisit': lastVisit,
            'joinDate': joinDate,
            'performance': perf.clamp(0, 100),
            'isApproved': chw['is_approved'] ?? false,
            'status': chw['status'] ?? 'pending',
          };
        }).toList();
        _isLoading = false;
      });

      _fadeCtrl.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading CHWs: $e'),
          backgroundColor: _kDanger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final list = _chws.where((chw) {
      final q = _search.toLowerCase();
      final matchSearch = chw['name'].toLowerCase().contains(q) ||
          chw['healthCenter'].toLowerCase().contains(q) ||
          chw['district'].toLowerCase().contains(q);
      final matchStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Active' && chw['isActive'] == true) ||
          (_statusFilter == 'Inactive' && chw['isActive'] != true);
      return matchSearch && matchStatus;
    }).toList();
    list.sort(
        (a, b) => (b['performance'] as int).compareTo(a['performance'] as int));
    return list;
  }

  Color _perfColor(int p) {
    if (p >= 90) return _kPrimary;
    if (p >= 80) return _kAccentOrange;
    return _kDanger;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final activeCHWs = _chws.where((c) => c['isActive'] == true).length;
    final totalMothers =
        _chws.fold<int>(0, (s, c) => s + (c['mothersRegistered'] as int));
    final totalPreds =
        _chws.fold<int>(0, (s, c) => s + (c['predictionsMade'] as int));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: _CHWTopBar(onRefresh: _loadCHWsData),
      ),
      floatingActionButton: _AddCHWFab(onTap: _addNewCHW),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : FadeTransition(
              opacity: _fadeAnim,
              child: _CHWBody(
                totalCHWs: _chws.length,
                activeCHWs: activeCHWs,
                totalMothers: totalMothers,
                totalPreds: totalPreds,
                search: _search,
                statusFilter: _statusFilter,
                filtered: _filtered,
                onSearch: (v) => setState(() => _search = v),
                onStatus: (v) => setState(() => _statusFilter = v!),
                perfColor: _perfColor,
                onView: _showCHWDetails,
                onEdit: _editCHW,
              ),
            ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  void _showCHWDetails(Map<String, dynamic> chw) {
    showDialog(
      context: context,
      builder: (_) => _CHWDetailDialog(chw: chw, perfColor: _perfColor),
    );
  }

  void _editCHW(Map<String, dynamic> chw) {
    showDialog(
      context: context,
      builder: (_) => _EditCHWDialog(
        chw: chw,
        onSave: (updatedData) async {
          try {
            await _apiService.updateUser(chw['id'], updatedData);
            await _loadCHWsData(); // Refresh the list
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${chw['name']} updated successfully'),
                backgroundColor: _kPrimary,
                behavior: SnackBarBehavior.floating,
              ));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to update ${chw['name']}: $e'),
                backgroundColor: _kDanger,
                behavior: SnackBarBehavior.floating,
              ));
            }
          }
        },
      ),
    );
  }

  void _addNewCHW() {
    showDialog(
      context: context,
      builder: (_) => _AddCHWDialog(
        onSave: (newCHWData) async {
          try {
            await _apiService.register(
              name: newCHWData['name'],
              email: newCHWData['email'],
              phone: newCHWData['phone'],
              password: newCHWData['password'],
              role: 'chw',
              district: newCHWData['district'],
              sector: newCHWData['sector'],
              cell: newCHWData['cell'],
              village: newCHWData['village'],
              facility: newCHWData['facility'],
            );
            await _loadCHWsData(); // Refresh the list
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${newCHWData['name']} added successfully'),
                backgroundColor: _kPrimary,
                behavior: SnackBarBehavior.floating,
              ));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to add CHW: $e'),
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

class _CHWTopBar extends StatelessWidget {
  final VoidCallback onRefresh;
  const _CHWTopBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text('CHW Management',
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

class _CHWBody extends StatelessWidget {
  final int totalCHWs, activeCHWs, totalMothers, totalPreds;
  final String search, statusFilter;
  final List<Map<String, dynamic>> filtered;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final Color Function(int) perfColor;
  final void Function(Map<String, dynamic>) onView, onEdit;

  const _CHWBody({
    required this.totalCHWs,
    required this.activeCHWs,
    required this.totalMothers,
    required this.totalPreds,
    required this.search,
    required this.statusFilter,
    required this.filtered,
    required this.onSearch,
    required this.onStatus,
    required this.perfColor,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final activeRate =
        totalCHWs > 0 ? (activeCHWs / totalCHWs * 100).toInt() : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Cards ────────────────────────────────────────────────────
          Row(children: [
            _StatCard(
              label: 'Total CHWs',
              value: '$totalCHWs',
              sub: '$activeCHWs active',
              icon: Icons.people_alt_rounded,
              accentColor: _kPrimary,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'Active CHWs',
              value: '$activeCHWs',
              sub: '$activeRate% active rate',
              icon: Icons.check_circle_rounded,
              accentColor: _kPrimary,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'Total Mothers',
              value: '$totalMothers',
              sub: 'Under CHW care',
              icon: Icons.pregnant_woman_rounded,
              accentColor: _kPrimary,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'Predictions',
              value: '$totalPreds',
              sub: 'ML assessments',
              icon: Icons.psychology_rounded,
              accentColor: _kPrimary,
            ),
          ]),

          const SizedBox(height: 14),

          // ── Search + Filter ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kPrimary.withOpacity(0.7), width: 2.0),
                  ),
                  child: TextField(
                    onChanged: onSearch,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText:
                          'Search CHWs by name, health center, or district...',
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
                                  flex: 3, child: _ColHeader('CHW DETAILS')),
                              Expanded(child: _ColHeader('MOTHERS')),
                              Expanded(child: _ColHeader('PREDICTIONS')),
                              Expanded(child: _ColHeader('PERFORMANCE')),
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
                            itemBuilder: (_, i) => _CHWRow(
                              chw: filtered[i],
                              perfColor: perfColor,
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

// ─── Stat Card ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color accentColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2EDEB), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 4)),
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
                                      color: _kTextDark,
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

// ─── CHW Row ──────────────────────────────────────────────────────────────────

class _CHWRow extends StatelessWidget {
  final Map<String, dynamic> chw;
  final Color Function(int) perfColor;
  final VoidCallback onView, onEdit;

  const _CHWRow({
    required this.chw,
    required this.perfColor,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = chw['isActive'] == true;
    final int perf = chw['performance'] as int;
    final Color pc = perfColor(perf);
    final Color ac = active ? _kPrimary : _kDanger;
    final initials = (chw['name'] as String)
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // ── CHW Details ───────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _kPrimary.withOpacity(0.15),
                  child: Text(initials,
                      style: const TextStyle(
                          color: _kPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chw['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _kTextDark)),
                      Text(chw['email'],
                          style:
                              const TextStyle(fontSize: 11, color: _kTextMid),
                          overflow: TextOverflow.ellipsis),
                      Text('${chw['district']} District',
                          style: const TextStyle(
                              fontSize: 10, color: _kTextLight)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Mothers ───────────────────────────────────────────────────
          Expanded(
            child: Text('${chw['mothersRegistered']}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _kTextDark)),
          ),

          // ── Predictions ───────────────────────────────────────────────
          Expanded(
            child: Text('${chw['predictionsMade']}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _kTextDark)),
          ),

          // ── Performance bar + % ───────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$perf%',
                    style: TextStyle(
                        color: pc, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: perf / 100,
                    minHeight: 5,
                    backgroundColor: pc.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(pc),
                  ),
                ),
              ],
            ),
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
            child: const Icon(Icons.people_alt_rounded,
                size: 48, color: _kTextLight),
          ),
          const SizedBox(height: 16),
          const Text('No CHWs found',
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

// ─── Add CHW FAB ─────────────────────────────────────────────────────────────

class _AddCHWFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCHWFab({required this.onTap});

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
            Text('Add CHW',
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

class _CHWDetailDialog extends StatelessWidget {
  final Map<String, dynamic> chw;
  final Color Function(int) perfColor;

  const _CHWDetailDialog({
    required this.chw,
    required this.perfColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = chw['isActive'] == true;
    final int perf = chw['performance'] as int;
    final Color ac = active ? _kPrimary : _kDanger;
    final Color pc = perfColor(perf);
    final initials = (chw['name'] as String)
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join();

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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _kPrimary.withOpacity(0.15),
                  child: Text(initials,
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
                      Text(chw['name'],
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _kTextDark)),
                      Text(chw['email'],
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

            const SizedBox(height: 14),

            // Performance bar
            Row(
              children: [
                Text('Performance: $perf%',
                    style: TextStyle(
                        fontSize: 12, color: pc, fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: perf / 100,
                      minHeight: 6,
                      backgroundColor: pc.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(pc),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: _kBorder),
            const SizedBox(height: 14),

            // Details grid
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _Chip('Phone', chw['phone']),
                _Chip('District', '${chw['district']} District'),
                _Chip('Mothers', '${chw['mothersRegistered']}'),
                _Chip('Predictions', '${chw['predictionsMade']}'),
                _Chip('Referrals', '${chw['referralsCreated']}'),
                _Chip('Joined',
                    DateFormat('dd MMM yyyy').format(chw['joinDate'])),
                _Chip('Last Visit',
                    DateFormat('dd MMM yyyy').format(chw['lastVisit'])),
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

// ─── Edit CHW Dialog ──────────────────────────────────────────────────────────

class _EditCHWDialog extends StatefulWidget {
  final Map<String, dynamic> chw;
  final Function(Map<String, dynamic>) onSave;

  const _EditCHWDialog({
    required this.chw,
    required this.onSave,
  });

  @override
  State<_EditCHWDialog> createState() => _EditCHWDialogState();
}

class _EditCHWDialogState extends State<_EditCHWDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _facilityController;
  late TextEditingController _districtController;
  late TextEditingController _sectorController;
  late TextEditingController _cellController;
  late TextEditingController _villageController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.chw['name']);
    _emailController = TextEditingController(text: widget.chw['email']);
    _phoneController = TextEditingController(text: widget.chw['phone']);
    _facilityController = TextEditingController(text: widget.chw['healthCenter']);
    _districtController = TextEditingController(text: widget.chw['district']);
    _sectorController = TextEditingController(text: widget.chw['sector']);
    _cellController = TextEditingController(text: widget.chw['cell']);
    _villageController = TextEditingController(text: widget.chw['village']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _facilityController.dispose();
    _districtController.dispose();
    _sectorController.dispose();
    _cellController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit CHW - ${widget.chw['name']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField('Full Name', _nameController, required: true),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField('Email', _emailController, required: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField('Phone', _phoneController, required: true),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField('Health Facility', _facilityController, required: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Location Information
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField('District', _districtController, required: true),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField('Sector', _sectorController),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField('Cell', _cellController),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField('Village', _villageController),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _kTextMid,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
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

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kTextDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: required ? (value) => 
              (value?.isEmpty ?? true) ? '$label is required' : null : null,
        ),
      ],
    );
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'facility': _facilityController.text.trim(),
      'district': _districtController.text.trim(),
      'sector': _sectorController.text.trim(),
      'cell': _cellController.text.trim(),
      'village': _villageController.text.trim(),
    };

    widget.onSave(updatedData);
    Navigator.pop(context);
  }
}

// ─── Add CHW Dialog ───────────────────────────────────────────────────────────

class _AddCHWDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _AddCHWDialog({
    required this.onSave,
  });

  @override
  State<_AddCHWDialog> createState() => _AddCHWDialogState();
}

class _AddCHWDialogState extends State<_AddCHWDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _facilityController = TextEditingController();
  final _districtController = TextEditingController();
  final _sectorController = TextEditingController();
  final _cellController = TextEditingController();
  final _villageController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _facilityController.dispose();
    _districtController.dispose();
    _sectorController.dispose();
    _cellController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add New CHW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField('Full Name', _nameController, required: true),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField('Email', _emailController, required: true, isEmail: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField('Phone', _phoneController, required: true),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPasswordField(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Work Information
                      _buildTextField('Health Facility', _facilityController, required: true),
                      const SizedBox(height: 16),
                      
                      // Location Information
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField('District', _districtController, required: true),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField('Sector', _sectorController),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField('Cell', _cellController),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField('Village', _villageController),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _kTextMid,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addCHW,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Add CHW',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
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

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, bool isEmail = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kTextDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (required && (value?.isEmpty ?? true)) {
              return '$label is required';
            }
            if (isEmail && value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kTextDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: _kTextMid,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Password is required';
            }
            if (value!.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _addCHW() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final newCHWData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text,
      'facility': _facilityController.text.trim(),
      'district': _districtController.text.trim(),
      'sector': _sectorController.text.trim(),
      'cell': _cellController.text.trim(),
      'village': _villageController.text.trim(),
    };

    widget.onSave(newCHWData);
    Navigator.pop(context);
  }
}

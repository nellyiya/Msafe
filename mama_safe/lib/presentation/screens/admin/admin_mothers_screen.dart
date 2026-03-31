import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';

// ─── Design Tokens (shared with dashboard) ────────────────────────────────────
const _kPrimary = Color(0xFF0D6B5E);
const _kPrimaryLight = Color(0xFF12876F);
const _kPrimaryDark = Color(0xFF084F45);
const _kAccentBlue = Color(0xFF3498DB);
const _kAccentOrange = Color(0xFFD97706); // kWarning
const _kDanger = Color(0xFFCF3030);
const _kDangerLight = Color(0xFFFF4D4D);
const _kWarning = Color(0xFFD97706);
const _kSuccess = Color(0xFF059669);
const _kBg = Color(0xFFF5F8F7);
const _kBgDeep = Color(0xFFEDF3F1);
const _kSurface = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFE2EDEB);
const _kBorderStrong = Color(0xFFB8D5CF);
const _kTextDark = Color(0xFF0C1F1C);
const _kTextBody = Color(0xFF374845);
const _kTextMid = Color(0xFF6E8E8A);
const _kTextLight = Color(0xFFA3BFBB);

class AdminMothersScreen extends StatefulWidget {
  const AdminMothersScreen({super.key});

  @override
  State<AdminMothersScreen> createState() => _AdminMothersScreenState();
}

class _AdminMothersScreenState extends State<AdminMothersScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _search = '';
  String _riskFilter = 'All Risk';

  List<Map<String, dynamic>> _mothers = [];
  List<Map<String, dynamic>> _chws = [];

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadMothersData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMothersData() async {
    try {
      setState(() => _isLoading = true);
      final mothersData = await _apiService.getAllMothersAdmin();
      final chwsData = await _apiService.getCHWs();
      final referralsData = await _apiService.getAllReferrals();

      setState(() {
        _mothers = mothersData.map<Map<String, dynamic>>((mother) {
          final chwId = mother['chw']?['id'] ?? mother['created_by_chw_id'];
          final chw = chwsData.firstWhere(
            (c) => c['id'].toString() == chwId.toString(),
            orElse: () => {
              'name': 'Unassigned',
              'facility': 'Unknown Health Center',
              'health_center': 'Unknown Health Center',
              'district': 'Unknown'
            },
          );

          // Find the most recent referral for this mother
          final motherReferrals = referralsData
              .where(
                  (r) => r['mother_id']?.toString() == mother['id']?.toString())
              .toList();

          String healthCenter = 'No Referral';
          bool hasAppointment = false;
          if (motherReferrals.isNotEmpty) {
            // Sort by created_at to get the most recent referral
            motherReferrals.sort((a, b) {
              try {
                return DateTime.parse(b['created_at'].toString())
                    .compareTo(DateTime.parse(a['created_at'].toString()));
              } catch (_) {
                return 0;
              }
            });

            final latestReferral = motherReferrals.first;
            healthCenter = latestReferral['hospital']?.toString() ??
                latestReferral['health_center']?.toString() ??
                latestReferral['facility']?.toString() ??
                'Unknown Health Center';

            // Check if any referral has appointment status
            hasAppointment = motherReferrals.any((r) {
              final status = r['status']?.toString().toLowerCase() ?? '';
              return status.contains('appointment') ||
                  status.contains('scheduled') ||
                  status == 'appointment_scheduled';
            });
          }

          int pregnancyWeek = 20;
          DateTime? dueDate;
          try {
            if (mother['due_date'] != null) {
              dueDate = DateTime.parse(mother['due_date']);
              final weeksLeft = dueDate.difference(DateTime.now()).inDays / 7;
              pregnancyWeek = (40 - weeksLeft).round().clamp(1, 42);
            } else if (mother['created_at'] != null) {
              final createdAt = DateTime.parse(mother['created_at']);
              final weeksSince =
                  DateTime.now().difference(createdAt).inDays / 7;
              pregnancyWeek = (20 + weeksSince).round().clamp(1, 42);
              dueDate = createdAt.add(const Duration(days: 140));
            }
          } catch (_) {
            dueDate = DateTime.now().add(const Duration(days: 140));
          }

          DateTime lastVisit;
          try {
            lastVisit = DateTime.parse(
                mother['created_at'] ?? DateTime.now().toIso8601String());
          } catch (_) {
            lastVisit = DateTime.now().subtract(const Duration(days: 7));
          }

          return {
            'id': mother['id'],
            'name': mother['name'] ?? 'Unknown Mother',
            'age': mother['age'] ?? 25,
            'pregnancyWeek': pregnancyWeek,
            'riskLevel': mother['current_risk_level'] ?? 'Low',
            'chwAssigned': chw['name'] ?? 'Unassigned',
            'healthCenter': healthCenter,
            'district': chw['district'] ?? mother['district'] ?? 'Gasabo',
            'dueDate': dueDate ?? DateTime.now().add(const Duration(days: 140)),
            'lastVisit': lastVisit,
            'nextAppointment': null,
            'phone': mother['phone'] ?? '+250788000000',
            'hasAppointment': hasAppointment,
            'pregnancyNumber': 1,
            'complications': <String>[],
          };
        }).toList();
        _chws = List<Map<String, dynamic>>.from(chwsData);
        _isLoading = false;
      });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading mothers: $e'),
            backgroundColor: _kDanger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredMothers {
    var filtered = _mothers.where((m) {
      final q = _search.toLowerCase();
      final matchSearch = m['name'].toLowerCase().contains(q) ||
          m['chwAssigned'].toLowerCase().contains(q) ||
          m['healthCenter'].toLowerCase().contains(q);

      final riskLabel = '${m['riskLevel']} Risk';
      final matchRisk = _riskFilter == 'All Risk' || riskLabel == _riskFilter;

      return matchSearch && matchRisk;
    }).toList();

    return filtered;
  }

  bool _isDueSoon(DateTime d) {
    final diff = d.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 14;
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'High':
        return _kDanger;
      case 'Medium':
        return _kWarning;
      case 'Low':
        return _kSuccess;
      default:
        return _kTextMid;
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final total = _mothers.length;
    final highRisk = _mothers.where((m) => m['riskLevel'] == 'High').length;
    final dueSoon = _mothers.where((m) => _isDueSoon(m['dueDate'])).length;
    final newThisWeek = _mothers.where((m) {
      return (m['lastVisit'] as DateTime)
          .isAfter(DateTime.now().subtract(const Duration(days: 7)));
    }).length;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: _MothersTopBar(onRefresh: _loadMothersData),
      ),
      floatingActionButton: _AddMotherFab(onTap: _addNewMother),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : FadeTransition(
              opacity: _fadeAnim,
              child: _MothersBody(
                total: total,
                highRisk: highRisk,
                dueSoon: dueSoon,
                newVisits: newThisWeek,
                search: _search,
                riskFilter: _riskFilter,
                filtered: filteredMothers,
                onSearch: (v) => setState(() => _search = v),
                onRiskFilter: (v) => setState(() => _riskFilter = v!),
                onStatusDueSoon: () =>
                    setState(() => _riskFilter = 'High Risk'),
                isDueSoon: _isDueSoon,
                riskColor: _riskColor,
                onView: _showMotherDetails,
                onEdit: _editMother,
                onDelete: _deleteMother,
              ),
            ),
    );
  }

  // ─── Actions ────────────────────────────────────────────────────────────────

  void _showMotherDetails(Map<String, dynamic> m) {
    showDialog(
      context: context,
      builder: (_) => _ComprehensiveMotherDetailDialog(
        mother: m,
        apiService: _apiService,
      ),
    );
  }

  void _editMother(Map<String, dynamic> m) {
    showDialog(
      context: context,
      builder: (_) => _ComprehensiveEditMotherDialog(
        mother: m,
        apiService: _apiService,
        onSave: (updatedMother) async {
          try {
            print(
                'Updating mother ${m['id']} with data: $updatedMother'); // Debug log
            await _apiService.updateMother(m['id'], updatedMother);

            // Update local list
            setState(() {
              final index =
                  _mothers.indexWhere((mother) => mother['id'] == m['id']);
              if (index != -1) {
                // Update specific fields that were changed
                if (updatedMother.containsKey('name')) {
                  _mothers[index]['name'] = updatedMother['name'];
                }
                if (updatedMother.containsKey('age')) {
                  _mothers[index]['age'] = updatedMother['age'];
                }
                if (updatedMother.containsKey('phone')) {
                  _mothers[index]['phone'] = updatedMother['phone'];
                }
                if (updatedMother.containsKey('current_risk_level')) {
                  _mothers[index]['riskLevel'] =
                      updatedMother['current_risk_level'];
                }
                if (updatedMother.containsKey('created_by_chw_id')) {
                  // Find CHW name for the new ID
                  final chwId = updatedMother['created_by_chw_id'];
                  final chw = _chws.firstWhere(
                    (c) => c['id'].toString() == chwId.toString(),
                    orElse: () => {'name': 'Unassigned'},
                  );
                  _mothers[index]['chwAssigned'] = chw['name'] ?? 'Unassigned';
                }
              }
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${m['name']} updated successfully'),
                backgroundColor: _kPrimary,
                behavior: SnackBarBehavior.floating,
              ));
            }
          } catch (e) {
            print('Error updating mother: $e'); // Debug log
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to update ${m['name']}: $e'),
                backgroundColor: _kDanger,
                behavior: SnackBarBehavior.floating,
              ));
            }
          }
        },
      ),
    );
  }

  void _deleteMother(Map<String, dynamic> m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Mother',
            style: TextStyle(fontWeight: FontWeight.w700, color: _kTextDark)),
        content: Text(
          'Are you sure you want to delete ${m['name']}? This action cannot be undone.',
          style: const TextStyle(color: _kTextMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _kTextMid)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(backgroundColor: _kDanger),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteMother(m['id']);
        setState(() {
          _mothers.removeWhere((mother) => mother['id'] == m['id']);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${m['name']} deleted successfully'),
            backgroundColor: _kPrimary,
            behavior: SnackBarBehavior.floating,
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to delete ${m['name']}: $e'),
            backgroundColor: _kDanger,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  void _addNewMother() {
    showDialog(
      context: context,
      builder: (_) => _AddMotherDialog(
        chws: _chws,
        onSave: (newMotherData) async {
          try {
            print('Creating new mother with data: $newMotherData'); // Debug log
            final response = await _apiService.createMother(newMotherData);

            // Reload the mothers list to include the new mother
            await _loadMothersData();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${newMotherData['name']} added successfully'),
                backgroundColor: _kPrimary,
                behavior: SnackBarBehavior.floating,
              ));
            }
          } catch (e) {
            print('Error creating mother: $e'); // Debug log
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to add mother: $e'),
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

class _MothersTopBar extends StatelessWidget {
  final VoidCallback onRefresh;
  const _MothersTopBar({required this.onRefresh});

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
              Text('Mothers Management',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _kTextDark,
                      letterSpacing: -0.5)),
              SizedBox(height: 1),
              Text('Patient registry & risk overview',
                  style: TextStyle(
                      fontSize: 11, color: _kTextMid, letterSpacing: 0.1)),
            ],
          ),
          const Spacer(),
          _TopIconBtn(
              icon: Icons.refresh_rounded,
              onTap: onRefresh,
              tooltip: 'Refresh'),
          const SizedBox(width: 8),
          _TopIconBtn(
              icon: Icons.download_rounded, onTap: () {}, tooltip: 'Export'),
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

class _MothersBody extends StatelessWidget {
  final int total, highRisk, dueSoon, newVisits;
  final String search, riskFilter;
  final List<Map<String, dynamic>> filtered;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onRiskFilter;
  final VoidCallback onStatusDueSoon;
  final bool Function(DateTime) isDueSoon;
  final Color Function(String) riskColor;
  final void Function(Map<String, dynamic>) onView, onEdit, onDelete;

  const _MothersBody({
    required this.total,
    required this.highRisk,
    required this.dueSoon,
    required this.newVisits,
    required this.search,
    required this.riskFilter,
    required this.filtered,
    required this.onSearch,
    required this.onRiskFilter,
    required this.onStatusDueSoon,
    required this.isDueSoon,
    required this.riskColor,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
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
            // Total Mothers — teal accent
            _MiniStatCard(
              label: 'Total Mothers',
              value: '$total',
              sub: 'Registered',
              icon: Icons.pregnant_woman_rounded,
              accentColor: _kPrimary,
            ),
            const SizedBox(width: 10),
            // High Risk — dramatic red
            _MiniStatCard(
              label: 'High Risk',
              value: '$highRisk',
              sub: total > 0
                  ? '${(highRisk / total * 100).toInt()}% of total'
                  : '0% of total',
              icon: Icons.warning_amber_rounded,
              accentColor: _kDanger,
            ),
            const SizedBox(width: 10),
            _MiniStatCard(
              label: 'Due Soon',
              value: '$dueSoon',
              sub: 'Within 2 weeks',
              icon: Icons.schedule_rounded,
              accentColor: _kPrimary,
            ),
            const SizedBox(width: 10),
            _MiniStatCard(
              label: 'New Visits',
              value: '$newVisits',
              sub: 'This week',
              icon: Icons.fiber_new_rounded,
              accentColor: _kPrimary,
            ),
          ]),

          const SizedBox(height: 12),

          // ── Due Soon Alert Banner ─────────────────────────────────────────
          if (dueSoon > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: _kWarning.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kWarning.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _kWarning.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.schedule_rounded,
                        color: _kWarning, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$dueSoon Mothers Due Within 2 Weeks',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _kWarning,
                              fontSize: 12,
                              letterSpacing: -0.1),
                        ),
                        Text(
                          'Schedule follow-up visits and prepare delivery plans',
                          style: TextStyle(
                              fontSize: 11, color: _kWarning.withOpacity(0.75)),
                        ),
                      ],
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
                flex: 3,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kPrimary.withOpacity(0.7), width: 2.0),
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
                      hintText: 'Search by name, CHW, or health center...',
                      hintStyle:
                          TextStyle(fontSize: 13, color: _kTextLight),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: _kTextMid, size: 17),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FilterDropdown(
                value: riskFilter,
                items: const [
                  'All Risk',
                  'High Risk',
                  'Medium Risk',
                  'Low Risk'
                ],
                onChanged: onRiskFilter,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Table ─────────────────────────────────────────────────────────
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
              child: Column(
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
                        Expanded(flex: 3, child: _ColHeader('MOTHER DETAILS')),
                        Expanded(flex: 2, child: _ColHeader('PREGNANCY INFO')),
                        Expanded(flex: 2, child: _ColHeader('CHW & CENTER')),
                        Expanded(child: _ColHeader('RISK LEVEL')),
                        Expanded(child: _ColHeader('DUE DATE')),
                        SizedBox(width: 100, child: _ColHeader('ACTIONS')),
                      ],
                    ),
                  ),

                  // Rows
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: _kBgDeep,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.search_off_rounded,
                                      color: _kTextLight, size: 28),
                                ),
                                const SizedBox(height: 12),
                                const Text('No mothers found',
                                    style: TextStyle(
                                        color: _kTextMid,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final m = filtered[i];
                              return _MotherRow(
                                mother: m,
                                soon: isDueSoon(m['dueDate']),
                                riskColor: riskColor,
                                isEven: i.isEven,
                                onView: () => onView(m),
                                onEdit: () => onEdit(m),
                                onDelete: () => onDelete(m),
                              );
                            },
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

// ─── Mini Stat Card (white, colored left accent) ─────────────────────────────

class _MiniStatCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color accentColor;

  const _MiniStatCard({
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
          border: Border.all(color: _kBorder, width: 1),
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

// ─── Mini Alert Card (dramatic solid, for High Risk) ─────────────────────────

class _MiniAlertCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color cardColor;

  const _MiniAlertCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cardColor,
              Color.lerp(cardColor, const Color(0xFF8B0000), 0.35)!,
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

// ─── Legacy alias ─────────────────────────────────────────────────────────────
class _MiniKpiCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final LinearGradient gradient;
  const _MiniKpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.gradient,
  });
  @override
  Widget build(BuildContext context) => _MiniStatCard(
      label: label, value: value, sub: sub, icon: icon, accentColor: _kPrimary);
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _kTextMid,
            letterSpacing: 0.7));
  }
}

// ─── Mother Row ───────────────────────────────────────────────────────────────

class _MotherRow extends StatelessWidget {
  final Map<String, dynamic> mother;
  final bool soon;
  final bool isEven;
  final Color Function(String) riskColor;
  final VoidCallback onView, onEdit, onDelete;

  const _MotherRow({
    required this.mother,
    required this.soon,
    required this.riskColor,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    this.isEven = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color rc = riskColor(mother['riskLevel']);
    final initials = (mother['name'] as String)
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join();
    final dueDate = mother['dueDate'] as DateTime;
    final daysLeft = dueDate.difference(DateTime.now()).inDays;

    Color rowBg = Colors.transparent;
    if (soon) {
      rowBg = _kWarning.withOpacity(0.04);
    } else if (isEven) rowBg = _kBg.withOpacity(0.6);

    return Container(
      color: rowBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Row(
        children: [
          // ── Mother Details ───────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Rounded square avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kPrimary.withOpacity(0.18)),
                  ),
                  child: Center(
                    child: Text(initials,
                        style: const TextStyle(
                            color: _kPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mother['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _kTextDark,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 1),
                      Text('Age: ${mother['age']} · ${mother['phone']}',
                          style:
                              const TextStyle(fontSize: 11, color: _kTextMid)),
                      Text('Pregnancy #${mother['pregnancyNumber']}',
                          style: const TextStyle(
                              fontSize: 10, color: _kTextLight)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Pregnancy Info ───────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Wk ${mother['pregnancyWeek']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: _kPrimary)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    'Last: ${DateFormat('dd MMM').format(mother['lastVisit'])}',
                    style: const TextStyle(fontSize: 11, color: _kTextMid)),
              ],
            ),
          ),

          // ── CHW & Center ─────────────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mother['chwAssigned'],
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kTextDark)),
                Text(mother['healthCenter'],
                    style: const TextStyle(fontSize: 11, color: _kTextMid),
                    overflow: TextOverflow.ellipsis),
                Text(mother['district'],
                    style: const TextStyle(fontSize: 10, color: _kTextLight)),
              ],
            ),
          ),

          // ── Risk Badge ───────────────────────────────────────────────────
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: rc.withOpacity(0.09),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: rc.withOpacity(0.22)),
              ),
              child: Text(
                '${mother['riskLevel']} Risk',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: rc,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1),
              ),
            ),
          ),

          // ── Due Date ─────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('dd MMM yyyy').format(dueDate),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kTextDark)),
                Text(
                  soon ? '⚠ Due Soon!' : '$daysLeft days',
                  style: TextStyle(
                      fontSize: 10,
                      color: soon ? _kWarning : _kTextMid,
                      fontWeight: soon ? FontWeight.w700 : FontWeight.normal),
                ),
              ],
            ),
          ),

          // ── Actions ──────────────────────────────────────────────────────
          SizedBox(
            width: 100,
            child: Row(
              children: [
                _ActionBtn(
                    icon: Icons.visibility_outlined,
                    color: _kTextMid,
                    tooltip: 'View Details',
                    onTap: onView),
                _ActionBtn(
                    icon: Icons.edit_outlined,
                    color: _kAccentBlue,
                    tooltip: 'Edit Mother',
                    onTap: onEdit),
                _ActionBtn(
                    icon: Icons.delete_outline_rounded,
                    color: _kDanger,
                    tooltip: 'Delete Mother',
                    onTap: onDelete),
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─── Add Mother FAB ───────────────────────────────────────────────────────────

class _AddMotherFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMotherFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
              spreadRadius: -2,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_rounded, color: Colors.white, size: 17),
            SizedBox(width: 8),
            Text('Add Mother',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1)),
          ],
        ),
      ),
    );
  }
}

// ─── Comprehensive Mother Detail Dialog ──────────────────────────────────────

class _ComprehensiveMotherDetailDialog extends StatefulWidget {
  final Map<String, dynamic> mother;
  final ApiService apiService;

  const _ComprehensiveMotherDetailDialog({
    required this.mother,
    required this.apiService,
  });

  @override
  State<_ComprehensiveMotherDetailDialog> createState() =>
      _ComprehensiveMotherDetailDialogState();
}

class _ComprehensiveMotherDetailDialogState
    extends State<_ComprehensiveMotherDetailDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 800,
        height: 600,
        child: Column(
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
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      (widget.mother['name'] as String)
                          .split(' ')
                          .map((n) => n.isNotEmpty ? n[0] : '')
                          .take(2)
                          .join(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.mother['name'],
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text(
                            '${widget.mother['riskLevel']} Risk • Week ${widget.mother['pregnancyWeek']} • Age ${widget.mother['age']}',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9))),
                        Text('CHW: ${widget.mother['chwAssigned']}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _buildMotherDetails(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotherDetails() {
    // Normalize risk level for display
    String displayRiskLevel = widget.mother['riskLevel'];
    if (displayRiskLevel.toLowerCase() == 'mid') {
      displayRiskLevel = 'Medium';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Card
          _InfoCard(
            title: 'Personal Information',
            icon: Icons.person_outline,
            children: [
              _InfoRow('Full Name', widget.mother['name']),
              _InfoRow('Age', '${widget.mother['age']} years'),
              _InfoRow('Phone', widget.mother['phone']),
              _InfoRow(
                  'Pregnancy Number', '#${widget.mother['pregnancyNumber']}'),
            ],
          ),

          const SizedBox(height: 16),

          // Pregnancy Information Card
          _InfoCard(
            title: 'Pregnancy Information',
            icon: Icons.pregnant_woman,
            children: [
              _InfoRow(
                  'Current Week', 'Week ${widget.mother['pregnancyWeek']}'),
              _InfoRow('Risk Level', displayRiskLevel,
                  valueColor: _getRiskColor(displayRiskLevel)),
              _InfoRow('Due Date',
                  DateFormat('dd MMM yyyy').format(widget.mother['dueDate'])),
              _InfoRow('Days Until Due',
                  '${widget.mother['dueDate'].difference(DateTime.now()).inDays} days'),
            ],
          ),

          const SizedBox(height: 16),

          // Care Team & Location Card
          _InfoCard(
            title: 'Care Team & Location',
            icon: Icons.medical_services_outlined,
            children: [
              _InfoRow('Assigned CHW', widget.mother['chwAssigned']),
              _InfoRow('Health Center', widget.mother['healthCenter']),
              _InfoRow('District', widget.mother['district']),
              _InfoRow('Last Visit',
                  DateFormat('dd MMM yyyy').format(widget.mother['lastVisit'])),
            ],
          ),

          const SizedBox(height: 16),

          // Appointment Status Card
          _InfoCard(
            title: 'Appointment Status',
            icon: Icons.schedule,
            children: [
              _InfoRow('Has Appointment',
                  widget.mother['hasAppointment'] ? 'Yes' : 'No',
                  valueColor:
                      widget.mother['hasAppointment'] ? _kPrimary : _kTextMid),
              if (widget.mother['nextAppointment'] != null)
                _InfoRow(
                    'Next Appointment',
                    DateFormat('dd MMM yyyy')
                        .format(widget.mother['nextAppointment'])),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return _kDanger;
      case 'medium':
      case 'mid':
        return _kWarning;
      case 'low':
        return _kPrimary;
      default:
        return _kTextMid;
    }
  }
}

class _DetailChip extends StatelessWidget {
  final String label, value;
  const _DetailChip(this.label, this.value);

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

// ─── Edit Mother Dialog ───────────────────────────────────────────────────────

class _EditMotherDialog extends StatefulWidget {
  final Map<String, dynamic> mother;
  final List<Map<String, dynamic>> chws;
  final Function(Map<String, dynamic>) onSave;

  const _EditMotherDialog({
    required this.mother,
    required this.chws,
    required this.onSave,
  });

  @override
  State<_EditMotherDialog> createState() => _EditMotherDialogState();
}

class _EditMotherDialogState extends State<_EditMotherDialog> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  String _selectedRisk = 'Low';
  String? _selectedChwId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.mother['name']);
    _ageController =
        TextEditingController(text: widget.mother['age'].toString());
    _phoneController = TextEditingController(text: widget.mother['phone']);

    // Normalize risk level - convert "Mid" to "Medium"
    String riskLevel = widget.mother['riskLevel']?.toString() ?? 'Low';
    if (riskLevel.toLowerCase() == 'mid') {
      riskLevel = 'Medium';
    }
    // Ensure the risk level is one of our valid options
    if (!['Low', 'Medium', 'High'].contains(riskLevel)) {
      riskLevel = 'Low';
    }
    _selectedRisk = riskLevel;

    // Find CHW ID - try multiple possible sources
    final chwName = widget.mother['chwAssigned'];
    if (chwName != null && chwName != 'Unassigned') {
      final chw = widget.chws.firstWhere(
        (c) => c['name']?.toString() == chwName.toString(),
        orElse: () => {},
      );
      if (chw.isNotEmpty) {
        _selectedChwId = chw['id']?.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Edit Mother',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _kTextMid),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name field
            _buildTextField('Name', _nameController),
            const SizedBox(height: 16),

            // Age field
            _buildTextField('Age', _ageController, isNumber: true),
            const SizedBox(height: 16),

            // Phone field
            _buildTextField('Phone', _phoneController),
            const SizedBox(height: 16),

            // Risk level dropdown
            const Text('Risk Level',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: _kBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRisk,
                  items: ['Low', 'Medium', 'High']
                      .map((risk) =>
                          DropdownMenuItem(value: risk, child: Text(risk)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedRisk = value!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // CHW dropdown
            const Text('Assigned CHW',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: _kBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedChwId,
                  hint: const Text('Select CHW'),
                  items: widget.chws
                      .map((chw) => DropdownMenuItem(
                          value: chw['id'].toString(),
                          child: Text(chw['name'] ?? 'Unknown')))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedChwId = value),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: _kBorder)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: _kTextMid, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: _saveChanges,
                    style: TextButton.styleFrom(
                      backgroundColor: _kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Save Changes',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _kTextDark)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kPrimary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _saveChanges() {
    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name is required'), backgroundColor: _kDanger),
      );
      return;
    }

    final age = int.tryParse(_ageController.text);
    if (age == null || age < 1 || age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid age'),
            backgroundColor: _kDanger),
      );
      return;
    }

    final updatedData = <String, dynamic>{
      'name': _nameController.text.trim(),
      'age': age,
      'phone': _phoneController.text.trim(),
    };

    // Only include risk level if it's different
    if (_selectedRisk != widget.mother['riskLevel']) {
      // Convert back to API format if needed
      String apiRiskLevel = _selectedRisk;
      if (_selectedRisk == 'Medium') {
        apiRiskLevel = 'medium'; // API might expect lowercase
      } else {
        apiRiskLevel = _selectedRisk.toLowerCase();
      }
      updatedData['current_risk_level'] = apiRiskLevel;
    }

    // Only include CHW if selected and different
    if (_selectedChwId != null && _selectedChwId!.isNotEmpty) {
      updatedData['created_by_chw_id'] =
          int.tryParse(_selectedChwId!) ?? _selectedChwId;
    }

    print('Saving mother data: $updatedData'); // Debug log
    widget.onSave(updatedData);
    Navigator.pop(context);
  }
}
// ─── Add Mother Dialog ────────────────────────────────────────────────────────

class _AddMotherDialog extends StatefulWidget {
  final List<Map<String, dynamic>> chws;
  final Function(Map<String, dynamic>) onSave;

  const _AddMotherDialog({
    required this.chws,
    required this.onSave,
  });

  @override
  State<_AddMotherDialog> createState() => _AddMotherDialogState();
}

class _AddMotherDialogState extends State<_AddMotherDialog> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedChwId;
  DateTime? _selectedDueDate;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Add New Mother',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kTextDark)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: _kTextMid),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Two column layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      children: [
                        _buildTextField('Full Name *', _nameController),
                        const SizedBox(height: 16),
                        _buildTextField('Age *', _ageController,
                            isNumber: true),
                        const SizedBox(height: 16),
                        _buildTextField('Phone Number *', _phoneController),
                        const SizedBox(height: 16),
                        _buildTextField('Email', _emailController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Right column
                  Expanded(
                    child: Column(
                      children: [
                        _buildTextField(
                            'Location/Address', _locationController),
                        const SizedBox(height: 16),

                        // Due Date picker
                        const Text('Expected Due Date',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kTextDark)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectDueDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: _kBorder),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: _kTextMid, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDueDate != null
                                      ? DateFormat('dd MMM yyyy')
                                          .format(_selectedDueDate!)
                                      : 'Select due date',
                                  style: TextStyle(
                                    color: _selectedDueDate != null
                                        ? _kTextDark
                                        : _kTextMid,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // CHW assignment (full width)
              const Text('Assign to CHW *',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kTextDark)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: _kBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedChwId,
                    hint: const Text('Select CHW to assign this mother'),
                    isExpanded: true,
                    items: widget.chws
                        .map((chw) => DropdownMenuItem(
                            value: chw['id'].toString(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(chw['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    '${chw['facility'] ?? 'Unknown Facility'} • ${chw['district'] ?? 'Unknown District'}',
                                    style: const TextStyle(
                                        fontSize: 11, color: _kTextMid)),
                              ],
                            )))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedChwId = value),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: _kBorder)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              color: _kTextMid, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: _saveNewMother,
                      style: TextButton.styleFrom(
                        backgroundColor: _kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Add Mother',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
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

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _kTextDark)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kPrimary),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().add(const Duration(days: 180)), // ~6 months from now
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _kPrimary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _saveNewMother() {
    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      _showError('Name is required');
      return;
    }

    final age = int.tryParse(_ageController.text);
    if (age == null || age < 1 || age > 100) {
      _showError('Please enter a valid age');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showError('Phone number is required');
      return;
    }

    if (_selectedChwId == null) {
      _showError('Please assign this mother to a CHW');
      return;
    }

    final newMotherData = <String, dynamic>{
      'name': _nameController.text.trim(),
      'age': age,
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'location': _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      'created_by_chw_id': int.tryParse(_selectedChwId!) ?? _selectedChwId,
    };

    if (_selectedDueDate != null) {
      newMotherData['due_date'] = _selectedDueDate!.toIso8601String();
    }

    print('Creating mother with data: $newMotherData'); // Debug log
    widget.onSave(newMotherData);
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _kDanger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ComprehensiveEditMotherDialog extends StatefulWidget {
  final Map<String, dynamic> mother;
  final ApiService apiService;
  final Function(Map<String, dynamic>) onSave;

  const _ComprehensiveEditMotherDialog({
    required this.mother,
    required this.apiService,
    required this.onSave,
  });

  @override
  State<_ComprehensiveEditMotherDialog> createState() =>
      _ComprehensiveEditMotherDialogState();
}

class _ComprehensiveEditMotherDialogState
    extends State<_ComprehensiveEditMotherDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _locationController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _emergencyPhoneController;
  String? _selectedRiskLevel;
  String? _selectedChw;
  List<Map<String, dynamic>> _chws = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeControllers();
    _loadChws();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.mother['name'] ?? '');
    _phoneController =
        TextEditingController(text: widget.mother['phone'] ?? '');
    _ageController =
        TextEditingController(text: widget.mother['age']?.toString() ?? '');
    _locationController =
        TextEditingController(text: widget.mother['location'] ?? '');
    _emergencyContactController =
        TextEditingController(text: widget.mother['emergency_contact'] ?? '');
    _emergencyPhoneController =
        TextEditingController(text: widget.mother['emergency_phone'] ?? '');

    // Normalize risk level - convert "Mid" to "Medium"
    String riskLevel = widget.mother['riskLevel']?.toString() ?? 'Low';
    if (riskLevel.toLowerCase() == 'mid') {
      riskLevel = 'Medium';
    }
    // Ensure the risk level is one of our valid options
    if (!['Low', 'Medium', 'High'].contains(riskLevel)) {
      riskLevel = 'Low';
    }
    _selectedRiskLevel = riskLevel;

    _selectedChw = widget.mother['chwAssigned'];
  }

  Future<void> _loadChws() async {
    try {
      final response = await widget.apiService.getCHWs();
      setState(() {
        _chws = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
    }
  }

  Future<void> _saveMother() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedData = <String, dynamic>{
        'name': _nameController.text,
        'phone': _phoneController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
        'location': _locationController.text,
        'emergency_contact': _emergencyContactController.text,
        'emergency_phone': _emergencyPhoneController.text,
      };

      if (_selectedRiskLevel != null &&
          _selectedRiskLevel != widget.mother['riskLevel']) {
        updatedData['current_risk_level'] = _selectedRiskLevel!.toLowerCase();
      }

      if (_selectedChw != null &&
          _selectedChw != widget.mother['chwAssigned']) {
        final chw = _chws.firstWhere(
          (c) => c['name'] == _selectedChw,
          orElse: () => {},
        );
        if (chw.isNotEmpty) {
          updatedData['created_by_chw_id'] = chw['id'];
        }
      }

      widget.onSave(updatedData);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating mother: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Edit Mother - ${widget.mother['name']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: _kPrimary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _kPrimary,
              tabs: const [
                Tab(text: 'Basic Info'),
                Tab(text: 'Health Records'),
                Tab(text: 'Referrals'),
                Tab(text: 'Visit History'),
              ],
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBasicInfoTab(),
                    _buildHealthRecordsTab(),
                    _buildReferralsTab(),
                    _buildVisitHistoryTab(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveMother,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Card
          _EditCard(
            title: 'Personal Information',
            icon: Icons.person_outline,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration:
                          _inputDecoration('Full Name', Icons.person_outline),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Name is required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration(
                          'Phone Number', Icons.phone_outlined),
                      validator: (value) =>
                          value?.isEmpty == true ? 'Phone is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: _inputDecoration('Age', Icons.cake_outlined),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Age is required';
                        if (int.tryParse(value!) == null) return 'Invalid age';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: _inputDecoration(
                          'Location', Icons.location_on_outlined),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Risk & Assignment Card
          _EditCard(
            title: 'Risk Level & Assignment',
            icon: Icons.medical_services_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedRiskLevel,
                      decoration: _inputDecoration(
                          'Risk Level', Icons.warning_outlined),
                      items: ['Low', 'Medium', 'High'].map((level) {
                        return DropdownMenuItem(
                            value: level, child: Text(level));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedRiskLevel = value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedChw,
                      decoration: _inputDecoration(
                          'Assigned CHW', Icons.person_pin_outlined),
                      items: _chws.map<DropdownMenuItem<String>>((chw) {
                        return DropdownMenuItem<String>(
                          value: chw['name'],
                          child: Text(chw['name']),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedChw = value),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Emergency Contacts Card
          _EditCard(
            title: 'Emergency Contacts',
            icon: Icons.emergency_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emergencyContactController,
                      decoration: _inputDecoration('Emergency Contact',
                          Icons.contact_emergency_outlined),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _emergencyPhoneController,
                      decoration: _inputDecoration(
                          'Emergency Phone', Icons.phone_in_talk_outlined),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRecordsTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(
          'Health Records (View Only)\n\nThis section will display health records when available.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildReferralsTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(
          'Referrals (View Only)\n\nThis section will display referrals when available.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildVisitHistoryTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(
          'Visit History (View Only)\n\nThis section will display visit history when available.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kTextMid, fontSize: 13),
      prefixIcon: Icon(icon, color: _kPrimary, size: 18),
      filled: true,
      fillColor: _kBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kPrimary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kDanger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kDanger, width: 1.6),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }
}

// ─── Info Card for View Dialog ────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: _kPrimary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: _kPrimary, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _kTextDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: _kBorder, height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ─── Info Row for View Dialog ─────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _kTextMid,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? _kTextDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Card for Edit Dialog ────────────────────────────────────────────────
class _EditCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _EditCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: _kPrimary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: _kPrimary, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _kTextDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: _kBorder, height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

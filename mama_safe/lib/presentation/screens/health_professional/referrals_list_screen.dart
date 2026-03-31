import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/responsive.dart';
import '../../../providers/language_provider.dart';
import '../../../services/api_service.dart';
import '../../../models/mother_model.dart';
import '../chw/chat_screen.dart';
import 'case_management_screen.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS  (matches mothers_list_screen)
// ─────────────────────────────────────────────
const _teal = Color(0xFF1A7A6E);
const _tealLight = Color(0xFFE8F5F3);
const _white = Color(0xFFFFFFFF);
const _bgPage = Color(0xFFEDF2F1);
const _neuBase = Color(0xFFEDF2F1);
const _darkText = Color(0xFF1E2D4E);
const _gray = Color(0xFF6B7280);
const _border = Color(0xFFE5E9E8);
const _inputFill = Color(0xFFF9FAFA);

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  List<dynamic> _allReferrals = [];
  List<dynamic> _filteredReferrals = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReferrals();
  }

  Future<void> _loadReferrals() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final data = await apiService.getIncomingReferrals();
      setState(() {
        _allReferrals = data;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    List<dynamic> result = _allReferrals;

    // Status filter
    if (_selectedFilter != 'All') {
      result = result.where((ref) {
        final status = ref['status']?.toString() ?? '';
        switch (_selectedFilter) {
          case 'Pending':
            return status == 'PENDING' || status == 'Pending';
          case 'Appointment':
            return status == 'APPOINTMENT_SCHEDULED' ||
                status == 'Appointment Scheduled';
          case 'Emergency':
            return status == 'EMERGENCY_CARE_REQUIRED' ||
                status == 'Emergency Care Required';
          case 'Completed':
            return status == 'COMPLETED' || status == 'Completed';
          default:
            return true;
        }
      }).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((ref) {
        final name = (ref['mother']?['name'] ?? '').toString().toLowerCase();
        final hospital = (ref['hospital'] ?? '').toString().toLowerCase();
        return name.contains(q) || hospital.contains(q);
      }).toList();
    }

    _filteredReferrals = result;
  }

  int _countByStatus(String filter) {
    if (filter == 'All') return _allReferrals.length;
    return _allReferrals.where((ref) {
      final status = ref['status']?.toString() ?? '';
      switch (filter) {
        case 'Pending':
          return status == 'PENDING' || status == 'Pending';
        case 'Appointment':
          return status == 'APPOINTMENT_SCHEDULED' ||
              status == 'Appointment Scheduled';
        case 'Emergency':
          return status == 'EMERGENCY_CARE_REQUIRED' ||
              status == 'Emergency Care Required';
        case 'Completed':
          return status == 'COMPLETED' || status == 'Completed';
        default:
          return false;
      }
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isEnglish = languageProvider.isEnglish;

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Teal header ──────────────────────────────────────
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEnglish ? 'Referrals' : 'Referrals',
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
                        ? 'Manage incoming patient referrals'
                        : 'Gucunga referrals',
                    style: TextStyle(
                      color: _white.withOpacity(0.80),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Search bar ───────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.padding(context),
              ),
              child: TextField(
                onChanged: (v) => setState(() {
                  _searchQuery = v;
                  _applyFilter();
                }),
                style: const TextStyle(color: _darkText, fontSize: 14),
                decoration: InputDecoration(
                  hintText: isEnglish
                      ? 'Search referrals...'
                      : 'Shakisha referrals...',
                  hintStyle: const TextStyle(color: _gray, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: _gray, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: _gray, size: 18),
                          onPressed: () => setState(() {
                            _searchQuery = '';
                            _applyFilter();
                          }),
                        )
                      : null,
                  filled: true,
                  fillColor: _inputFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _teal, width: 1.8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Filter chips (Wrap = responsive, no cut-off) ────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.padding(context),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'All',
                    count: _countByStatus('All'),
                    selected: _selectedFilter,
                    onTap: _onFilterTap,
                  ),
                  _FilterChip(
                    label: 'Pending',
                    count: _countByStatus('Pending'),
                    selected: _selectedFilter,
                    onTap: _onFilterTap,
                    dotColor: const Color(0xFFF59E0B),
                  ),
                  _FilterChip(
                    label: 'Appointment',
                    count: _countByStatus('Appointment'),
                    selected: _selectedFilter,
                    onTap: _onFilterTap,
                    dotColor: const Color(0xFF059669),
                  ),
                  _FilterChip(
                    label: 'Emergency',
                    count: _countByStatus('Emergency'),
                    selected: _selectedFilter,
                    onTap: _onFilterTap,
                    dotColor: const Color(0xFFDC2626),
                  ),
                  _FilterChip(
                    label: 'Completed',
                    count: _countByStatus('Completed'),
                    selected: _selectedFilter,
                    onTap: _onFilterTap,
                    dotColor: _teal,
                  ),
                ],
              ),
            ),

            // ── Divider + count ──────────────────────────────────
            const SizedBox(height: 10),
            const Divider(color: _border, height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.padding(context),
                10,
                Responsive.padding(context),
                4,
              ),
              child: Text(
                '${_filteredReferrals.length} referral${_filteredReferrals.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: _gray,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // ── List / Empty ─────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _teal))
                  : _filteredReferrals.isEmpty
                  ? _EmptyState(isEnglish: isEnglish)
                  : RefreshIndicator(
                      color: _teal,
                      onRefresh: _loadReferrals,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.padding(context),
                          vertical: 8,
                        ),
                        itemCount: _filteredReferrals.length,
                        itemBuilder: (context, index) {
                          return _ReferralCard(
                            referral: _filteredReferrals[index],
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CaseManagementScreen(
                                    referralId: _filteredReferrals[index]['id'],
                                    referralData: _filteredReferrals[index],
                                  ),
                                ),
                              );
                              if (result == true) _loadReferrals();
                            },
                            onChatTap: () =>
                                _openChat(_filteredReferrals[index]),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _onFilterTap(String value) {
    setState(() {
      _selectedFilter = value;
      _applyFilter();
    });
  }

  void _openChat(Map<String, dynamic> referral) {
    // Extract mother info from referral
    final motherData = referral['mother'];
    if (motherData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mother information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create MotherModel from referral data
    final mother = MotherModel(
      id: motherData['id'].toString(),
      fullName: motherData['name'] ?? 'Unknown',
      age: motherData['age'] ?? 0,
      phoneNumber: motherData['phone'] ?? '',
      address:
          '${motherData['village'] ?? ''}, ${motherData['cell'] ?? ''}, ${motherData['sector'] ?? ''}',
      emergencyContact: motherData['phone'] ?? '',
      assignedChwId: referral['chw']?['id']?.toString() ?? '',
      assignedChwName: referral['chw']?['name'] ?? 'CHW',
      riskLevel: motherData['risk_level'] ?? 'High',
      status: 'referred',
      dueDate: DateTime.now().add(const Duration(days: 280)),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatScreen(mother: mother, referralId: referral['id']),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FILTER CHIP  (matches mothers list exactly)
// ─────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final String selected;
  final void Function(String) onTap;
  final Color? dotColor;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == label;

    return GestureDetector(
      onTap: () => onTap(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _teal : _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _teal : _border, width: 1.3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null && !isSelected) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              '$label ($count)',
              style: TextStyle(
                color: isSelected ? _white : _darkText,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  REFERRAL CARD  (clean — matches MotherCard)
// ─────────────────────────────────────────────
class _ReferralCard extends StatelessWidget {
  final Map<String, dynamic> referral;
  final VoidCallback onTap;
  final VoidCallback onChatTap;

  const _ReferralCard({
    required this.referral,
    required this.onTap,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    final mother = referral['mother'];
    final chw = referral['chw'];
    final status = referral['status'] ?? 'PENDING';
    final severity = referral['severity'] ?? 'Unknown';
    final riskLevel = mother?['risk_level'] ?? 'Unknown';
    final createdAt = referral['created_at'] != null
        ? DateTime.parse(referral['created_at'])
        : null;

    // Initials from mother name — same as MotherCard
    final name = (mother?['name'] ?? 'U').toString();
    final initials = name
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: teal-light avatar + name + badges ────
              Row(
                children: [
                  // ✅ Teal-light initials avatar — like DD / KK / GG
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _neuBase,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        const BoxShadow(
                          color: Color(0xFFFFFFFF),
                          blurRadius: 6,
                          offset: Offset(-3, -3),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 6,
                          offset: const Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: _teal,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Unknown Patient',
                          style: const TextStyle(
                            color: _darkText,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 12,
                              color: _gray,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Age: ${mother?['age'] ?? 'N/A'}',
                              style: const TextStyle(
                                color: _gray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Risk + Status stacked badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _RiskBadge(risk: riskLevel),
                      const SizedBox(height: 5),
                      _StatusBadge(status: status),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Info chips row ───────────────────────────────
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.emergency_rounded,
                    label: severity,
                    color: _getSeverityColor(severity),
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.access_time_rounded,
                    label: createdAt != null ? _formatTime(createdAt) : 'N/A',
                    color: _teal,
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: _border, height: 1),
              const SizedBox(height: 10),

              // ── CHW row + chat button + chevron ────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _neuBase,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        const BoxShadow(
                          color: Color(0xFFFFFFFF),
                          blurRadius: 4,
                          offset: Offset(-2, -2),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      size: 13,
                      color: _teal,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'CHW: ${chw?['name'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 12, color: _gray),
                    ),
                  ),
                  // Chat button
                  GestureDetector(
                    onTap: onChatTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _teal.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 14,
                            color: _teal,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Chat',
                            style: TextStyle(
                              fontSize: 11,
                              color: _teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onTap,
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: _gray,
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

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626);
      case 'moderate':
        return const Color(0xFFF59E0B);
      case 'lower':
        return _teal;
      default:
        return _gray;
    }
  }

  String _formatTime(DateTime dateTime) {
    // Convert UTC to local time
    final localTime = dateTime.toLocal();
    final hour = localTime.hour;
    final minute = localTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ─────────────────────────────────────────────
//  INFO CHIP  (pill style — same as mothers)
// ─────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.20), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  RISK BADGE
// ─────────────────────────────────────────────
class _RiskBadge extends StatelessWidget {
  final String risk;
  const _RiskBadge({required this.risk});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (risk == 'High') {
      color = const Color(0xFFDC2626);
    } else if (risk == 'Mid' || risk == 'Medium') {
      color = const Color(0xFFF59E0B);
    } else {
      color = _teal;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(
        risk,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STATUS BADGE
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'PENDING':
      case 'Pending':
        color = const Color(0xFFF59E0B);
        label = 'Pending';
        break;
      case 'RECEIVED':
      case 'Received':
        color = _teal;
        label = 'Received';
        break;
      case 'EMERGENCY_CARE_REQUIRED':
      case 'Emergency Care Required':
        color = const Color(0xFFDC2626);
        label = 'Emergency';
        break;
      case 'APPOINTMENT_SCHEDULED':
      case 'Appointment Scheduled':
        color = const Color(0xFF059669);
        label = 'Scheduled';
        break;
      case 'COMPLETED':
      case 'Completed':
        color = const Color(0xFF059669);
        label = 'Completed';
        break;
      default:
        color = _gray;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.30), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isEnglish;
  const _EmptyState({required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _neuBase,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                const BoxShadow(
                  color: Color(0xFFFFFFFF),
                  blurRadius: 8,
                  offset: Offset(-4, -4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: const Icon(Icons.inbox_outlined, color: _teal, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            isEnglish ? 'No referrals found' : 'Nta referrals',
            style: const TextStyle(
              color: _darkText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isEnglish
                ? 'Incoming referrals will appear here'
                : 'Referrals izagaragara hano',
            style: const TextStyle(color: _gray, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

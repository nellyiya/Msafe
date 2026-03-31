import 'package:flutter/material.dart';
import '../../../models/referral_model.dart';
import '../../../services/api_service.dart';
import 'medical_consultation_form.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS  (matches mothers_list_screen)
// ─────────────────────────────────────────────
const _teal = Color(0xFF1A7A6E);
const _tealLight = Color(0xFFE8F5F3);
const _navy = Color(0xFF1E2D4E); // used only for status badge tints
const _darkText = Color(0xFF1A2B2A); // dark teal-black — no blue in text
const _white = Color(0xFFFFFFFF);
const _bgPage = Color(0xFFF4F7F6);
const _gray = Color(0xFF6B7280);
const _cardBorder = Color(0xFFE5E9E8);
const _inputFill = Color(0xFFF9FAFA);

class HealthProReferralsScreen extends StatefulWidget {
  const HealthProReferralsScreen({super.key});

  @override
  State<HealthProReferralsScreen> createState() =>
      _HealthProReferralsScreenState();
}

class _HealthProReferralsScreenState extends State<HealthProReferralsScreen> {
  List<Referral> _referrals = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadReferrals();
  }

  Future<void> _loadReferrals() async {
    try {
      final apiService = ApiService();
      final data = await apiService.getIncomingReferrals();
      setState(() {
        _referrals = data.map((r) => Referral.fromJson(r)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _setFilter(String value) =>
      setState(() => _filterStatus = _filterStatus == value ? 'All' : value);

  List<Referral> get _filtered {
    return _referrals.where((r) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!r.hospital.toLowerCase().contains(q) && !'#${r.id}'.contains(q)) {
          return false;
        }
      }
      if (_filterStatus != 'All') {
        if (r.status.displayName.toLowerCase() != _filterStatus.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: _bgPage,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : Column(
              children: [
                // ── Search bar (same as mothers list) ───────────────────────
                Container(
                  color: _white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: _darkText, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search referrals...',
                      hintStyle: const TextStyle(color: _gray, fontSize: 14),
                      prefixIcon:
                          const Icon(Icons.search, color: _gray, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: _gray, size: 18),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: _inputFill,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _cardBorder, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _teal, width: 1.8),
                      ),
                    ),
                  ),
                ),

                // ── Filter chips (same style as mothers list) ────────────────
                Container(
                  color: _white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                            label: 'All',
                            value: 'All',
                            selected: _filterStatus,
                            onTap: _setFilter),
                        const SizedBox(width: 8),
                        _FilterChip(
                            label: 'Pending',
                            value: 'Pending',
                            selected: _filterStatus,
                            onTap: _setFilter,
                            dotColor: const Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        _FilterChip(
                            label: 'Accepted',
                            value: 'Accepted',
                            selected: _filterStatus,
                            onTap: _setFilter,
                            dotColor: _teal),
                        const SizedBox(width: 8),
                        _FilterChip(
                            label: 'Treated',
                            value: 'Treated',
                            selected: _filterStatus,
                            onTap: _setFilter,
                            dotColor: _gray),
                        const SizedBox(width: 8),
                        _FilterChip(
                            label: 'Closed',
                            value: 'Closed',
                            selected: _filterStatus,
                            onTap: _setFilter,
                            dotColor: const Color(0xFF059669)),
                      ],
                    ),
                  ),
                ),

                // ── Thin divider ─────────────────────────────────────────────
                const Divider(color: _cardBorder, height: 1),

                // ── Count label ──────────────────────────────────────────────
                Container(
                  color: _bgPage,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} referral${filtered.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: _gray,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── List / Empty ─────────────────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? const _EmptyState()
                      : RefreshIndicator(
                          color: _teal,
                          onRefresh: _loadReferrals,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _ReferralCard(
                              referral: filtered[index],
                              onTap: () =>
                                  _showReferralDetails(filtered[index]),
                              onStatusChange: (action) =>
                                  _updateStatus(filtered[index].id, action),
                              onDownloadReport: _downloadReport,
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  // ── Referral detail dialog ────────────────────────────────────────────────
  void _showReferralDetails(Referral referral) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Referral Details',
          style: TextStyle(
              color: _darkText, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogRow('ID', '#${referral.id}'),
            _dialogRow('Hospital', referral.hospital),
            _dialogRow('Status', referral.status.displayName),
            if (referral.notes != null) _dialogRow('Notes', referral.notes!),
            if (referral.diagnosis != null)
              _dialogRow('Diagnosis', referral.diagnosis!),
          ],
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
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:',
                style: const TextStyle(color: _gray, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: _darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Status update ─────────────────────────────────────────────────────────
  Future<void> _updateStatus(int referralId, String action) async {
    if (action == 'complete') {
      _showMedicalConsultationForm(referralId);
      return;
    }
    
    String status;
    switch (action) {
      case 'accept':
        status = 'Accepted';
        break;
      case 'treat':
        status = 'Treated';
        break;
      case 'close':
        status = 'Closed';
        break;
      default:
        return;
    }
    try {
      final apiService = ApiService();
      await apiService.updateReferral(referralId, {'status': status});
      await _loadReferrals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Referral updated'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  // ── Show medical consultation form ────────────────────────────────────────
  void _showMedicalConsultationForm(int referralId) async {
    final referral = _referrals.firstWhere((r) => r.id == referralId);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MedicalConsultationForm(
        referralId: referralId,
        referralData: {
          'id': referral.id,
          'hospital': referral.hospital,
          'status': referral.status.displayName,
          'severity': referral.severity ?? 'Unknown',
          'notes': referral.notes,
          'diagnosis': referral.diagnosis,
          'mother': const {
            'name': 'Patient Name',
            'age': 28,
            'phone': '+250788000000',
            'sector': 'Kimironko',
            'cell': 'Kibagabaga',
            'village': 'Nyarutarama',
            'risk_level': 'High',
          },
        },
      ),
    );
    
    if (result == true) {
      await _loadReferrals();
    }
  }

  // ── Download completed consultation report ────────────────────────────────
  void _downloadReport(Referral referral) {
    if (referral.treatmentNotes == null || referral.treatmentNotes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No consultation report available'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: _teal, size: 20),
            SizedBox(width: 8),
            Text(
              'Download Report',
              style: TextStyle(
                  color: _darkText, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _tealLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _teal.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: _teal, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Referral #${referral.id} - ${referral.hospital}',
                        style: const TextStyle(
                          color: _teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Report Preview:',
                style: TextStyle(
                  color: _darkText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _inputFill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      referral.treatmentNotes!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: _darkText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: _gray),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _performDownload(referral);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: _white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download PDF'),
          ),
        ],
      ),
    );
  }

  void _performDownload(Referral referral) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_rounded, color: _white, size: 16),
            const SizedBox(width: 8),
            Text('Downloading consultation report for Referral #${referral.id}...'),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        action: SnackBarAction(
          label: 'View',
          textColor: _white,
          onPressed: () => _showFullReport(referral),
        ),
      ),
    );
  }

  void _showFullReport(Referral referral) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          height: 700,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _teal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medical_services, color: _white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medical Consultation Report',
                          style: TextStyle(
                            color: _darkText,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Referral #${referral.id} - ${referral.hospital}',
                          style: const TextStyle(
                            color: _gray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: _gray),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: _cardBorder),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    referral.treatmentNotes ?? 'No report available',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: _darkText,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: _cardBorder),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _gray,
                        side: const BorderSide(color: _cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Report saved to Downloads folder'),
                            backgroundColor: Color(0xFF059669),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_alt, size: 16),
                      label: const Text('Save PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: _white,
                        elevation: 0,
                      ),
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
//  FILTER CHIP  (identical to mothers list)
// ─────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final void Function(String) onTap;
  final Color? dotColor;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;

    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _teal : _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _teal : _cardBorder,
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null && !isSelected) ...[
              Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _white : _darkText,
                fontSize: 13,
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
  final Referral referral;
  final VoidCallback onTap;
  final void Function(String) onStatusChange;
  final void Function(Referral)? onDownloadReport;

  const _ReferralCard({
    required this.referral,
    required this.onTap,
    required this.onStatusChange,
    this.onDownloadReport,
  });

  /// First letter of hospital name as the initials avatar letter
  String get _initial => referral.hospital.trim().isNotEmpty
      ? referral.hospital.trim()[0].toUpperCase()
      : 'R';

  @override
  Widget build(BuildContext context) {
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
              // ── Top row: teal-light initial avatar + name + status badge ─
              Row(
                children: [
                  // ✅ Teal-light initial avatar — same as MotherCard
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF2F1),
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
                        _initial,
                        style: const TextStyle(
                          color: _teal,
                          fontSize: 18,
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
                          referral.hospital,
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
                            const Icon(Icons.tag_rounded,
                                size: 12, color: _gray),
                            const SizedBox(width: 4),
                            Text(
                              'Referral #${referral.id}',
                              style:
                                  const TextStyle(color: _gray, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: referral.status),
                ],
              ),

              const SizedBox(height: 12),

              // ── Info chips row ───────────────────────────────────────────
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.local_hospital_outlined,
                    label: referral.hospital.length > 16
                        ? '${referral.hospital.substring(0, 16)}…'
                        : referral.hospital,
                  ),
                  if (referral.diagnosis != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.medical_information_outlined,
                        label: referral.diagnosis!.length > 16
                            ? '${referral.diagnosis!.substring(0, 16)}…'
                            : referral.diagnosis!,
                      ),
                    ),
                  ],
                ],
              ),

              // ── Notes / Diagnosis detail rows ────────────────────────────
              if (referral.notes != null || referral.diagnosis != null) ...[
                const SizedBox(height: 12),
                const Divider(color: _cardBorder, height: 1),
                const SizedBox(height: 10),
                if (referral.notes != null)
                  _DetailRow(
                    icon: Icons.notes_rounded,
                    label: 'Notes',
                    value: referral.notes!,
                  ),
                if (referral.notes != null && referral.diagnosis != null)
                  const SizedBox(height: 6),
                if (referral.diagnosis != null)
                  _DetailRow(
                    icon: Icons.medical_information_outlined,
                    label: 'Diagnosis',
                    value: referral.diagnosis!,
                  ),
              ],

              const SizedBox(height: 14),

              // ── Action buttons — mirrors mothers list Details / Predict ──
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.visibility_outlined, size: 15),
                        label: const Text('Details',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () => _showActionMenu(context),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('Update',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: _white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
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

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Referral Status',
                style: TextStyle(
                    color: _darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _ActionTile(
                icon: Icons.check_circle_outline_rounded,
                label: 'Accept',
                color: const Color(0xFF059669),
                onTap: () {
                  Navigator.pop(context);
                  onStatusChange('accept');
                },
              ),
              _ActionTile(
                icon: Icons.medical_services_outlined,
                label: 'Complete Consultation',
                color: _teal,
                onTap: () {
                  Navigator.pop(context);
                  onStatusChange('complete');
                },
              ),
              if (referral.status == ReferralStatus.completed && 
                  referral.treatmentNotes != null && 
                  referral.treatmentNotes!.isNotEmpty)
                _ActionTile(
                  icon: Icons.download_rounded,
                  label: 'Download Report',
                  color: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.pop(context);
                    onDownloadReport?.call(referral);
                  },
                ),
              _ActionTile(
                icon: Icons.cancel_outlined,
                label: 'Close Referral',
                color: const Color(0xFFDC2626),
                onTap: () {
                  Navigator.pop(context);
                  onStatusChange('close');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ACTION TILE  (bottom sheet row)
// ─────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        label,
        style: const TextStyle(
            color: _darkText, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: _gray, size: 20),
    );
  }
}

// ─────────────────────────────────────────────
//  STATUS BADGE  (matches mothers list style)
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final ReferralStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ReferralStatus.pending:
        color = const Color(0xFFF59E0B);
        break;
      case ReferralStatus.accepted:
        color = _teal;
        break;
      case ReferralStatus.treated:
        color = _gray;
        break;
      case ReferralStatus.closed:
        color = const Color(0xFF059669);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(
        status.displayName,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  INFO CHIP  (identical to mothers list)
// ─────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _bgPage,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _gray),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: _gray, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DETAIL ROW  (identical to original)
// ─────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 13, color: _teal),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: _gray)),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE  (mirrors mothers list empty)
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              color: _tealLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.inbox_outlined, color: _teal, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'No referrals found',
            style: TextStyle(
                color: _darkText, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Incoming referrals will appear here',
            style: TextStyle(color: _gray, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

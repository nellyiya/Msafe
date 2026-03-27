import 'package:flutter/material.dart';
import '../../services/api_service.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF0D6B5E);
const _kPrimaryDark = Color(0xFF0A5549);
const _kDanger = Color(0xFFE74C3C);
const _kBg = Color(0xFFF0F4F3);
const _kSurface = Colors.white;
const _kTextDark = Color(0xFF1A2E2B);
const _kTextMid = Color(0xFF9CA3AF);
const _kTextLight = Color(0xFF8AADA8);
const _kBorder = Color(0xFFECF0F1);

class AdminCreateReferralDialog extends StatefulWidget {
  const AdminCreateReferralDialog({super.key});

  @override
  State<AdminCreateReferralDialog> createState() => _AdminCreateReferralDialogState();
}

class _AdminCreateReferralDialogState extends State<AdminCreateReferralDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isLoadingData = true;

  List<Map<String, dynamic>> _mothers = [];
  List<Map<String, dynamic>> _chws = [];
  List<Map<String, dynamic>> _healthcarePros = [];

  Map<String, dynamic>? _selectedMother;
  Map<String, dynamic>? _selectedCHW;
  String? _selectedFacility;
  String _selectedUrgency = 'Normal';

  final List<String> _facilities = [
    'King Faisal Hospital Rwanda',
    'Kibagabaga Level II Teaching Hospital',
    'Kacyiru District Hospital',
  ];

  final List<String> _urgencyLevels = ['Normal', 'Urgent', 'Emergency'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _apiService.getAllMothersAdmin(),
        _apiService.getCHWs(),
        _apiService.getHealthcarePros(),
      ]);

      setState(() {
        _mothers = List<Map<String, dynamic>>.from(results[0]);
        _chws = List<Map<String, dynamic>>.from(results[1]);
        _healthcarePros = List<Map<String, dynamic>>.from(results[2]);
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showSnack('Failed to load data: $e', error: true);
    }
  }

  Future<void> _createReferral() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMother == null) {
      _showSnack('Please select a mother', error: true);
      return;
    }
    if (_selectedFacility == null) {
      _showSnack('Please select a facility', error: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get healthcare professional for the selected facility
      final healthcarePro = _getHealthcareProForFacility(_selectedFacility!);
      
      await _apiService.createReferral({
        'mother_id': _selectedMother!['id'],
        'chw_id': _selectedCHW?['id'],
        'referred_to_facility': _selectedFacility,
        'referred_to_id': healthcarePro?['id'],
        'reason': _reasonController.text.trim(),
        'notes': _notesController.text.trim(),
        'urgency': _selectedUrgency.toLowerCase(),
        'status': _selectedUrgency == 'Emergency' ? 'emergency' : 'pending',
      });

      if (mounted) {
        Navigator.pop(context, true);
        _showSnack('Referral created successfully');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to create referral: $e', error: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _getHealthcareProForFacility(String facility) {
    // Map facilities to healthcare professionals
    switch (facility.toLowerCase()) {
      case 'king faisal hospital rwanda':
        return _healthcarePros.firstWhere(
          (hp) => hp['name']?.toString().toLowerCase().contains('aurore') == true ||
                  hp['facility']?.toString().toLowerCase().contains('king faisal') == true,
          orElse: () => _healthcarePros.isNotEmpty ? _healthcarePros.first : <String, dynamic>{},
        );
      case 'kibagabaga level ii teaching hospital':
        return _healthcarePros.firstWhere(
          (hp) => hp['name']?.toString().toLowerCase().contains('keza') == true ||
                  hp['facility']?.toString().toLowerCase().contains('kibagabaga') == true,
          orElse: () => _healthcarePros.isNotEmpty ? _healthcarePros.first : <String, dynamic>{},
        );
      case 'kacyiru district hospital':
        return _healthcarePros.firstWhere(
          (hp) => hp['name']?.toString().toLowerCase().contains('sonia') == true ||
                  hp['facility']?.toString().toLowerCase().contains('kacyiru') == true,
          orElse: () => _healthcarePros.isNotEmpty ? _healthcarePros.first : <String, dynamic>{},
        );
      default:
        return _healthcarePros.isNotEmpty ? _healthcarePros.first : null;
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? _kDanger : _kPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _urgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'emergency':
        return _kDanger;
      case 'urgent':
        return Colors.orange;
      default:
        return _kPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
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
                  const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create New Referral',
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
            if (_isLoadingData)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: _kPrimary),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mother Selection
                        const Text(
                          'Select Mother',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: _kBorder),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<Map<String, dynamic>>(
                            initialValue: _selectedMother,
                            decoration: const InputDecoration(
                              hintText: 'Choose a mother',
                              prefixIcon: Icon(Icons.person_outline, color: _kPrimary),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _mothers.map((mother) {
                              return DropdownMenuItem(
                                value: mother,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: _kPrimary.withOpacity(0.1),
                                      child: Text(
                                        (mother['name']?.toString().isNotEmpty == true
                                            ? mother['name'].toString()[0]
                                            : 'M').toUpperCase(),
                                        style: const TextStyle(
                                          color: _kPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mother['name'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (mother['risk_level'] != null)
                                            Text(
                                              'Risk: ${mother['risk_level']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: mother['risk_level'] == 'High' 
                                                  ? _kDanger 
                                                  : _kTextMid,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedMother = value),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // CHW Selection (Optional)
                        const Text(
                          'Assign CHW (Optional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: _kBorder),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<Map<String, dynamic>>(
                            initialValue: _selectedCHW,
                            decoration: const InputDecoration(
                              hintText: 'Choose a CHW (optional)',
                              prefixIcon: Icon(Icons.medical_services_outlined, color: _kPrimary),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _chws.map((chw) {
                              return DropdownMenuItem(
                                value: chw,
                                child: Text(chw['name'] ?? 'Unknown CHW'),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedCHW = value),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Facility Selection
                        const Text(
                          'Select Facility',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: _kBorder),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedFacility,
                            decoration: const InputDecoration(
                              hintText: 'Choose a facility',
                              prefixIcon: Icon(Icons.local_hospital_outlined, color: _kPrimary),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _facilities.map((facility) {
                              return DropdownMenuItem(
                                value: facility,
                                child: Text(facility),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedFacility = value),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Urgency Level
                        const Text(
                          'Urgency Level',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: _kBorder),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedUrgency,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.priority_high_rounded, color: _kPrimary),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: _urgencyLevels.map((urgency) {
                              return DropdownMenuItem(
                                value: urgency,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _urgencyColor(urgency),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(urgency),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedUrgency = value!),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Reason
                        const Text(
                          'Reason for Referral',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _reasonController,
                          decoration: InputDecoration(
                            hintText: 'Enter reason for referral',
                            prefixIcon: const Icon(Icons.edit_note_outlined, color: _kPrimary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _kBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _kPrimary, width: 2),
                            ),
                          ),
                          validator: (value) => 
                              (value?.isEmpty ?? true) ? 'Please enter reason' : null,
                        ),

                        const SizedBox(height: 20),

                        // Notes
                        const Text(
                          'Additional Notes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Enter any additional notes or observations...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _kBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _kPrimary, width: 2),
                            ),
                          ),
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
                      onPressed: _isLoading ? null : _createReferral,
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
                              'Create Referral',
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
}
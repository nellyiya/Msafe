import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';
import '../../../services/api_service.dart';
import 'prediction_history_screen.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
const _teal = Color(0xFF1A7A6E);
const _tealLight = Color(0xFFE8F5F3);
const _navy = Color(0xFF1E2D4E);
const _white = Color(0xFFFFFFFF);
const _bgPage = Color(0xFFEDF2F1);
const _neuBase = Color(0xFFEDF2F1);
const _gray = Color(0xFF6B7280);
const _cardBorder = Color(0xFFE5E9E8);
const _divider = Color(0xFFF0F3F2);

class MotherDetailScreen extends StatefulWidget {
  final String motherId;

  const MotherDetailScreen({super.key, required this.motherId});

  @override
  State<MotherDetailScreen> createState() => _MotherDetailScreenState();
}

class _MotherDetailScreenState extends State<MotherDetailScreen> {
  Map<String, dynamic>? _motherData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMotherData();
  }

  Future<void> _loadMotherData() async {
    try {
      final apiService = ApiService();
      final data = await apiService.getMother(int.parse(widget.motherId));
      setState(() {
        _motherData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ── AppBar factory ─────────────────────────────────────────────────────────
  AppBar _appBar(String title) => AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: _white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _teal,
        foregroundColor: _white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _white),
      );

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isEnglish = languageProvider.isEnglish;
    final appBarTitle = isEnglish ? 'Mother Details' : 'Amakuru ya Mama';

    // ── Loading ──────────────────────────────────────────────────────────────
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bgPage,
        appBar: _appBar(appBarTitle),
        body: const Center(
          child: CircularProgressIndicator(color: _teal),
        ),
      );
    }

    // ── Not found ────────────────────────────────────────────────────────────
    if (_motherData == null) {
      return Scaffold(
        backgroundColor: _bgPage,
        appBar: _appBar(appBarTitle),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _neuBase,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0xFFFFFFFF),
                      blurRadius: 5,
                      offset: Offset(-3, -3),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 5,
                      offset: const Offset(3, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_search_outlined,
                    color: _teal, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                isEnglish ? 'Mother not found' : 'Mama ntiyabonetse',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasReferrals = _motherData!['referrals'] != null &&
        (_motherData!['referrals'] as List).isNotEmpty;

    // ── Main screen ──────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: _appBar(appBarTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            _buildProfileHeader(isEnglish),
            const SizedBox(height: 16),

            // Risk banner
            _buildRiskBanner(isEnglish),
            const SizedBox(height: 24),

            // Personal info
            _SectionLabel(
                label: isEnglish ? 'Personal Information' : 'Amakuru bwite'),
            const SizedBox(height: 12),
            _InfoCard(
              rows: [
                _InfoRowData(
                    Icons.person_outline,
                    isEnglish ? 'Full Name' : 'Amazina',
                    _motherData!['name'] ?? ''),
                _InfoRowData(Icons.cake_outlined, isEnglish ? 'Age' : 'Imyaka',
                    '${_motherData!['age']} ${isEnglish ? 'years' : 'imyaka'}'),
                _InfoRowData(
                    Icons.phone_outlined,
                    isEnglish ? 'Phone' : 'Telephone',
                    _motherData!['phone'] ?? ''),
              ],
            ),
            const SizedBox(height: 20),

            // Location
            _SectionLabel(label: isEnglish ? 'Location Details' : 'Aho atuye'),
            const SizedBox(height: 12),
            _InfoCard(
              rows: [
                _InfoRowData(
                    Icons.location_city_outlined,
                    isEnglish ? 'Province' : 'Intara',
                    _motherData!['province'] ?? ''),
                _InfoRowData(
                    Icons.apartment_outlined,
                    isEnglish ? 'District' : 'Akarere',
                    _motherData!['district'] ?? ''),
                _InfoRowData(
                    Icons.location_on_outlined,
                    isEnglish ? 'Sector' : 'Umurenge',
                    _motherData!['sector'] ?? ''),
                _InfoRowData(Icons.map_outlined, isEnglish ? 'Cell' : 'Akagari',
                    _motherData!['cell'] ?? ''),
                _InfoRowData(
                    Icons.home_outlined,
                    isEnglish ? 'Village' : 'Umudugudu',
                    _motherData!['village'] ?? ''),
              ],
            ),
            const SizedBox(height: 20),

            // Pregnancy info
            _SectionLabel(
                label: isEnglish ? 'Pregnancy Information' : 'Amakuru y\'inda'),
            const SizedBox(height: 12),
            _buildPregnancyCard(isEnglish),

            // Referral
            if (hasReferrals) ...[
              const SizedBox(height: 20),
              _SectionLabel(
                  label: isEnglish
                      ? 'Referral & Appointment'
                      : 'Referral n\'Gahunda'),
              const SizedBox(height: 12),
              _buildReferralCard(isEnglish),
              if (_hasScheduledAppointment()) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAppointmentDetails(context, isEnglish),
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      isEnglish ? 'View Appointment Details' : 'Reba Gahunda',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: _white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Profile Header ─────────────────────────────────────────────────────────
  Widget _buildProfileHeader(bool isEnglish) {
    final initials = (_motherData!['name'] as String? ?? 'M')
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          const BoxShadow(
            color: Color(0xFFFFFFFF),
            blurRadius: 14,
            spreadRadius: 1,
            offset: Offset(-6, -6),
          ),
          BoxShadow(
            color: const Color(0xFF1A7A6E).withOpacity(0.25),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(6, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: _white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: _white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _motherData!['name'] ?? '',
                  style: const TextStyle(
                    color: _white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                _ProfileChip(
                  icon: Icons.cake_outlined,
                  label: isEnglish
                      ? 'Age: ${_motherData!['age']} yrs'
                      : 'Imyaka: ${_motherData!['age']}',
                ),
                const SizedBox(height: 4),
                _ProfileChip(
                  icon: Icons.phone_outlined,
                  label: _motherData!['phone'] ?? '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Risk Banner ────────────────────────────────────────────────────────────
  Widget _buildRiskBanner(bool isEnglish) {
    final riskLevel = _motherData!['current_risk_level'] ?? 'Not Predicted';

    Color riskColor;
    String riskLabel;
    IconData riskIcon;

    switch (riskLevel) {
      case 'High':
        riskColor = const Color(0xFFDC2626);
        riskLabel = isEnglish ? 'High Risk' : 'Ibibazo biri hejuru';
        riskIcon = Icons.warning_amber_rounded;
        break;
      case 'Medium':
        riskColor = const Color(0xFFD97706);
        riskLabel = isEnglish ? 'Medium Risk' : 'Ibibazo bisanzwe';
        riskIcon = Icons.info_outline;
        break;
      case 'Low':
        riskColor = _teal;
        riskLabel = isEnglish ? 'Low Risk' : 'Ibibazo bike';
        riskIcon = Icons.check_circle_outline;
        break;
      default:
        riskColor = _gray;
        riskLabel = isEnglish ? 'Not Predicted' : 'Ntibyavuzwe';
        riskIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: riskColor.withOpacity(0.25), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(riskIcon, color: riskColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnglish ? 'Current Risk Level' : 'Urwego rw\'ibibazo',
                  style: const TextStyle(color: _gray, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  riskLabel,
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: riskColor.withOpacity(0.3)),
            ),
            child: Text(
              riskLevel,
              style: TextStyle(
                color: riskColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Prediction Results Card ───────────────────────────────────────────────
  Widget _buildPredictionResultsCard(bool isEnglish) {
    final riskLevel = _motherData!['current_risk_level'] ?? 'Not Predicted';
    
    Color resultColor;
    IconData resultIcon;
    
    switch (riskLevel) {
      case 'High':
        resultColor = const Color(0xFFDC2626);
        resultIcon = Icons.warning_amber_rounded;
        break;
      case 'Medium':
        resultColor = const Color(0xFFD97706);
        resultIcon = Icons.info_outline;
        break;
      default:
        resultColor = _teal;
        resultIcon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(resultIcon, color: resultColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnglish ? 'Risk Level' : 'Urwego rw\'ibibazo',
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEnglish ? 'AI-powered assessment' : 'Isuzuma ry\'ibibazo',
                      style: const TextStyle(color: _gray, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: resultColor.withOpacity(0.3)),
                ),
                child: Text(
                  riskLevel,
                  style: TextStyle(
                    color: resultColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Prediction explanation note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: resultColor.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: resultColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEnglish 
                        ? 'This prediction was generated based on health parameters like blood pressure, blood sugar, heart rate, and other vital signs.'
                        : 'Ibi bitekerezo byakozwe ukurikije ibipimo by\'ubuzima nk\'umuvuduko w\'amaraso, shugar, n\'ibindi.',
                    style: TextStyle(
                      color: resultColor,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ── Next Visit Card ───────────────────────────────────────────────────────
  Widget _buildNextVisitCard(bool isEnglish) {
    final nextVisitDate = _motherData!['next_visit_date'];
    final hasNextVisit = nextVisitDate != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
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
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _neuBase,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0xFFFFFFFF),
                      blurRadius: 5,
                      offset: Offset(-3, -3),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 5,
                      offset: const Offset(3, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.calendar_today_outlined, color: _teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEnglish ? 'Next Visit' : 'Urugendo rukurikira',
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasNextVisit 
                          ? (isEnglish ? 'Visit scheduled' : 'Urugendo rwateganijwe')
                          : (isEnglish ? 'No visit scheduled' : 'Nta rugendo rwateganijwe'),
                      style: TextStyle(
                        color: hasNextVisit ? _teal : _gray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasNextVisit)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _teal.withOpacity(0.3)),
                  ),
                  child: Text(
                    isEnglish ? 'Scheduled' : 'Byateganijwe',
                    style: const TextStyle(
                      color: _teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          
          if (hasNextVisit) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _teal.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: _teal, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateTime.parse(nextVisitDate).toString().split(' ')[0],
                      style: const TextStyle(
                        color: _teal,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _scheduleNextVisit(context, isEnglish),
                  icon: Icon(
                    hasNextVisit ? Icons.edit_calendar : Icons.add_circle_outline,
                    size: 16,
                  ),
                  label: Text(
                    hasNextVisit 
                        ? (isEnglish ? 'Reschedule' : 'Hindura itariki')
                        : (isEnglish ? 'Schedule Visit' : 'Teganiza urugendo'),
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _teal,
                    side: const BorderSide(color: _teal),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (hasNextVisit) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelNextVisit(context, isEnglish),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: Text(
                      isEnglish ? 'Cancel' : 'Kuraguza',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _scheduleNextVisit(BuildContext context, bool isEnglish) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _neuBase,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0xFFFFFFFF),
                      blurRadius: 5,
                      offset: Offset(-3, -3),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 5,
                      offset: const Offset(3, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.calendar_today_outlined, color: _teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEnglish ? 'Schedule Next Visit' : 'Teganiza urugendo rukurikira',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEnglish 
                    ? 'Select date for next visit:'
                    : 'Hitamo itariki y\'urugendo rukurikira:',
                style: const TextStyle(color: _gray, fontSize: 14),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: _teal,
                              onPrimary: _white,
                              surface: _white,
                              onSurface: _navy,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (selectedDate != null) {
                      Navigator.of(context).pop();
                      
                      // Update local data and refresh
                      setState(() {
                        _motherData!['next_visit_date'] = selectedDate.toIso8601String();
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEnglish
                                ? 'Next visit scheduled for ${selectedDate.toString().split(' ')[0]}'
                                : 'Urugendo rwateganijwe kuri ${selectedDate.toString().split(' ')[0]}',
                          ),
                          backgroundColor: _teal,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    isEnglish ? 'Choose Date' : 'Hitamo itariki',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: _white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: _gray),
              child: Text(isEnglish ? 'Cancel' : 'Kuraguza'),
            ),
          ],
        );
      },
    );
  }

  void _cancelNextVisit(BuildContext context, bool isEnglish) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isEnglish ? 'Cancel Visit' : 'Kuraguza urugendo',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isEnglish 
              ? 'Are you sure you want to cancel the scheduled visit?'
              : 'Uzi neza ko ushaka kuraguza urugendo rwateganijwe?',
          style: const TextStyle(color: _gray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: _gray),
            child: Text(isEnglish ? 'Keep Visit' : 'Komeza urugendo'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _motherData!['next_visit_date'] = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEnglish ? 'Visit cancelled' : 'Urugendo rwarahagaritswe',
                  ),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: Text(isEnglish ? 'Cancel Visit' : 'Kuraguza'),
          ),
        ],
      ),
    );
  }

  Widget _buildPregnancyCard(bool isEnglish) {
    final dueDate = _motherData!['due_date'];
    final dueDateStr = dueDate != null
        ? DateTime.parse(dueDate).toString().split(' ')[0]
        : (isEnglish ? 'Not set' : 'Ntiyashyizweho');

    return _InfoCard(
      rows: [
        _InfoRowData(
          Icons.calendar_today_outlined,
          isEnglish ? 'Expected Due Date' : 'Itariki y\'kubyara',
          dueDateStr,
        ),
      ],
    );
  }

  // ── Referral Card ──────────────────────────────────────────────────────────
  Widget _buildReferralCard(bool isEnglish) {
    final referrals = _motherData!['referrals'] as List;
    final latestReferral = referrals.isNotEmpty ? referrals.last : null;
    if (latestReferral == null) return const SizedBox.shrink();

    final status = latestReferral['status'] ?? 'Pending';
    final hospital = latestReferral['hospital'] ?? 'N/A';
    final appointmentDate = latestReferral['appointment_date'];
    final appointmentTime = latestReferral['appointment_time'];
    final department = latestReferral['department'];

    // Status color
    Color statusColor;
    switch (status) {
      case 'Emergency Care Required':
        statusColor = const Color(0xFFDC2626);
        break;
      case 'Appointment Scheduled':
        statusColor = _teal;
        break;
      case 'Received':
        statusColor = const Color(0xFFD97706);
        break;
      default:
        statusColor = _gray;
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          _buildInfoRowWidget(Icons.local_hospital_outlined,
              isEnglish ? 'Hospital' : 'Ibitaro', hospital),
          const _Divider(),
          // Status with colored badge
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.info_outline, color: statusColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEnglish ? 'Status' : 'Uko bimeze',
                        style: const TextStyle(color: _gray, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: statusColor.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (appointmentDate != null) ...[
            const _Divider(),
            _buildInfoRowWidget(
              Icons.calendar_today_outlined,
              isEnglish ? 'Appointment Date' : 'Itariki y\'gahunda',
              DateTime.parse(appointmentDate).toString().split(' ')[0],
            ),
          ],
          if (appointmentTime != null) ...[
            const _Divider(),
            _buildInfoRowWidget(
              Icons.access_time_outlined,
              isEnglish ? 'Appointment Time' : 'Igihe cy\'gahunda',
              appointmentTime,
            ),
          ],
          if (department != null) ...[
            const _Divider(),
            _buildInfoRowWidget(
              Icons.medical_services_outlined,
              isEnglish ? 'Department' : 'Ishami',
              department,
            ),
          ],
        ],
      ),
    );
  }

  // ── Shared info row widget ─────────────────────────────────────────────────
  Widget _buildInfoRowWidget(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _neuBase,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                const BoxShadow(
                  color: Color(0xFFFFFFFF),
                  blurRadius: 5,
                  offset: Offset(-3, -3),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 5,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: Icon(icon, color: _teal, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _gray, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasScheduledAppointment() {
    if (_motherData == null || _motherData!['referrals'] == null) return false;
    final referrals = _motherData!['referrals'] as List;
    if (referrals.isEmpty) return false;
    final latestReferral = referrals.last;
    return latestReferral['status'] == 'Appointment Scheduled' &&
        latestReferral['appointment_date'] != null;
  }

  void _viewAllPredictions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PredictionHistoryScreen(
          motherId: widget.motherId,
          motherName: _motherData!['name'] ?? 'Unknown',
        ),
      ),
    );
  }

  void _showAppointmentDetails(BuildContext context, bool isEnglish) {
    final referrals = _motherData!['referrals'] as List;
    final latestReferral = referrals.last;
    final appointmentDate = latestReferral['appointment_date'];
    final appointmentTime = latestReferral['appointment_time'];
    final department = latestReferral['department'];
    final hospital = latestReferral['hospital'];
    final doctorName = latestReferral['healthcare_pro']?['name'] ?? 'Not assigned';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _neuBase,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0xFFFFFFFF),
                    blurRadius: 5,
                    offset: Offset(-3, -3),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 5,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.calendar_today_outlined, color: _teal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isEnglish ? 'Appointment Details' : 'Amakuru y\'Gahunda',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogInfoRow(
                icon: Icons.person_outline,
                label: isEnglish ? 'Patient' : 'Umurwayi',
                value: _motherData!['name'] ?? '',
              ),
              const SizedBox(height: 12),
              _DialogInfoRow(
                icon: Icons.local_hospital_outlined,
                label: isEnglish ? 'Hospital' : 'Ibitaro',
                value: hospital ?? 'N/A',
              ),
              const SizedBox(height: 12),
              _DialogInfoRow(
                icon: Icons.medical_services_outlined,
                label: isEnglish ? 'Department' : 'Ishami',
                value: department ?? 'N/A',
              ),
              const SizedBox(height: 12),
              _DialogInfoRow(
                icon: Icons.calendar_today_outlined,
                label: isEnglish ? 'Date' : 'Itariki',
                value: appointmentDate != null
                    ? DateTime.parse(appointmentDate).toString().split(' ')[0]
                    : 'N/A',
              ),
              const SizedBox(height: 12),
              _DialogInfoRow(
                icon: Icons.access_time_outlined,
                label: isEnglish ? 'Time' : 'Igihe',
                value: appointmentTime ?? 'N/A',
              ),
              const SizedBox(height: 12),
              _DialogInfoRow(
                icon: Icons.person_outlined,
                label: isEnglish ? 'Doctor' : 'Muganga',
                value: doctorName,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: _teal),
            child: Text(isEnglish ? 'Close' : 'Funga'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PROFILE CHIP  (small label in header)
// ─────────────────────────────────────────────
class _ProfileChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _navy,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  INFO ROW DATA MODEL
// ─────────────────────────────────────────────
class _InfoRowData {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRowData(this.icon, this.label, this.value);
}

// ─────────────────────────────────────────────
//  INFO CARD  (list of rows inside white card)
// ─────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final List<_InfoRowData> rows;

  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _InfoRowWidget(data: rows[i]),
            if (i < rows.length - 1) const _Divider(),
          ],
        ],
      ),
    );
  }
}

class _InfoRowWidget extends StatelessWidget {
  final _InfoRowData data;

  const _InfoRowWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _neuBase,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                const BoxShadow(
                  color: Color(0xFFFFFFFF),
                  blurRadius: 5,
                  offset: Offset(-3, -3),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 5,
                  offset: const Offset(3, 3),
                ),
              ],
            ),
            child: Icon(data.icon, color: _teal, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label,
                    style: const TextStyle(color: _gray, fontSize: 12)),
                const SizedBox(height: 2),
                Text(data.value,
                    style: const TextStyle(
                        color: _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  THIN DIVIDER
// ─────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(color: _divider, height: 1, thickness: 1);
}


// ─────────────────────────────────────────────
//  DIALOG INFO ROW
// ─────────────────────────────────────────────
class _DialogInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DialogInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _neuBase,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              const BoxShadow(
                color: Color(0xFFFFFFFF),
                blurRadius: 5,
                offset: Offset(-3, -3),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 5,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Icon(icon, color: _teal, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: _gray, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

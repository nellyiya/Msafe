import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';
import '../../../services/api_service.dart';
import 'run_prediction_screen.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
const _teal = Color(0xFF1A7A6E);
const _tealLight = Color(0xFFE8F5F3);
const _navy = Color(0xFF1E2D4E);
const _white = Color(0xFFFFFFFF);
const _bgPage = Color(0xFFF4F7F6);
const _gray = Color(0xFF6B7280);
const _cardBorder = Color(0xFFE5E9E8);
const _red = Color(0xFFDC2626);
const _amber = Color(0xFFD97706);

class PredictionHistoryScreen extends StatefulWidget {
  final String motherId;
  final String motherName;

  const PredictionHistoryScreen({
    super.key,
    required this.motherId,
    required this.motherName,
  });

  @override
  State<PredictionHistoryScreen> createState() => _PredictionHistoryScreenState();
}

class _PredictionHistoryScreenState extends State<PredictionHistoryScreen> {
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPredictionHistory();
  }

  Future<void> _loadPredictionHistory() async {
    try {
      final apiService = ApiService();
      
      // Get health records, mother data, and referrals
      final predictions = await apiService.getHealthRecords(int.parse(widget.motherId));
      final motherData = await apiService.getMother(int.parse(widget.motherId));
      
      setState(() {
        // Add mother's age and referral info to each prediction record
        _predictions = predictions.map<Map<String, dynamic>>((prediction) {
          final predictionMap = Map<String, dynamic>.from(prediction);
          predictionMap['age'] = motherData['age']; // Add age from mother data
          
          // Find referral for this health record if it exists
          final referrals = motherData['referrals'] as List<dynamic>? ?? [];
          final matchingReferral = referrals.where((ref) {
            // Match referral created around the same time as health record
            final refDate = DateTime.parse(ref['created_at']);
            final predDate = DateTime.parse(prediction['created_at']);
            final timeDiff = refDate.difference(predDate).inMinutes.abs();
            return timeDiff <= 30; // Within 30 minutes
          }).firstOrNull;
          
          if (matchingReferral != null) {
            predictionMap['hospital'] = matchingReferral['hospital'];
            predictionMap['referral_status'] = matchingReferral['status'];
          }
          
          return predictionMap;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addNewPrediction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunPredictionScreen(motherId: widget.motherId),
      ),
    );
    
    if (result == true) {
      // Refresh the prediction history
      _loadPredictionHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isEnglish = languageProvider.isEnglish;

    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        title: Text(
          isEnglish ? 'Prediction History' : 'Amateka y\'Ibitekerezo',
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPrediction,
        backgroundColor: _teal,
        foregroundColor: _white,
        child: const Icon(Icons.add, size: 28),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  _buildHeaderCard(isEnglish),
                  const SizedBox(height: 24),

                  // Predictions list
                  if (_predictions.isEmpty) ...[
                    _buildEmptyState(isEnglish),
                  ] else ...[
                    Text(
                      isEnglish 
                          ? 'All Predictions (${_predictions.length})'
                          : 'Ibitekerezo Byose (${_predictions.length})',
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._predictions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final prediction = entry.value;
                      final isLatest = index == 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPredictionCard(prediction, isLatest, isEnglish),
                      );
                    }),
                  ],

                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(bool isEnglish) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.timeline, color: _white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.motherName,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnglish 
                      ? 'Complete prediction history'
                      : 'Amateka yose y\'ibitekerezo',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isEnglish) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _tealLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.psychology_outlined, color: _teal, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            isEnglish ? 'No Predictions Yet' : 'Nta bitekerezo',
            style: const TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEnglish 
                ? 'Tap the + button to run the first prediction'
                : 'Kanda + kugira ngo ukore ibitekerezo bya mbere',
            style: const TextStyle(color: _gray, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _addNewPrediction,
            icon: const Icon(Icons.add, size: 20),
            label: Text(isEnglish ? 'Run First Prediction' : 'Kora Ibitekerezo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: _white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> prediction, bool isLatest, bool isEnglish) {
    final riskLevel = prediction['risk_level'] ?? 'Unknown';
    final createdAt = prediction['created_at'];
    final age = prediction['age'];
    final systolicBP = prediction['systolic_bp'];
    final diastolicBP = prediction['diastolic_bp'];
    final bloodSugar = prediction['blood_sugar'];
    final bodyTemp = prediction['body_temp'];
    final heartRate = prediction['heart_rate'];
    final hospital = prediction['hospital'];
    final referralStatus = prediction['referral_status'];

    Color riskColor;
    IconData riskIcon;

    switch (riskLevel) {
      case 'High':
        riskColor = _red;
        riskIcon = Icons.warning_amber_rounded;
        break;
      case 'Medium':
      case 'Mid':
        riskColor = _amber;
        riskIcon = Icons.info_outline;
        break;
      default:
        riskColor = _teal;
        riskIcon = Icons.check_circle_outline;
    }

    final dateStr = createdAt != null 
        ? DateTime.parse(createdAt).toString().split(' ')[0]
        : 'Unknown date';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest ? _teal : _cardBorder, 
          width: isLatest ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with risk level and date
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(riskIcon, color: riskColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: riskColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            riskLevel,
                            style: TextStyle(
                              color: riskColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isLatest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isEnglish ? 'LATEST' : 'BYA NYUMA',
                              style: const TextStyle(
                                color: _teal,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(color: _gray, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Referral info if exists
          if (hospital != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_hospital, color: _red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEnglish ? 'Referred to Hospital' : 'Yoherejwe mu bitaro',
                          style: const TextStyle(
                            color: _red,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          hospital,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (referralStatus != null)
                          Text(
                            'Status: $referralStatus',
                            style: const TextStyle(
                              color: _gray,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),

          // Health parameters
          Text(
            isEnglish ? 'Health Parameters' : 'Ibipimo by\'Ubuzima',
            style: const TextStyle(
              color: _navy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bgPage,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _cardBorder.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                _buildParameterRow(
                  Icons.cake_outlined, 
                  isEnglish ? 'Age' : 'Imyaka', 
                  '$age ${isEnglish ? 'years' : 'imyaka'}'
                ),
                const SizedBox(height: 8),
                _buildParameterRow(
                  Icons.favorite_border, 
                  isEnglish ? 'Blood Pressure' : 'Umuvuduko w\'amaraso', 
                  '$systolicBP/$diastolicBP mmHg'
                ),
                const SizedBox(height: 8),
                _buildParameterRow(
                  Icons.water_drop_outlined, 
                  isEnglish ? 'Blood Sugar' : 'Shugar', 
                  '$bloodSugar mmol/L'
                ),
                const SizedBox(height: 8),
                _buildParameterRow(
                  Icons.thermostat_outlined, 
                  isEnglish ? 'Temperature' : 'Igipfungo', 
                  '$bodyTemp°C'
                ),
                const SizedBox(height: 8),
                _buildParameterRow(
                  Icons.monitor_heart_outlined, 
                  isEnglish ? 'Heart Rate' : 'Igipimo cya mutima', 
                  '$heartRate bpm'
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: _teal, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _gray, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _navy,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
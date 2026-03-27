import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/mother_provider.dart';
import 'prediction_history_screen.dart';
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

class PredictionsOverviewScreen extends StatefulWidget {
  const PredictionsOverviewScreen({super.key});

  @override
  State<PredictionsOverviewScreen> createState() => _PredictionsOverviewScreenState();
}

class _PredictionsOverviewScreenState extends State<PredictionsOverviewScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MotherProvider>().loadMothers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final motherProvider = context.watch<MotherProvider>();
    final isEnglish = languageProvider.isEnglish;

    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        title: Text(
          isEnglish ? 'Predictions' : 'Ibitekerezo',
          style: const TextStyle(
            color: _white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _teal,
        foregroundColor: _white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: motherProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : Column(
              children: [
                // ── Search bar ─────────────────────────────────────────────────────
                Container(
                  color: _white,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: _navy, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: isEnglish ? 'Search mothers...' : 'Shakisha ababyeyi...',
                      hintStyle: const TextStyle(color: _gray, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: _gray, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: _gray, size: 18),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF9FAFA),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _cardBorder, width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _teal, width: 1.8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // ── Mothers list ────────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_filteredMothers(motherProvider.mothers).isEmpty) ...[
                          _buildEmptyState(isEnglish),
                        ] else ...[
                          Text(
                            isEnglish 
                                ? 'All Mothers (${_filteredMothers(motherProvider.mothers).length})'
                                : 'Ababyeyi Bose (${_filteredMothers(motherProvider.mothers).length})',
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._filteredMothers(motherProvider.mothers).map((mother) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildMotherCard(mother, isEnglish),
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<dynamic> _filteredMothers(List<dynamic> mothers) {
    if (_searchQuery.isEmpty) return mothers;
    
    final query = _searchQuery.toLowerCase();
    return mothers.where((mother) {
      return mother.fullName.toLowerCase().contains(query) ||
             mother.phoneNumber.contains(query);
    }).toList();
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
            child: const Icon(Icons.pregnant_woman_outlined, color: _teal, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            isEnglish ? 'No Mothers Registered' : 'Nta babyeyi biyandikishije',
            style: const TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEnglish 
                ? 'Register mothers first to start making predictions'
                : 'Andika ababyeyi mbere yo gutangira ibitekerezo',
            style: const TextStyle(color: _gray, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMotherCard(dynamic mother, bool isEnglish) {
    final riskLevel = mother.riskLevel ?? 'Not Predicted';
    final hasScheduledAppointment = mother.hasScheduledAppointment ?? false;

    Color riskColor;
    IconData riskIcon;
    String riskLabel;

    switch (riskLevel) {
      case 'High':
        riskColor = _red;
        riskIcon = Icons.warning_amber_rounded;
        riskLabel = isEnglish ? 'High Risk' : 'Ibibazo biri hejuru';
        break;
      case 'Medium':
      case 'Mid':
        riskColor = _amber;
        riskIcon = Icons.info_outline;
        riskLabel = isEnglish ? 'Medium Risk' : 'Ibibazo bisanzwe';
        break;
      case 'Low':
        riskColor = _teal;
        riskIcon = Icons.check_circle_outline;
        riskLabel = isEnglish ? 'Low Risk' : 'Ibibazo bike';
        break;
      default:
        riskColor = _gray;
        riskIcon = Icons.help_outline;
        riskLabel = isEnglish ? 'Not Predicted' : 'Ntibyavuzwe';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1.2),
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
          // Header with mother info
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _tealLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    mother.fullName.isNotEmpty ? mother.fullName[0].toUpperCase() : 'M',
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
                      mother.fullName,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isEnglish ? 'Age' : 'Imyaka'}: ${mother.age} • ${mother.phoneNumber}',
                      style: const TextStyle(color: _gray, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (hasScheduledAppointment)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, color: _teal, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        isEnglish ? 'Scheduled' : 'Gahunda',
                        style: const TextStyle(
                          color: _teal,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Risk level banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: riskColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(riskIcon, color: riskColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEnglish ? 'Current Risk Level' : 'Urwego rw\'ibibazo',
                        style: const TextStyle(color: _gray, fontSize: 11),
                      ),
                      Text(
                        riskLabel,
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewPredictionHistory(mother),
                  icon: const Icon(Icons.timeline, size: 16),
                  label: Text(
                    isEnglish ? 'View History' : 'Reba Amateka',
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
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _runNewPrediction(mother),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    isEnglish ? 'New Prediction' : 'Ibitekerezo Bishya',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: _white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _viewPredictionHistory(dynamic mother) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PredictionHistoryScreen(
          motherId: mother.id,
          motherName: mother.fullName,
        ),
      ),
    );
  }

  void _runNewPrediction(dynamic mother) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunPredictionScreen(motherId: mother.id),
      ),
    );
    
    if (result == true) {
      // Refresh the mothers list
      context.read<MotherProvider>().loadMothers();
    }
  }
}
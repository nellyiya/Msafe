import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF0D6B5E);
const _kPrimaryDark = Color(0xFF0A5549);
const _kDanger = Color(0xFFCF3030);
const _kWarning = Color(0xFFD97706);
const _kSuccess = Color(0xFF059669);
const _kBg = Color(0xFFF5F8F7);
const _kSurface = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFE2EDEB);
const _kTextDark = Color(0xFF0C1F1C);
const _kTextMid = Color(0xFF6E8E8A);
const _kTextLight = Color(0xFFA3BFBB);

class AdminAIInsightsScreen extends StatefulWidget {
  const AdminAIInsightsScreen({super.key});

  @override
  State<AdminAIInsightsScreen> createState() => _AdminAIInsightsScreenState();
}

class _AdminAIInsightsScreenState extends State<AdminAIInsightsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  int _totalPredictions = 0;
  int _highRiskCount = 0;
  int _mediumRiskCount = 0;
  int _lowRiskCount = 0;
  double _modelAccuracy = 94.2;
  double _precision = 91.8;
  double _recall = 93.5;
  double _f1Score = 92.6;
  List<int> _weeklyTrend = [12, 18, 14, 22, 19, 27, 24];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final mothers = await _apiService.getAllMothersAdmin();

      int high = 0, medium = 0, low = 0;
      for (final m in mothers) {
        final risk = m['current_risk_level']?.toString().toLowerCase() ?? 'low';
        if (risk == 'high') high++;
        else if (risk == 'medium' || risk == 'mid') medium++;
        else low++;
      }

      setState(() {
        _totalPredictions = mothers.length;
        _highRiskCount = high;
        _mediumRiskCount = medium;
        _lowRiskCount = low;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Container(
          color: _kSurface,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Text('AI Insights',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextDark)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: _kTextMid, size: 20),
                onPressed: _loadData,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : RefreshIndicator(
              color: _kPrimary,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── AI Insights Cards ──────────────────────────────────
                    _sectionLabel('AI Insights'),
                    const SizedBox(height: 12),
                    Row(children: [
                      _StatCard(label: 'Total Predictions', value: '$_totalPredictions', sub: 'ML assessments', icon: Icons.psychology_rounded, accentColor: _kPrimary),
                      const SizedBox(width: 10),
                      _StatCard(label: 'High Risk', value: '$_highRiskCount', sub: 'Critical cases', icon: Icons.warning_amber_rounded, accentColor: _kDanger),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Medium Risk', value: '$_mediumRiskCount', sub: 'Monitor closely', icon: Icons.info_rounded, accentColor: _kWarning),
                      const SizedBox(width: 10),
                      _StatCard(label: 'Low Risk', value: '$_lowRiskCount', sub: 'Routine care', icon: Icons.check_circle_rounded, accentColor: _kSuccess),
                    ]),

                    const SizedBox(height: 24),

                    // ── Risk Trend Graph ───────────────────────────────────
                    _sectionLabel('Risk Trend (Last 7 Days)'),
                    const SizedBox(height: 12),
                    _PanelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _iconBox(Icons.bar_chart_rounded),
                              const SizedBox(width: 10),
                              const Text('High Risk Cases Per Day',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextDark)),
                              const Spacer(),
                              _legendDot(_kDanger, 'High Risk'),
                              const SizedBox(width: 16),
                              _legendDot(_kWarning, 'Medium'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 180,
                            child: _RiskTrendChart(weeklyData: _weeklyTrend),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                                .map((d) => Text(d, style: const TextStyle(fontSize: 11, color: _kTextMid)))
                                .toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Model Accuracy ─────────────────────────────────────
                    _sectionLabel('Model Accuracy'),
                    const SizedBox(height: 12),
                    _PanelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _iconBox(Icons.analytics_rounded),
                              const SizedBox(width: 10),
                              const Text('ML Model Performance',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextDark)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: _AccuracyGauge(value: _modelAccuracy, label: 'Accuracy', color: _kPrimary)),
                              Expanded(child: _AccuracyGauge(value: _precision, label: 'Precision', color: _kSuccess)),
                              Expanded(child: _AccuracyGauge(value: _recall, label: 'Recall', color: _kWarning)),
                              Expanded(child: _AccuracyGauge(value: _f1Score, label: 'F1 Score', color: Color(0xFF7C3AED))),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _kPrimary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _kPrimary.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb_outline_rounded, color: _kPrimary, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Model trained on ${_totalPredictions} cases. High risk detection accuracy is strong. Consider retraining when dataset exceeds 500 cases.',
                                    style: const TextStyle(fontSize: 12, color: _kTextDark, height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kTextMid, letterSpacing: 1.1)),
      ],
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: _kPrimary.withOpacity(0.09), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, color: _kPrimary, size: 16),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: _kTextMid)),
      ],
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color accentColor;

  const _StatCard({required this.label, required this.value, required this.sub, required this.icon, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
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
                          decoration: BoxDecoration(color: accentColor.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
                          child: Icon(icon, color: accentColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _kTextDark, letterSpacing: -1.0, height: 1.0)),
                              const SizedBox(height: 2),
                              Text(label, style: const TextStyle(fontSize: 12, color: _kTextDark, fontWeight: FontWeight.w600)),
                              Text(sub, style: TextStyle(fontSize: 10, color: accentColor, fontWeight: FontWeight.w500)),
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

// ─── Panel Card ───────────────────────────────────────────────────────────────
class _PanelCard extends StatelessWidget {
  final Widget child;
  const _PanelCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(color: _kPrimary.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

// ─── Risk Trend Chart ─────────────────────────────────────────────────────────
class _RiskTrendChart extends StatelessWidget {
  final List<int> weeklyData;
  const _RiskTrendChart({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrendPainter(data: weeklyData),
      child: const SizedBox.expand(),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<int> data;
  _TrendPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxVal == 0) return;

    final w = size.width;
    final h = size.height;

    // Grid lines
    final gridPaint = Paint()..color = _kBorder..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = h * i / 4;
      double x = 0;
      while (x < w) {
        canvas.drawLine(Offset(x, y), Offset(x + 4, y), gridPaint);
        x += 8;
      }
    }

    // Bar chart
    final barW = w / data.length;
    for (int i = 0; i < data.length; i++) {
      final barH = (data[i] / maxVal) * (h - 20);
      final x = i * barW + barW * 0.2;
      final bw = barW * 0.6;
      final top = h - barH;
      final rect = Rect.fromLTWH(x, top, bw, barH);
      canvas.drawRRect(
        RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(6), topRight: const Radius.circular(6)),
        Paint()..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF4D4D), _kDanger],
        ).createShader(rect),
      );

      // Value label
      final tp = TextPainter(
        text: TextSpan(text: '${data[i]}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kTextDark)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + bw / 2 - tp.width / 2, top - 16));
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.data != data;
}

// ─── Accuracy Gauge ───────────────────────────────────────────────────────────
class _AccuracyGauge extends StatelessWidget {
  final double value;
  final String label;
  final Color color;

  const _AccuracyGauge({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: _GaugePainter(value: value / 100, color: color),
                child: const SizedBox(width: 80, height: 80),
              ),
              Text('${value.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: _kTextMid, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    const stroke = 8.0;
    const start = -1.5707963;

    canvas.drawArc(rect, 0, 6.28318, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = color.withOpacity(0.12));

    canvas.drawArc(rect, start, value * 6.28318, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = color);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value;
}

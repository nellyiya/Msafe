import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:mamasafe/presentation/theme/app_theme.dart';
import 'package:mamasafe/presentation/models/models.dart';
import 'package:mamasafe/presentation/widgets/shared_widgets.dart';

class AdminPredictionsScreen extends StatefulWidget {
  const AdminPredictionsScreen({super.key});

  @override
  State<AdminPredictionsScreen> createState() => _AdminPredictionsScreenState();
}

class _AdminPredictionsScreenState extends State<AdminPredictionsScreen> {
  String _search = '';
  RiskLevel? _filter;

  List<Prediction> get _filtered => MockData.predictions.where((p) {
        final matchSearch =
            p.motherName.toLowerCase().contains(_search.toLowerCase()) ||
                p.chwName.toLowerCase().contains(_search.toLowerCase());
        final matchRisk = _filter == null || p.riskLevel == _filter;
        return matchSearch && matchRisk;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Prediction Monitoring',
      subtitle: 'Machine learning risk assessments across all mothers',
      children: [
        // ── Stats ──
        _buildStats(),
        const SizedBox(height: 24),

        // ── Charts Row ──
        LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _PredictionTrendChart()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _ConfidenceDistributionChart()),
            ]);
          }
          return Column(children: [
            _PredictionTrendChart(),
            const SizedBox(height: 16),
            _ConfidenceDistributionChart(),
          ]);
        }),
        const SizedBox(height: 24),

        // ── Search & Filter ──
        Row(children: [
          Expanded(
            child: SearchField(
              hint: 'Search by mother name or CHW...',
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(width: 12),
          _RiskFilterRow(
            selected: _filter,
            onChanged: (r) => setState(() => _filter = r),
          ),
        ]),
        const SizedBox(height: 20),

        // ── Table ──
        ContentCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(children: [
                Text(
                  '${_filtered.length} predictions',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary),
                ),
                const Spacer(),
                PrimaryButton(
                    label: 'Export',
                    icon: Icons.download_rounded,
                    small: true),
              ]),
            ),
            const Divider(color: AppTheme.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(4),
              child: StyledDataTable(
                columns: const [
                  DataColumn(label: Text('MOTHER')),
                  DataColumn(label: Text('RISK LEVEL')),
                  DataColumn(label: Text('CONFIDENCE')),
                  DataColumn(label: Text('DATE & TIME')),
                  DataColumn(label: Text('CHW')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: _filtered
                    .map((p) => DataRow(cells: [
                          DataCell(Row(children: [
                            UserAvatar(
                              name: p.motherName,
                              size: 32,
                              color: _riskColor(p.riskLevel),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(p.motherName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text('ID: ${p.id}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textMuted)),
                              ],
                            ),
                          ])),
                          DataCell(RiskBadge(risk: p.riskLevel)),
                          DataCell(_ConfidenceBar(score: p.confidenceScore)),
                          DataCell(Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy').format(p.date),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                DateFormat('HH:mm').format(p.date),
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          )),
                          DataCell(Row(children: [
                            UserAvatar(name: p.chwName, size: 24),
                            const SizedBox(width: 8),
                            Text(p.chwName,
                                style: const TextStyle(fontSize: 12)),
                          ])),
                          DataCell(Row(children: [
                            _ActionBtn(
                                icon: Icons.visibility_rounded,
                                color: AppTheme.primary),
                            const SizedBox(width: 6),
                            _ActionBtn(
                                icon: Icons.track_changes_rounded,
                                color: AppTheme.accent),
                            if (p.riskLevel == RiskLevel.high) ...[
                              const SizedBox(width: 6),
                              _ActionBtn(
                                  icon: Icons.send_rounded,
                                  color: AppTheme.danger),
                            ],
                          ])),
                        ]))
                    .toList(),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 24),

        // ── High Risk Alert Panel ──
        _HighRiskAlertPanel(),
      ],
    );
  }

  Widget _buildStats() {
    final highCount =
        MockData.predictions.where((p) => p.riskLevel == RiskLevel.high).length;
    final avgConf = MockData.predictions.isEmpty
        ? 0.0
        : MockData.predictions.fold(0.0, (s, p) => s + p.confidenceScore) /
            MockData.predictions.length;
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 900
          ? 4
          : constraints.maxWidth > 600
              ? 2
              : 1;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          StatCard(
              label: 'Total Predictions',
              value: '${MockData.stats.totalPredictions}',
              icon: Icons.psychology_rounded,
              color: AppTheme.primary,
              subtitle: '+94 this week'),
          StatCard(
              label: 'High Risk Detected',
              value: '$highCount',
              icon: Icons.warning_amber_rounded,
              color: AppTheme.danger,
              highlight: true,
              subtitle: 'Requires action'),
          StatCard(
              label: 'Avg. Confidence Score',
              value: '${(avgConf * 100).toStringAsFixed(1)}%',
              icon: Icons.bar_chart_rounded,
              color: AppTheme.success,
              subtitle: 'Model accuracy'),
          StatCard(
              label: 'Predictions Today',
              value: '12',
              icon: Icons.today_rounded,
              color: AppTheme.info,
              subtitle: '3 high risk'),
        ],
      );
    });
  }

  Color _riskColor(RiskLevel r) => switch (r) {
        RiskLevel.low => AppTheme.riskLow,
        RiskLevel.medium => AppTheme.riskMedium,
        RiskLevel.high => AppTheme.riskHigh,
      };
}

// ─── Confidence Progress Bar ──────────────────────────────────────────────────

class _ConfidenceBar extends StatelessWidget {
  final double score;
  const _ConfidenceBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score > 0.85
        ? AppTheme.success
        : score > 0.7
            ? AppTheme.warning
            : AppTheme.danger;
    return SizedBox(
      width: 110,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${(score * 100).toInt()}%',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trend Chart ──────────────────────────────────────────────────────────────

class _PredictionTrendChart extends StatelessWidget {
  final List<int> monthly = const [
    45, 62, 58, 74, 81, 89, 76, 94, 102, 88, 97, 111
  ];
  final List<String> months = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
            title: 'Predictions Per Month',
            subtitle: 'Monthly volume of ML assessments'),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: LineChart(LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: AppTheme.border, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}',
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.textMuted)))),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) => Text(
                          months[v.toInt().clamp(0, 11)],
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.textMuted)))),
              topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: monthly
                    .asMap()
                    .entries
                    .map((e) =>
                        FlSpot(e.key.toDouble(), e.value.toDouble()))
                    .toList(),
                isCurved: true,
                color: AppTheme.primary,
                barWidth: 2.5,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.2),
                      AppTheme.primary.withOpacity(0)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            minX: 0,
            maxX: 11,
            minY: 0,
            maxY: 130,
          )),
        ),
      ]),
    );
  }
}

// ─── Confidence Distribution ──────────────────────────────────────────────────

class _ConfidenceDistributionChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
            title: 'Risk Distribution',
            subtitle: 'Breakdown of prediction outcomes'),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: PieChart(PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 45,
            sections: [
              PieChartSectionData(
                  value: 245,
                  color: AppTheme.riskLow,
                  title: 'Low\n245',
                  radius: 48,
                  titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              PieChartSectionData(
                  value: 67,
                  color: AppTheme.riskHigh,
                  title: 'High\n67',
                  radius: 54,
                  titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              PieChartSectionData(
                  value: 98,
                  color: AppTheme.riskMedium,
                  title: 'Med\n98',
                  radius: 48,
                  titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          )),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _LegendDot(color: AppTheme.riskLow, label: 'Low Risk', value: '245'),
          _LegendDot(
              color: AppTheme.riskMedium, label: 'Medium Risk', value: '98'),
          _LegendDot(
              color: AppTheme.riskHigh, label: 'High Risk', value: '67'),
        ]),
      ]),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendDot(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary)),
      Text(label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
    ]);
  }
}

// ─── High Risk Alert Panel ────────────────────────────────────────────────────

class _HighRiskAlertPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final highRisk = MockData.predictions
        .where((p) => p.riskLevel == RiskLevel.high)
        .toList();
    return ContentCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppTheme.danger, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('High Risk Cases',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            Text('Immediate attention required',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
          const Spacer(),
          PrimaryButton(
              label: 'Create Referrals for All',
              icon: Icons.send_rounded,
              small: true),
        ]),
        const SizedBox(height: 16),
        const Divider(color: AppTheme.border, height: 1),
        const SizedBox(height: 12),
        ...highRisk.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.danger.withOpacity(0.2)),
              ),
              child: Row(children: [
                UserAvatar(
                    name: p.motherName, size: 38, color: AppTheme.danger),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(p.motherName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      Text(
                          'CHW: ${p.chwName} • Confidence: ${(p.confidenceScore * 100).toInt()}%',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary)),
                    ])),
                Row(children: [
                  _ActionBtn(
                      icon: Icons.send_rounded, color: AppTheme.warning),
                  const SizedBox(width: 6),
                  _ActionBtn(
                      icon: Icons.visibility_rounded,
                      color: AppTheme.primary),
                ]),
              ]),
            )),
      ]),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _RiskFilterRow extends StatelessWidget {
  final RiskLevel? selected;
  final ValueChanged<RiskLevel?> onChanged;
  const _RiskFilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _Chip(
          label: 'All',
          selected: selected == null,
          color: AppTheme.primary,
          onTap: () => onChanged(null)),
      const SizedBox(width: 8),
      _Chip(
          label: 'High',
          selected: selected == RiskLevel.high,
          color: AppTheme.danger,
          onTap: () => onChanged(RiskLevel.high)),
      const SizedBox(width: 8),
      _Chip(
          label: 'Medium',
          selected: selected == RiskLevel.medium,
          color: AppTheme.warning,
          onTap: () => onChanged(RiskLevel.medium)),
      const SizedBox(width: 8),
      _Chip(
          label: 'Low',
          selected: selected == RiskLevel.low,
          color: AppTheme.success,
          onTap: () => onChanged(RiskLevel.low)),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : AppTheme.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : AppTheme.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _ActionBtn({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, size: 14, color: color),
    );
  }
}

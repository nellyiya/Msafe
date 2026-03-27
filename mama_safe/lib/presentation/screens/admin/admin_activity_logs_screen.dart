import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mamasafe/presentation/theme/app_theme.dart';
import 'package:mamasafe/presentation/models/models.dart';
import 'package:mamasafe/presentation/widgets/shared_widgets.dart';

class AdminActivityLogsScreen extends StatefulWidget {
  const AdminActivityLogsScreen({super.key});

  @override
  State<AdminActivityLogsScreen> createState() =>
      _AdminActivityLogsScreenState();
}

class _AdminActivityLogsScreenState extends State<AdminActivityLogsScreen> {
  String _search = '';
  String? _categoryFilter;

  final _categories = [
    'Prediction',
    'Referral',
    'User Management',
    'Mother',
    'Appointment',
    'Notification',
  ];

  List<ActivityLog> get _filtered => MockData.logs.where((l) {
        final matchSearch =
            l.user.toLowerCase().contains(_search.toLowerCase()) ||
                l.action.toLowerCase().contains(_search.toLowerCase()) ||
                l.category.toLowerCase().contains(_search.toLowerCase());
        final matchCat =
            _categoryFilter == null || l.category == _categoryFilter;
        return matchSearch && matchCat;
      }).toList();

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Activity Logs',
      subtitle: 'Complete audit trail of all system actions and events',
      headerAction: Row(children: [
        PrimaryButton(
            label: 'Export Logs',
            icon: Icons.download_rounded,
            small: true),
        const SizedBox(width: 10),
        PrimaryButton(
            label: 'Clear Old Logs',
            icon: Icons.delete_sweep_rounded,
            small: true),
      ]),
      children: [
        // ── Stats ──
        Row(children: [
          Expanded(child: StatCard(label: 'Total Events', value: '${MockData.logs.length * 47}', icon: Icons.history_rounded, color: AppTheme.primary, subtitle: 'All time')),
          const SizedBox(width: 16),
          Expanded(child: StatCard(label: 'Events Today', value: '23', icon: Icons.today_rounded, color: AppTheme.info, subtitle: 'Since midnight')),
          const SizedBox(width: 16),
          Expanded(child: StatCard(label: 'Unique Users', value: '12', icon: Icons.people_rounded, color: AppTheme.accent, subtitle: 'Active today')),
          const SizedBox(width: 16),
          Expanded(child: StatCard(label: 'Critical Events', value: '4', icon: Icons.warning_rounded, color: AppTheme.danger, highlight: true, subtitle: 'Needs review')),
        ]),
        const SizedBox(height: 24),

        // ── Filters ──
        Row(children: [
          Expanded(
            child: SearchField(
              hint: 'Search logs by user, action, or category...',
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(width: 12),
          PrimaryButton(
              label: 'Filter by Date',
              icon: Icons.calendar_today_rounded,
              small: true),
        ]),
        const SizedBox(height: 12),

        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _CategoryChip(
              label: 'All',
              selected: _categoryFilter == null,
              color: AppTheme.primary,
              onTap: () => setState(() => _categoryFilter = null),
            ),
            ..._categories.map((cat) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _CategoryChip(
                label: cat,
                selected: _categoryFilter == cat,
                color: _catColor(cat),
                onTap: () => setState(() =>
                    _categoryFilter = _categoryFilter == cat ? null : cat),
              ),
            )),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Log Timeline ──
        LayoutBuilder(builder: (ctx, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _LogList(logs: _filtered)),
              const SizedBox(width: 16),
              SizedBox(width: 260, child: _CategorySummary(logs: MockData.logs, categories: _categories)),
            ]);
          }
          return Column(children: [
            _LogList(logs: _filtered),
            const SizedBox(height: 16),
            _CategorySummary(logs: MockData.logs, categories: _categories),
          ]);
        }),
      ],
    );
  }

  Color _catColor(String cat) => switch (cat) {
        'Prediction' => AppTheme.primary,
        'Referral' => AppTheme.warning,
        'User Management' => AppTheme.info,
        'Mother' => AppTheme.accent,
        'Appointment' => AppTheme.success,
        'Notification' => AppTheme.danger,
        _ => AppTheme.textMuted,
      };
}

// ─── Log List ─────────────────────────────────────────────────────────────────

class _LogList extends StatelessWidget {
  final List<ActivityLog> logs;
  const _LogList({required this.logs});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(children: [
            Text('${logs.length} events',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const Spacer(),
            const Icon(Icons.sort_rounded, size: 16, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            const Text('Newest first',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ]),
        ),
        const Divider(color: AppTheme.border, height: 1),
        ...logs.asMap().entries.map((entry) =>
            _LogRow(log: entry.value, isLast: entry.key == logs.length - 1)),
      ]),
    );
  }
}

class _LogRow extends StatefulWidget {
  final ActivityLog log;
  final bool isLast;
  const _LogRow({required this.log, required this.isLast});

  @override
  State<_LogRow> createState() => _LogRowState();
}

class _LogRowState extends State<_LogRow> {
  bool _hovered = false;

  Color get _categoryColor => switch (widget.log.category) {
        'Prediction' => AppTheme.primary,
        'Referral' => AppTheme.warning,
        'User Management' => AppTheme.info,
        'Mother' => AppTheme.accent,
        'Appointment' => AppTheme.success,
        'Notification' => AppTheme.danger,
        _ => AppTheme.textMuted,
      };

  IconData get _categoryIcon => switch (widget.log.category) {
        'Prediction' => Icons.psychology_rounded,
        'Referral' => Icons.send_rounded,
        'User Management' => Icons.manage_accounts_rounded,
        'Mother' => Icons.pregnant_woman_rounded,
        'Appointment' => Icons.calendar_month_rounded,
        'Notification' => Icons.notifications_rounded,
        _ => Icons.info_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovered ? AppTheme.primary.withOpacity(0.03) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: widget.isLast
            ? null
            : const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppTheme.border, width: 1))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Timeline dot & line
          Column(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(_categoryIcon, size: 16, color: _categoryColor),
            ),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: widget.log.user,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      TextSpan(
                          text: '  ${widget.log.action}',
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary)),
                    ]),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: _categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(widget.log.category,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _categoryColor)),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time_rounded,
                    size: 11, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(widget.log.timestamp),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.person_outline_rounded,
                    size: 11, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(widget.log.id,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Category Summary ─────────────────────────────────────────────────────────

class _CategorySummary extends StatelessWidget {
  final List<ActivityLog> logs;
  final List<String> categories;
  const _CategorySummary({required this.logs, required this.categories});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
            title: 'Events by Category', subtitle: 'Distribution of log types'),
        const SizedBox(height: 16),
        ...categories.map((cat) {
          final count = logs.where((l) => l.category == cat).length;
          final total = logs.length;
          final pct = total == 0 ? 0.0 : count / total;
          final color = _catColor(cat);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cat,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      Text('$count events',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textMuted)),
                    ]),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppTheme.border,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }),
      ]),
    );
  }

  Color _catColor(String cat) => switch (cat) {
        'Prediction' => AppTheme.primary,
        'Referral' => AppTheme.warning,
        'User Management' => AppTheme.info,
        'Mother' => AppTheme.accent,
        'Appointment' => AppTheme.success,
        'Notification' => AppTheme.danger,
        _ => AppTheme.textMuted,
      };
}

// ─── Category Chip ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mamasafe/presentation/theme/app_theme.dart';
import 'package:mamasafe/presentation/widgets/shared_widgets.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  String _targetGroup = 'All CHWs';
  String _priority = 'Normal';

  final _groups = [
    'All CHWs',
    'All Healthcare Professionals',
    'High-Risk Mothers\' CHWs',
    'All Users',
    'Specific CHW',
    'Specific Healthcare Pro',
  ];

  final _priorities = ['Normal', 'Important', 'Emergency'];

  final _recentNotifs = const [
    _NotifData(title: 'Emergency Alert', message: 'High-risk pregnancy detected for Vestine N. — Immediate referral required.', type: 'Emergency', timeAgo: '2 hrs ago'),
    _NotifData(title: 'New Referral Assigned', message: 'Referral R002 has been assigned to Dr. Solange Akimana.', type: 'Referral', timeAgo: '6 hrs ago'),
    _NotifData(title: 'System Update', message: 'MamaSafe prediction model updated to version 2.1. Accuracy improved by 3.2%.', type: 'System', timeAgo: '1 day ago'),
    _NotifData(title: 'Appointment Reminder', message: '14 visits scheduled for today. Please ensure CHWs are notified.', type: 'Reminder', timeAgo: '1 day ago'),
    _NotifData(title: 'Weekly Report', message: 'Weekly system summary is ready. 94 predictions made, 12 referrals created.', type: 'Report', timeAgo: '3 days ago'),
    _NotifData(title: 'New CHW Registered', message: 'Josephine Niyomugabo has been added to Gikondo Health Center.', type: 'User', timeAgo: '4 days ago'),
  ];

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Notifications',
      subtitle: 'Send system notifications and alerts to staff and users',
      children: [
        // ── Stats ──
        Row(children: [
          Expanded(child: StatCard(label: 'Sent This Month', value: '47', icon: Icons.send_rounded, color: AppTheme.primary, subtitle: '+8 this week')),
          const SizedBox(width: 16),
          Expanded(child: StatCard(label: 'Emergency Alerts', value: '3', icon: Icons.emergency_rounded, color: AppTheme.danger, highlight: true, subtitle: 'This month')),
          const SizedBox(width: 16),
          Expanded(child: StatCard(label: 'Read Rate', value: '91%', icon: Icons.mark_email_read_rounded, color: AppTheme.success, subtitle: '+4% vs last month')),
          const SizedBox(width: 16),
          Expanded(child: StatCard(label: 'Pending Delivery', value: '2', icon: Icons.pending_rounded, color: AppTheme.warning, subtitle: 'In queue')),
        ]),
        const SizedBox(height: 24),

        LayoutBuilder(builder: (ctx, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _ComposeCard(
                targetGroup: _targetGroup,
                groups: _groups,
                priority: _priority,
                priorities: _priorities,
                onGroupChanged: (v) => setState(() => _targetGroup = v!),
                onPriorityChanged: (v) => setState(() => _priority = v),
              )),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _RecentNotificationsPanel(notifs: _recentNotifs)),
            ]);
          }
          return Column(children: [
            _ComposeCard(
              targetGroup: _targetGroup,
              groups: _groups,
              priority: _priority,
              priorities: _priorities,
              onGroupChanged: (v) => setState(() => _targetGroup = v!),
              onPriorityChanged: (v) => setState(() => _priority = v),
            ),
            const SizedBox(height: 16),
            _RecentNotificationsPanel(notifs: _recentNotifs),
          ]);
        }),
      ],
    );
  }
}

// ─── Compose Card ─────────────────────────────────────────────────────────────

class _ComposeCard extends StatelessWidget {
  final String targetGroup;
  final List<String> groups;
  final String priority;
  final List<String> priorities;
  final ValueChanged<String?> onGroupChanged;
  final ValueChanged<String> onPriorityChanged;

  const _ComposeCard({
    required this.targetGroup,
    required this.groups,
    required this.priority,
    required this.priorities,
    required this.onGroupChanged,
    required this.onPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(
          title: 'Compose Notification',
          subtitle: 'Send alerts and updates to system users',
        ),
        const SizedBox(height: 20),

        const _FieldLabel('Target Audience'),
        const SizedBox(height: 8),
        _DropdownField(
          value: targetGroup,
          items: groups,
          onChanged: onGroupChanged,
        ),
        const SizedBox(height: 16),

        const _FieldLabel('Notification Title'),
        const SizedBox(height: 8),
        const _TextField(hint: 'e.g. High-risk pregnancy alert for Area 4'),
        const SizedBox(height: 16),

        const _FieldLabel('Message Body'),
        const SizedBox(height: 8),
        const _TextField(
          hint: 'Type your detailed notification message here...',
          maxLines: 5,
        ),
        const SizedBox(height: 16),

        const _FieldLabel('Priority Level'),
        const SizedBox(height: 10),
        Row(children: priorities.map((p) {
          final (color, icon) = switch (p) {
            'Normal' => (AppTheme.info, Icons.notifications_rounded),
            'Important' => (AppTheme.warning, Icons.priority_high_rounded),
            _ => (AppTheme.danger, Icons.emergency_rounded),
          };
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onPriorityChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: priority == p ? color.withOpacity(0.12) : AppTheme.bgBase,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: priority == p ? color : AppTheme.border,
                    width: priority == p ? 1.5 : 1,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 15, color: priority == p ? color : AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text(p,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: priority == p ? color : AppTheme.textSecondary)),
                ]),
              ),
            ),
          );
        }).toList()),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send Notification',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Recent Notifications Panel ───────────────────────────────────────────────

class _RecentNotificationsPanel extends StatelessWidget {
  final List<_NotifData> notifs;
  const _RecentNotificationsPanel({required this.notifs});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SectionHeader(
              title: 'Recent Notifications',
              subtitle: 'Previously sent notifications'),
          const Spacer(),
          TextButton(
              onPressed: () {},
              child: const Text('View All',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary))),
        ]),
        const SizedBox(height: 12),
        ...notifs.map((n) => _NotifRow(notif: n)),
      ]),
    );
  }
}

class _NotifRow extends StatelessWidget {
  final _NotifData notif;
  const _NotifRow({required this.notif});

  Color get _typeColor => switch (notif.type) {
        'Emergency' => AppTheme.danger,
        'Referral' => AppTheme.warning,
        'System' => AppTheme.info,
        'Reminder' => AppTheme.success,
        'Report' => AppTheme.primary,
        'User' => AppTheme.accent,
        _ => AppTheme.textMuted,
      };

  IconData get _typeIcon => switch (notif.type) {
        'Emergency' => Icons.emergency_rounded,
        'Referral' => Icons.send_rounded,
        'System' => Icons.settings_rounded,
        'Reminder' => Icons.alarm_rounded,
        'Report' => Icons.bar_chart_rounded,
        'User' => Icons.person_add_rounded,
        _ => Icons.notifications_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border, width: 1))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(_typeIcon, size: 16, color: _typeColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(notif.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(notif.type,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _typeColor)),
              ),
            ]),
            const SizedBox(height: 3),
            Text(notif.message,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(notif.timeAgo,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textMuted)),
          ]),
        ),
      ]),
    );
  }
}

// ─── Data & Helpers ───────────────────────────────────────────────────────────

class _NotifData {
  final String title;
  final String message;
  final String type;
  final String timeAgo;
  const _NotifData(
      {required this.title,
      required this.message,
      required this.type,
      required this.timeAgo});
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary));
  }
}

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField(
      {required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: AppTheme.bgBase,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border)),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        items: items
            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final String hint;
  final int maxLines;
  const _TextField({required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppTheme.bgBase,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border)),
      child: TextFormField(
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}

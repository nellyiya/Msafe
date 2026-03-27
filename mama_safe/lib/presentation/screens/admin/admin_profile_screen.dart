import 'package:flutter/material.dart';
import 'package:mamasafe/presentation/theme/app_theme.dart';
import 'package:mamasafe/presentation/widgets/shared_widgets.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool _emailNotifs = true;
  bool _smsAlerts = true;
  bool _highRiskAlerts = true;
  bool _dailyReports = false;
  bool _weeklyDigest = true;
  bool _twoFactor = false;
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Profile & Settings',
      subtitle: 'Manage your admin account and system preferences',
      children: [
        // ── Two column layout ──
        LayoutBuilder(builder: (ctx, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _ProfileCard(editMode: _editMode, onToggleEdit: () => setState(() => _editMode = !_editMode))),
              const SizedBox(width: 16),
              Expanded(child: Column(children: [
                _NotificationSettings(
                  emailNotifs: _emailNotifs,
                  smsAlerts: _smsAlerts,
                  highRiskAlerts: _highRiskAlerts,
                  dailyReports: _dailyReports,
                  weeklyDigest: _weeklyDigest,
                  onEmailChanged: (v) => setState(() => _emailNotifs = v),
                  onSmsChanged: (v) => setState(() => _smsAlerts = v),
                  onHighRiskChanged: (v) => setState(() => _highRiskAlerts = v),
                  onDailyChanged: (v) => setState(() => _dailyReports = v),
                  onWeeklyChanged: (v) => setState(() => _weeklyDigest = v),
                ),
                const SizedBox(height: 16),
                _SystemPreferences(),
              ])),
            ]);
          }
          return Column(children: [
            _ProfileCard(editMode: _editMode, onToggleEdit: () => setState(() => _editMode = !_editMode)),
            const SizedBox(height: 16),
            _NotificationSettings(
              emailNotifs: _emailNotifs,
              smsAlerts: _smsAlerts,
              highRiskAlerts: _highRiskAlerts,
              dailyReports: _dailyReports,
              weeklyDigest: _weeklyDigest,
              onEmailChanged: (v) => setState(() => _emailNotifs = v),
              onSmsChanged: (v) => setState(() => _smsAlerts = v),
              onHighRiskChanged: (v) => setState(() => _highRiskAlerts = v),
              onDailyChanged: (v) => setState(() => _dailyReports = v),
              onWeeklyChanged: (v) => setState(() => _weeklyDigest = v),
            ),
            const SizedBox(height: 16),
            _SystemPreferences(),
          ]);
        }),
        const SizedBox(height: 16),

        // ── Security Section ──
        _SecurityCard(twoFactor: _twoFactor, onTwoFactorChanged: (v) => setState(() => _twoFactor = v)),
      ],
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final bool editMode;
  final VoidCallback onToggleEdit;
  const _ProfileCard({required this.editMode, required this.onToggleEdit});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SectionHeader(title: 'Admin Profile', subtitle: 'Your account information'),
          const Spacer(),
          GestureDetector(
            onTap: onToggleEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: editMode ? AppTheme.success.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: editMode ? AppTheme.success.withOpacity(0.3) : AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(editMode ? Icons.check_rounded : Icons.edit_rounded, size: 14, color: editMode ? AppTheme.success : AppTheme.primary),
                const SizedBox(width: 5),
                Text(editMode ? 'Save' : 'Edit Profile',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: editMode ? AppTheme.success : AppTheme.primary)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 20),

        // Avatar
        Center(
          child: Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Center(
                  child: Text('SA', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                ),
              ),
              if (editMode)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(child: Column(children: [
          const Text('System Administrator', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Super Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ),
        ])),
        const SizedBox(height: 24),
        const Divider(color: AppTheme.border),
        const SizedBox(height: 16),

        _ProfileField(icon: Icons.person_rounded, label: 'Full Name', value: 'System Administrator', editable: editMode),
        _ProfileField(icon: Icons.email_rounded, label: 'Email Address', value: 'admin@mamasafe.rw', editable: editMode),
        _ProfileField(icon: Icons.phone_rounded, label: 'Phone Number', value: '+250 788 000 000', editable: editMode),
        _ProfileField(icon: Icons.location_on_rounded, label: 'Location', value: 'Kigali, Rwanda', editable: editMode),
        _ProfileField(icon: Icons.business_rounded, label: 'Organization', value: 'MamaSafe Health Rwanda', editable: editMode),
        const _ProfileField(icon: Icons.access_time_rounded, label: 'Account Created', value: 'January 15, 2024', editable: false),
      ]),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool editable;
  const _ProfileField({required this.icon, required this.label, required this.value, required this.editable});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: AppTheme.bgBase, borderRadius: BorderRadius.circular(7)),
          child: Icon(icon, size: 14, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          editable
              ? SizedBox(
                  height: 32,
                  child: TextFormField(
                    initialValue: value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                )
              : Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ])),
      ]),
    );
  }
}

// ─── Notification Settings ────────────────────────────────────────────────────

class _NotificationSettings extends StatelessWidget {
  final bool emailNotifs;
  final bool smsAlerts;
  final bool highRiskAlerts;
  final bool dailyReports;
  final bool weeklyDigest;
  final ValueChanged<bool> onEmailChanged;
  final ValueChanged<bool> onSmsChanged;
  final ValueChanged<bool> onHighRiskChanged;
  final ValueChanged<bool> onDailyChanged;
  final ValueChanged<bool> onWeeklyChanged;

  const _NotificationSettings({
    required this.emailNotifs, required this.smsAlerts, required this.highRiskAlerts,
    required this.dailyReports, required this.weeklyDigest,
    required this.onEmailChanged, required this.onSmsChanged, required this.onHighRiskChanged,
    required this.onDailyChanged, required this.onWeeklyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: 'Notification Settings', subtitle: 'Configure alert preferences'),
        const SizedBox(height: 20),
        _Toggle(
          label: 'Email Notifications',
          subtitle: 'Receive system updates via email',
          icon: Icons.email_rounded,
          color: AppTheme.primary,
          value: emailNotifs,
          onChanged: onEmailChanged,
        ),
        _Toggle(
          label: 'SMS Alerts',
          subtitle: 'Critical emergency SMS notifications',
          icon: Icons.sms_rounded,
          color: AppTheme.info,
          value: smsAlerts,
          onChanged: onSmsChanged,
        ),
        _Toggle(
          label: 'High-Risk Pregnancy Alerts',
          subtitle: 'Instant alerts for high-risk detections',
          icon: Icons.warning_rounded,
          color: AppTheme.danger,
          value: highRiskAlerts,
          onChanged: onHighRiskChanged,
        ),
        _Toggle(
          label: 'Daily Summary Reports',
          subtitle: 'End-of-day system activity digest',
          icon: Icons.summarize_rounded,
          color: AppTheme.success,
          value: dailyReports,
          onChanged: onDailyChanged,
        ),
        _Toggle(
          label: 'Weekly Digest',
          subtitle: 'Weekly performance and trend report',
          icon: Icons.calendar_view_week_rounded,
          color: AppTheme.accent,
          value: weeklyDigest,
          onChanged: onWeeklyChanged,
          isLast: true,
        ),
      ]),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _Toggle({
    required this.label, required this.subtitle, required this.icon,
    required this.color, required this.value, required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: isLast
          ? null
          : const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border, width: 1))),
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value ? color.withOpacity(0.1) : AppTheme.bgBase,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: value ? color : AppTheme.textMuted),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ])),
        Switch(value: value, onChanged: onChanged, activeThumbColor: AppTheme.primary),
      ]),
    );
  }
}

// ─── System Preferences ───────────────────────────────────────────────────────

class _SystemPreferences extends StatefulWidget {
  @override
  State<_SystemPreferences> createState() => _SystemPreferencesState();
}

class _SystemPreferencesState extends State<_SystemPreferences> {
  String _language = 'English';
  String _timezone = 'Africa/Kigali (UTC+2)';
  String _dateFormat = 'DD/MM/YYYY';

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: 'System Preferences', subtitle: 'Locale and display settings'),
        const SizedBox(height: 20),
        _PrefRow(
          label: 'Language',
          icon: Icons.language_rounded,
          child: _SelectField(
            value: _language,
            items: const ['English', 'Kinyarwanda', 'French'],
            onChanged: (v) => setState(() => _language = v!),
          ),
        ),
        _PrefRow(
          label: 'Time Zone',
          icon: Icons.access_time_rounded,
          child: _SelectField(
            value: _timezone,
            items: const ['Africa/Kigali (UTC+2)', 'UTC', 'Europe/Paris (UTC+1)'],
            onChanged: (v) => setState(() => _timezone = v!),
          ),
        ),
        _PrefRow(
          label: 'Date Format',
          icon: Icons.calendar_today_rounded,
          isLast: true,
          child: _SelectField(
            value: _dateFormat,
            items: const ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
            onChanged: (v) => setState(() => _dateFormat = v!),
          ),
        ),
      ]),
    );
  }
}

class _PrefRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  final bool isLast;
  const _PrefRow({required this.label, required this.icon, required this.child, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: isLast
          ? null
          : const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: AppTheme.bgBase, borderRadius: BorderRadius.circular(7)),
          child: Icon(icon, size: 14, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
        SizedBox(width: 180, child: child),
      ]),
    );
  }
}

class _SelectField extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _SelectField({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgBase,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Security Card ────────────────────────────────────────────────────────────

class _SecurityCard extends StatelessWidget {
  final bool twoFactor;
  final ValueChanged<bool> onTwoFactorChanged;
  const _SecurityCard({required this.twoFactor, required this.onTwoFactorChanged});

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: 'Security', subtitle: 'Password and authentication settings'),
        const SizedBox(height: 20),

        // Change password
        _SecurityRow(
          icon: Icons.lock_rounded,
          color: AppTheme.primary,
          title: 'Change Password',
          subtitle: 'Last changed 30 days ago • Strong password',
          action: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.lock_reset_rounded, size: 14),
            label: const Text('Change', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Divider(color: AppTheme.border),
        const SizedBox(height: 14),

        // 2FA
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: twoFactor ? AppTheme.success.withOpacity(0.1) : AppTheme.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.security_rounded, size: 16, color: twoFactor ? AppTheme.success : AppTheme.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Two-Factor Authentication', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text(twoFactor ? 'Enabled — your account is more secure' : 'Not enabled — recommended for admin accounts',
                style: TextStyle(fontSize: 11, color: twoFactor ? AppTheme.success : AppTheme.textMuted)),
          ])),
          Switch(value: twoFactor, onChanged: onTwoFactorChanged, activeThumbColor: AppTheme.primary),
        ]),
        const SizedBox(height: 14),
        const Divider(color: AppTheme.border),
        const SizedBox(height: 14),

        // Active sessions
        _SecurityRow(
          icon: Icons.devices_rounded,
          color: AppTheme.info,
          title: 'Active Sessions',
          subtitle: '2 active sessions — this device + Chrome/Windows',
          action: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.logout_rounded, size: 14),
            label: const Text('Sign Out All', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.warning,
              side: const BorderSide(color: AppTheme.warning),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Divider(color: AppTheme.border),
        const SizedBox(height: 14),

        // Sign out
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.logout_rounded, size: 16, color: AppTheme.danger),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Sign Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.danger)),
            const Text('End your current admin session', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ])),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.logout_rounded, size: 14),
            label: const Text('Logout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
          ),
        ]),
      ]),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget action;
  const _SecurityRow({required this.icon, required this.color, required this.title, required this.subtitle, required this.action});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ])),
      action,
    ]);
  }
}

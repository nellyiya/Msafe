import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import 'auth/sign_in_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

const _teal = Color(0xFF1A7A6E);
const _tealLight = Color(0xFFE8F5F3);
const _navy = Color(0xFF1E2D4E);
const _white = Color(0xFFFFFFFF);
const _bgPage = Color(0xFFEDF2F1);
const _neuBase = Color(0xFFEDF2F1);
const _gray = Color(0xFF6B7280);
const _cardBorder = Color(0xFFE5E9E8);

/// Settings Screen – MamaSafe clean design
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isEnglish = languageProvider.isEnglish;
    final isDarkMode = themeProvider.isDarkMode;

    final userName = authProvider.currentUserName ?? 'User';
    final userEmail = authProvider.currentUserEmail ?? 'email@example.com';

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Header Card ─────────────────────────
              _ProfileHeader(
                userName: userName,
                userEmail: userEmail,
                roleLabel: authProvider.getRoleDisplayName(),
                profileImageBytes: authProvider.profileImageBytes,
                onPickImage: () async {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                    maxWidth: 400,
                  );
                  if (picked != null) {
                    final bytes = await picked.readAsBytes();
                    await authProvider.updateProfileImage(bytes);
                  }
                },
              ),
              const SizedBox(height: 28),

              // ── Account section ─────────────────────────────
              _SectionLabel(label: isEnglish ? 'Account' : 'Konti'),
              const SizedBox(height: 14),

              // ── Edit Profile tile ───────────────────────────
              _SettingsTile(
                icon: Icons.person_outline,
                iconBg: _teal,
                title: isEnglish ? 'Edit Profile' : 'Hindura Profayile',
                subtitle: isEnglish ? 'Update your personal information' : 'Hindura amakuru yawe',
                trailing: const Icon(Icons.arrow_forward_ios, color: _gray, size: 16),
                onTap: () => _editProfile(context, isEnglish),
              ),
              const SizedBox(height: 12),

              // ── Change Password tile ────────────────────────
              _SettingsTile(
                icon: Icons.lock_outline,
                iconBg: _teal,
                title: isEnglish ? 'Change Password' : 'Hindura Ijambo Banga',
                subtitle: isEnglish ? 'Update your account password' : 'Hindura ijambo banga ryawe',
                trailing: const Icon(Icons.arrow_forward_ios, color: _gray, size: 16),
                onTap: () => _changePassword(context, isEnglish),
              ),
              const SizedBox(height: 28),

              // ── Section label ───────────────────────────────
              _SectionLabel(label: isEnglish ? 'Settings' : 'Igenamiterere'),
              const SizedBox(height: 14),

              // ── Language tile ───────────────────────────────
              _SettingsTile(
                icon: Icons.language_outlined,
                iconBg: _teal,
                title: isEnglish ? 'Language' : 'Ururimi',
                subtitle:
                    languageProvider.isEnglish ? 'English' : 'Kinyarwanda',
                trailing: _StyledSwitch(
                  value: !languageProvider.isEnglish,
                  onChanged: (v) => v 
                      ? languageProvider.setKinyarwanda()
                      : languageProvider.setEnglish(),
                ),
              ),
              const SizedBox(height: 12),

              // ── Dark mode tile ──────────────────────────────
              _SettingsTile(
                icon: isDarkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                iconBg: _teal,
                title: isEnglish ? 'Dark Mode' : 'Umucyo mweru',
                subtitle: isDarkMode
                    ? (isEnglish ? 'Enabled' : 'Akoresha')
                    : (isEnglish ? 'Disabled' : 'Hatakoresha'),
                trailing: _StyledSwitch(
                  value: isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ),
              const SizedBox(height: 28),

              // ── Logout button ───────────────────────────────
              _LogoutButton(isEnglish: isEnglish, authProvider: authProvider),
              const SizedBox(height: 36),

              // ── App info ────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Text(
                      'MamaSafe v1.0.0',
                      style: TextStyle(
                        color: _gray.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEnglish
                          ? 'Maternal Health Monitoring'
                          : 'Ikurikiranire ya Mama',
                      style: TextStyle(
                        color: _gray.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editProfile(BuildContext context, bool isEnglish) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  void _changePassword(BuildContext context, bool isEnglish) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
  }
}

// ─────────────────────────────────────────────
//  PROFILE HEADER CARD
// ─────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String roleLabel;
  final Uint8List? profileImageBytes;
  final VoidCallback onPickImage;

  const _ProfileHeader({
    required this.userName,
    required this.userEmail,
    required this.roleLabel,
    required this.profileImageBytes,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          const BoxShadow(
            color: Color(0xFFFFFFFF),
            blurRadius: 16,
            spreadRadius: 1,
            offset: Offset(-6, -6),
          ),
          BoxShadow(
            color: const Color(0xFF1A7A6E).withOpacity(0.30),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(6, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            left: -16,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _white.withOpacity(0.04),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              children: [
                // Avatar with camera overlay
                GestureDetector(
                  onTap: onPickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: profileImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.memory(
                                  profileImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    color: _teal,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _teal,
                            shape: BoxShape.circle,
                            border: Border.all(color: _white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: _white, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  userName,
                  style: const TextStyle(
                    color: _white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: _white.withOpacity(0.78),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                // Role badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: _white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _white.withOpacity(0.25), width: 1),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
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
}

// ─────────────────────────────────────────────
//  SECTION LABEL
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _teal,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: _navy,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SETTINGS TILE
// ─────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon — clean teal style matching dashboard cards
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _neuBase,
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
              child: Icon(icon, color: _teal, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _gray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STYLED SWITCH
// ─────────────────────────────────────────────
class _StyledSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _StyledSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: _teal,
      activeTrackColor: _teal.withOpacity(0.3),
      inactiveThumbColor: _gray.withOpacity(0.5),
      inactiveTrackColor: _gray.withOpacity(0.15),
    );
  }
}

// ─────────────────────────────────────────────
//  LOGOUT BUTTON
// ─────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final bool isEnglish;
  final AuthProvider authProvider;

  const _LogoutButton({required this.isEnglish, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutConfirmation(context),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text(
          isEnglish ? 'Logout' : 'Sohoka',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: _white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEnglish ? 'Logout' : 'Sohoka',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            isEnglish 
                ? 'Are you sure you want to logout?'
                : 'Uzi neza ko ushaka gusohoka?',
            style: const TextStyle(
              color: _gray,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isEnglish ? 'Cancel' : 'Kuraguza',
                style: const TextStyle(
                  color: _gray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: _white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                isEnglish ? 'Logout' : 'Sohoka',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
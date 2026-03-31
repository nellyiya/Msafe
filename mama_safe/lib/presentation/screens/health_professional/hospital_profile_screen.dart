import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../core/responsive.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../auth/sign_in_screen.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
const _teal = Color(0xFF1A7A6E);
const _navy = Color(0xFF1E2D4E);
const _white = Color(0xFFFFFFFF);
const _bgPage = Color(0xFFEDF2F1);
const _neuBase = Color(0xFFEDF2F1);
const _gray = Color(0xFF6B7280);

class HospitalProfileScreen extends StatefulWidget {
  const HospitalProfileScreen({super.key});

  @override
  State<HospitalProfileScreen> createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends State<HospitalProfileScreen> {
  String _getDoctorName(String facility) {
    switch (facility) {
      case 'King Faisal Hospital Rwanda': return 'Dr. Aurore Isimbi';
      case 'Kibagabaga Level II Teaching Hospital': return 'Dr. Keza Diana';
      case 'Kacyiru District Hospital': return 'Dr. Sonia Uwera';
      default: return 'Doctor';
    }
  }

  String _getDoctorEmail(String facility) {
    switch (facility) {
      case 'King Faisal Hospital Rwanda': return 'aurore.ismbi@kfh.rw';
      case 'Kibagabaga Level II Teaching Hospital': return 'keza.diana@kibagabagahospital.rw';
      case 'Kacyiru District Hospital': return 'sonia.uwera@kacyiruhospital.rw';
      default: return '';
    }
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final isEnglish = languageProvider.isEnglish;

    final hospitalName = authProvider.currentUserFacility ?? '';
    final userName = authProvider.currentUserName ?? 'User';
    final userEmail = authProvider.currentUserEmail ?? '';
    final userPhone = authProvider.currentUserPhone ?? '';

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.padding(context),
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Header Card ─────────────────────────
              _ProfileHeader(
                userName: userName,
                userEmail: userEmail,
                hospitalName: hospitalName.isNotEmpty ? hospitalName : 'Hospital',
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

              // ── Hospital Info section ────────────────────────
              _SectionLabel(label: isEnglish ? 'Hospital Info' : 'Amakuru y\'ibitaro'),
              const SizedBox(height: 14),

              _InfoTile(
                icon: Icons.local_hospital_outlined,
                title: isEnglish ? 'Hospital' : 'Ibitaro',
                subtitle: hospitalName.isNotEmpty ? hospitalName : (isEnglish ? 'Not provided' : 'Ntabwo yatanzwe'),
              ),
              const SizedBox(height: 12),
              _InfoTile(
                icon: Icons.person_outline,
                title: isEnglish ? 'Doctor' : 'Muganga',
                subtitle: hospitalName.isNotEmpty ? _getDoctorName(hospitalName) : (isEnglish ? 'Not provided' : 'Ntabwo yatanzwe'),
              ),
              const SizedBox(height: 12),
              _InfoTile(
                icon: Icons.email_outlined,
                title: isEnglish ? 'Doctor Email' : 'Imeri ya Muganga',
                subtitle: hospitalName.isNotEmpty ? _getDoctorEmail(hospitalName) : (isEnglish ? 'Not provided' : 'Ntabwo yatanzwe'),
              ),
              const SizedBox(height: 12),
              _InfoTile(
                icon: Icons.phone_outlined,
                title: isEnglish ? 'Contact Phone' : 'Telefoni',
                subtitle: userPhone.isNotEmpty ? userPhone : (isEnglish ? 'Not provided' : 'Ntabwo yatanzwe'),
              ),

              const SizedBox(height: 28),

              // ── Security section ─────────────────────────────
              _SectionLabel(label: isEnglish ? 'Security' : 'Umutekano'),
              const SizedBox(height: 14),

              _InfoTile(
                icon: Icons.lock_outline,
                title: isEnglish ? 'Change Password' : 'Hindura Ijambo Banga',
                subtitle: isEnglish ? 'Update your account password' : 'Hindura ijambo banga ryawe',
                trailing: const Icon(Icons.arrow_forward_ios, color: _gray, size: 16),
                onTap: () => _changePassword(context, isEnglish),
              ),
              const SizedBox(height: 28),

              // ── Logout button ────────────────────────────────
              _LogoutButton(isEnglish: isEnglish, authProvider: authProvider),
              const SizedBox(height: 36),

              // ── App info ─────────────────────────────────────
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
                      isEnglish ? 'Maternal Health Monitoring' : 'Ikurikiranire ya Mama',
                      style: TextStyle(color: _gray.withOpacity(0.5), fontSize: 11),
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

  void _changePassword(BuildContext context, bool isEnglish) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEnglish ? 'Change Password' : 'Hindura ijambo ry\'ibanga',
          style: const TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogTextField(controller: currentPasswordController, label: isEnglish ? 'Current Password' : 'Ijambo ry\'ibanga rya none', obscure: true),
            const SizedBox(height: 12),
            _dialogTextField(controller: newPasswordController, label: isEnglish ? 'New Password' : 'Ijambo ry\'ibanga rishya', obscure: true),
            const SizedBox(height: 12),
            _dialogTextField(controller: confirmPasswordController, label: isEnglish ? 'Confirm Password' : 'Emeza ijambo ry\'ibanga', obscure: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: _gray),
            child: Text(isEnglish ? 'Cancel' : 'Hagarika'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isEnglish ? 'Passwords do not match' : 'Amagambo y\'ibanga ntabwo ahura'),
                  backgroundColor: AppColors.error,
                ));
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isEnglish ? 'Password changed successfully' : 'Ijambo ry\'ibanga ryahinduwe'),
                backgroundColor: AppColors.success,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: _white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isEnglish ? 'Change' : 'Hindura'),
          ),
        ],
      ),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: _navy, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _gray, fontSize: 13),
        filled: true,
        fillColor: _bgPage,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E9E8))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E9E8))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _teal, width: 1.8)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PROFILE HEADER CARD
// ─────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String hospitalName;
  final Uint8List? profileImageBytes;
  final VoidCallback onPickImage;

  const _ProfileHeader({
    required this.userName,
    required this.userEmail,
    required this.hospitalName,
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
          const BoxShadow(color: Color(0xFFFFFFFF), blurRadius: 16, spreadRadius: 1, offset: Offset(-6, -6)),
          BoxShadow(color: const Color(0xFF1A7A6E).withOpacity(0.30), blurRadius: 16, spreadRadius: 1, offset: const Offset(6, 6)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _white.withOpacity(0.06)),
            ),
          ),
          Positioned(
            left: -16,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _white.withOpacity(0.04)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              children: [
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
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: profileImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.memory(profileImageBytes!, fit: BoxFit.cover),
                              )
                            : Center(
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: _teal, fontSize: 28, fontWeight: FontWeight.bold),
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
                  style: const TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(color: _white.withOpacity(0.78), fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: _white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _white.withOpacity(0.25), width: 1),
                  ),
                  child: Text(
                    hospitalName,
                    style: const TextStyle(color: _white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                    textAlign: TextAlign.center,
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
          decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: _navy, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  INFO TILE
// ─────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
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
            const BoxShadow(color: Color(0xFFFFFFFF), blurRadius: 14, spreadRadius: 1, offset: Offset(-5, -5)),
            BoxShadow(color: const Color(0xFF1A7A6E).withOpacity(0.12), blurRadius: 14, spreadRadius: 1, offset: const Offset(5, 5)),
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(3, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _neuBase,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  const BoxShadow(color: Color(0xFFFFFFFF), blurRadius: 6, offset: Offset(-3, -3)),
                  BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 6, offset: const Offset(3, 3)),
                ],
              ),
              child: Icon(icon, color: _teal, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: _navy, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: _gray, fontSize: 12)),
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
        boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6))],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                isEnglish ? 'Logout' : 'Sohoka',
                style: const TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Text(
            isEnglish ? 'Are you sure you want to logout?' : 'Uzi neza ko ushaka gusohoka?',
            style: const TextStyle(color: _gray, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isEnglish ? 'Cancel' : 'Kuraguza',
                style: const TextStyle(color: _gray, fontSize: 14, fontWeight: FontWeight.w500),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                isEnglish ? 'Logout' : 'Sohoka',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}

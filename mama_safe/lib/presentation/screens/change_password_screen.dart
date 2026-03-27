import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';

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

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isEnglish = languageProvider.isEnglish;

    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        title: Text(
          isEnglish ? 'Change Password' : 'Hindura Ijambo Banga',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _tealLight,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _teal.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security,
                    color: _teal,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _teal.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: _teal, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEnglish
                            ? 'Your password must be at least 6 characters long'
                            : 'Ijambo banga rigomba kuba rifite byibuze inyuguti 6',
                        style: const TextStyle(
                          color: _teal,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Current Password Field
              _buildPasswordField(
                controller: _currentPasswordController,
                label: isEnglish ? 'Current Password' : 'Ijambo Banga Rihari',
                isVisible: _showCurrentPassword,
                onToggleVisibility: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return isEnglish ? 'Current password is required' : 'Ijambo banga rihari rirakenewe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // New Password Field
              _buildPasswordField(
                controller: _newPasswordController,
                label: isEnglish ? 'New Password' : 'Ijambo Banga Rishya',
                isVisible: _showNewPassword,
                onToggleVisibility: () => setState(() => _showNewPassword = !_showNewPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return isEnglish ? 'New password is required' : 'Ijambo banga rishya rirakenewe';
                  }
                  if (value.length < 6) {
                    return isEnglish ? 'Password must be at least 6 characters' : 'Ijambo banga rigomba kuba rifite byibuze inyuguti 6';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirm Password Field
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: isEnglish ? 'Confirm New Password' : 'Emeza Ijambo Banga Rishya',
                isVisible: _showConfirmPassword,
                onToggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return isEnglish ? 'Please confirm your password' : 'Nyamuneka emeza ijambo banga';
                  }
                  if (value != _newPasswordController.text) {
                    return isEnglish ? 'Passwords do not match' : 'Amagambo banga ntabwo ahura';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Change Password Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: _white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: _white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEnglish ? 'Change Password' : 'Hindura Ijambo Banga',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _navy,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          validator: validator,
          style: const TextStyle(color: _navy, fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, color: _teal, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: _gray,
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
            filled: true,
            fillColor: _white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cardBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _teal, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final languageProvider = context.read<LanguageProvider>();
      final isEnglish = languageProvider.isEnglish;

      // Change password
      await authProvider.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEnglish 
                  ? 'Password changed successfully!'
                  : 'Ijambo banga ryahinduwe neza!',
            ),
            backgroundColor: _teal,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final languageProvider = context.read<LanguageProvider>();
        final isEnglish = languageProvider.isEnglish;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEnglish 
                  ? 'Failed to change password. Please check your current password.'
                  : 'Byanze guhindura ijambo banga. Reba neza ijambo banga rihari.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
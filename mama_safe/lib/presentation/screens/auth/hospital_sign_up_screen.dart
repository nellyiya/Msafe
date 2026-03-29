import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/responsive.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
const _teal = Color(0xFF1A7A6E);
const _tealDark = Color(0xFF145F55);
const _navy = Color(0xFF1E2D4E);
const _white = Color(0xFFFFFFFF);
const _bgPage = Color(0xFFF0F4F3);
const _gray = Color(0xFF6B7280);
const _border = Color(0xFFDDE3E2);
const _fieldBg = Color(0xFFF0F4F3);
const _tealLight = Color(0xFFE8F5F3);

class HospitalSignUpScreen extends StatefulWidget {
  const HospitalSignUpScreen({super.key});

  @override
  State<HospitalSignUpScreen> createState() => _HospitalSignUpScreenState();
}

class _HospitalSignUpScreenState extends State<HospitalSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedHospital;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showTermsDialog(BuildContext context, bool isEnglish) {
    showDialog(
      context: context,
      builder: (_) => _TermsDialog(isEnglish: isEnglish),
    );
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedHospital == null) {
        _showSnack('Please select a hospital');
        return;
      }
      final authProvider = context.read<AuthProvider>();
      try {
        final success = await authProvider.signUp(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          role: AppUserRole.healthcareProfessional,
          password: _passwordController.text,
          facility: _selectedHospital,
        );
        if (success && mounted) _showSuccessDialog();
      } catch (e) {
        if (mounted) _showSnack('Error: ${e.toString()}');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: _teal,
                  size: 42,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Account Created!',
                style: TextStyle(
                  color: _navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your account is pending Admin approval. You will be notified once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _gray, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              _PrimaryButton(
                label: 'OK',
                isLoading: false,
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isEnglish = languageProvider.isEnglish;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.isDesktop(context) ? 500 : double.infinity,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                Responsive.padding(context),
                24,
                Responsive.padding(context),
                24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Facility card ───────────────────────
                    _SectionCard(
                      label: isEnglish ? 'Facility' : 'Ibitaro',
                      icon: Icons.local_hospital_outlined,
                      children: [
                        _FieldLabel(
                            label: isEnglish
                                ? 'Hospital Name'
                                : 'Izina ry\'ibitaro'),
                        const SizedBox(height: 8),
                        _StyledDropdown<String>(
                          value: _selectedHospital,
                          hint: isEnglish
                              ? 'Select your hospital'
                              : 'Hitamo ibitaro',
                          icon: Icons.local_hospital_outlined,
                          items: const [
                            DropdownMenuItem(
                              value: 'King Faisal Hospital Rwanda',
                              child: Text('King Faisal Hospital Rwanda'),
                            ),
                            DropdownMenuItem(
                              value: 'Kibagabaga Level II Teaching Hospital',
                              child:
                                  Text('Kibagabaga Level II Teaching Hospital'),
                            ),
                            DropdownMenuItem(
                              value: 'Kacyiru District Hospital',
                              child: Text('Kacyiru District Hospital'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedHospital = v),
                          validator: (v) => (v == null)
                              ? (isEnglish
                                  ? 'Please select a hospital'
                                  : 'Hitamo ibitaro')
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Representative Info card ────────────
                    _SectionCard(
                      label: isEnglish
                          ? 'Representative Info'
                          : 'Amakuru y\'uhagarariye',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _FieldLabel(
                            label: isEnglish
                                ? 'Full Name'
                                : 'Amazina y\'uhagarariye'),
                        const SizedBox(height: 8),
                        _InputField(
                          controller: _nameController,
                          hint:
                              isEnglish ? 'Enter full name' : 'Amazina yuzuye',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => (v == null || v.isEmpty)
                              ? (isEnglish
                                  ? 'Enter representative name'
                                  : 'Andika amazina')
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel(
                            label:
                                isEnglish ? 'Work Email' : 'Imeyili y\'akazi'),
                        const SizedBox(height: 8),
                        _InputField(
                          controller: _emailController,
                          hint: 'work@hospital.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return isEnglish
                                  ? 'Enter work email'
                                  : 'Andika imeyili';
                            }
                            if (!v.contains('@')) {
                              return isEnglish
                                  ? 'Enter a valid email'
                                  : 'Imeyili siyo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel(
                            label: isEnglish
                                ? 'Phone Number'
                                : 'Nimero ya telefone'),
                        const SizedBox(height: 8),
                        _InputField(
                          controller: _phoneController,
                          hint: '+250 7XX XXX XXX',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.isEmpty)
                              ? (isEnglish
                                  ? 'Enter phone number'
                                  : 'Andika numero')
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Security card ───────────────────────
                    _SectionCard(
                      label: isEnglish ? 'Security' : 'Umutekano',
                      icon: Icons.lock_outline_rounded,
                      children: [
                        _FieldLabel(
                            label:
                                isEnglish ? 'Password' : 'Ijambo ry\'ibanga'),
                        const SizedBox(height: 8),
                        _InputField(
                          controller: _passwordController,
                          hint: isEnglish
                              ? 'Min. 6 characters'
                              : 'Nibura inyuguti 6',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _gray,
                              size: 20,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return isEnglish
                                  ? 'Enter a password'
                                  : 'Andika ijambo ry\'ibanga';
                            }
                            if (v.length < 6) {
                              return isEnglish
                                  ? 'At least 6 characters'
                                  : 'Nibura inyuguti 6';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel(
                            label: isEnglish
                                ? 'Confirm Password'
                                : 'Emeza ijambo ry\'ibanga'),
                        const SizedBox(height: 8),
                        _InputField(
                          controller: _confirmPasswordController,
                          hint: isEnglish
                              ? 'Re-enter password'
                              : 'Ongera ijambo ry\'ibanga',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                            child: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _gray,
                              size: 20,
                            ),
                          ),
                          validator: (v) => (v != _passwordController.text)
                              ? (isEnglish
                                  ? 'Passwords do not match'
                                  : 'Amagambo atagaranye')
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Terms & Conditions ─────────────────────
                    _TermsCheckbox(
                      agreed: _agreedToTerms,
                      isEnglish: isEnglish,
                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                      onReadTerms: () => _showTermsDialog(context, isEnglish),
                    ),

                    const SizedBox(height: 16),

                    // ── Submit button ──────────────────────────
                    _PrimaryButton(
                      label: isEnglish
                          ? 'Create Hospital Account'
                          : 'Fungura Konti y\'ibitaro',
                      isLoading: authProvider.isLoading,
                      onPressed: _agreedToTerms ? _signUp : null,
                    ),

                    const SizedBox(height: 20),

                    // ── Sign in row ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isEnglish
                              ? 'Already have an account?'
                              : 'Ufite konti?',
                          style: const TextStyle(color: _gray, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: _teal,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            isEnglish ? 'Sign In' : 'Injira',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'MamaSafe · Maternal Health Monitoring',
                        style: TextStyle(
                          color: _gray.withOpacity(0.50),
                          fontSize: 11,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION CARD
// ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.label,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: _tealLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _teal,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: _white, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FIELD LABEL
// ─────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: _navy,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      );
}

// ─────────────────────────────────────────────
//  INPUT FIELD
// ─────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
      style: const TextStyle(
        color: _navy,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _gray.withOpacity(0.55), fontSize: 14),
        filled: true,
        fillColor: _fieldBg,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: _teal, size: 20),
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 14),
                child: suffixIcon,
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _teal, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2.0),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STYLED DROPDOWN
// ─────────────────────────────────────────────
class _StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(
        color: _navy,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      dropdownColor: _white,
      icon:
          const Icon(Icons.keyboard_arrow_down_rounded, color: _gray, size: 20),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _gray.withOpacity(0.55), fontSize: 14),
        filled: true,
        fillColor: _fieldBg,
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, color: _teal, size: 20),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _teal, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2.0),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PRIMARY BUTTON
// ─────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: enabled ? [_teal, _tealDark] : [_gray, _gray],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: _white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: _white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TERMS CHECKBOX
// ─────────────────────────────────────────────
class _TermsCheckbox extends StatelessWidget {
  final bool agreed;
  final bool isEnglish;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onReadTerms;

  const _TermsCheckbox({
    required this.agreed,
    required this.isEnglish,
    required this.onChanged,
    required this.onReadTerms,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: agreed ? _teal.withOpacity(0.06) : _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: agreed ? _teal.withOpacity(0.40) : _border,
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: agreed,
              onChanged: onChanged,
              activeColor: _teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              side: BorderSide(color: agreed ? _teal : _gray, width: 1.5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              children: [
                Text(
                  isEnglish ? 'I have read and agree to the ' : 'Nasomye kandi nemeye ',
                  style: const TextStyle(color: _navy, fontSize: 13),
                ),
                GestureDetector(
                  onTap: onReadTerms,
                  child: Text(
                    isEnglish ? 'Terms & Conditions' : 'Amategeko n\'Amabwiriza',
                    style: const TextStyle(
                      color: _teal,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: _teal,
                    ),
                  ),
                ),
                Text(
                  isEnglish ? ' and ' : ' na ',
                  style: const TextStyle(color: _navy, fontSize: 13),
                ),
                GestureDetector(
                  onTap: onReadTerms,
                  child: Text(
                    isEnglish ? 'Privacy Policy' : 'Politiki y\'Ubuzima bw\'Amakuru',
                    style: const TextStyle(
                      color: _teal,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: _teal,
                    ),
                  ),
                ),
                Text(
                  isEnglish ? ' of MamaSafe.' : ' ya MamaSafe.',
                  style: const TextStyle(color: _navy, fontSize: 13),
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
//  TERMS DIALOG
// ─────────────────────────────────────────────
class _TermsDialog extends StatelessWidget {
  final bool isEnglish;
  const _TermsDialog({required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: _tealLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _teal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.gavel_rounded, color: _white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEnglish ? 'Terms & Conditions' : 'Amategeko n\'Amabwiriza',
                    style: const TextStyle(
                      color: _teal,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close_rounded, color: _gray, size: 22),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TermsSection(
                    title: isEnglish ? '1. Data Collection & Use' : '1. Gukusanya no Gukoresha Amakuru',
                    body: isEnglish
                        ? 'MamaSafe collects personal health data of pregnant mothers including vital signs, risk assessments, and referral information. This data is used solely to support maternal health monitoring and care coordination within the Kimironko Sector, Gasabo District.'
                        : 'MamaSafe ikusanya amakuru y\'ubuzima bw\'ababyeyi barindiriye nk\'ibimenyetso by\'ubuzima, isuzuma ry\'ibyago, n\'amakuru y\'iyoherezwa. Aya makuru akoreshwa gusa gufasha gukurikirana ubuzima bw\'ababyeyi mu Murenge wa Kimironko, Akarere ka Gasabo.',
                  ),
                  _TermsSection(
                    title: isEnglish ? '2. Confidentiality' : '2. Ibanga',
                    body: isEnglish
                        ? 'All patient data is strictly confidential. As a registered user, you are obligated to protect the privacy of all mothers in the system. Sharing patient information outside the platform is strictly prohibited and may result in account suspension.'
                        : 'Amakuru yose y\'abarwayi ni ibanga cyane. Nk\'umukoresha wanditswe, ufite inshingano yo kurinda ubuzima bw\'amakuru y\'ababyeyi bose mu sisitemu.',
                  ),
                  _TermsSection(
                    title: isEnglish ? '3. Authorised Use Only' : '3. Gukoresha Byemewe Gusa',
                    body: isEnglish
                        ? 'This platform is exclusively for authorised Healthcare Professionals operating within the approved facilities (King Faisal Hospital Rwanda, Kibagabaga Level II Teaching Hospital, Kacyiru District Hospital). Misuse of the system is a violation of these terms.'
                        : 'Iyi platform ni iy\'inzobere z\'ubuzima zikorera mu bikorwa byemewe gusa (King Faisal Hospital Rwanda, Kibagabaga Level II Teaching Hospital, Kacyiru District Hospital).',
                  ),
                  _TermsSection(
                    title: isEnglish ? '4. AI Predictions Disclaimer' : '4. Impanuro z\'AI',
                    body: isEnglish
                        ? 'Risk predictions generated by MamaSafe are decision-support tools only. They do not replace professional medical judgment. All clinical decisions must be made by qualified healthcare professionals.'
                        : 'Ubushinjacyaha bw\'ibyago bwakozwe na MamaSafe ni ibikoresho byo gufasha gufata ibyemezo gusa. Ntibisimbuza ubushobozi bw\'inzobere z\'ubuvuzi.',
                  ),
                  _TermsSection(
                    title: isEnglish ? '5. Account Responsibility' : '5. Inshingano za Konti',
                    body: isEnglish
                        ? 'You are responsible for maintaining the confidentiality of your login credentials. Do not share your password with anyone. Report any suspected unauthorised access immediately.'
                        : 'Uri inshingano yo kubika ibanga ry\'amakuru yo kwinjira. Ntugabane ijambo ry\'ibanga nawe uwo ari we wese.',
                  ),
                  _TermsSection(
                    title: isEnglish ? '6. Data Retention' : '6. Kubika Amakuru',
                    body: isEnglish
                        ? 'Patient data is retained for the duration necessary to support ongoing maternal care. Data may be anonymised and used for public health research in compliance with Rwandan data protection laws.'
                        : 'Amakuru y\'abarwayi abikwa igihe gikenewe gufasha uburyo bw\'ubuzima bw\'ababyeyi hakurikijwe amategeko y\'uburinzi bw\'amakuru ya Rwanda.',
                  ),
                  _TermsSection(
                    title: isEnglish ? '7. Patient Consent' : '7. Imenyesha ry\'Umurwayi',
                    body: isEnglish
                        ? 'Healthcare professionals must ensure informed consent has been obtained from each patient before accessing or updating their records in the system.'
                        : 'Inzobere z\'ubuzima zigomba kugaragaza ko imenyesha ryahawe buri murwayi mbere yo kugera ku makuru yabo cyangwa kuyavugurura mu sisitemu.',
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _teal.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: _teal, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isEnglish
                                ? 'Last updated: March 2025 · MamaSafe v2.0'
                                : 'Ivugururwa rya nyuma: Werurwe 2025 · MamaSafe v2.0',
                            style: const TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: _white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  isEnglish ? 'I Understand' : 'Nararosoye',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String body;
  const _TermsSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: _navy, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(body,
              style: const TextStyle(color: _gray, fontSize: 12, height: 1.6)),
        ],
      ),
    );
  }
}

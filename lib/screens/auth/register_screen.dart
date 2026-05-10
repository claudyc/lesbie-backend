import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _acceptTerms = false;
  DateTime? _birthDate;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Welcome to\nLesbie Chat! 🌸',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.white,
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create your free account in less than 2 minutes',
                style: TextStyle(fontSize: 13, color: AppTheme.gray),
              ),
              const SizedBox(height: 28),

              _buildLabel('Full Name'),
              _buildTextField(
                controller: _nameController,
                hint: 'e.g. Marie Joseph',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              _buildLabel('Email Address'),
              _buildTextField(
                controller: _emailController,
                hint: 'you@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildLabel('Phone Number'),
              _buildTextField(
                controller: _phoneController,
                hint: '+1 XXX XXX XXXX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              _buildLabel('Date of Birth (18+ required)'),
              GestureDetector(
                onTap: _pickBirthDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(
                        color: AppTheme.pink.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.pink, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _birthDate == null
                            ? 'Select your date of birth'
                            : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                        style: TextStyle(
                          color: _birthDate == null
                              ? AppTheme.gray2
                              : AppTheme.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Password'),
              _buildTextField(
                controller: _passwordController,
                hint: 'Minimum 8 characters',
                icon: Icons.lock_outline,
                isPassword: true,
                obscure: _obscurePassword,
                onToggle: () => setState(
                        () => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 16),

              _buildLabel('Confirm Password'),
              _buildTextField(
                controller: _confirmPasswordController,
                hint: 'Repeat your password',
                icon: Icons.lock_outline,
                isPassword: true,
                obscure: _obscureConfirm,
                onToggle: () => setState(
                        () => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 20),

              // Terms
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (v) =>
                        setState(() => _acceptTerms = v ?? false),
                    activeColor: AppTheme.pink,
                    side: BorderSide(
                        color: AppTheme.gray2.withOpacity(0.5)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              color: AppTheme.gray, fontSize: 13),
                          children: [
                            TextSpan(text: 'I accept the '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: AppTheme.pinkSoft,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: AppTheme.pinkSoft,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Register button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                  _isLoading || !_acceptTerms ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pink,
                    disabledBackgroundColor:
                    AppTheme.pink.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(AppTheme.radius),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                      color: Colors.white)
                      : const Text(
                    'Create My Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account?',
                    style: TextStyle(color: AppTheme.gray, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppTheme.pinkSoft,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.gray,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.pink.withOpacity(0.12)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscure : false,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppTheme.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.gray2),
          prefixIcon: Icon(icon, color: AppTheme.pink, size: 20),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.gray2,
              size: 20,
            ),
            onPressed: onToggle,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate:
      DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.pink,
              surface: AppTheme.card,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty) {
      _showError('Please enter your name!');
      return;
    }
    if (_emailController.text.isEmpty) {
      _showError('Please enter your email!');
      return;
    }
    if (_phoneController.text.isEmpty) {
      _showError('Please enter your phone number!');
      return;
    }
    if (_birthDate == null) {
      _showError('Please select your date of birth!');
      return;
    }
    if (_passwordController.text.length < 8) {
      _showError('Password must be at least 8 characters!');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'birthDate': _birthDate!.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false,
        'gender': 'female',
        'onboardingComplete': true,
      });

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already in use!';
          break;
        case 'weak-password':
          message = 'Password is too weak!';
          break;
        case 'invalid-email':
          message = 'Invalid email address!';
          break;
        default:
          message = 'Error: ${e.message}';
      }
      _showError(message);
    } catch (e) {
      _showError('Unexpected error — please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
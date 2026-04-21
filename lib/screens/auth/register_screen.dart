import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../onboarding/identity_screen.dart';

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
      backgroundColor: const Color(0xFF2D1B4E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kreye kont ou',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Byenveni nan\nLesbie Chat! 🌸',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kreye kont ou gratis — pran mwens pase 2 minit',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFED93B1),
                ),
              ),
              const SizedBox(height: 28),
              _buildLabel('Non konplè'),
              _buildTextField(
                controller: _nameController,
                hint: 'Egz: Marie Joseph',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildLabel('Adrès email'),
              _buildTextField(
                controller: _emailController,
                hint: 'ou@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildLabel('Nimewo telefòn'),
              _buildTextField(
                controller: _phoneController,
                hint: '+509 XXXX XXXX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildLabel('Dat nesans (18+ obligatwa)'),
              GestureDetector(
                onTap: _pickBirthDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Color(0xFF7F77DD),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _birthDate == null
                            ? 'Chwazi dat nesans ou'
                            : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                        style: TextStyle(
                          color: _birthDate == null
                              ? Colors.white.withOpacity(0.4)
                              : Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('Modpas'),
              _buildTextField(
                controller: _passwordController,
                hint: 'Minimòm 8 karaktè',
                icon: Icons.lock_outline,
                isPassword: true,
                obscure: _obscurePassword,
                onToggle: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('Konfime modpas'),
              _buildTextField(
                controller: _confirmPasswordController,
                hint: 'Repete modpas la',
                icon: Icons.lock_outline,
                isPassword: true,
                obscure: _obscureConfirm,
                onToggle: () => setState(
                      () => _obscureConfirm = !_obscureConfirm,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (v) =>
                        setState(() => _acceptTerms = v ?? false),
                    activeColor: const Color(0xFFD4537E),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(text: 'Mwen aksepte '),
                            TextSpan(
                              text: 'Tèm itilizasyon',
                              style: TextStyle(
                                color: Color(0xFFED93B1),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: ' ak '),
                            TextSpan(
                              text: 'Politik konfidansyalite',
                              style: TextStyle(
                                color: Color(0xFFED93B1),
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
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading || !_acceptTerms ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4537E),
                    disabledBackgroundColor:
                    const Color(0xFFD4537E).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Kreye kont mwen',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Deja gen kont?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Konekte',
                      style: TextStyle(
                        color: Color(0xFFED93B1),
                        fontWeight: FontWeight.bold,
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
          color: Colors.white70,
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscure : false,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(icon, color: const Color(0xFF7F77DD), size: 20),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.white54,
              size: 20,
            ),
            onPressed: onToggle,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4537E),
              surface: Color(0xFF2D1B4E),
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
      _showError('Mete non ou!');
      return;
    }
    if (_emailController.text.isEmpty) {
      _showError('Mete email ou!');
      return;
    }
    if (_phoneController.text.isEmpty) {
      _showError('Mete nimewo telefòn ou!');
      return;
    }
    if (_birthDate == null) {
      _showError('Chwazi dat nesans ou!');
      return;
    }
    if (_passwordController.text.length < 8) {
      _showError('Modpas la bezwen minimòm 8 karaktè!');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Modpas yo pa matche!');
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
        'onboardingComplete': false,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const IdentityScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email sa a deja itilize!';
          break;
        case 'weak-password':
          message = 'Modpas la twò fèb!';
          break;
        case 'invalid-email':
          message = 'Email la pa valid!';
          break;
        default:
          message = 'Erè: ${e.message}';
      }
      _showError(message);
    } catch (e) {
      _showError('Erè inatandi — eseye ankò.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
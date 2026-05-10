import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import 'photo_screen.dart';

class UsernameScreen extends StatefulWidget {
  final String city;
  final String state;
  final String country;

  const UsernameScreen({
    super.key,
    required this.city,
    required this.state,
    required this.country,
  });

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool? _usernameAvailable;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkUsername(String username) async {
    if (username.length < 3) {
      setState(() => _usernameAvailable = null);
      return;
    }

    setState(() => _isCheckingUsername = true);

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .get();

    if (mounted) {
      setState(() {
        _usernameAvailable = query.docs.isEmpty;
        _isCheckingUsername = false;
      });
    }
  }

  bool _isValidUsername(String username) {
    final regex = RegExp(r'^[a-zA-Z0-9_.]{3,20}$');
    return regex.hasMatch(username);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              AppTheme.pink.withOpacity(0.07),
              AppTheme.bg,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.pink.withOpacity(0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppTheme.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Progress
                _buildProgress(3, 5),
                const SizedBox(height: 28),

                // Title
                const Text(
                  'Create your\nusername ✨',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.white,
                    height: 1.2,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is how other women will find you',
                  style: TextStyle(fontSize: 14, color: AppTheme.gray),
                ),
                const SizedBox(height: 32),

                // Username field
                _buildLabel('Username'),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(
                      color: _usernameAvailable == null
                          ? AppTheme.pink.withOpacity(0.15)
                          : _usernameAvailable!
                          ? AppTheme.green
                          : AppTheme.red,
                      width: _usernameAvailable != null ? 1.5 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: AppTheme.white),
                    onChanged: (value) {
                      if (_isValidUsername(value)) {
                        _checkUsername(value);
                      } else {
                        setState(() => _usernameAvailable = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. marie_beauty',
                      hintStyle: const TextStyle(color: AppTheme.gray2),
                      prefixIcon: const Icon(
                        Icons.alternate_email,
                        color: AppTheme.pink,
                        size: 20,
                      ),
                      suffixIcon: _isCheckingUsername
                          ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: AppTheme.pink,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                          : _usernameAvailable != null
                          ? Icon(
                        _usernameAvailable!
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: _usernameAvailable!
                            ? AppTheme.green
                            : AppTheme.red,
                        size: 20,
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Letters, numbers, _ and . only. 3-20 characters.',
                  style: TextStyle(color: AppTheme.gray2, fontSize: 11),
                ),
                const SizedBox(height: 20),

                // Password field
                _buildLabel('Password'),
                _buildPasswordField(
                  controller: _passwordController,
                  hint: 'Minimum 8 characters',
                  obscure: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 16),

                // Confirm password
                _buildLabel('Confirm Password'),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  hint: 'Repeat your password',
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 32),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.pinkGrad,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      boxShadow: AppTheme.pinkShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radius),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: AppTheme.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.pink.withOpacity(0.15)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: AppTheme.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppTheme.gray2),
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppTheme.pink,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.gray2,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  void _continue() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (username.isEmpty) {
      _showError('Please enter a username!');
      return;
    }
    if (!_isValidUsername(username)) {
      _showError('Username can only have letters, numbers, _ and .');
      return;
    }
    if (_usernameAvailable == false) {
      _showError('This username is already taken!');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters!');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match!');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoScreen(
          city: widget.city,
          state: widget.state,
          country: widget.country,
          username: username,
          password: password,
        ),
      ),
    );
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

  Widget _buildProgress(int current, int total) {
    return Row(
      children: List.generate(total, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < total - 1 ? 6 : 0),
            height: 3,
            decoration: BoxDecoration(
              color: index < current ? AppTheme.pink : AppTheme.gray3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
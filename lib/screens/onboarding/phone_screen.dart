import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  final bool isSignUp;

  const PhoneScreen({super.key, this.isSignUp = true});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _phoneController = TextEditingController();
  String _countryCode = '+1';
  String _countryFlag = '🇺🇸';
  bool _isLoading = false;

  final List<Map<String, String>> _countries = [
    {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
    {'code': '+1', 'flag': '🇨🇦', 'name': 'Canada'},
    {'code': '+509', 'flag': '🇭🇹', 'name': 'Haiti'},
    {'code': '+1809', 'flag': '🇩🇴', 'name': 'Dominican Republic'},
    {'code': '+52', 'flag': '🇲🇽', 'name': 'Mexico'},
    {'code': '+56', 'flag': '🇨🇱', 'name': 'Chile'},
    {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.gray3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Country',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...(_countries.map((c) => ListTile(
            leading: Text(c['flag']!,
                style: const TextStyle(fontSize: 24)),
            title: Text(
              c['name']!,
              style: const TextStyle(
                  color: AppTheme.white, fontSize: 15),
            ),
            trailing: Text(
              c['code']!,
              style: const TextStyle(
                  color: AppTheme.gray, fontSize: 14),
            ),
            onTap: () {
              setState(() {
                _countryCode = c['code']!;
                _countryFlag = c['flag']!;
              });
              Navigator.pop(context);
            },
          ))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _continue() async {
    if (_phoneController.text.isEmpty) {
      _showError('Please enter your phone number!');
      return;
    }

    setState(() => _isLoading = true);

    final fullPhone = '$_countryCode${_phoneController.text.trim()}';

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showError('Error: ${e.message}');
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpScreen(
                  phoneNumber: fullPhone,
                  verificationId: verificationId,
                  resendToken: resendToken,
                  isSignUp: widget.isSignUp,
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout');
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error: $e');
      }
    }
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
              AppTheme.pink.withValues(alpha: 0.07),
              AppTheme.bg,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
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
                        color: AppTheme.pink.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppTheme.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Logo
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppTheme.pinkShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  widget.isSignUp
                      ? 'Create your\naccount 🌸'
                      : 'Welcome\nback 👋',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.white,
                    height: 1.2,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.isSignUp
                      ? 'Enter your phone number to get started'
                      : 'Enter your phone number to sign in',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.gray,
                  ),
                ),
                const SizedBox(height: 40),

                // Phone label
                const Text(
                  'Phone Number',
                  style: TextStyle(
                    color: AppTheme.gray,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Phone input
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(
                        color: AppTheme.pink.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _showCountryPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: AppTheme.pink.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(_countryFlag,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 6),
                              Text(
                                _countryCode,
                                style: const TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: AppTheme.gray2,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 15,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'XXX XXX XXXX',
                            hintStyle: TextStyle(color: AppTheme.gray2),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(Icons.lock_outline,
                        color: AppTheme.gray2, size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'Your number stays private',
                      style: TextStyle(
                          color: AppTheme.gray2, fontSize: 12),
                    ),
                  ],
                ),

                const Spacer(),

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
                          borderRadius:
                          BorderRadius.circular(AppTheme.radius),
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
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.isSignUp
                                ? 'Continue'
                                : 'Sign In',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward,
                              color: AppTheme.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
}
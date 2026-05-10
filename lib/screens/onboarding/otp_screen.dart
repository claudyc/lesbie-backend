import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../main/home_screen.dart';
import 'city_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;
  final bool isSignUp;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
    this.isSignUp = true,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendSeconds = 60;
  bool _canResend = false;
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendSeconds > 0) {
        setState(() => _resendSeconds--);
        _startResendTimer();
      } else if (mounted) {
        setState(() => _canResend = true);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otp.length == 6) {
      _verifyOtp();
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _canResend = false;
      _resendSeconds = 60;
    });
    _startResendTimer();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      forceResendingToken: widget.resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) _showError('Error: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() => _verificationId = verificationId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('New code sent!'),
              backgroundColor: AppTheme.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _verifyOtp() async {
    if (_otp.length < 6) {
      _showError('Please enter the complete 6-digit code!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otp,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) throw Exception('No user found');

      // Check by UID first
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data()?['onboardingComplete'] == true) {
        // Account found by UID — go to HomeScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
        return;
      }

      // Check by phone number
      final phoneQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: widget.phoneNumber)
          .limit(1)
          .get();

      if (!mounted) return;

      if (phoneQuery.docs.isNotEmpty &&
          phoneQuery.docs.first.data()['onboardingComplete'] == true) {
        // Account found by phone — go to HomeScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
      } else if (!widget.isSignUp) {
        // Sign In but no account found
        await FirebaseAuth.instance.signOut();
        setState(() => _isLoading = false);
        _showError(
            'No account found with this number. Please sign up first.');
      } else {
        // New account — go to onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CityScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        switch (e.code) {
          case 'invalid-verification-code':
            _showError('Incorrect code. Please try again.');
            break;
          case 'session-expired':
            _showError('Code expired. Please request a new one.');
            break;
          default:
            _showError('Error: ${e.message}');
        }
      }
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
                const SizedBox(height: 28),

                // Title
                const Text(
                  'Verify your\nnumber 📱',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.white,
                    height: 1.2,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'We sent a 6-digit code to\n${widget.phoneNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.gray,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // OTP fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      height: 58,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _controllers[index].text.isNotEmpty
                                ? AppTheme.pink
                                : AppTheme.pink.withValues(alpha: 0.15),
                            width: _controllers[index].text.isNotEmpty
                                ? 1.5
                                : 1,
                          ),
                        ),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          onChanged: (value) => _onChanged(value, index),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Resend timer
                Center(
                  child: _canResend
                      ? TextButton(
                    onPressed: _resendCode,
                    child: const Text(
                      'Resend Code',
                      style: TextStyle(
                        color: AppTheme.pink,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  )
                      : Text(
                    'Resend code in ${_resendSeconds}s',
                    style: const TextStyle(
                      color: AppTheme.gray2,
                      fontSize: 13,
                    ),
                  ),
                ),

                const Spacer(),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.pinkGrad,
                      borderRadius:
                      BorderRadius.circular(AppTheme.radius),
                      boxShadow: AppTheme.pinkShadow,
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
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
                          : const Text(
                        'Verify Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.white,
                        ),
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
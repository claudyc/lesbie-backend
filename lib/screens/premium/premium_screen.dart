import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isLoading = false;
  int  _selectedPlan = 0; // 0 = monthly, 1 = yearly

  static const _backendUrl = 'https://lesbie-backend.vercel.app';

  // Plan prices
  static const _plans = [
    {'label': 'Monthly', 'price': '\$20', 'sub': 'per month', 'saving': ''},
    {'label': 'Yearly',  'price': '\$150', 'sub': 'per year', 'saving': 'Save 37%'},
  ];

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
        title: const Text('Premium',
            style: TextStyle(color: AppTheme.white,
                fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 10),

          // Crown
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: AppTheme.pinkGrad,
              borderRadius: BorderRadius.circular(26),
              boxShadow: AppTheme.pinkShadow,
            ),
            child: const Center(
                child: Text('👑', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 20),

          const Text('Lesbie Chat Premium',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                  color: AppTheme.white, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          const Text('Unlock the full experience',
              style: TextStyle(fontSize: 14, color: AppTheme.gray)),
          const SizedBox(height: 28),

          // Features
          _buildFeature(Icons.all_inclusive,        'Unlimited connections'),
          _buildFeature(Icons.videocam_outlined,    'Unlimited video calls'),
          _buildFeature(Icons.block,                'No ads'),
          _buildFeature(Icons.star_outline,         'Priority visibility'),
          _buildFeature(Icons.photo_library_outlined, 'Unlimited photos'),
          _buildFeature(Icons.verified_outlined,    'Premium badge'),

          const SizedBox(height: 28),

          // ✅ Plan selector
          Row(children: [
            _buildPlanCard(0),
            const SizedBox(width: 12),
            _buildPlanCard(1),
          ]),

          const SizedBox(height: 20),

          // ✅ Stripe payment button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.pinkGrad,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                boxShadow: AppTheme.pinkShadow,
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Subscribe ${_plans[_selectedPlan]['price']}'
                            '/${_selectedPlan == 0 ? 'mo' : 'yr'}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                      ),
                    ]),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Security badges
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.security, color: AppTheme.gray2, size: 14),
            const SizedBox(width: 4),
            const Text('Secured by Stripe',
                style: TextStyle(color: AppTheme.gray2, fontSize: 12)),
            const SizedBox(width: 16),
            Icon(Icons.cancel_outlined, color: AppTheme.gray2, size: 14),
            const SizedBox(width: 4),
            const Text('Cancel anytime',
                style: TextStyle(color: AppTheme.gray2, fontSize: 12)),
          ]),

          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  // ✅ Plan card — monthly / yearly
  Widget _buildPlanCard(int index) {
    final plan      = _plans[index];
    final isSelected = _selectedPlan == index;
    final hasSaving  = plan['saving']!.isNotEmpty;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlan = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.pinkGrad : null,
            color: isSelected ? null : AppTheme.card2,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: isSelected
                  ? AppTheme.pink
                  : AppTheme.pink.withValues(alpha: 0.15),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasSaving)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : AppTheme.pink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(plan['saving']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.pink,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              if (hasSaving) const SizedBox(height: 8),
              Text(plan['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.gray,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 4),
              Text(plan['price']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  )),
              Text(plan['sub']!,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppTheme.gray,
                    fontSize: 12,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppTheme.pink.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.pink, size: 18),
        ),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(
            color: AppTheme.white, fontSize: 15,
            fontWeight: FontWeight.w500)),
        const Spacer(),
        const Icon(Icons.check_circle, color: AppTheme.pink, size: 18),
      ]),
    );
  }

  // ✅ Stripe payment flow
  Future<void> _startPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1 — Jwenn Firebase Auth token
      final idToken = await user.getIdToken();

      // 2 — Kreye subscription nan backend
      final response = await http.post(
        Uri.parse('$_backendUrl/create-subscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'email': user.email ?? '${user.uid}@lesbie.chat',
          'plan': _selectedPlan == 0 ? 'monthly' : 'yearly',
        }),
      );

      if (response.statusCode != 200) {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Server error');
      }

      final data = jsonDecode(response.body);
      final clientSecret = data['clientSecret'] as String?;

      if (clientSecret == null) {
        throw Exception('Pa jwenn client secret');
      }

      // 3 — Montre Stripe payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Lesbie Chat',
          style: ThemeMode.dark,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: AppTheme.pink,
              background: AppTheme.bg,
              componentBackground: AppTheme.card2,
              componentText: AppTheme.white,
              placeholderText: AppTheme.gray,
              icon: AppTheme.pink,
              componentBorder: AppTheme.gray3,
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // 4 — Mete ajou Firestore apre peman siksè
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isPremium': true,
        'premiumSince': FieldValue.serverTimestamp(),
        'premiumPlan': _selectedPlan == 0 ? 'monthly' : 'yearly',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Welcome to Premium! 👑'),
            backgroundColor: AppTheme.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }

    } on StripeException catch (e) {
      // Moun nan anile — pa montre erè
      if (e.error.code != FailureCode.Canceled) {
        if (mounted) _showError('Peman anile: ${e.error.localizedMessage}');
      }
    } catch (e) {
      if (mounted) _showError('Erè: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
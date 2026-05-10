import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

class BoostScreen extends StatefulWidget {
  const BoostScreen({super.key});

  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  bool _isLoading = false;
  String? _selectedBoost;

  final List<Map<String, dynamic>> _boostOptions = [
    {
      'key': '1h',
      'duration': '1 Èdtan',
      'price': '\$0.99',
      'emoji': '⚡',
      'description': 'Parèt an premye pandan 1 èdtan',
    },
    {
      'key': '6h',
      'duration': '6 Èdtan',
      'price': '\$2.99',
      'emoji': '🔥',
      'description': 'Parèt an premye pandan 6 èdtan',
      'popular': true,
    },
    {
      'key': '24h',
      'duration': '24 Èdtan',
      'price': '\$4.99',
      'emoji': '👑',
      'description': 'Parèt an premye pandan 24 èdtan',
    },
  ];

  Future<void> _startBoost(String boostType) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final dio = Dio();

      final response = await dio.post(
        'https://lesbie-backend.vercel.app/create-boost-payment',
        data: {
          'userId': user.uid,
          'boostType': boostType,
        },
      );

      final clientSecret =
      response.data['client_secret'] as String;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Lesbie Chat',
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFFD4537E),
              background: Color(0xFF2D1B4E),
              componentBackground: Color(0xFF3D2560),
              primaryText: Colors.white,
              secondaryText: Color(0xFFED93B1),
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (mounted) {
        _showSuccess(
            'Boost aktive! Pwofil ou ap parèt an premye! 🚀');
        Navigator.pop(context, true);
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return;
      _showError('Erè peman: ${e.error.message}');
    } catch (e) {
      _showError('Erè inatandi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B4E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B4E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Boost Pwofil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Text('🚀',
                      style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  const Text(
                    'Boost Pwofil Ou',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Parèt an premye nan Discovery\nepi jwenn plis match!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ...(_boostOptions.map((option) {
              final isSelected = _selectedBoost == option['key'];
              return GestureDetector(
                onTap: () => setState(
                        () => _selectedBoost = option['key'] as String),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFD4537E).withOpacity(0.2)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFD4537E)
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        option['emoji'] as String,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  option['duration'] as String,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFFD4537E)
                                        : Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (option['popular'] == true)
                                  Container(
                                    margin: const EdgeInsets.only(
                                        left: 8),
                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                      const Color(0xFFD4537E),
                                      borderRadius:
                                      BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Popilè',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option['description'] as String,
                              style: TextStyle(
                                color:
                                Colors.white.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        option['price'] as String,
                        style: const TextStyle(
                          color: Color(0xFFD4537E),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList()),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading || _selectedBoost == null
                    ? null
                    : () => _startBoost(_selectedBoost!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4537E),
                  disabledBackgroundColor:
                  const Color(0xFFD4537E).withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                    color: Colors.white)
                    : const Text(
                  'Boost Kounye a 🚀',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
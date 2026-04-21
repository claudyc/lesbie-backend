import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/verification_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isLoading = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final verified = await VerificationService.checkVerificationStatus();
    if (mounted) setState(() => _isVerified = verified);
  }

  Future<void> _startVerification() async {
    setState(() => _isLoading = true);
    try {
      // Kreye session
      final session =
      await VerificationService.createVerificationSession();

      // Ouvri URL verifikasyon nan browser
      final url = session['url'] as String?;
      if (url != null) {
        // TODO: Ouvri URL nan WebView oswa browser
        _showInfo(
          'Ale sou lyen sa a pou verifye:\n$url',
        );
      }
    } catch (e) {
      _showError('Erè — eseye ankò: $e');
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verifikasyon ID',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Ikonèt
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _isVerified
                    ? Colors.green.withOpacity(0.2)
                    : const Color(0xFFD4537E).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isVerified
                    ? Icons.verified_user
                    : Icons.badge_outlined,
                color: _isVerified
                    ? Colors.green
                    : const Color(0xFFD4537E),
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isVerified
                  ? 'Ou verifye! ✅'
                  : 'Verifye idantite ou',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isVerified
                  ? 'Pwofil ou gen badge verifikasyon — moun yo ka fè konfyans ou!'
                  : 'Verifye ID ou pou jwenn badge ✅ sou pwofil ou ak plis match.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            if (!_isVerified) ...[
              // Etap yo
              _buildStep(
                '1',
                'Prepare ID ou',
                'Passeport, Permis kondwi, oswa Kat nasyonal',
              ),
              const SizedBox(height: 16),
              _buildStep(
                '2',
                'Pran selfie',
                'Yon foto klè ak figi ou',
              ),
              const SizedBox(height: 16),
              _buildStep(
                '3',
                'Tann verifikasyon',
                'Pran 1-2 minit',
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4537E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text(
                    'Kòmanse verifikasyon',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Idantite ou verifye — badge ✅ parèt sou pwofil ou!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
      String number, String title, String description) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFD4537E),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
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

  void _showInfo(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3D2560),
        title: const Text(
          'Lyen verifikasyon',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFD4537E)),
            ),
          ),
        ],
      ),
    );
  }
}
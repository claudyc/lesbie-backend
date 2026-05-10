import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'lifestyle_screen.dart';

class VerificationSuccessScreen extends StatelessWidget {
  const VerificationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.green.withValues(alpha: 0.12),
                  border: Border.all(color: AppTheme.green.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 56),
              ),
              const SizedBox(height: 28),
              const Text('Soumisyon Reyisi! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.white)),
              const SizedBox(height: 12),
              const Text('Video verifikasyon ou a voye ak siksè.\nEkip nou an ap revize li nan 24-48 èdtan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.gray, height: 1.6)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.pinkGrad,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    boxShadow: AppTheme.pinkShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) => const LifestyleScreen()),
                      (route) => false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
                    ),
                    child: const Text('Kontinye nan App',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

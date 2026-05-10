import 'package:flutter/material.dart';
import '../../core/theme.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

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
          'Verification',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Verification coming soon',
          style: TextStyle(color: AppTheme.gray),
        ),
      ),
    );
  }
}
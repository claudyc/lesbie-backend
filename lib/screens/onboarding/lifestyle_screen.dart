import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../main/home_screen.dart';

class LifestyleScreen extends StatefulWidget {
  const LifestyleScreen({super.key});

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  String? _lookingFor;
  String? _relationshipGoal;
  final List<String> _interests = [];
  bool _isLoading = false;

  final List<Map<String, String>> _lookingForOptions = [
    {'value': 'friends', 'emoji': '👯', 'label': 'Friends'},
    {'value': 'dating', 'emoji': '💕', 'label': 'Dating'},
    {'value': 'relationship', 'emoji': '💍', 'label': 'Relationship'},
    {'value': 'networking', 'emoji': '🤝', 'label': 'Networking'},
    {'value': 'casual', 'emoji': '✨', 'label': 'Casual'},
    {'value': 'undecided', 'emoji': '🌈', 'label': 'Open to anything'},
  ];

  final List<Map<String, String>> _relationshipOptions = [
    {'value': 'monogamous', 'emoji': '💑', 'label': 'Monogamous'},
    {'value': 'polyamorous', 'emoji': '💞', 'label': 'Polyamorous'},
    {'value': 'not_sure', 'emoji': '🤷', 'label': 'Not sure yet'},
  ];

  final List<Map<String, String>> _interestOptions = [
    {'value': 'travel', 'emoji': '✈️', 'label': 'Travel'},
    {'value': 'music', 'emoji': '🎵', 'label': 'Music'},
    {'value': 'art', 'emoji': '🎨', 'label': 'Art'},
    {'value': 'fitness', 'emoji': '💪', 'label': 'Fitness'},
    {'value': 'cooking', 'emoji': '🍳', 'label': 'Cooking'},
    {'value': 'gaming', 'emoji': '🎮', 'label': 'Gaming'},
    {'value': 'reading', 'emoji': '📚', 'label': 'Reading'},
    {'value': 'movies', 'emoji': '🎬', 'label': 'Movies'},
    {'value': 'nature', 'emoji': '🌿', 'label': 'Nature'},
    {'value': 'fashion', 'emoji': '👗', 'label': 'Fashion'},
    {'value': 'dancing', 'emoji': '💃', 'label': 'Dancing'},
    {'value': 'photography', 'emoji': '📸', 'label': 'Photography'},
  ];

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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: 1.0,
                            backgroundColor: AppTheme.gray3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.pink),
                            minHeight: 3,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tell us about\nyourself 💫',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.white,
                        height: 1.2,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Help us find the right connections for you',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.gray,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Looking for
                      const Text(
                        'What are you looking for?',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _lookingForOptions.map((opt) {
                          final isSelected = _lookingFor == opt['value'];
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _lookingFor = opt['value']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.pink.withValues(alpha: 0.15)
                                    : AppTheme.card,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusPill),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.pink
                                      : AppTheme.pink
                                      .withValues(alpha: 0.12),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(opt['emoji']!,
                                      style:
                                      const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    opt['label']!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.pink
                                          : AppTheme.gray,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // Relationship style
                      const Text(
                        'Relationship style',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _relationshipOptions.map((opt) {
                          final isSelected =
                              _relationshipGoal == opt['value'];
                          return GestureDetector(
                            onTap: () => setState(
                                    () => _relationshipGoal = opt['value']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.pink.withValues(alpha: 0.15)
                                    : AppTheme.card,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusPill),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.pink
                                      : AppTheme.pink
                                      .withValues(alpha: 0.12),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(opt['emoji']!,
                                      style:
                                      const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    opt['label']!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.pink
                                          : AppTheme.gray,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // Interests
                      const Text(
                        'Your interests (pick at least 3)',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _interestOptions.map((opt) {
                          final isSelected =
                          _interests.contains(opt['value']);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _interests.remove(opt['value']);
                                } else {
                                  _interests.add(opt['value']!);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.pink.withValues(alpha: 0.15)
                                    : AppTheme.card,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusPill),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.pink
                                      : AppTheme.pink
                                      .withValues(alpha: 0.12),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(opt['emoji']!,
                                      style:
                                      const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    opt['label']!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.pink
                                          : AppTheme.gray,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _lookingFor != null &&
                                _interests.length >= 3
                                ? AppTheme.pinkGrad
                                : const LinearGradient(
                              colors: [
                                Color(0xFF2E2C38),
                                Color(0xFF2E2C38),
                              ],
                            ),
                            borderRadius:
                            BorderRadius.circular(AppTheme.radius),
                            boxShadow: _lookingFor != null &&
                                _interests.length >= 3
                                ? AppTheme.pinkShadow
                                : [],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ||
                                _lookingFor == null ||
                                _interests.length < 3
                                ? null
                                : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radius),
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
                              "Let's Go! 🚀",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Skip
                      Center(
                        child: TextButton(
                          onPressed: _isLoading ? null : _skip,
                          child: const Text(
                            'Skip for now',
                            style: TextStyle(
                              color: AppTheme.gray2,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'lookingFor': _lookingFor,
        'relationshipGoal': _relationshipGoal,
        'interests': _interests,
        'onboardingComplete': true,
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error: $e');
      }
    }
  }

  Future<void> _skip() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'onboardingComplete': true});
    }
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
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
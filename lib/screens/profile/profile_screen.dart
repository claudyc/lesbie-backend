import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../onboarding/splash_screen.dart';
import '../premium/premium_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (mounted && doc.exists) {
      setState(() => _userData = doc.data());
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _userData?['username'] ?? _userData?['name'] ?? 'User';
    final city = _userData?['city'] ?? '';
    final country = _userData?['country'] ?? '';
    final photoUrl = _userData?['photoUrl'];
    final isVerified = _userData?['isVerified'] == true;
    final isPremium = _userData?['isPremium'] == true;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Avatar
              Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.pinkGrad,
                      boxShadow: AppTheme.pinkShadow,
                      image: photoUrl != null
                          ? DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: photoUrl == null
                        ? Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.white,
                        ),
                      ),
                    )
                        : null,
                  ),
                  if (isVerified)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppTheme.pink,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.bg, width: 2),
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: AppTheme.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.white,
                ),
              ),
              const SizedBox(height: 4),

              // Location
              if (city.isNotEmpty)
                Text(
                  '📍 $city${country.isNotEmpty ? ', $country' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.gray,
                  ),
                ),
              const SizedBox(height: 12),

              // Premium badge
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.pinkGrad,
                    borderRadius:
                    BorderRadius.circular(AppTheme.radiusPill),
                    boxShadow: AppTheme.pinkShadow,
                  ),
                  child: const Text(
                    '👑 Premium Member',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 28),

              // Buttons
              _buildButton(
                icon: Icons.star,
                label: isPremium
                    ? 'Premium Member 👑'
                    : 'Get Premium 👑',
                color: isPremium ? AppTheme.green : AppTheme.pink,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PremiumScreen()),
                  );
                  _loadUserData();
                },
              ),
              const SizedBox(height: 12),

              _buildButton(
                icon: Icons.edit,
                label: 'Edit Profile',
                color: AppTheme.card2,
                onTap: () async {
                  if (_userData == null) return;
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditProfileScreen(userData: _userData!),
                    ),
                  );
                  if (updated == true) _loadUserData();
                },
              ),
              const SizedBox(height: 12),

              _buildButton(
                icon: Icons.settings_outlined,
                label: 'Settings',
                color: AppTheme.card2,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildButton(
                icon: Icons.logout,
                label: 'Sign Out',
                color: AppTheme.red.withValues(alpha: 0.15),
                textColor: AppTheme.red,
                onTap: _signOut,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color color,
    Color textColor = AppTheme.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
        const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(
            color: AppTheme.pink.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
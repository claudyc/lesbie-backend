import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../onboarding/splash_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _notificationsEnabled = true;
  bool _hideLocation = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_currentUser == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .get();
    if (mounted && doc.exists) {
      final data = doc.data()!;
      setState(() {
        _notificationsEnabled = data['notificationsEnabled'] ?? true;
        _hideLocation = data['hideLocation'] ?? false;
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    if (_currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .update({key: value});
  }

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
          'Settings',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account section
            _buildSectionTitle('Account'),
            const SizedBox(height: 12),
            _buildToggleItem(
              icon: Icons.notifications_outlined,
              label: 'Push Notifications',
              value: _notificationsEnabled,
              onChanged: (val) {
                setState(() => _notificationsEnabled = val);
                _updateSetting('notificationsEnabled', val);
              },
            ),
            _buildToggleItem(
              icon: Icons.visibility_off_outlined,
              label: 'Hide My Location',
              value: _hideLocation,
              onChanged: (val) {
                setState(() => _hideLocation = val);
                _updateSetting('hideLocation', val);
              },
            ),
            const SizedBox(height: 24),

            // Privacy section
            _buildSectionTitle('Privacy & Safety'),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.block,
              label: 'Blocked Users',
              onTap: () => _showBlockedUsers(),
            ),
            _buildSettingItem(
              icon: Icons.flag_outlined,
              label: 'Report a Problem',
              onTap: () => _showReportDialog(),
            ),
            const SizedBox(height: 24),

            // Support section
            _buildSectionTitle('Support'),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.help_outline,
              label: 'Help Center',
              onTap: () => _showHelpCenter(),
            ),
            _buildSettingItem(
              icon: Icons.info_outline,
              label: 'About Lesbie Chat',
              onTap: () => _showAbout(),
            ),
            const SizedBox(height: 24),

            // Sign out
            GestureDetector(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const SplashScreen()),
                        (route) => false,
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(
                    color: AppTheme.red.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: AppTheme.red, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: AppTheme.red,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Blocked Users
  void _showBlockedUsers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Column(
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
              'Blocked Users',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('blocked_users')
                    .where('blockedBy', isEqualTo: _currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final blocked = snapshot.data?.docs ?? [];

                  if (blocked.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block,
                              size: 48, color: AppTheme.gray2),
                          SizedBox(height: 12),
                          Text(
                            'No blocked users',
                            style: TextStyle(
                              color: AppTheme.gray,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: blocked.length,
                    itemBuilder: (context, index) {
                      final data = blocked[index].data()
                      as Map<String, dynamic>;
                      final blockedUid = data['blockedUid'];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(blockedUid)
                            .get(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData) {
                            return const SizedBox();
                          }
                          final userData = userSnap.data!.data()
                          as Map<String, dynamic>?;
                          final name = userData?['username'] ??
                              userData?['name'] ??
                              'User';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.card2,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radius),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.pinkGrad,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: AppTheme.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await blocked[index]
                                        .reference
                                        .delete();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '$name unblocked'),
                                          backgroundColor:
                                          AppTheme.green,
                                          behavior:
                                          SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(
                                                12),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'Unblock',
                                    style: TextStyle(
                                      color: AppTheme.pink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Report a Problem
  void _showReportDialog() {
    final _reportController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              'Report a Problem',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Describe the issue and we will look into it.',
              style: TextStyle(color: AppTheme.gray, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.card2,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(
                    color: AppTheme.pink.withValues(alpha: 0.15)),
              ),
              child: TextField(
                controller: _reportController,
                maxLines: 5,
                style: const TextStyle(
                    color: AppTheme.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Describe the problem...',
                  hintStyle: TextStyle(color: AppTheme.gray2),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.pinkGrad,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  boxShadow: AppTheme.pinkShadow,
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_reportController.text.trim().isEmpty) return;

                    await FirebaseFirestore.instance
                        .collection('problem_reports')
                        .add({
                      'uid': _currentUser?.uid,
                      'message': _reportController.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                      'status': 'pending',
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Report submitted. Thank you!'),
                          backgroundColor: AppTheme.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(AppTheme.radius),
                    ),
                  ),
                  child: const Text(
                    'Submit Report',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.white,
                    ),
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

  // Help Center
  void _showHelpCenter() {
    final faqs = [
      {
        'q': 'How do I get verified?',
        'a':
        'Record a short video during signup. Our team reviews it within 24-48 hours.'
      },
      {
        'q': 'How do connections work?',
        'a':
        'When two women like each other, a connection is created and they can chat.'
      },
      {
        'q': 'Is Lesbie Chat only for women?',
        'a':
        'Yes! Lesbie Chat is exclusively for women 18+. All accounts are verified.'
      },
      {
        'q': 'How do I report someone?',
        'a':
        'Tap on their profile and use the Report button. We review all reports.'
      },
      {
        'q': 'What is Premium?',
        'a':
        'Premium gives you unlimited likes, see who liked you, and more features.'
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
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
              'Help Center',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  return _buildFaqItem(
                    faqs[index]['q']!,
                    faqs[index]['a']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.card2,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
            color: AppTheme.pink.withValues(alpha: 0.08)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: AppTheme.pink,
        collapsedIconColor: AppTheme.gray2,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(
                color: AppTheme.gray,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // About
  void _showAbout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.gray3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.pinkGrad,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.pinkShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lesbie Chat',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: AppTheme.gray, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'A safe, verified space for women to connect, share and grow together.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.gray,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppTheme.pink.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(AppTheme.radius),
                      ),
                    ),
                    child: const Text(
                      'Terms of Service',
                      style: TextStyle(
                          color: AppTheme.pinkSoft, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppTheme.pink.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(AppTheme.radius),
                      ),
                    ),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(
                          color: AppTheme.pinkSoft, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '© 2026 Chana Network. All rights reserved.',
              style: TextStyle(color: AppTheme.gray2, fontSize: 11),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.pinkSoft,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
            color: AppTheme.pink.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.gray, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.pink,
            inactiveThumbColor: AppTheme.gray2,
            inactiveTrackColor: AppTheme.gray3,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(
              color: AppTheme.pink.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.gray, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.gray2,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
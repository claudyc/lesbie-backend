import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme.dart';
import 'video_verify_screen.dart';

class PhotoScreen extends StatefulWidget {
  final String city;
  final String state;
  final String country;
  final String username;
  final String password;

  const PhotoScreen({
    super.key,
    required this.city,
    required this.state,
    required this.country,
    required this.username,
    required this.password,
  });

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _showImagePicker() {
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
            const Text(
              'Choose Photo',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _buildPickerOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _buildPickerOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.card2,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(
              color: AppTheme.pink.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.pink, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continue() async {
    setState(() => _isLoading = true);

    try {
      // ✅ Kont deja kreye nan Phone Auth — jis jwenn user aktyèl la
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Session expired. Please sign in again.');
        setState(() => _isLoading = false);
        return;
      }

      String? photoUrl;

      // Upload photo si chwazi
      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('${user.uid}.jpg');

        await ref.putFile(_selectedImage!);
        photoUrl = await ref.getDownloadURL();
      }

      // ✅ Sove done nan Firestore — pa kreye nouvo kont
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'username': widget.username.toLowerCase(),
        'name': widget.username,
        'city': widget.city,
        'state': widget.state,
        'country': widget.country,
        'photoUrl': photoUrl,
        'phone': user.phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false,
        'gender': 'female',
        'onboardingComplete': false,
        'isPremium': false,
      });

      // Navigate to video verification
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const VideoVerifyScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: $e');
        setState(() => _isLoading = false);
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
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
                ),
                const SizedBox(height: 28),

                // Progress
                _buildProgress(4, 5),
                const SizedBox(height: 36),

                // Title
                const Text(
                  'Add your photo 📸',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can skip this and add it later',
                  style: TextStyle(fontSize: 14, color: AppTheme.gray),
                ),
                const SizedBox(height: 40),

                // Photo picker
                GestureDetector(
                  onTap: _showImagePicker,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.card,
                      border: Border.all(
                        color: AppTheme.pink.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: AppTheme.pinkShadow,
                      image: _selectedImage != null
                          ? DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: _selectedImage == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppTheme.pinkGrad,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Add Photo',
                          style: TextStyle(
                            color: AppTheme.pinkSoft,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                if (_selectedImage != null)
                  TextButton.icon(
                    onPressed: _showImagePicker,
                    icon: const Icon(Icons.edit,
                        color: AppTheme.pink, size: 16),
                    label: const Text(
                      'Change Photo',
                      style:
                      TextStyle(color: AppTheme.pink, fontSize: 13),
                    ),
                  ),

                const Spacer(),

                // Continue button
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
                          : const Text(
                        'Continue',
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

                // Skip button
                TextButton(
                  onPressed: _isLoading ? null : _continue,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: AppTheme.gray2,
                      fontSize: 14,
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

  Widget _buildProgress(int current, int total) {
    return Row(
      children: List.generate(total, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < total - 1 ? 6 : 0),
            height: 3,
            decoration: BoxDecoration(
              color: index < current ? AppTheme.pink : AppTheme.gray3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
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
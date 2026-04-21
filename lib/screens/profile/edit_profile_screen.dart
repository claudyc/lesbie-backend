import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  String? _selectedIdentity;
  String? _selectedLookingFor;
  List<String> _selectedInterests = [];
  File? _newPhoto;
  bool _isLoading = false;
  final _picker = ImagePicker();

  final List<Map<String, String>> _identities = [
    {'key': 'stud', 'label': 'Stud 👑'},
    {'key': 'femme', 'label': 'Femme 💕'},
    {'key': 'versatile', 'label': 'Versatile ⚖️'},
    {'key': 'androgyne', 'label': 'Androgyne 🌈'},
    {'key': 'prefer_not_say', 'label': 'Pito pa di 🤷'},
  ];

  final List<Map<String, String>> _lookingForOptions = [
    {'key': 'stud', 'label': 'Stud 👑'},
    {'key': 'femme', 'label': 'Femme 💕'},
    {'key': 'versatile', 'label': 'Versatile ⚖️'},
    {'key': 'any', 'label': 'Nenpòt 🌈'},
    {'key': 'friendship', 'label': 'Zanmitay 💬'},
  ];

  final List<Map<String, String>> _interestOptions = [
    {'key': 'music', 'label': 'Mizik 🎵'},
    {'key': 'travel', 'label': 'Vwayaj ✈️'},
    {'key': 'sports', 'label': 'Spò ⚽'},
    {'key': 'cooking', 'label': 'Kwizin 🍳'},
    {'key': 'reading', 'label': 'Lekti 📚'},
    {'key': 'art', 'label': 'Atizana 🎨'},
    {'key': 'movies', 'label': 'Fim 🎬'},
    {'key': 'nature', 'label': 'Nati 🌿'},
    {'key': 'fitness', 'label': 'Fitness 💪'},
    {'key': 'dancing', 'label': 'Dans 💃'},
    {'key': 'gaming', 'label': 'Gaming 🎮'},
    {'key': 'photography', 'label': 'Foto 📸'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.userData['name'] ?? '',
    );
    _bioController = TextEditingController(
      text: widget.userData['bio'] ?? '',
    );
    _cityController = TextEditingController(
      text: widget.userData['city'] ?? '',
    );
    _selectedIdentity = widget.userData['identity'];
    _selectedLookingFor = widget.userData['lookingFor'];
    _selectedInterests =
    List<String>.from(widget.userData['interests'] ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked != null) {
      setState(() => _newPhoto = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      _showError('Non pa ka vid!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String? photoUrl = widget.userData['photoUrl'];

      // Upload nouvo foto si moun chwazi youn
      if (_newPhoto != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('${user.uid}.jpg');
        await ref.putFile(_newPhoto!);
        photoUrl = await ref.getDownloadURL();
      }

      // Mete ajou Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'city': _cityController.text.trim(),
        'identity': _selectedIdentity,
        'lookingFor': _selectedLookingFor,
        'interests': _selectedInterests,
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSuccess('Pwofil mete ajou! ✅');
        Navigator.pop(context, true);
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
          'Modifye pwofil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text(
              'Sove',
              style: TextStyle(
                color: Color(0xFFD4537E),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto pwofil
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD4537E),
                        border: Border.all(
                          color: const Color(0xFF7F77DD),
                          width: 3,
                        ),
                        image: _newPhoto != null
                            ? DecorationImage(
                          image: FileImage(_newPhoto!),
                          fit: BoxFit.cover,
                        )
                            : widget.userData['photoUrl'] != null
                            ? DecorationImage(
                          image: NetworkImage(
                            widget.userData['photoUrl'],
                          ),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: _newPhoto == null &&
                          widget.userData['photoUrl'] == null
                          ? Center(
                        child: Text(
                          widget.userData['name'] != null
                              ? widget.userData['name'][0]
                              .toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD4537E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Non
            _buildLabel('Non konplè'),
            _buildTextField(
              controller: _nameController,
              hint: 'Non ou',
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 16),

            // Bio
            _buildLabel('Bio — pale de ou'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              child: TextField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 200,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                  'Di yon bagay sou ou... (200 karaktè maks)',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Vil
            _buildLabel('Vil'),
            _buildTextField(
              controller: _cityController,
              hint: 'Vil ou',
              icon: Icons.location_city,
            ),

            const SizedBox(height: 24),

            // Idantite
            _buildLabel('Idantite ou'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _identities.map((item) {
                final isSelected = _selectedIdentity == item['key'];
                return GestureDetector(
                  onTap: () => setState(
                        () => _selectedIdentity = item['key'],
                  ),
                  child: _buildChip(
                    item['label']!,
                    isSelected,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Chache
            _buildLabel('Kisa ou chache?'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _lookingForOptions.map((item) {
                final isSelected =
                    _selectedLookingFor == item['key'];
                return GestureDetector(
                  onTap: () => setState(
                        () => _selectedLookingFor = item['key'],
                  ),
                  child: _buildChip(
                    item['label']!,
                    isSelected,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Enterè
            _buildLabel('Enterè ou'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _interestOptions.map((item) {
                final isSelected =
                _selectedInterests.contains(item['key']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedInterests.remove(item['key']);
                      } else {
                        _selectedInterests.add(item['key']!);
                      }
                    });
                  },
                  child: _buildChip(
                    item['label']!,
                    isSelected,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Bouton sove
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
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
                  'Sove chanjman yo ✅',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(icon, color: const Color(0xFF7F77DD)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFD4537E)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFD4537E)
              : Colors.white.withOpacity(0.15),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : Colors.white.withOpacity(0.8),
          fontWeight:
          isSelected ? FontWeight.bold : FontWeight.normal,
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
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../core/theme.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final _picker = ImagePicker();
  bool _isUploading = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _openCamera() async {
    final user = _currentUser;
    if (user == null) return;

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
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.gray3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Add Story',
                style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _buildOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            _buildOption(
              icon: Icons.videocam_outlined,
              label: 'Record a Video',
              onTap: () {
                Navigator.pop(context);
                _pickVideoAndUpload();
              },
            ),
            const SizedBox(height: 12),
            _buildOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openTextStory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TextStoryCreator(
          onPost: (text, bgColor, textColor) =>
              _postTextStory(text, bgColor, textColor),
        ),
      ),
    );
  }

  Widget _buildOption({
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
          border: Border.all(color: AppTheme.pink.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.pink, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final user = _currentUser;
    if (user == null) return;

    // ✅ FIX 1 — verifye pèmisyon anvan kamera/galri
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) _showError('Kamera pèmisyon obligatwa.');
        return;
      }
    } else {
      final status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          if (mounted) _showError('Galri pèmisyon obligatwa.');
          return;
        }
      }
    }

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('stories')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await _saveStory(user, imageUrl: url);

      // ✅ FIX 2 — efase fichye tanporè apre upload
      await file.delete();
    } catch (e) {
      if (mounted) _showError('Error uploading: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickVideoAndUpload() async {
    final user = _currentUser;
    if (user == null) return;

    // ✅ FIX 1 — verifye pèmisyon kamera pou video
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      if (mounted) _showError('Kamera ak mikwofòn pèmisyon obligatwa pou video.');
      return;
    }

    final picked = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 30),
    );
    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('stories')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.mp4');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await _saveStory(user, videoUrl: url);

      // ✅ FIX 2 — efase fichye tanporè
      await file.delete();
    } catch (e) {
      if (mounted) _showError('Error uploading video: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _postTextStory(
      String text, Color bgColor, Color textColor) async {
    final user = _currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      await _saveStory(
        user,
        storyText: text,
        bgColor: bgColor.toARGB32().toString(),
        textColor: textColor.toARGB32().toString(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveStory(User user, {
    String? imageUrl,
    String? videoUrl,
    String? storyText,
    String? bgColor,
    String? textColor,
  }) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data() ?? {};

    String type = 'image';
    if (videoUrl != null) type = 'video';
    if (storyText != null) type = 'text';

    await FirebaseFirestore.instance.collection('stories').add({
      'uid': user.uid,
      'username': userData['username'] ?? userData['name'] ?? 'User',
      'userPhoto': userData['photoUrl'],
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'storyText': storyText,
      'bgColor': bgColor,
      'textColor': textColor,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24)),
      ),
      'views': [],
      'reactions': [],
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Story posted! ✨'),
          backgroundColor: AppTheme.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Stories',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.white)),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _openTextStory,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTheme.pink.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.edit_outlined,
                              color: AppTheme.pink, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _isUploading ? null : _openCamera,
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: AppTheme.pinkGrad,
                            shape: BoxShape.circle,
                            boxShadow: AppTheme.pinkShadow,
                          ),
                          child: _isUploading
                              ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                              : const Icon(Icons.camera_alt,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stories')
                    .where('expiresAt', isGreaterThan: Timestamp.now())
                    .orderBy('expiresAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: AppTheme.pink));
                  }

                  // ✅ FIX 3 — trete erè Firestore
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off,
                              color: AppTheme.gray, size: 48),
                          const SizedBox(height: 12),
                          const Text('Erè koneksyon',
                              style: TextStyle(color: AppTheme.gray)),
                        ],
                      ),
                    );
                  }

                  final stories = snapshot.data?.docs ?? [];
                  final currentUid = _currentUser?.uid;

                  final List<QueryDocumentSnapshot> myStories = [];
                  final Map<String, List<QueryDocumentSnapshot>> otherStories = {};

                  for (final story in stories) {
                    final data = story.data() as Map<String, dynamic>;
                    final uid = data['uid'] as String?;
                    if (uid == null || uid.isEmpty) continue;

                    if (uid == currentUid) {
                      myStories.add(story);
                    } else {
                      otherStories.putIfAbsent(uid, () => []).add(story);
                    }
                  }

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _buildStoriesRow(
                          myStories: myStories,
                          otherStories: otherStories),
                      const SizedBox(height: 24),

                      if (stories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_stories_outlined,
                                  size: 64, color: AppTheme.gray2),
                              const SizedBox(height: 16),
                              const Text('No stories yet',
                                  style: TextStyle(
                                      color: AppTheme.gray,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              const Text(
                                'Add your first story or check back later.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppTheme.gray2, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              const Text('Recent Stories',
                                  style: TextStyle(
                                      color: AppTheme.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                              const Spacer(),
                              Text('${stories.length}',
                                  style: const TextStyle(
                                      color: AppTheme.gray,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: otherStories.length +
                                (myStories.isEmpty ? 0 : 1),
                            itemBuilder: (context, index) {
                              if (myStories.isNotEmpty && index == 0) {
                                final firstStory = myStories.first.data()
                                as Map<String, dynamic>;
                                return _buildStoryCard(
                                    firstStory, myStories, currentUid ?? '');
                              }

                              final adjustedIndex =
                              myStories.isEmpty ? index : index - 1;
                              final uid = otherStories.keys.elementAt(adjustedIndex);
                              final userStoriesList = otherStories[uid]!;
                              final firstStory = userStoriesList.first.data()
                              as Map<String, dynamic>;

                              return _buildStoryCard(
                                  firstStory, userStoriesList, uid);
                            },
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesRow({
    required List<QueryDocumentSnapshot> myStories,
    required Map<String, List<QueryDocumentSnapshot>> otherStories,
  }) {
    final currentUid = _currentUser?.uid;
    final hasContent = myStories.isNotEmpty || otherStories.isNotEmpty;

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // My Story bubble
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: myStories.isEmpty
                ? GestureDetector(
              onTap: _openCamera,
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 68, height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.card,
                          border: Border.all(
                              color: AppTheme.pink.withValues(alpha: 0.3),
                              width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.add,
                              color: AppTheme.pink, size: 28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  const SizedBox(
                    width: 78,
                    child: Text('Add Story',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppTheme.gray,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            )
                : _buildMyStoryPreview(myStories),
          ),

          // Other stories bubbles
          ...otherStories.entries.map((entry) {
            final uid = entry.key;
            final userStoriesList = entry.value;
            final data = userStoriesList.first.data() as Map<String, dynamic>;

            // ✅ FIX 4 — indikatè "vue" pou stories ou deja wè
            final views = List.from(data['views'] ?? []);
            final isViewed = views.contains(currentUid);

            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildOtherStoryCircle(
                data: data,
                stories: userStoriesList,
                isViewed: isViewed,
              ),
            );
          }),

          if (!hasContent) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMyStoryPreview(List<QueryDocumentSnapshot> myStories) {
    final data = myStories.first.data() as Map<String, dynamic>;
    final imageUrl = data['imageUrl'];
    final storyText = data['storyText'];
    final bgColorStr = data['bgColor'];

    Color bgColor = AppTheme.card;
    if (bgColorStr != null) {
      try {
        bgColor = Color(int.parse(bgColorStr) & 0xFFFFFFFF);
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _viewStory(myStories, _currentUser?.uid ?? ''),
      child: Column(
        children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.pink, width: 2),
              color: bgColor,
              boxShadow: AppTheme.pinkShadow,
              image: imageUrl != null
                  ? DecorationImage(
                  image: NetworkImage(imageUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: imageUrl == null
                ? Center(
              child: storyText != null &&
                  storyText.toString().trim().isNotEmpty
                  ? Text(storyText.toString()[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800))
                  : const Icon(Icons.auto_stories,
                  color: Colors.white, size: 28),
            )
                : null,
          ),
          const SizedBox(height: 7),
          const SizedBox(
            width: 78,
            child: Text('My Story',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ✅ FIX 4 — ajoute paramèt isViewed pou chanje koulè sèk la
  Widget _buildOtherStoryCircle({
    required Map<String, dynamic> data,
    required List<QueryDocumentSnapshot> stories,
    bool isViewed = false,
  }) {
    final username = data['username'] ?? 'User';
    final userPhoto = data['userPhoto'];
    final imageUrl = data['imageUrl'];

    return GestureDetector(
      onTap: () => _viewStory(stories, data['uid'] ?? ''),
      child: Column(
        children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // ✅ Sèk gri si deja wè, pink si pa wè — menm jan WhatsApp
              border: Border.all(
                color: isViewed
                    ? AppTheme.gray.withValues(alpha: 0.5)
                    : AppTheme.pink,
                width: 2,
              ),
              color: AppTheme.card,
              image: userPhoto != null
                  ? DecorationImage(
                  image: NetworkImage(userPhoto), fit: BoxFit.cover)
                  : imageUrl != null
                  ? DecorationImage(
                  image: NetworkImage(imageUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: userPhoto == null && imageUrl == null
                ? Center(
              child: Text(
                username.toString().isNotEmpty
                    ? username.toString()[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800),
              ),
            )
                : null,
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: 78,
            child: Text(
              username.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isViewed ? AppTheme.gray : AppTheme.white,
                fontSize: 11,
                fontWeight: isViewed ? FontWeight.w400 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(
      Map<String, dynamic> data,
      List<QueryDocumentSnapshot> userStories,
      String uid,
      ) {
    final username = data['username'] ?? 'User';
    final imageUrl = data['imageUrl'];
    final storyText = data['storyText'];
    final bgColorStr = data['bgColor'];
    final textColorStr = data['textColor'];
    final userPhoto = data['userPhoto'];
    final isMyStory = uid == _currentUser?.uid;
    final views = (data['views'] as List?)?.length ?? 0;
    final type = data['type'] ?? 'image';

    Color bgColor = Colors.black;
    if (bgColorStr != null) {
      try {
        bgColor = Color(int.parse(bgColorStr) & 0xFFFFFFFF);
      } catch (_) {}
    }

    Color textColor = Colors.white;
    if (textColorStr != null) {
      try {
        textColor = Color(int.parse(textColorStr) & 0xFFFFFFFF);
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _viewStory(userStories, uid),
      child: Container(
        decoration: BoxDecoration(
          color: type == 'text' ? bgColor : AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: isMyStory
                ? AppTheme.pink
                : AppTheme.pink.withValues(alpha: 0.12),
            width: isMyStory ? 2 : 1,
          ),
          image: imageUrl != null
              ? DecorationImage(
              image: NetworkImage(imageUrl), fit: BoxFit.cover)
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            gradient: type == 'text'
                ? null
                : LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.pinkGrad,
                        border: Border.all(color: AppTheme.pink, width: 2),
                        image: userPhoto != null
                            ? DecorationImage(
                            image: NetworkImage(userPhoto),
                            fit: BoxFit.cover)
                            : null,
                      ),
                      child: userPhoto == null
                          ? Center(
                        child: Text(username[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      )
                          : null,
                    ),
                    const Spacer(),
                    if (isMyStory)
                      GestureDetector(
                        onTap: () => _deleteStory(userStories.first.id),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),

                if (type == 'text' && storyText != null)
                  Expanded(
                    child: Center(
                      child: Text(storyText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis),
                    ),
                  )
                else if (type == 'video')
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_circle_fill,
                            color: Colors.white, size: 32),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: imageUrl == null
                        ? Center(
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.pinkGrad,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(username[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22)),
                        ),
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),

                Text(isMyStory ? 'My Story' : username,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined,
                        color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    Text('$views views',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    const Spacer(),
                    if (userStories.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.pink,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${userStories.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewStory(List<QueryDocumentSnapshot> stories, String uid) {
    // ✅ FIX 5 — mete ajou views yon sèl fwa (pa pou chak story)
    final currentUid = _currentUser?.uid;
    if (currentUid != null) {
      for (final story in stories) {
        final data = story.data() as Map<String, dynamic>;
        final views = List.from(data['views'] ?? []);
        if (!views.contains(currentUid) && data['uid'] != currentUid) {
          story.reference.update({
            'views': FieldValue.arrayUnion([currentUid]),
          });
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryViewScreen(
          stories: stories,
          currentUserUid: currentUid ?? '',
        ),
      ),
    );
  }

  Future<void> _deleteStory(String storyId) async {
    await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Story deleted'),
          backgroundColor: AppTheme.gray3,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Text Story Creator ─────────────────────────────────────────────────────────
class TextStoryCreator extends StatefulWidget {
  final Function(String text, Color bgColor, Color textColor) onPost;
  const TextStoryCreator({super.key, required this.onPost});

  @override
  State<TextStoryCreator> createState() => _TextStoryCreatorState();
}

class _TextStoryCreatorState extends State<TextStoryCreator> {
  final _textController = TextEditingController();
  Color _selectedBgColor = Colors.black;
  Color _selectedTextColor = Colors.white;
  bool _isPosting = false;

  final List<Color> _bgColors = [
    Colors.black,
    const Color(0xFF1A1A2E),
    const Color(0xFF16213E),
    const Color(0xFF0F3460),
    const Color(0xFF2C3E50),
    const Color(0xFF7B2D8B),
    const Color(0xFFFF2D8D),
    const Color(0xFFE94560),
    const Color(0xFF27AE60),
    const Color(0xFFE67E22),
  ];

  final List<Color> _textColors = [
    Colors.white,
    Colors.black,
    const Color(0xFFFF2D8D),
    const Color(0xFFFFD700),
    const Color(0xFF00E5FF),
    const Color(0xFF69FF47),
    const Color(0xFFFF6B6B),
    const Color(0xFFE040FB),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _selectedBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _isPosting || _textController.text.trim().isEmpty
                  ? null
                  : () async {
                setState(() => _isPosting = true);
                await widget.onPost(
                  _textController.text.trim(),
                  _selectedBgColor,
                  _selectedTextColor,
                );
                setState(() => _isPosting = false);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isPosting
                    ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      color: AppTheme.pink, strokeWidth: 2),
                )
                    : const Text('Post',
                    style: TextStyle(
                        color: AppTheme.pink,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTextColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type something...',
                    hintStyle: TextStyle(
                        color: _selectedTextColor.withValues(alpha: 0.5),
                        fontSize: 28),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Text Color',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _textColors.map((color) {
                      final isSelected = _selectedTextColor == color;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedTextColor = color),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: isSelected ? 38 : 32,
                          height: isSelected ? 38 : 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Background',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _bgColors.map((color) {
                      final isSelected = _selectedBgColor == color;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedBgColor = color),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: isSelected ? 38 : 32,
                          height: isSelected ? 38 : 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Story Viewer ───────────────────────────────────────────────────────────────
class StoryViewScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> stories;
  final String currentUserUid;

  const StoryViewScreen({
    super.key,
    required this.stories,
    required this.currentUserUid,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _progressController;
  bool _isPaused = false;

  // ✅ FIX 6 — reply text controller tankou WhatsApp
  final _replyController = TextEditingController();
  bool _isReplying = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _startProgress();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _startProgress() {
    _progressController.reset();
    _progressController.forward().then((_) {
      if (!mounted) return;
      if (_currentIndex < widget.stories.length - 1) {
        setState(() => _currentIndex++);
        _startProgress();
      } else {
        Navigator.pop(context);
      }
    });
  }

  void _goNext() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _startProgress();
    } else {
      Navigator.pop(context);
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startProgress();
    }
  }

  void _pause() {
    if (!_isPaused) {
      _progressController.stop();
      setState(() => _isPaused = true);
    }
  }

  void _resume() {
    if (_isPaused) {
      _progressController.forward();
      setState(() => _isPaused = false);
    }
  }

  // ✅ FIX 6 — reply dirèkteman sou story tankou WhatsApp
  Future<void> _sendReply(String text) async {
    if (text.trim().isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final storyDoc = widget.stories[_currentIndex];
    final storyData = storyDoc.data() as Map<String, dynamic>;
    final storyOwnerUid = storyData['uid']?.toString() ?? '';

    if (storyOwnerUid.isEmpty || storyOwnerUid == currentUser.uid) return;

    try {
      // Jwenn oswa kreye match ant 2 users yo
      final matchQuery = await FirebaseFirestore.instance
          .collection('matches')
          .where('users', arrayContains: currentUser.uid)
          .get();

      String? matchId;
      for (final doc in matchQuery.docs) {
        final users = List<String>.from(doc.data()['users'] ?? []);
        if (users.contains(storyOwnerUid)) {
          matchId = doc.id;
          break;
        }
      }

      // Si pa gen match, kreye youn
      if (matchId == null) {
        final newMatch = await FirebaseFirestore.instance
            .collection('matches')
            .add({
          'users': [currentUser.uid, storyOwnerUid],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': text,
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
        matchId = newMatch.id;
      }

      // Voye mesaj la
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .add({
        'text': '📸 Story reply: $text',
        'type': 'text',
        'senderId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .update({
        'lastMessage': '📸 Story reply: $text',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      _replyController.clear();
      setState(() => _isReplying = false);
      _resume();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reply sent! 💬'),
            backgroundColor: AppTheme.pink,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1500),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendStoryReaction(String emoji) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUid = currentUser?.uid;
    if (currentUid == null) return;

    final storyDoc = widget.stories[_currentIndex];
    final storyData = storyDoc.data() as Map<String, dynamic>;
    final storyOwnerUid = storyData['uid']?.toString() ?? '';

    if (storyOwnerUid.isEmpty) return;

    try {
      await storyDoc.reference.update({
        'reactions': FieldValue.arrayUnion([
          {
            'uid': currentUid,
            'emoji': emoji,
            'createdAt': Timestamp.now(),
          }
        ]),
      });

      if (currentUid != storyOwnerUid) {
        final myDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .get();
        final myData = myDoc.data() ?? {};

        await FirebaseFirestore.instance.collection('notifications').add({
          'toUid': storyOwnerUid,
          'fromUid': currentUid,
          'fromName': myData['username'] ?? myData['name'] ?? 'Someone',
          'fromPhoto': myData['photoUrl'],
          'type': 'story_react',
          'emoji': emoji,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reaction sent $emoji'),
          backgroundColor: AppTheme.pink,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 900),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reaction failed: $e'),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteCurrentStory() async {
    final storyId = widget.stories[_currentIndex].id;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Story',
            style: TextStyle(color: AppTheme.white)),
        content: const Text('Are you sure you want to delete this story?',
            style: TextStyle(color: AppTheme.gray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.gray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await FirebaseFirestore.instance
        .collection('stories')
        .doc(storyId)
        .delete();

    if (mounted) {
      if (widget.stories.length <= 1) {
        Navigator.pop(context);
      } else if (_currentIndex >= widget.stories.length - 1) {
        setState(() => _currentIndex--);
        _startProgress();
      } else {
        _startProgress();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex].data() as Map<String, dynamic>;
    final imageUrl = story['imageUrl'];
    final videoUrl = story['videoUrl'];
    final storyText = story['storyText'];
    final bgColorStr = story['bgColor'];
    final textColorStr = story['textColor'];
    final username = story['username'] ?? 'User';
    final userPhoto = story['userPhoto'];
    final storyUid = story['uid'] ?? '';
    final type = story['type'] ?? 'image';
    final isMyStory = storyUid == widget.currentUserUid;

    Color bgColor = Colors.black;
    if (bgColorStr != null) {
      try {
        bgColor = Color(int.parse(bgColorStr) & 0xFFFFFFFF);
      } catch (_) {}
    }

    Color textColor = Colors.white;
    if (textColorStr != null) {
      try {
        textColor = Color(int.parse(textColorStr) & 0xFFFFFFFF);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: type == 'text' ? bgColor : Colors.black,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTapDown: (details) {
          if (_isReplying) return;
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            _goPrev();
          } else {
            _goNext();
          }
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < -200) _goNext();
          else if (details.primaryVelocity! > 200) _goPrev();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Konteni ─────────────────────────────────────
            if (type == 'image' && imageUrl != null)
              Image.network(imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity)
            else if (type == 'video' && videoUrl != null)
              _VideoStoryPlayer(videoUrl: videoUrl)
            else if (type == 'text' && storyText != null)
                Container(
                  color: bgColor,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.fromLTRB(32, 90, 32, 150),
                  child: Text(storyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.4)),
                ),

            // Gradient top
            if (type != 'text')
              Positioned(
                top: 0, left: 0, right: 0, height: 140,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8, right: 8,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) => Row(
                  children: List.generate(widget.stories.length, (i) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: i < _currentIndex
                                ? 1.0
                                : i == _currentIndex
                                ? _progressController.value
                                : 0.0,
                            backgroundColor:
                            Colors.white.withValues(alpha: 0.3),
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 3,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // User info + bouton
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16, right: 16,
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.pinkGrad,
                      border: Border.all(color: AppTheme.pink, width: 2),
                      image: userPhoto != null
                          ? DecorationImage(
                          image: NetworkImage(userPhoto), fit: BoxFit.cover)
                          : null,
                    ),
                    child: userPhoto == null
                        ? Center(
                      child: Text(username[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(username,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4)
                          ])),
                  const Spacer(),
                  if (_isPaused)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.pause_circle_outline,
                          color: Colors.white70, size: 20),
                    ),
                  if (isMyStory)
                    GestureDetector(
                      onTap: _deleteCurrentStory,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ FIX 6 — Reactions + Reply bar anba (tankou WhatsApp)
            if (!isMyStory)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 0, right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emoji reactions
                    if (!_isReplying)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['❤️', '😍', '🔥', '👏', '😮']
                            .map((emoji) {
                          return GestureDetector(
                            onTap: () => _sendStoryReaction(emoji),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                              child: Text(emoji,
                                  style: const TextStyle(fontSize: 24)),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 12),

                    // Reply input bar — tankou WhatsApp
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _isReplying = true);
                                _pause();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: _isReplying
                                    ? TextField(
                                  controller: _replyController,
                                  autofocus: true,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
                                  decoration: const InputDecoration(
                                    hintText: 'Reply to story...',
                                    hintStyle: TextStyle(
                                        color: Colors.white54),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (text) => _sendReply(text),
                                )
                                    : const Text('Reply to story...',
                                    style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14)),
                              ),
                            ),
                          ),
                          if (_isReplying) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                _sendReply(_replyController.text);
                              },
                              child: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.pinkGrad,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.send,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() => _isReplying = false);
                                _replyController.clear();
                                _resume();
                              },
                              child: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Reactions sèlman pou my story (pa gen reply)
            if (isMyStory)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['❤️', '😍', '🔥', '👏', '😮']
                      .map((emoji) {
                    return GestureDetector(
                      onTap: () => _sendStoryReaction(emoji),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Video Story Player ─────────────────────────────────────────────────────────
class _VideoStoryPlayer extends StatefulWidget {
  final String videoUrl;
  const _VideoStoryPlayer({required this.videoUrl});

  @override
  State<_VideoStoryPlayer> createState() => _VideoStoryPlayerState();
}

class _VideoStoryPlayerState extends State<_VideoStoryPlayer> {
  late VideoPlayerController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    )..initialize().then((_) {
      if (mounted) {
        setState(() => _isReady = true);
        _controller.play();
        _controller.setLooping(true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.pink));
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
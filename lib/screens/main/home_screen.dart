import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/theme.dart';
import '../chat/chat_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../stories/stories_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userData;
  final _currentUser = FirebaseAuth.instance.currentUser;

  // ✅ FIX 1 — State pou connections, likes, ak blocked users
  // Pa FutureBuilder + StreamBuilder pou chak kat
  Set<String> _connectedUids = {};
  Set<String> _likedUids = {};
  Set<String> _blockedUids = {};
  bool _isLoading = true;

  static const String _backendUrl = 'https://lesbie-backend.vercel.app';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ✅ FIX 1 — Chaje tout done yo yon sèl fwa
  Future<void> _loadAll() async {
    if (_currentUser == null) return;
    await Future.wait([
      _loadUserData(),
      _loadConnectedUids(),
      _loadMyLikes(),
      _loadBlockedUids(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .get();
    if (mounted && doc.exists) {
      setState(() => _userData = doc.data());
    }
  }

  // ✅ FIX 1 — Connections chaje yon sèl fwa nan state
  Future<void> _loadConnectedUids() async {
    if (_currentUser == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('connections')
        .where('users', arrayContains: _currentUser!.uid)
        .get();

    final uids = <String>{};
    for (final doc in snap.docs) {
      final users = List<String>.from(doc.data()['users'] ?? []);
      for (final uid in users) {
        if (uid != _currentUser!.uid) uids.add(uid);
      }
    }
    if (mounted) setState(() => _connectedUids = uids);
  }

  // ✅ FIX 2 — Chaje tous likes yon sèl fwa (pa 50 StreamBuilder)
  Future<void> _loadMyLikes() async {
    if (_currentUser == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('likes')
        .where('fromUid', isEqualTo: _currentUser!.uid)
        .get();

    if (mounted) {
      setState(() {
        _likedUids = snap.docs
            .map((d) => (d.data()['toUid'] ?? '') as String)
            .where((uid) => uid.isNotEmpty)
            .toSet();
      });
    }
  }

  // ✅ FIX 3 — Chaje blocked users pou filtre grid la
  Future<void> _loadBlockedUids() async {
    if (_currentUser == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('blocked_users')
        .where('blockedBy', isEqualTo: _currentUser!.uid)
        .get();

    if (mounted) {
      setState(() {
        _blockedUids = snap.docs
            .map((d) => (d.data()['blockedUid'] ?? '') as String)
            .where((uid) => uid.isNotEmpty)
            .toSet();
      });
    }
  }

  Future<void> _sendPushNotification({
    required String toUid,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(toUid)
          .get();
      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null) return;

      await http.post(
        Uri.parse('$_backendUrl/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': fcmToken,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );
    } catch (e) {
      debugPrint('Push notification error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX 4 — IndexedStack kenbe eta chak tab (pa rekreye yo)
    final List<Widget> screens = [
      _buildDiscoverTab(),
      const StoriesScreen(),
      const ChatListScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      // ✅ FIX 4 — IndexedStack olye screens[_currentIndex]
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0A12),
        border: Border(
          top: BorderSide(
            color: AppTheme.pink.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUid', isEqualTo: _currentUser?.uid)
            .where('read', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data?.docs.length ?? 0;

          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: const Color(0xFF0B0A12),
            selectedItemColor: AppTheme.pinkSoft,
            unselectedItemColor: AppTheme.gray2,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Discover',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.auto_stories_outlined),
                activeIcon: Icon(Icons.auto_stories),
                label: 'Stories',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (unreadCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppTheme.pink,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: const Icon(Icons.notifications),
                label: 'Notifs',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 108,
                  child: Image.asset(
                    'assets/logos/assetslogoslesbie_chat_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'Lesbie Chat',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      );
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.pink.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: AppTheme.gray,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildStoriesRow(),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Women near you',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(
                child: CircularProgressIndicator(color: AppTheme.pink))
                : StreamBuilder<QuerySnapshot>(
              // ✅ FIX 5 — retire isNotEqualTo — filtre côté Flutter
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.pink),
                  );
                }

                // ✅ FIX 3+5 — filtre: pa mwen, pa connected, pa blocked
                final users =
                (snapshot.data?.docs ?? []).where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uid = data['uid'] ?? doc.id;
                  return uid != _currentUser?.uid &&
                      !_connectedUids.contains(uid) &&
                      !_blockedUids.contains(uid);
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppTheme.gray2,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No new profiles yet',
                          style: TextStyle(
                            color: AppTheme.gray,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'Check back soon!',
                          style: TextStyle(
                            color: AppTheme.gray2,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data()
                    as Map<String, dynamic>;
                    // ✅ FIX 2 — pase isLiked dirèkteman, pa StreamBuilder
                    final uid = data['uid'] ?? users[index].id;
                    final isLiked = _likedUids.contains(uid);
                    return _buildUserCard(data, isLiked);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesRow() {
    return SizedBox(
      height: 92,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .where('expiresAt', isGreaterThan: Timestamp.now())
            .snapshots(),
        builder: (context, snapshot) {
          final allStories = snapshot.data?.docs ?? [];
          final currentUid = _currentUser?.uid;

          final List<QueryDocumentSnapshot> myStories = [];
          final Map<String, List<QueryDocumentSnapshot>>
          otherStoriesByUser = {};

          for (final doc in allStories) {
            final data = doc.data() as Map<String, dynamic>;
            final uid = data['uid']?.toString() ?? '';
            if (uid.isEmpty) continue;

            if (uid == currentUid) {
              myStories.add(doc);
            } else {
              otherStoriesByUser.putIfAbsent(uid, () => []).add(doc);
            }
          }

          final otherEntries = otherStoriesByUser.entries.toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: otherEntries.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                if (myStories.isEmpty) {
                  return _buildAddStory();
                }
                return _buildStoryItem(
                  stories: myStories,
                  label: 'My Story',
                  isMyStory: true,
                );
              }

              final stories = otherEntries[index - 1].value;
              final data =
              stories.first.data() as Map<String, dynamic>;
              final username =
                  data['username']?.toString() ?? 'User';

              // ✅ FIX 6 — pase isViewed pou stories déjà wè
              final views = List.from(data['views'] ?? []);
              final isViewed = views.contains(currentUid);

              return _buildStoryItem(
                stories: stories,
                label: username,
                isViewed: isViewed,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAddStory() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = 1),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: AppTheme.pinkGrad,
                shape: BoxShape.circle,
                boxShadow: AppTheme.pinkShadow,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            const SizedBox(
              width: 70,
              child: Text(
                'My Story',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.gray,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem({
    required List<QueryDocumentSnapshot> stories,
    required String label,
    bool isMyStory = false,
    bool isViewed = false, // ✅ FIX 6
  }) {
    final firstStory = stories.first.data() as Map<String, dynamic>;
    final photoUrl = firstStory['userPhoto'];
    final imageUrl = firstStory['imageUrl'];
    final bgColorStr = firstStory['bgColor'];
    final storyText = firstStory['storyText'];
    final displayLabel = label.isEmpty ? 'User' : label;

    Color bgColor = AppTheme.card;
    if (bgColorStr != null) {
      try {
        bgColor =
            Color(int.parse(bgColorStr.toString()) & 0xFFFFFFFF);
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoryViewScreen(
                stories: stories,
                currentUserUid: _currentUser?.uid ?? '',
              ),
            ),
          );
        },
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // ✅ FIX 6 — sèk gri si wè, pink si pa wè
                gradient: (!isMyStory && isViewed)
                    ? null
                    : AppTheme.pinkGrad,
                color: (!isMyStory && isViewed)
                    ? AppTheme.gray.withValues(alpha: 0.4)
                    : null,
                boxShadow: isMyStory ? AppTheme.pinkShadow : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(color: AppTheme.bg, width: 2),
                  image: photoUrl != null
                      ? DecorationImage(
                    image: NetworkImage(photoUrl),
                    fit: BoxFit.cover,
                  )
                      : imageUrl != null
                      ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: photoUrl == null && imageUrl == null
                    ? Center(
                  child: storyText != null
                      ? const Icon(
                    Icons.auto_stories,
                    color: Colors.white,
                    size: 24,
                  )
                      : Text(
                    displayLabel[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 70,
              child: Text(
                displayLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  // ✅ FIX 6 — tèks gri si wè
                  color: isMyStory
                      ? AppTheme.white
                      : isViewed
                      ? AppTheme.gray
                      : AppTheme.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIX 2 — isLiked pase kòm paramèt, pa StreamBuilder
  Widget _buildUserCard(Map<String, dynamic> data, bool isLiked) {
    final name = data['username'] ??
        data['name']?.toString().split(' ').first ??
        'User';

    final city = data['city'] ?? '';
    final photoUrl = data['photoUrl'];
    final isVerified = data['isVerified'] == true;
    final uid = data['uid'] ?? '';

    return GestureDetector(
      onTap: () => _showUserProfile(data),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: AppTheme.pink.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.card2,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusCard),
                      ),
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
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.pink,
                        ),
                      ),
                    )
                        : null,
                  ),
                  if (isVerified)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.pink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified,
                                color: Colors.white, size: 10),
                            SizedBox(width: 3),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleLike(uid, isLiked),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isLiked
                              ? AppTheme.pink
                              : Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isLiked
                                ? AppTheme.pink
                                : Colors.white
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (city.isNotEmpty)
                    Text(
                      '📍 $city',
                      style: const TextStyle(
                        color: AppTheme.gray,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(String otherUid, bool isLiked) async {
    if (_currentUser == null) return;

    final likeDoc = FirebaseFirestore.instance
        .collection('likes')
        .doc('${_currentUser!.uid}_$otherUid');

    if (isLiked) {
      await likeDoc.delete();
      // ✅ Mete ajou state lokal imedyatman
      if (mounted) setState(() => _likedUids.remove(otherUid));
    } else {
      await likeDoc.set({
        'fromUid': _currentUser!.uid,
        'toUid': otherUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ Mete ajou state lokal imedyatman
      if (mounted) setState(() => _likedUids.add(otherUid));

      final fromName =
          _userData?['username'] ?? _userData?['name'] ?? 'Someone';

      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': otherUid,
        'fromUid': _currentUser!.uid,
        'fromName': fromName,
        'fromPhoto': _userData?['photoUrl'],
        'type': 'like',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _sendPushNotification(
        toUid: otherUid,
        title: '❤️ New Like!',
        body: '$fromName liked your profile',
        data: {
          'type': 'like',
          'fromUid': _currentUser!.uid,
        },
      );

      final reverseDoc = await FirebaseFirestore.instance
          .collection('likes')
          .doc('${otherUid}_${_currentUser!.uid}')
          .get();

      if (reverseDoc.exists) {
        await _createConnection(otherUid);
      }
    }
  }

  Future<void> _createConnection(String otherUid) async {
    if (_currentUser == null) return;

    final connectionId = _currentUser!.uid.compareTo(otherUid) < 0
        ? '${_currentUser!.uid}_$otherUid'
        : '${otherUid}_${_currentUser!.uid}';

    final connectionDoc = FirebaseFirestore.instance
        .collection('connections')
        .doc(connectionId);

    final exists = await connectionDoc.get();

    if (!exists.exists) {
      await connectionDoc.set({
        'users': [_currentUser!.uid, otherUid],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('matches')
          .doc(connectionId)
          .set({
        'users': [_currentUser!.uid, otherUid],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      // ✅ Mete ajou _connectedUids lokal
      if (mounted) setState(() => _connectedUids.add(otherUid));

      final fromName =
          _userData?['username'] ?? _userData?['name'] ?? 'Someone';

      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid': otherUid,
        'fromUid': _currentUser!.uid,
        'fromName': fromName,
        'fromPhoto': _userData?['photoUrl'],
        'type': 'connection',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _sendPushNotification(
        toUid: otherUid,
        title: '🎉 New Connection!',
        body: '$fromName connected with you! Start chatting.',
        data: {
          'type': 'connection',
          'fromUid': _currentUser!.uid,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Text('🎉 ', style: TextStyle(fontSize: 18)),
                Text(
                  'New Connection! You can now chat!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.pink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showUserProfile(Map<String, dynamic> data) {
    final name = data['username'] ??
        data['name']?.toString().split(' ').first ??
        'User';

    final city = data['city'] ?? '';
    final photoUrl = data['photoUrl'];
    final isVerified = data['isVerified'] == true;
    final uid = data['uid'] ?? '';
    final bio = data['bio'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
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
                  width: 100,
                  height: 100,
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
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  )
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.white,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        color: AppTheme.pink,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                if (city.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '📍 $city',
                    style: const TextStyle(
                      color: AppTheme.gray,
                      fontSize: 14,
                    ),
                  ),
                ],
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.gray,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // ✅ Like bouton — li etat lokal, pa StreamBuilder
                StatefulBuilder(
                  builder: (context, setModalState) {
                    final isLiked = _likedUids.contains(uid);
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: isLiked
                              ? const LinearGradient(colors: [
                            AppTheme.gray3,
                            AppTheme.gray3,
                          ])
                              : AppTheme.pinkGrad,
                          borderRadius:
                          BorderRadius.circular(AppTheme.radius),
                          boxShadow:
                          isLiked ? [] : AppTheme.pinkShadow,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _toggleLike(uid, isLiked);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radius),
                            ),
                          ),
                          icon: Icon(
                            isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.white,
                          ),
                          label: Text(
                            isLiked ? 'Liked ✓' : 'Like',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _blockUser(uid);
                        },
                        icon: const Icon(Icons.block,
                            color: AppTheme.gray, size: 16),
                        label: const Text('Block',
                            style: TextStyle(
                                color: AppTheme.gray, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.gray3
                                .withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppTheme.radius),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _reportUser(uid);
                        },
                        icon: const Icon(Icons.flag_outlined,
                            color: AppTheme.red, size: 16),
                        label: const Text('Report',
                            style: TextStyle(
                                color: AppTheme.red, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.red.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppTheme.radius),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _blockUser(String otherUid) async {
    if (_currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('blocked_users')
        .doc('${_currentUser!.uid}_$otherUid')
        .set({
      'blockedBy': _currentUser!.uid,
      'blockedUid': otherUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ✅ Mete ajou state lokal — retire user soti grid imedyatman
    if (mounted) setState(() => _blockedUids.add(otherUid));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User blocked'),
          backgroundColor: AppTheme.gray3,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _reportUser(String otherUid) async {
    if (_currentUser == null) return;

    await FirebaseFirestore.instance.collection('reports').add({
      'reportedBy': _currentUser!.uid,
      'reportedUid': otherUid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report submitted — thank you'),
          backgroundColor: AppTheme.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}